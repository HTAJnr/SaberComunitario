const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');
const { exigirNivel } = require('../middleware/permissoes');

// POST /api/manutencao/refresh-snapshots
// Força REFRESH COMPLETE em todas as MVs do nó ligado.
// Equivale a chamar DBMS_MVIEW.REFRESH_ALL_MVIEWS no Oracle.
// Restrito a Administrador.
router.post('/refresh-snapshots', exigirNivel('Administrador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    const result = await conn.execute(
      `BEGIN DBMS_MVIEW.REFRESH_ALL_MVIEWS(:n_falhas); END;`,
      { n_falhas: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER } }
    );

    const falhas = result.outBinds.n_falhas;
    if (falhas > 0) {
      return res.status(207).json({
        ok: false,
        mensagem: `Refresh concluído com ${falhas} falha(s). Verifique os nós remotos.`,
        falhas
      });
    }

    res.json({ ok: true, mensagem: 'Todos os snapshots actualizados com sucesso.' });
  } catch (err) {
    console.error('\x1b[31m[MANUTENCAO POST /refresh-snapshots] ERRO\x1b[0m');
    console.error('     BD: DBMS_MVIEW.REFRESH_ALL_MVIEWS');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/manutencao/snapshots
// Lista MVs locais, data do último refresh e estado.
router.get('/snapshots', exigirNivel('Administrador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT MVIEW_NAME       AS nome,
              REFRESH_MODE     AS modo,
              REFRESH_METHOD   AS metodo,
              LAST_REFRESH_DATE AS ultimo_refresh,
              STALENESS        AS estado
         FROM USER_MVIEWS
        ORDER BY MVIEW_NAME`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[MANUTENCAO GET /snapshots] ERRO\x1b[0m');
    console.error('     BD: USER_MVIEWS');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
