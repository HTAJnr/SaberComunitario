const express = require('express');
const router  = express.Router();
const { getConnection, oracledb } = require('../db');
const { exigirNivel } = require('../middleware/permissoes');

// GET /api/auditoria — lê VW_AUDITORIA (view padronizada criada por cada nó no seu schema)
// Transparência de localização: o Oracle resolve VW_AUDITORIA para o schema do DB_USER activo.
router.get('/', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    const { operacao, resultado, data_inicio, data_fim } = req.query;
    const page   = Math.max(1, parseInt(req.query.page) || 1);
    const limit  = 20;
    const offset = (page - 1) * limit;

    const conditions = ['1=1'];
    const binds      = {};

    if (operacao) {
      conditions.push('operacao = :operacao');
      binds.operacao = operacao;
    }
    if (resultado) {
      conditions.push('resultado = :resultado');
      binds.resultado = resultado;
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
           SELECT id_auditoria, data_operacao, operacao, resultado,
                  motivo_falha, nos_afetados, observacoes, no_origem
             FROM VW_AUDITORIA
            WHERE ${where}
            ORDER BY data_operacao DESC
         ) t WHERE ROWNUM <= :rn_max
       ) WHERE RN > :rn_min`,
      binds,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const totalResult = await conn.execute(
      `SELECT COUNT(*) AS N FROM VW_AUDITORIA WHERE ${where}`,
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
    console.error('     BD: VW_AUDITORIA');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/auditoria/opcoes — valores distintos para os dropdowns de filtro
router.get('/opcoes', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    const opR = await conn.execute(
      `SELECT DISTINCT operacao FROM VW_AUDITORIA ORDER BY operacao`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const resR = await conn.execute(
      `SELECT DISTINCT resultado FROM VW_AUDITORIA ORDER BY resultado`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({
      operacoes:  opR.rows.map(r => r.OPERACAO),
      resultados: resR.rows.map(r => r.RESULTADO),
    });
  } catch (err) {
    console.error('\x1b[31m[AUDITORIA GET /opcoes]\x1b[0m');
    console.error('     BD: VW_AUDITORIA');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
