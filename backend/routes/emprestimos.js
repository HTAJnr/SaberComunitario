const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');
const { autenticar } = require('../middleware/permissoes');

// Taxas de multa por atraso (MT/dia) — RN03.1
const TAXA_MULTA = { ADULTO: 15, CRIANCA: 5, PROFESSOR: 10 };

// RN02: prazo = 14 + floor(distancia/10) ± ajustes, mínimo 7 dias
function calcularPrazo(distancia, tipoLeitor, historicoPontualidade) {
  const base = 14;
  const geografico = Math.floor((distancia || 0) / 10);
  const professor = tipoLeitor === 'PROFESSOR' ? 7 : 0;
  let pontualidade = 0;
  if (historicoPontualidade === 'Irregular') pontualidade = -3;
  if (historicoPontualidade === 'Mau') pontualidade = -5;
  const dias = Math.max(base + geografico + professor + pontualidade, 7);
  const prazo = new Date();
  prazo.setDate(prazo.getDate() + dias);
  return { prazo, dias, detalhes: { base, geografico, professor, pontualidade } };
}

function isAdmin(req) {
  return (req.session.nivel_acesso || req.session.funcionario?.NIVEL_ACESSO) === 'Administrador';
}

// RN03.1 — multa por atraso (sem dano)
async function calcularMulta(conn, prazo, numCartao, tipoLeitor) {
  const hoje = new Date();
  const diasAtraso = Math.max(0, Math.floor((hoje - new Date(prazo)) / (1000 * 60 * 60 * 24)));
  if (diasAtraso === 0) return { multa: 0, diasAtraso: 0 };

  if (tipoLeitor === 'PROFESSOR') {
    const r = await conn.execute(
      `SELECT COUNT(*) AS N FROM EMPRESTIMO
       WHERE NUM_CARTAO = :nc AND MULTA_VALOR > 0 AND DATA_DEVOLUCAO IS NOT NULL`,
      { nc: numCartao },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const multa = r.rows[0].N > 0 ? diasAtraso * TAXA_MULTA.PROFESSOR : 0;
    return { multa, diasAtraso };
  }

  const taxa = TAXA_MULTA[tipoLeitor] || TAXA_MULTA.ADULTO;
  return { multa: diasAtraso * taxa, diasAtraso };
}

// RN05 — penalização por dano ao material
async function calcularMultaDano(conn, codMaterial, estadoRetorno) {
  const estado = (estadoRetorno || '').toLowerCase();
  if (estado === 'bom') return { multaDano: 0, valorEstimado: null };

  const r = await conn.execute(
    `SELECT VALOR_AQUISICAO FROM MATERIAL_BIBLIOGRAFICO WHERE COD_MATERIAL = :id`,
    { id: codMaterial },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );
  const valorEstimado = r.rows.length > 0 ? (r.rows[0].VALOR_AQUISICAO || 0) : 0;

  let multaDano = 0;
  if (estado === 'degradado') {
    multaDano = valorEstimado * 0.20;
  } else if (estado === 'destruido' || estado === 'perdido') {
    multaDano = valorEstimado * 1.50 + 50;
  }
  return { multaDano, valorEstimado };
}

// Construir filtro de biblioteca: admin pode passar ?biblioteca=, não-admin é locked à sessão
function filtrosBiblioteca(req) {
  const params = {};
  let where = '';
  const bibParam = req.query.biblioteca;
  if (isAdmin(req) && bibParam) {
    where = ' AND COD_BIBLIOTECA = :cod_bib';
    params.cod_bib = bibParam;
  } else if (!isAdmin(req) && req.session.cod_biblioteca) {
    where = ' AND COD_BIBLIOTECA = :cod_bib';
    params.cod_bib = req.session.cod_biblioteca;
  }
  return { where, params };
}

// ── GET / — listar empréstimos com paginação, filtros de estado e biblioteca ───
router.get('/', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { estado } = req.query;
    const page  = Math.max(1, parseInt(req.query.page)  || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 20));
    const offset = (page - 1) * limit;

    const { where: bibWhere, params } = filtrosBiblioteca(req);

    // Colunas comuns a ambas as views
    const colunasActivos = `
      ID_EMPRESTIMO, NUM_CARTAO, NOME_LEITOR,
      MATERIAL_TITULO AS TITULO,
      DATA_RETIRADA   AS DATA_EMP,
      PRAZO_DEVOLUCAO AS DATA_DEVOLUCAO_PREV,
      MULTA_ESTIMADA  AS MULTA,
      DIAS_ATRASO,
      'ACTIVO'        AS ESTADO,
      BIBLIOTECA_NOME`;

    const colunasHistorico = `
      ID_EMPRESTIMO, NUM_CARTAO, NOME_LEITOR,
      MATERIAL_TITULO AS TITULO,
      DATA_RETIRADA   AS DATA_EMP,
      PRAZO_DEVOLUCAO AS DATA_DEVOLUCAO_PREV,
      MULTA_VALOR     AS MULTA,
      CASE WHEN DATA_DEVOLUCAO IS NOT NULL AND DATA_DEVOLUCAO > PRAZO_DEVOLUCAO
           THEN ROUND(DATA_DEVOLUCAO - PRAZO_DEVOLUCAO) ELSE 0 END AS DIAS_ATRASO,
      CASE WHEN DATA_DEVOLUCAO IS NOT NULL THEN 'DEVOLVIDO' ELSE 'HISTORICO' END AS ESTADO,
      BIBLIOTECA_NOME`;

    let innerSql;
    const estadoLower = (estado || 'activo').toLowerCase();

    if (estadoLower === 'activo') {
      innerSql = `SELECT ${colunasActivos} FROM vw_emprestimos_ativos WHERE 1=1${bibWhere} ORDER BY DATA_RETIRADA DESC`;
    } else if (estadoLower === 'vencido') {
      innerSql = `SELECT ${colunasActivos} FROM vw_emprestimos_ativos WHERE DIAS_ATRASO > 0${bibWhere} ORDER BY DIAS_ATRASO DESC`;
    } else if (estadoLower === 'devolvido') {
      innerSql = `SELECT ${colunasHistorico} FROM vw_historico_emprestimos WHERE DATA_DEVOLUCAO IS NOT NULL${bibWhere} ORDER BY DATA_RETIRADA DESC`;
    } else {
      // todos
      innerSql = `SELECT ${colunasHistorico} FROM vw_historico_emprestimos WHERE 1=1${bibWhere} ORDER BY DATA_RETIRADA DESC`;
    }

    const sql = `SELECT * FROM (
      SELECT t.*, ROWNUM AS RN FROM (${innerSql}) t WHERE ROWNUM <= :rn_max
    ) WHERE RN > :rn_min`;

    params.rn_max = offset + limit;
    params.rn_min = offset;

    const result = await conn.execute(sql, params, { outFormat: oracledb.OUT_FORMAT_OBJECT });
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[EMPRESTIMOS GET /] ERRO\x1b[0m', err.message);
    res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── GET /validar-leitor/:num_cartao — validação rápida antes de criar empréstimo ──
router.get('/validar-leitor/:num_cartao', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const nc = req.params.num_cartao;

    // Buscar leitor
    const leitorR = await conn.execute(
      `SELECT l.STATUS_LEITOR,
              CASE WHEN p.NUM_CARTAO IS NOT NULL THEN 'PROFESSOR'
                   WHEN a.NUM_CARTAO IS NOT NULL THEN 'ADULTO'
                   WHEN cr.NUM_CARTAO IS NOT NULL THEN 'CRIANCA'
                   ELSE 'ADULTO' END AS TIPO_LEITOR,
              l.NOME_COMPLETO
         FROM LEITOR l
         LEFT JOIN PROFESSOR p  ON p.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN ADULTO    a  ON a.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN CRIANCA   cr ON cr.NUM_CARTAO = l.NUM_CARTAO
        WHERE l.NUM_CARTAO = :nc`,
      { nc },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    if (leitorR.rows.length === 0) {
      return res.status(404).json({ pode_emprestar: false, motivo: 'Leitor não encontrado.', codigo: 'LEITOR_NAO_ENCONTRADO' });
    }

    const leitor = leitorR.rows[0];

    if (leitor.STATUS_LEITOR === 'Bloqueado') {
      return res.json({ pode_emprestar: false, motivo: 'Leitor está bloqueado permanentemente.', codigo: 'LEITOR_BLOQUEADO' });
    }

    // Verificar suspensão activa
    const suspR = await conn.execute(
      `SELECT s.ID_SUSPENSAO, s.DATA_FIM FROM SUSPENSAO s
        WHERE s.NUM_CARTAO = :nc AND s.ESTADO_SUSPENSAO = 'Activa' AND SYSDATE <= s.DATA_FIM
          AND ROWNUM = 1`,
      { nc },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (suspR.rows.length > 0) {
      return res.json({
        pode_emprestar: false,
        motivo: 'Leitor tem suspensão activa.',
        codigo: 'LEITOR_SUSPENSO',
        suspensao: { data_fim: suspR.rows[0].DATA_FIM }
      });
    }

    // Verificar empréstimo activo
    const empR = await conn.execute(
      `SELECT e.ID_EMPRESTIMO, m.TITULO, e.PRAZO_DEVOLUCAO
         FROM EMPRESTIMO e
         JOIN MATERIAL_BIBLIOGRAFICO m ON m.COD_MATERIAL = e.COD_MATERIAL
        WHERE e.NUM_CARTAO = :nc AND e.DATA_DEVOLUCAO IS NULL
          AND ROWNUM = 1`,
      { nc },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (empR.rows.length > 0) {
      const e = empR.rows[0];
      return res.json({
        pode_emprestar: false,
        motivo: 'Leitor tem empréstimo activo.',
        codigo: 'EMPRESTIMO_ACTIVO',
        emprestimo_activo: { id_emprestimo: e.ID_EMPRESTIMO, titulo: e.TITULO, prazo_devolucao: e.PRAZO_DEVOLUCAO }
      });
    }

    res.json({ pode_emprestar: true, motivo: null, codigo: null });
  } catch (err) {
    console.error('\x1b[31m[EMPRESTIMOS GET /validar-leitor] ERRO\x1b[0m', err.message);
    res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── POST /calcular-prazo — preview do prazo antes de confirmar empréstimo ──────
router.post('/calcular-prazo', autenticar, async (req, res) => {
  const { num_cartao } = req.body;
  if (!num_cartao) return res.status(400).json({ erro: true, codigo: 'DADOS_INCOMPLETOS', mensagem: 'num_cartao obrigatório.' });

  let conn;
  try {
    conn = await getConnection();
    const r = await conn.execute(
      `SELECT l.DISTANCIA_BIBLIOTECA, l.HISTORICO_PONTUALIDADE,
              CASE WHEN p.NUM_CARTAO IS NOT NULL THEN 'PROFESSOR'
                   WHEN a.NUM_CARTAO IS NOT NULL THEN 'ADULTO'
                   WHEN cr.NUM_CARTAO IS NOT NULL THEN 'CRIANCA'
                   ELSE 'ADULTO' END AS TIPO_LEITOR
         FROM LEITOR l
         LEFT JOIN PROFESSOR p  ON p.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN ADULTO    a  ON a.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN CRIANCA   cr ON cr.NUM_CARTAO = l.NUM_CARTAO
        WHERE l.NUM_CARTAO = :nc`,
      { nc: num_cartao },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (r.rows.length === 0) return res.status(404).json({ erro: true, codigo: 'LEITOR_NAO_ENCONTRADO', mensagem: 'Leitor não encontrado.' });

    const l = r.rows[0];
    const { prazo, dias, detalhes } = calcularPrazo(l.DISTANCIA_BIBLIOTECA, l.TIPO_LEITOR, l.HISTORICO_PONTUALIDADE);

    res.json({
      prazo_devolucao: prazo.toISOString().slice(0, 10),
      dias_prazo: dias,
      detalhes
    });
  } catch (err) {
    console.error('\x1b[31m[EMPRESTIMOS POST /calcular-prazo] ERRO\x1b[0m', err.message);
    res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── POST /preview-devolucao — simular multa antes de confirmar devolução ────────
router.post('/preview-devolucao', autenticar, async (req, res) => {
  const { id_emprestimo, estado_material_retorno } = req.body;
  if (!id_emprestimo) return res.status(400).json({ erro: true, codigo: 'DADOS_INCOMPLETOS', mensagem: 'id_emprestimo obrigatório.' });

  let conn;
  try {
    conn = await getConnection();
    const empR = await conn.execute(
      `SELECT e.PRAZO_DEVOLUCAO, e.NUM_CARTAO, e.COD_MATERIAL, e.DATA_DEVOLUCAO,
              CASE WHEN p.NUM_CARTAO IS NOT NULL THEN 'PROFESSOR'
                   WHEN a.NUM_CARTAO IS NOT NULL THEN 'ADULTO'
                   WHEN cr.NUM_CARTAO IS NOT NULL THEN 'CRIANCA'
                   ELSE 'ADULTO' END AS TIPO_LEITOR
         FROM EMPRESTIMO e
         JOIN LEITOR l ON l.NUM_CARTAO = e.NUM_CARTAO
         LEFT JOIN PROFESSOR p  ON p.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN ADULTO    a  ON a.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN CRIANCA   cr ON cr.NUM_CARTAO = l.NUM_CARTAO
        WHERE e.ID_EMPRESTIMO = :id`,
      { id: parseInt(id_emprestimo) },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (empR.rows.length === 0) return res.status(404).json({ erro: true, codigo: 'EMPRESTIMO_NAO_ENCONTRADO', mensagem: 'Empréstimo não encontrado.' });

    const emp = empR.rows[0];
    if (emp.DATA_DEVOLUCAO) return res.status(409).json({ erro: true, codigo: 'JA_DEVOLVIDO', mensagem: 'Empréstimo já devolvido.' });

    const { multa: multaAtraso, diasAtraso } = await calcularMulta(conn, emp.PRAZO_DEVOLUCAO, emp.NUM_CARTAO, emp.TIPO_LEITOR);
    const { multaDano, valorEstimado } = await calcularMultaDano(conn, emp.COD_MATERIAL, estado_material_retorno || 'Bom');
    const taxa = TAXA_MULTA[emp.TIPO_LEITOR] || TAXA_MULTA.ADULTO;

    res.json({
      multa_atraso: multaAtraso,
      multa_dano: multaDano,
      multa_total: multaAtraso + multaDano,
      dias_atraso: diasAtraso,
      detalhes: {
        taxa_diaria: taxa,
        estado_material: estado_material_retorno || 'Bom',
        valor_estimado_material: valorEstimado
      }
    });
  } catch (err) {
    console.error('\x1b[31m[EMPRESTIMOS POST /preview-devolucao] ERRO\x1b[0m', err.message);
    res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── GET /:id — detalhe de um empréstimo ─────────────────────────────────────────
router.get('/:id', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT e.*,
              l.NOME_COMPLETO AS NOME_LEITOR,
              m.TITULO, m.AUTOR
         FROM EMPRESTIMO e
         JOIN LEITOR l ON l.NUM_CARTAO = e.NUM_CARTAO
         JOIN MATERIAL_BIBLIOGRAFICO m ON m.COD_MATERIAL = e.COD_MATERIAL
        WHERE e.ID_EMPRESTIMO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (result.rows.length === 0) return res.status(404).json({ erro: true, codigo: 'EMPRESTIMO_NAO_ENCONTRADO', mensagem: 'Empréstimo não encontrado.' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(`\x1b[31m[EMPRESTIMOS GET /${req.params.id}] ERRO\x1b[0m`, err.message);
    res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── POST / — criar empréstimo ────────────────────────────────────────────────────
router.post('/', autenticar, async (req, res) => {
  const { num_cartao, cod_material, cod_funcionario, estado_material_saida } = req.body;
  if (!num_cartao || !cod_material) {
    return res.status(400).json({ erro: true, codigo: 'DADOS_INCOMPLETOS', mensagem: 'Leitor e material obrigatórios.' });
  }

  let conn;
  try {
    conn = await getConnection();

    // 1. Verificar disponibilidade do material
    const matR = await conn.execute(
      `SELECT m.ESTADO_MATERIAL_CONSERVACAO, m.COD_CATEGORIA,
              (SELECT COUNT(*) FROM EMPRESTIMO e
               WHERE e.COD_MATERIAL = m.COD_MATERIAL AND e.DATA_DEVOLUCAO IS NULL) AS EMP_ATIVOS,
              (SELECT COUNT(*) FROM TRANSFERENCIA t
               WHERE t.COD_MATERIAL = m.COD_MATERIAL
                 AND t.ESTADO_TRANSFERENCIA IN ('Pendente','Aprovada')) AS TRANS_ATIVAS
         FROM MATERIAL_BIBLIOGRAFICO m WHERE m.COD_MATERIAL = :id`,
      { id: cod_material },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (matR.rows.length === 0)
      return res.status(404).json({ erro: true, codigo: 'MATERIAL_NAO_ENCONTRADO', mensagem: 'Material não encontrado.' });

    const mat = matR.rows[0];
    if (mat.ESTADO_MATERIAL_CONSERVACAO === 'Indisponivel')
      return res.status(409).json({ erro: true, codigo: 'MATERIAL_INDISPONIVEL', mensagem: 'Material indisponível para empréstimo.' });
    if (mat.EMP_ATIVOS > 0)
      return res.status(409).json({ erro: true, codigo: 'MATERIAL_EMPRESTADO', mensagem: 'Material já se encontra emprestado.' });
    if (mat.TRANS_ATIVAS > 0)
      return res.status(409).json({ erro: true, codigo: 'MATERIAL_EM_TRANSFERENCIA', mensagem: 'Material está em processo de transferência.' });

    // 2. Verificar leitor
    const leitorR = await conn.execute(
      `SELECT l.STATUS_LEITOR, l.DISTANCIA_BIBLIOTECA, l.HISTORICO_PONTUALIDADE,
              CASE WHEN p.NUM_CARTAO IS NOT NULL THEN 'PROFESSOR'
                   WHEN a.NUM_CARTAO IS NOT NULL THEN 'ADULTO'
                   WHEN cr.NUM_CARTAO IS NOT NULL THEN 'CRIANCA'
                   ELSE 'ADULTO' END AS TIPO_LEITOR,
              (SELECT COUNT(*) FROM EMPRESTIMO e
               WHERE e.NUM_CARTAO = l.NUM_CARTAO AND e.DATA_DEVOLUCAO IS NULL) AS ATIVOS
         FROM LEITOR l
         LEFT JOIN PROFESSOR p  ON p.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN ADULTO    a  ON a.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN CRIANCA   cr ON cr.NUM_CARTAO = l.NUM_CARTAO
        WHERE l.NUM_CARTAO = :nc`,
      { nc: num_cartao },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (leitorR.rows.length === 0)
      return res.status(404).json({ erro: true, codigo: 'LEITOR_NAO_ENCONTRADO', mensagem: 'Leitor não encontrado.' });

    const leitor = leitorR.rows[0];

    if (leitor.STATUS_LEITOR === 'Bloqueado')
      return res.status(409).json({ erro: true, codigo: 'LEITOR_BLOQUEADO', mensagem: 'Leitor está bloqueado permanentemente.' });
    if (leitor.STATUS_LEITOR === 'Suspenso')
      return res.status(409).json({ erro: true, codigo: 'LEITOR_SUSPENSO', mensagem: 'Leitor tem suspensão activa.' });
    if (leitor.STATUS_LEITOR !== 'Activo')
      return res.status(409).json({ erro: true, codigo: 'LEITOR_INACTIVO', mensagem: `Leitor não pode efectuar empréstimos (estado: ${leitor.STATUS_LEITOR}).` });

    // RN01 v3 — limite de 1 empréstimo activo para todos
    if (leitor.ATIVOS >= 1)
      return res.status(409).json({ erro: true, codigo: 'EMPRESTIMO_ACTIVO', mensagem: 'Leitor já possui um empréstimo activo.' });

    // Verificar suspensão activa na tabela SUSPENSAO (leitor pode estar Activo mas com suspensão pendente de trigger)
    const suspR = await conn.execute(
      `SELECT COUNT(*) AS CNT FROM SUSPENSAO
        WHERE NUM_CARTAO = :nc AND ESTADO_SUSPENSAO = 'Activa' AND SYSDATE <= DATA_FIM`,
      { nc: num_cartao },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (suspR.rows[0].CNT > 0)
      return res.status(409).json({ erro: true, codigo: 'LEITOR_SUSPENSO', mensagem: 'Leitor tem suspensão activa.' });

    // RN04.1 — faixa etária
    const catR = await conn.execute(
      `SELECT FAIXA_ETARIA, NIVEL_LEITURA FROM CATEGORIA WHERE ID_CATEGORIA = :id`,
      { id: mat.COD_CATEGORIA },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    let avisoNivelLeitura = false;

    if (catR.rows.length > 0) {
      const cat = catR.rows[0];

      if (cat.FAIXA_ETARIA === 'Adulto' && leitor.TIPO_LEITOR === 'CRIANCA')
        return res.status(409).json({ erro: true, codigo: 'FAIXA_ETARIA_INVALIDA', mensagem: 'Material para adultos não pode ser emprestado a crianças.' });

      // RN04.2 — recomendação por literacia (só ADULTO, não bloqueia)
      if (leitor.TIPO_LEITOR === 'ADULTO' && cat.NIVEL_LEITURA) {
        const adultR = await conn.execute(
          `SELECT NIVEL_LITERACIA FROM ADULTO WHERE NUM_CARTAO = :nc`,
          { nc: num_cartao },
          { outFormat: oracledb.OUT_FORMAT_OBJECT }
        );
        if (adultR.rows.length > 0) {
          const nivelLeitor = adultR.rows[0].NIVEL_LITERACIA;
          const nivelMat = cat.NIVEL_LEITURA;
          const incompativel =
            (nivelLeitor === 'Basico'    && nivelMat !== 'Basico') ||
            (nivelLeitor === 'Funcional' && !['Basico', 'Intermedio'].includes(nivelMat));
          if (incompativel) avisoNivelLeitura = true;
        }
      }
    }

    // 4. Inserir empréstimo com prazo calculado por RN02
    const { prazo } = calcularPrazo(leitor.DISTANCIA_BIBLIOTECA, leitor.TIPO_LEITOR, leitor.HISTORICO_PONTUALIDADE);
    const prazoStr = prazo.toISOString().slice(0, 10);

    const empResult = await conn.execute(
      `INSERT INTO EMPRESTIMO
         (ID_EMPRESTIMO, NUM_CARTAO, COD_MATERIAL, DATA_RETIRADA, PRAZO_DEVOLUCAO,
          ESTADO_MATERIAL_SAIDA, MULTA_PAGA, COD_FUNCIONARIO)
       VALUES
         (SEQ_EMPRESTIMO.NEXTVAL, :nc, :id_mat, SYSDATE,
          TO_DATE(:prazo, 'YYYY-MM-DD'), :estado_saida, 'N', :id_func)
       RETURNING ID_EMPRESTIMO INTO :id_out`,
      {
        nc:          num_cartao,
        id_mat:      cod_material,
        prazo:       prazoStr,
        estado_saida: estado_material_saida || 'Bom',
        id_func:     cod_funcionario || req.session.cod_funcionario || null,
        id_out:      { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      }
    );
    await conn.commit();

    res.status(201).json({
      ok: true,
      id_emprestimo: empResult.outBinds.id_out[0],
      prazo_devolucao: prazoStr,
      aviso_nivel_leitura: avisoNivelLeitura
    });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[EMPRESTIMOS POST /] ERRO\x1b[0m', err.message);
    res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── PATCH /:id/devolver — registar devolução com RN03+RN05 ──────────────────────
router.patch('/:id/devolver', autenticar, async (req, res) => {
  const { estado_material_retorno, observacoes_devolucao } = req.body;
  let conn;
  try {
    conn = await getConnection();

    const empR = await conn.execute(
      `SELECT e.PRAZO_DEVOLUCAO, e.NUM_CARTAO, e.COD_MATERIAL, e.DATA_DEVOLUCAO,
              CASE WHEN p.NUM_CARTAO IS NOT NULL THEN 'PROFESSOR'
                   WHEN a.NUM_CARTAO IS NOT NULL THEN 'ADULTO'
                   WHEN cr.NUM_CARTAO IS NOT NULL THEN 'CRIANCA'
                   ELSE 'ADULTO' END AS TIPO_LEITOR
         FROM EMPRESTIMO e
         JOIN LEITOR l ON l.NUM_CARTAO = e.NUM_CARTAO
         LEFT JOIN PROFESSOR p  ON p.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN ADULTO    a  ON a.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN CRIANCA   cr ON cr.NUM_CARTAO = l.NUM_CARTAO
        WHERE e.ID_EMPRESTIMO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (empR.rows.length === 0)
      return res.status(404).json({ erro: true, codigo: 'EMPRESTIMO_NAO_ENCONTRADO', mensagem: 'Empréstimo não encontrado.' });

    const emp = empR.rows[0];
    if (emp.DATA_DEVOLUCAO)
      return res.status(409).json({ erro: true, codigo: 'JA_DEVOLVIDO', mensagem: 'Empréstimo já devolvido.' });

    const estadoRetorno = estado_material_retorno || 'Bom';

    // Calcular multa total = atraso (RN03.1) + dano (RN05)
    const { multa: multaAtraso, diasAtraso } = await calcularMulta(conn, emp.PRAZO_DEVOLUCAO, emp.NUM_CARTAO, emp.TIPO_LEITOR);
    const { multaDano } = await calcularMultaDano(conn, emp.COD_MATERIAL, estadoRetorno);
    const multaTotal = multaAtraso + multaDano;

    // RN05: definir motivo antes da procedure — CHECK constraint exige MOTIVO_INDISPONIBILIDADE
    // quando ESTADO = 'Indisponivel'. A procedure lida com 'PERDIDO' mas não define o motivo.
    const estadoLower = estadoRetorno.toLowerCase();
    if (estadoLower === 'destruido') {
      await conn.execute(
        `UPDATE MATERIAL_BIBLIOGRAFICO
            SET ESTADO_MATERIAL_CONSERVACAO = 'Indisponivel',
                MOTIVO_INDISPONIBILIDADE    = 'Destruído'
          WHERE COD_MATERIAL = :id`,
        { id: emp.COD_MATERIAL }
      );
    } else if (estadoLower === 'perdido') {
      await conn.execute(
        `UPDATE MATERIAL_BIBLIOGRAFICO
            SET MOTIVO_INDISPONIBILIDADE = 'Perdido em empréstimo'
          WHERE COD_MATERIAL = :id`,
        { id: emp.COD_MATERIAL }
      );
    }

    // Chamar procedure — faz COMMIT internamente e dispara trigger trg_aplica_suspensao
    const devolR = await conn.execute(
      `BEGIN processar_devolucao(:id_emp, :cond, :obs, :multa_val, :sucesso); END;`,
      {
        id_emp:    parseInt(req.params.id),
        cond:      estadoRetorno,
        obs:       observacoes_devolucao || null,
        multa_val: multaTotal,
        sucesso:   { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 200 }
      }
    );

    const sucesso = devolR.outBinds.sucesso;
    if (sucesso && sucesso.startsWith('Erro')) {
      return res.status(409).json({ erro: true, codigo: 'ERRO_DEVOLUCAO', mensagem: sucesso });
    }

    // Consultar suspensão criada pelo trigger (procedure já fez COMMIT)
    let suspensao = null;
    try {
      const suspR = await conn.execute(
        `SELECT DIAS_SUSPENSAO, DATA_FIM FROM (
           SELECT DIAS_SUSPENSAO, DATA_FIM FROM SUSPENSAO
            WHERE ID_EMPRESTIMO = :id ORDER BY DATA_INICIO DESC
         ) WHERE ROWNUM = 1`,
        { id: parseInt(req.params.id) },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      if (suspR.rows.length > 0) {
        suspensao = { dias: suspR.rows[0].DIAS_SUSPENSAO, data_fim: suspR.rows[0].DATA_FIM };
      }
    } catch (_) { /* suspensão é informação extra — não falhar por isso */ }

    res.json({ ok: true, multa: multaTotal, dias_atraso: diasAtraso, suspensao });
  } catch (err) {
    if (conn) try { await conn.rollback(); } catch (_) {}
    console.error(`\x1b[31m[EMPRESTIMOS PATCH /${req.params.id}/devolver] ERRO\x1b[0m`, err.message);
    res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── PATCH /:id/pagar-multa — marcar multa como paga ─────────────────────────────
router.patch('/:id/pagar-multa', autenticar, async (req, res) => {
  const { data_pagamento_multa } = req.body;
  let conn;
  try {
    conn = await getConnection();

    const empR = await conn.execute(
      `SELECT MULTA_VALOR, MULTA_PAGA FROM EMPRESTIMO WHERE ID_EMPRESTIMO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (empR.rows.length === 0)
      return res.status(404).json({ erro: true, codigo: 'EMPRESTIMO_NAO_ENCONTRADO', mensagem: 'Empréstimo não encontrado.' });

    const emp = empR.rows[0];
    if (emp.MULTA_PAGA === 'S')
      return res.status(409).json({ erro: true, codigo: 'MULTA_JA_PAGA', mensagem: 'Multa já foi registada como paga.' });
    if (!emp.MULTA_VALOR || emp.MULTA_VALOR === 0)
      return res.status(409).json({ erro: true, codigo: 'SEM_MULTA', mensagem: 'Este empréstimo não tem multa por pagar.' });

    const dataPag = data_pagamento_multa || new Date().toISOString().slice(0, 10);

    await conn.execute(
      `UPDATE EMPRESTIMO
          SET MULTA_PAGA = 'S',
              DATA_PAGAMENTO_MULTA = TO_DATE(:data, 'YYYY-MM-DD')
        WHERE ID_EMPRESTIMO = :id`,
      { data: dataPag, id: req.params.id }
    );
    await conn.commit();

    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[EMPRESTIMOS PATCH /${req.params.id}/pagar-multa] ERRO\x1b[0m`, err.message);
    res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── GET /:id/multa — preview de multa por atraso (sem dano, sem commit) ─────────
router.get('/:id/multa', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const empR = await conn.execute(
      `SELECT e.PRAZO_DEVOLUCAO, e.NUM_CARTAO,
              CASE WHEN p.NUM_CARTAO IS NOT NULL THEN 'PROFESSOR'
                   WHEN a.NUM_CARTAO IS NOT NULL THEN 'ADULTO'
                   WHEN cr.NUM_CARTAO IS NOT NULL THEN 'CRIANCA'
                   ELSE 'ADULTO' END AS TIPO_LEITOR
         FROM EMPRESTIMO e
         JOIN LEITOR l ON l.NUM_CARTAO = e.NUM_CARTAO
         LEFT JOIN PROFESSOR p  ON p.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN ADULTO    a  ON a.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN CRIANCA   cr ON cr.NUM_CARTAO = l.NUM_CARTAO
        WHERE e.ID_EMPRESTIMO = :id AND e.DATA_DEVOLUCAO IS NULL`,
      { id: parseInt(req.params.id) },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (empR.rows.length === 0) return res.json({ multa: 0, dias_atraso: 0 });

    const emp = empR.rows[0];
    const { multa, diasAtraso } = await calcularMulta(conn, emp.PRAZO_DEVOLUCAO, emp.NUM_CARTAO, emp.TIPO_LEITOR);
    res.json({ multa, dias_atraso: diasAtraso });
  } catch (err) {
    console.error(`\x1b[31m[EMPRESTIMOS GET /${req.params.id}/multa] ERRO\x1b[0m`, err.message);
    res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
