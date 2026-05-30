const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');
const { autenticar, exigirNivel } = require('../middleware/permissoes');

function isAdmin(req) {
  return (req.session.nivel_acesso || req.session.funcionario?.NIVEL_ACESSO) === 'Administrador';
}

function getCodBib(req) {
  return req.session.cod_biblioteca;
}

// Executa uma query de contagem e devolve 0 se o nó remoto estiver offline.
// Usar apenas para métricas não-críticas — evita que um nó offline derrube todo o dashboard.
async function safeCount(conn, sql, params) {
  try {
    const r = await conn.execute(sql, params || [], { outFormat: oracledb.OUT_FORMAT_OBJECT });
    return r.rows[0]?.TOTAL ?? 0;
  } catch {
    return 0;
  }
}

// ── Endpoints legados (mantidos para compatibilidade) ─────────────────────────

router.get('/metricas', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    let result;
    if (isAdmin(req)) {
      result = await conn.execute(
        `SELECT
           TOTAL_LEITORES_CADASTRADOS  AS TOTAL_LEITORES,
           TOTAL_EMPRESTIMOS_ATIVOS    AS EMPRESTIMOS_ATIVOS,
           TOTAL_MATERIAIS_ACERVO      AS MATERIAIS_DISPONIVEIS,
           VALOR_MULTAS_PENDENTES      AS MULTAS_PENDENTES,
           TOTAL_BIBLIOTECAS_ATIVAS    AS TOTAL_BIBLIOTECAS,
           LEITORES_SUSPENSOS,
           TAXA_DEVOLUCAO_NO_PRAZO     AS TAXA_PONTUALIDADE,
           TOTAL_DOACOES_MES_ATUAL     AS DOACOES_MES,
           EVENTOS_PROXIMOS_30_DIAS    AS EVENTOS_PROXIMOS
         FROM vw_metricas_sistema`,
        [],
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
    } else {
      const codBib = getCodBib(req);
      if (!codBib) return res.status(400).json({ erro: 'Sessão sem biblioteca associada.' });
      result = await conn.execute(
        `SELECT
           TOTAL_LEITORES         AS TOTAL_LEITORES,
           EMPRESTIMOS_ATIVOS,
           MATERIAIS_DISPONIVEIS,
           MULTAS_PENDENTES,
           EMPRESTIMOS_HOJE,
           DEVOLUCOES_HOJE,
           EMPRESTIMOS_MUITO_ATRASADOS AS ATRASOS_GRAVES,
           EVENTOS_PROXIMOS,
           EVENTO_HOJE,
           NOME_BIBLIOTECA,
           TOTAL_MATERIAIS
         FROM vw_metricas_por_biblioteca
         WHERE cod_BIBLIOTECA = :cod_bib`,
        { cod_bib: codBib },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
    }

    res.json(result.rows[0] || {});
  } catch (err) {
    console.error('\x1b[31m[DASHBOARD /metricas]\x1b[0m', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/emprestimos-ativos', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    let sql;
    const params = {};
    const base = `SELECT E.ID_EMPRESTIMO,
                         L.NOME_COMPLETO AS NOME_LEITOR,
                         E.NUM_CARTAO,
                         M.TITULO,
                         E.PRAZO_DEVOLUCAO AS DATA_DEVOLUCAO_PREV,
                         GREATEST(0, TRUNC(SYSDATE) - TRUNC(E.PRAZO_DEVOLUCAO)) AS DIAS_ATRASO
                  FROM snap_emp_activos E
                  JOIN LEITOR L ON E.NUM_CARTAO = L.NUM_CARTAO
                  JOIN snap_material_basico M ON E.COD_MATERIAL = M.COD_MATERIAL
                  WHERE TRUNC(SYSDATE) > TRUNC(E.PRAZO_DEVOLUCAO)`;
    if (isAdmin(req)) {
      sql = `SELECT * FROM (${base} ORDER BY DIAS_ATRASO DESC) WHERE ROWNUM <= 10`;
    } else {
      sql = `SELECT * FROM (${base} AND M.COD_BIBLIOTECA = :cod_bib ORDER BY DIAS_ATRASO DESC) WHERE ROWNUM <= 10`;
      params.cod_bib = getCodBib(req);
    }

    const result = await conn.execute(sql, params, { outFormat: oracledb.OUT_FORMAT_OBJECT });
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[DASHBOARD /emprestimos-ativos]\x1b[0m', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/eventos-proximos', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT * FROM (
         SELECT E.ID_EVENTO,
                E.TITULO_EVENTO   AS NOME,
                E.DATA_EVENTO     AS DATA_INICIO,
                B.NOME_BIBLIOTECA AS NOME_BIBLIOTECA
         FROM snap_eventos E
         JOIN BIBLIOTECA B ON E.COD_BIBLIOTECA = B.COD_BIBLIOTECA
         WHERE E.DATA_EVENTO >= SYSDATE
           AND (E.STATUS_EVENTO IS NULL OR E.STATUS_EVENTO != 'Cancelado')
         ORDER BY E.DATA_EVENTO
       ) WHERE ROWNUM <= 5`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[DASHBOARD /eventos-proximos]\x1b[0m', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── Módulo Dashboard — spec frontend_guide.md §4 ─────────────────────────────

// GET /api/dashboard/rede — visão global da rede (só Administrador)
router.get('/rede', exigirNivel('Administrador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    const metResult = await conn.execute(
      `SELECT
         TOTAL_BIBLIOTECAS_ATIVAS   AS TOTAL_BIBLIOTECAS,
         TOTAL_LEITORES_CADASTRADOS AS TOTAL_LEITORES,
         TOTAL_EMPRESTIMOS_ATIVOS   AS EMPRESTIMOS_ATIVOS,
         TOTAL_MATERIAIS_ACERVO     AS MATERIAIS_ACERVO,
         VALOR_MULTAS_PENDENTES     AS TOTAL_MULTAS_POR_COBRAR
       FROM vw_metricas_sistema`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Usa snap_emp_activos (local) em vez de link live ao EmprestimosDB
    const empVencidos = await safeCount(conn,
      `SELECT COUNT(*) AS TOTAL FROM snap_emp_activos
       WHERE TRUNC(SYSDATE) > TRUNC(PRAZO_DEVOLUCAO)`, []);

    // Materiais perdidos este mês — dado histórico, requer link live; safeCount protege se offline
    const matPerdidos = await safeCount(conn,
      `SELECT COUNT(*) AS TOTAL FROM EMPRESTIMO
       WHERE ESTADO_MATERIAL_RETORNO = 'Perdido'
         AND TRUNC(DATA_DEVOLUCAO, 'MM') = TRUNC(SYSDATE, 'MM')`, []);

    // Usa snap_transferencias (local) em vez de link live ao MateriaisDB
    const transfPendentes = await safeCount(conn,
      `SELECT COUNT(*) AS TOTAL FROM snap_transferencias
       WHERE ESTADO_TRANSFERENCIA = 'Pendente'`, []);

    const m = metResult.rows[0] || {};
    res.json({
      total_bibliotecas:        m.TOTAL_BIBLIOTECAS        || 0,
      total_leitores:           m.TOTAL_LEITORES            || 0,
      emprestimos_ativos:       m.EMPRESTIMOS_ATIVOS        || 0,
      materiais_acervo:         m.MATERIAIS_ACERVO          || 0,
      emprestimos_vencidos:     empVencidos,
      transferencias_pendentes: transfPendentes,
      materiais_perdidos_mes:   matPerdidos,
      total_multas_por_cobrar:  m.TOTAL_MULTAS_POR_COBRAR  || 0,
    });
  } catch (err) {
    console.error('\x1b[31m[DASHBOARD /rede]\x1b[0m', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/dashboard/biblioteca — visão local da biblioteca (Coordenador, Bibliotecário, Assistente)
router.get('/biblioteca', autenticar, async (req, res) => {
  const codBib = getCodBib(req);
  if (!codBib) return res.status(400).json({ erro: 'Sessão sem biblioteca associada.' });

  let conn;
  try {
    conn = await getConnection();

    const metResult = await conn.execute(
      `SELECT EMPRESTIMOS_ATIVOS, MATERIAIS_DISPONIVEIS, DEVOLUCOES_HOJE, MULTAS_PENDENTES
       FROM vw_metricas_por_biblioteca
       WHERE COD_BIBLIOTECA = :bib`,
      { bib: codBib },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Empréstimos vencidos — snapshot local (resiliente a EmprestimosDB offline)
    const vencResult = await conn.execute(
      `SELECT COUNT(*) AS TOTAL
       FROM snap_emp_activos E, snap_material_basico M
       WHERE E.COD_MATERIAL = M.COD_MATERIAL
         AND M.COD_BIBLIOTECA = :bib
         AND TRUNC(SYSDATE) > TRUNC(E.PRAZO_DEVOLUCAO)`,
      { bib: codBib },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Transferências pendentes — snapshot local (resiliente a MateriaisDB offline)
    const transfResult = await conn.execute(
      `SELECT COUNT(*) AS TOTAL
       FROM snap_transferencias
       WHERE ESTADO_TRANSFERENCIA = 'Pendente'
         AND (COD_BIBLIOTECA_ORIGEM = :bib OR COD_BIBLIOTECA_DESTINO = :bib2)`,
      { bib: codBib, bib2: codBib },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Eventos do mês — snapshot local (resiliente a EventosDB offline)
    const eventosResult = await conn.execute(
      `SELECT COUNT(*) AS TOTAL
       FROM snap_eventos
       WHERE COD_BIBLIOTECA = :bib
         AND EXTRACT(MONTH FROM DATA_EVENTO) = EXTRACT(MONTH FROM SYSDATE)
         AND EXTRACT(YEAR  FROM DATA_EVENTO) = EXTRACT(YEAR  FROM SYSDATE)`,
      { bib: codBib },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Doações — locais no NacionalDB, sem risco de offline
    const doacoesResult = await conn.execute(
      `SELECT COUNT(DISTINCT D.ID_DOACAO) AS TOTAL
       FROM DOACAO D
       JOIN ITEM_DOACAO I ON D.ID_DOACAO = I.ID_DOACAO
       WHERE I.COD_BIBLIOTECA = :bib
         AND EXTRACT(MONTH FROM D.DATA_DOACAO) = EXTRACT(MONTH FROM SYSDATE)
         AND EXTRACT(YEAR  FROM D.DATA_DOACAO) = EXTRACT(YEAR  FROM SYSDATE)`,
      { bib: codBib },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Empréstimos da semana — snapshots locais
    const semanaResult = await conn.execute(
      `SELECT TRUNC(E.DATA_RETIRADA) AS DIA, COUNT(*) AS TOTAL
       FROM snap_emp_activos E, snap_material_basico M
       WHERE E.COD_MATERIAL = M.COD_MATERIAL
         AND M.COD_BIBLIOTECA = :bib
         AND E.DATA_RETIRADA >= TRUNC(SYSDATE) - 6
       GROUP BY TRUNC(E.DATA_RETIRADA)
       ORDER BY DIA`,
      { bib: codBib },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Top 5 materiais actualmente em empréstimo (snapshot — dados activos apenas)
    const topResult = await conn.execute(
      `SELECT * FROM (
         SELECT M.TITULO, COUNT(*) AS TOTAL_EMPRESTIMOS
         FROM snap_emp_activos E, snap_material_basico M
         WHERE E.COD_MATERIAL = M.COD_MATERIAL
           AND M.COD_BIBLIOTECA = :bib
         GROUP BY M.TITULO
         ORDER BY COUNT(*) DESC
       ) WHERE ROWNUM <= 5`,
      { bib: codBib },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Constrói array de 7 dias — índice 0 = há 6 dias, índice 6 = hoje
    const porDia = {};
    semanaResult.rows.forEach(r => {
      porDia[new Date(r.DIA).toDateString()] = r.TOTAL;
    });
    const emprestimos_semana = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      emprestimos_semana.push(porDia[d.toDateString()] || 0);
    }

    const m = metResult.rows[0] || {};
    res.json({
      emprestimos_ativos:       m.EMPRESTIMOS_ATIVOS       || 0,
      emprestimos_vencidos:     vencResult.rows[0]?.TOTAL  || 0,
      devolucoes_hoje:          m.DEVOLUCOES_HOJE           || 0,
      materiais_disponiveis:    m.MATERIAIS_DISPONIVEIS     || 0,
      materiais_emprestados:    m.EMPRESTIMOS_ATIVOS        || 0,
      multas_por_cobrar:        m.MULTAS_PENDENTES          || 0,
      eventos_este_mes:         eventosResult.rows[0]?.TOTAL  || 0,
      doacoes_este_mes:         doacoesResult.rows[0]?.TOTAL  || 0,
      transferencias_pendentes: transfResult.rows[0]?.TOTAL   || 0,
      emprestimos_semana,
      top_materiais: topResult.rows.map(r => ({
        titulo:            r.TITULO,
        total_emprestimos: r.TOTAL_EMPRESTIMOS,
      })),
    });
  } catch (err) {
    console.error('\x1b[31m[DASHBOARD /biblioteca]\x1b[0m', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/dashboard/devolucoes-hoje — empréstimos a vencer hoje nesta biblioteca
router.get('/devolucoes-hoje', autenticar, async (req, res) => {
  const codBib = getCodBib(req);
  if (!codBib) return res.json([]);

  let conn;
  try {
    conn = await getConnection();
    // Usa snapshots locais — resiliente a EmprestimosDB e MateriaisDB offline
    const result = await conn.execute(
      `SELECT * FROM (
         SELECT E.ID_EMPRESTIMO,
                L.NOME_COMPLETO  AS NOME_LEITOR,
                E.NUM_CARTAO,
                M.TITULO,
                E.PRAZO_DEVOLUCAO
         FROM snap_emp_activos E
         JOIN LEITOR L ON E.NUM_CARTAO = L.NUM_CARTAO
         JOIN snap_material_basico M ON E.COD_MATERIAL = M.COD_MATERIAL
         WHERE M.COD_BIBLIOTECA = :bib
           AND TRUNC(E.PRAZO_DEVOLUCAO) = TRUNC(SYSDATE)
         ORDER BY E.PRAZO_DEVOLUCAO
       ) WHERE ROWNUM <= 5`,
      { bib: codBib },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[DASHBOARD /devolucoes-hoje]\x1b[0m', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/dashboard/leitores-recentes — últimos leitores cadastrados
router.get('/leitores-recentes', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  const codBib = getCodBib(req);
  if (!codBib) return res.json([]);

  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT * FROM (
         SELECT L.NUM_CARTAO, L.NOME_COMPLETO, L.STATUS_LEITOR,
                CASE WHEN P.NUM_CARTAO IS NOT NULL THEN 'Professor'
                     WHEN A.NUM_CARTAO IS NOT NULL THEN 'Adulto'
                     ELSE 'Crianca' END AS TIPO
         FROM LEITOR L
         LEFT JOIN ADULTO A   ON L.NUM_CARTAO = A.NUM_CARTAO
         LEFT JOIN PROFESSOR P ON L.NUM_CARTAO = P.NUM_CARTAO
         WHERE L.COD_BIBLIOTECA = :bib
         ORDER BY L.NUM_CARTAO DESC
       ) WHERE ROWNUM <= 5`,
      { bib: codBib },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[DASHBOARD /leitores-recentes]\x1b[0m', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/dashboard/transferencias-recentes — últimas transferências desta biblioteca
router.get('/transferencias-recentes', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const codBib = getCodBib(req);
  if (!codBib) return res.json([]);

  let conn;
  try {
    conn = await getConnection();
    // Usa snapshots locais — resiliente a MateriaisDB offline.
    // Ordenado por ID_TRANSFERENCIA DESC (DATA_SOLICITACAO não está no snapshot).
    const result = await conn.execute(
      `SELECT * FROM (
         SELECT T.ID_TRANSFERENCIA, M.TITULO,
                BO.NOME_BIBLIOTECA AS NOME_ORIGEM,
                BD.NOME_BIBLIOTECA AS NOME_DESTINO,
                T.ESTADO_TRANSFERENCIA,
                T.COD_BIBLIOTECA_ORIGEM, T.COD_BIBLIOTECA_DESTINO
         FROM snap_transferencias T
         JOIN snap_material_basico M ON T.COD_MATERIAL = M.COD_MATERIAL
         JOIN BIBLIOTECA BO ON T.COD_BIBLIOTECA_ORIGEM = BO.COD_BIBLIOTECA
         JOIN BIBLIOTECA BD ON T.COD_BIBLIOTECA_DESTINO = BD.COD_BIBLIOTECA
         WHERE T.COD_BIBLIOTECA_ORIGEM = :bib OR T.COD_BIBLIOTECA_DESTINO = :bib2
         ORDER BY T.ID_TRANSFERENCIA DESC
       ) WHERE ROWNUM <= 3`,
      { bib: codBib, bib2: codBib },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[DASHBOARD /transferencias-recentes]\x1b[0m', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
