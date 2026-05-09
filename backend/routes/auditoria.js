const express = require('express');
const router  = express.Router();
const { getConnection, oracledb } = require('../db');
const { exigirNivel } = require('../middleware/permissoes');

// GET /api/auditoria — listar registos de auditoria com filtros e paginação
router.get('/', exigirNivel('Administrador'), async (req, res) => {
  let conn;
  try {
    const { cod_funcionario, operacao, data_inicio, data_fim } = req.query;
    const page   = Math.max(1, parseInt(req.query.page) || 1);
    const limit  = 20;
    const offset = (page - 1) * limit;

    // Construir WHERE dinâmico — valores via bind, nunca interpolados
    const conditions = ['1=1'];
    const binds      = {};

    if (cod_funcionario) {
      conditions.push('cod_funcionario = :cod_func');
      binds.cod_func = cod_funcionario;
    }
    if (operacao) {
      conditions.push('operacao = :operacao');
      binds.operacao = operacao;
    }
    if (data_inicio) {
      conditions.push('data_operacao >= TO_DATE(:data_inicio, \'YYYY-MM-DD\')');
      binds.data_inicio = data_inicio;
    }
    if (data_fim) {
      conditions.push('data_operacao < TO_DATE(:data_fim, \'YYYY-MM-DD\') + 1');
      binds.data_fim = data_fim;
    }

    const where = conditions.join(' AND ');

    binds.rn_max = offset + limit;
    binds.rn_min = offset;

    conn = await getConnection();

    const result = await conn.execute(
      `SELECT * FROM (
         SELECT t.*, ROWNUM AS RN FROM (
           SELECT a.id_auditoria, a.data_operacao, a.cod_funcionario,
                  f.nome_funcionario,
                  a.operacao, a.objeto_afetado, a.resultado,
                  a.motivo_falha, a.nos_afetados, a.observacoes
             FROM AUDITORIA_OPERACOES a
             LEFT JOIN FUNCIONARIO f ON f.cod_funcionario = a.cod_funcionario
            WHERE ${where}
            ORDER BY a.data_operacao DESC
         ) t WHERE ROWNUM <= :rn_max
       ) WHERE RN > :rn_min`,
      binds,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const totalResult = await conn.execute(
      `SELECT COUNT(*) AS N FROM AUDITORIA_OPERACOES WHERE ${where}`,
      Object.fromEntries(Object.entries(binds).filter(([k]) => !['rn_max', 'rn_min'].includes(k))),
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({
      total:    totalResult.rows[0].N,
      pagina:   page,
      registos: result.rows
    });
  } catch (err) {
    console.error('\x1b[31m[AUDITORIA GET /]\x1b[0m');
    console.error('     BD: AUDITORIA_OPERACOES');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/auditoria/opcoes — listas para popular dropdowns de filtro na UI
router.get('/opcoes', exigirNivel('Administrador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    const opR = await conn.execute(
      `SELECT DISTINCT operacao FROM AUDITORIA_OPERACOES ORDER BY operacao`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const funcR = await conn.execute(
      `SELECT DISTINCT a.cod_funcionario, f.nome_funcionario
         FROM AUDITORIA_OPERACOES a
         LEFT JOIN FUNCIONARIO f ON f.cod_funcionario = a.cod_funcionario
        ORDER BY f.nome_funcionario`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({
      operacoes:    opR.rows.map(r => r.OPERACAO),
      funcionarios: funcR.rows.map(r => ({
        cod_funcionario:  r.COD_FUNCIONARIO,
        nome_funcionario: r.NOME_FUNCIONARIO
      }))
    });
  } catch (err) {
    console.error('\x1b[31m[AUDITORIA GET /opcoes]\x1b[0m');
    console.error('     BD: AUDITORIA_OPERACOES + FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
