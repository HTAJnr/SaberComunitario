const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');

function isAdmin(req) {
  return (req.session.nivel_acesso || req.session.funcionario?.FUNCAO) === 'Administrador';
}

router.get('/metricas', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    let result;
    if (isAdmin(req)) {
      // Administrador: visão global da rede
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
      // Bibliotecário/Assistente/Coordenador: métricas da sua biblioteca
      const codBib = req.session.cod_biblioteca;
      if (!codBib) {
        return res.status(400).json({ erro: 'Sessão sem biblioteca associada.' });
      }
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
    console.error('\x1b[31m[DASHBOARD GET /metricas] ERRO ao carregar métricas\x1b[0m');
    console.error('     BD: vw_metricas_sistema (admin) ou vw_metricas_por_biblioteca (outros)');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/emprestimos-ativos', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    let sql;
    const params = {};
    if (isAdmin(req)) {
      sql = `SELECT ID_EMPRESTIMO, NOME_LEITOR, NUM_CARTAO,
                    MATERIAL_TITULO AS TITULO,
                    PRAZO_DEVOLUCAO AS DATA_DEVOLUCAO_PREV,
                    DIAS_ATRASO
             FROM vw_emprestimos_ativos WHERE ROWNUM <= 10`;
    } else {
      sql = `SELECT ID_EMPRESTIMO, NOME_LEITOR, NUM_CARTAO,
                    MATERIAL_TITULO AS TITULO,
                    PRAZO_DEVOLUCAO AS DATA_DEVOLUCAO_PREV,
                    DIAS_ATRASO
             FROM vw_emprestimos_ativos
             WHERE cod_BIBLIOTECA = :cod_bib AND ROWNUM <= 10`;
      params.cod_bib = req.session.cod_biblioteca;
    }

    const result = await conn.execute(sql, params, { outFormat: oracledb.OUT_FORMAT_OBJECT });
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[DASHBOARD GET /emprestimos-ativos] ERRO ao carregar empréstimos activos\x1b[0m');
    console.error('     BD: VIEW vw_emprestimos_ativos');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/eventos-proximos', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT ID_EVENTO,
              TITULO_EVENTO   AS NOME,
              DATA_EVENTO     AS DATA_INICIO,
              BIBLIOTECA_NOME AS NOME_BIBLIOTECA
       FROM vw_eventos_proximos WHERE ROWNUM <= 5`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[DASHBOARD GET /eventos-proximos] ERRO ao carregar eventos próximos\x1b[0m');
    console.error('     BD: VIEW vw_eventos_proximos');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
