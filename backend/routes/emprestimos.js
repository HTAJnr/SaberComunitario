const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');

// Taxas de multa por tipo de leitor (MT/dia)
const TAXA_MULTA = { ADULTO: 15, CRIANCA: 5, PROFESSOR: 10 };

// RN02: prazo = 14 + floor(distancia/10) ± ajustes por tipo e histórico, mínimo 7 dias
function calcularPrazo(distancia, tipoLeitor, historicoPontualidade) {
  let dias = 14;
  dias += Math.floor((distancia || 0) / 10);
  if (tipoLeitor === 'PROFESSOR') dias += 7;
  if (historicoPontualidade === 'Irregular') dias -= 3;
  if (historicoPontualidade === 'Mau') dias -= 5;
  dias = Math.max(dias, 7);
  const prazo = new Date();
  prazo.setDate(prazo.getDate() + dias);
  return prazo;
}
const LIMITE_EMPRESTIMO = { PROFESSOR: 5, ADULTO: 3, CRIANCA: 2 };

function isAdmin(req) {
  return (req.session.nivel_acesso || req.session.funcionario?.FUNCAO) === 'Administrador';
}

async function calcularMulta(conn, id_emprestimo, prazo, numCartao, tipoLeitor) {
  const hoje = new Date();
  const diasAtraso = Math.max(0, Math.floor((hoje - new Date(prazo)) / (1000 * 60 * 60 * 24)));
  if (diasAtraso === 0) return 0;

  if (tipoLeitor === 'PROFESSOR') {
    // Primeira vez sem multa; a partir da segunda: 10MT/dia
    const antResult = await conn.execute(
      `SELECT COUNT(*) AS N FROM EMPRESTIMO
       WHERE NUM_CARTAO = :nc AND MULTA_VALOR > 0 AND DATA_DEVOLUCAO IS NOT NULL`,
      { nc: numCartao },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    return antResult.rows[0].N > 0 ? diasAtraso * TAXA_MULTA.PROFESSOR : 0;
  }

  const taxa = TAXA_MULTA[tipoLeitor] || TAXA_MULTA.ADULTO;
  return diasAtraso * taxa;
}

router.get('/', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { estado } = req.query;
    const bibFiltro = !isAdmin(req) && req.session.cod_biblioteca
      ? ` AND cod_BIBLIOTECA = '${req.session.cod_biblioteca}'`
      : '';

    let sql;
    if (!estado || estado === 'ACTIVO') {
      sql = `SELECT ID_EMPRESTIMO, NUM_CARTAO, NOME_LEITOR,
                    MATERIAL_TITULO   AS TITULO,
                    DATA_RETIRADA     AS DATA_EMP,
                    PRAZO_DEVOLUCAO   AS DATA_DEVOLUCAO_PREV,
                    MULTA_ESTIMADA    AS MULTA,
                    DIAS_ATRASO,
                    'ACTIVO'          AS ESTADO,
                    BIBLIOTECA_NOME
             FROM vw_emprestimos_ativos WHERE 1=1${bibFiltro} ORDER BY DATA_RETIRADA DESC`;
    } else {
      sql = `SELECT ID_EMPRESTIMO, NUM_CARTAO, NOME_LEITOR,
                    MATERIAL_TITULO   AS TITULO,
                    DATA_RETIRADA     AS DATA_EMP,
                    PRAZO_DEVOLUCAO   AS DATA_DEVOLUCAO_PREV,
                    MULTA_VALOR       AS MULTA,
                    CASE WHEN DATA_DEVOLUCAO IS NOT NULL AND DATA_DEVOLUCAO > PRAZO_DEVOLUCAO
                         THEN ROUND(DATA_DEVOLUCAO - PRAZO_DEVOLUCAO)
                         ELSE 0
                    END AS DIAS_ATRASO,
                    CASE WHEN DATA_DEVOLUCAO IS NOT NULL THEN 'DEVOLVIDO' ELSE 'HISTORICO' END AS ESTADO,
                    BIBLIOTECA_NOME
             FROM vw_historico_emprestimos WHERE 1=1${bibFiltro} ORDER BY DATA_RETIRADA DESC`;
    }
    const result = await conn.execute(sql, [], { outFormat: oracledb.OUT_FORMAT_OBJECT });
    res.json(result.rows);
  } catch (err) {
    const view = (!req.query.estado || req.query.estado === 'ACTIVO') ? 'vw_emprestimos_ativos' : 'vw_historico_emprestimos';
    console.error('\x1b[31m[EMPRESTIMOS GET /] ERRO ao listar empréstimos\x1b[0m');
    console.error(`     BD: VIEW ${view}`);
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/:id', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT e.*,
              l.NOME_COMPLETO AS NOME_LEITOR,
              m.TITULO, m.AUTOR
         FROM EMPRESTIMO e
         JOIN LEITOR l ON l.NUM_CARTAO = e.NUM_CARTAO
         JOIN MATERIAL_BIBLIOGRAFICO m ON m.cod_MATERIAL = e.cod_MATERIAL
        WHERE e.ID_EMPRESTIMO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (result.rows.length === 0) return res.status(404).json({ erro: 'Empréstimo não encontrado.' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(`\x1b[31m[EMPRESTIMOS GET /${req.params.id}] ERRO ao buscar empréstimo\x1b[0m`);
    console.error('     BD: EMPRESTIMO + LEITOR + MATERIAL_BIBLIOGRAFICO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/', async (req, res) => {
  const { num_cartao, cod_material, prazo_devolucao, cod_funcionario, estado_material_saida } = req.body;
  if (!num_cartao || !cod_material) return res.status(400).json({ erro: 'Leitor e material obrigatórios.' });

  let conn;
  try {
    conn = await getConnection();

    // 1. Verificar disponibilidade do material
    const matResult = await conn.execute(
      `SELECT m.ESTADO_MATERIAL_CONSERVACAO,
              (SELECT COUNT(*) FROM EMPRESTIMO e
               WHERE e.cod_MATERIAL = m.cod_MATERIAL AND e.DATA_DEVOLUCAO IS NULL) AS EMP_ATIVOS,
              (SELECT COUNT(*) FROM TRANSFERENCIA t
               WHERE t.cod_MATERIAL = m.cod_MATERIAL
               AND t.ESTADO_TRANSFERENCIA IN ('Pendente','Aprovada')) AS TRANS_ATIVAS,
              m.COD_CATEGORIA
       FROM MATERIAL_BIBLIOGRAFICO m
       WHERE m.cod_MATERIAL = :id`,
      { id: cod_material },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (matResult.rows.length === 0) return res.status(404).json({ erro: 'Material não encontrado.' });
    const mat = matResult.rows[0];
    if (mat.ESTADO_MATERIAL_CONSERVACAO === 'Indisponivel')
      return res.status(409).json({ erro: 'Material indisponível para empréstimo.' });
    if (mat.EMP_ATIVOS > 0)
      return res.status(409).json({ erro: 'Material já se encontra emprestado.' });
    if (mat.TRANS_ATIVAS > 0)
      return res.status(409).json({ erro: 'Material está em processo de transferência.' });

    // 2. Verificar leitor: status, tipo e limite
    const leitorResult = await conn.execute(
      `SELECT l.STATUS_LEITOR,
              l.DISTANCIA_BIBLIOTECA,
              l.HISTORICO_PONTUALIDADE,
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
    if (leitorResult.rows.length === 0) return res.status(404).json({ erro: 'Leitor não encontrado.' });
    const leitor = leitorResult.rows[0];

    if (leitor.STATUS_LEITOR !== 'Activo')
      return res.status(409).json({ erro: `Leitor não pode efectuar empréstimos (estado: ${leitor.STATUS_LEITOR}).` });

    const limite = LIMITE_EMPRESTIMO[leitor.TIPO_LEITOR] || 3;
    if (leitor.ATIVOS >= limite)
      return res.status(409).json({ erro: `Limite de empréstimos atingido para ${leitor.TIPO_LEITOR} (máximo: ${limite}).` });

    // 2b. Verificar suspensão activa na tabela SUSPENSAO (RN03)
    const suspResult = await conn.execute(
      `SELECT COUNT(*) AS CNT FROM SUSPENSAO
       WHERE num_cartao = :nc
         AND estado_suspensao = 'Activa'
         AND SYSDATE <= data_fim`,
      { nc: num_cartao },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (suspResult.rows[0].CNT > 0)
      return res.status(409).json({ erro: 'Leitor tem suspensão activa.' });

    // 3. Verificar faixa etária do material vs tipo de leitor
    const catResult = await conn.execute(
      `SELECT FAIXA_ETARIA FROM CATEGORIA WHERE ID_CATEGORIA = :id`,
      { id: mat.COD_CATEGORIA },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (catResult.rows.length > 0) {
      const faixa = catResult.rows[0].FAIXA_ETARIA;
      if (faixa === 'Adulto' && leitor.TIPO_LEITOR === 'CRIANCA')
        return res.status(409).json({ erro: 'Material para adultos não pode ser emprestado a crianças.' });
    }

    // 4. Inserir empréstimo — prazo calculado por RN02 (override possível via body)
    const prazoCalculado = calcularPrazo(
      leitor.DISTANCIA_BIBLIOTECA,
      leitor.TIPO_LEITOR,
      leitor.HISTORICO_PONTUALIDADE
    );
    const prazoFinal = prazo_devolucao || prazoCalculado.toISOString().slice(0, 10);

    const empResult = await conn.execute(
      `INSERT INTO EMPRESTIMO
         (ID_EMPRESTIMO, NUM_CARTAO, cod_MATERIAL, DATA_RETIRADA, PRAZO_DEVOLUCAO,
          ESTADO_MATERIAL_SAIDA, MULTA_PAGA, cod_FUNCIONARIO)
       VALUES
         (SEQ_EMPRESTIMO.NEXTVAL, :nc, :id_mat, SYSDATE,
          TO_DATE(:prazo,'YYYY-MM-DD'),
          :estado_saida, 'N', :id_func)
       RETURNING ID_EMPRESTIMO INTO :id_out`,
      { nc: num_cartao, id_mat: cod_material,
        prazo: prazoFinal,
        estado_saida: estado_material_saida || 'Bom',
        id_func: cod_funcionario || req.session.cod_funcionario || null,
        id_out: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER } }
    );
    await conn.commit();
    res.status(201).json({ ok: true, id_emprestimo: empResult.outBinds.id_out[0] });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[EMPRESTIMOS POST /] ERRO ao criar empréstimo\x1b[0m');
    console.error('     BD: MATERIAL_BIBLIOGRAFICO + LEITOR + INSERT EMPRESTIMO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.put('/:id/devolver', async (req, res) => {
  const { condicao_devolucao, observacoes } = req.body;
  let conn;
  try {
    conn = await getConnection();

    // Buscar dados do empréstimo para calcular multa no backend
    const empResult = await conn.execute(
      `SELECT e.PRAZO_DEVOLUCAO, e.NUM_CARTAO, e.DATA_DEVOLUCAO,
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
    if (empResult.rows.length === 0)
      return res.status(404).json({ erro: 'Empréstimo não encontrado.' });

    const emp = empResult.rows[0];
    if (emp.DATA_DEVOLUCAO)
      return res.status(409).json({ erro: 'Empréstimo já devolvido.' });

    const multaValor = await calcularMulta(
      conn, parseInt(req.params.id),
      emp.PRAZO_DEVOLUCAO, emp.NUM_CARTAO, emp.TIPO_LEITOR
    );

    // Chamar procedure com multa calculada pelo backend
    const devolResult = await conn.execute(
      `BEGIN processar_devolucao(:id_emp, :cond, :obs, :multa_val, :sucesso); END;`,
      {
        id_emp:    parseInt(req.params.id),
        cond:      condicao_devolucao || 'Bom',
        obs:       observacoes || null,
        multa_val: multaValor,
        sucesso:   { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 200 }
      }
    );

    const sucesso = devolResult.outBinds.sucesso;
    if (sucesso && sucesso.startsWith('Erro')) {
      return res.status(409).json({ erro: sucesso });
    }

    await conn.commit();
    res.json({ ok: true, multa: multaValor });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[EMPRESTIMOS PUT /${req.params.id}/devolver] ERRO ao processar devolução\x1b[0m`);
    console.error('     BD: PROCEDURE processar_devolucao + EMPRESTIMO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Calcular multa estimada — sem chamar função BD (foi removida na Sessão 3)
router.get('/:id/multa', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const empResult = await conn.execute(
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
    if (empResult.rows.length === 0) return res.json({ multa: 0 });

    const emp = empResult.rows[0];
    const multa = await calcularMulta(
      conn, parseInt(req.params.id),
      emp.PRAZO_DEVOLUCAO, emp.NUM_CARTAO, emp.TIPO_LEITOR
    );
    res.json({ multa });
  } catch (err) {
    console.error(`\x1b[31m[EMPRESTIMOS GET /${req.params.id}/multa] ERRO ao calcular multa\x1b[0m`);
    console.error('     Cálculo em JS: EMPRESTIMO + LEITOR');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
