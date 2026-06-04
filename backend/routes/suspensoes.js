const express = require('express');
const router  = express.Router();
const { getConnectionEmprestimos: getConnection, oracledb, isOfflineError } = require('../db');
const { exigirNivel } = require('../middleware/permissoes');

// PATCH /api/suspensoes/:id/reduzir  (RN03.2 — só Coordenador ou Administrador)
router.patch('/:id/reduzir', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const { nova_data_fim, observacoes } = req.body;

  if (!nova_data_fim) {
    return res.status(400).json({ erro: true, codigo: 'CAMPO_OBRIGATORIO', mensagem: 'nova_data_fim é obrigatório.', detalhes: {} });
  }
  if (!observacoes || !observacoes.trim()) {
    return res.status(400).json({ erro: true, codigo: 'CAMPO_OBRIGATORIO', mensagem: 'observacoes são obrigatórias (justificativa obrigatória).', detalhes: {} });
  }

  const id = parseInt(req.params.id);
  let conn;
  try {
    conn = await getConnection();

    const check = await conn.execute(
      `SELECT ID_SUSPENSAO, DATA_INICIO, DATA_FIM, ESTADO_SUSPENSAO, NUM_CARTAO
         FROM SUSPENSAO WHERE ID_SUSPENSAO = :id`,
      { id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    if (check.rows.length === 0) {
      return res.status(404).json({ erro: true, codigo: 'SUSPENSAO_NAO_ENCONTRADA', mensagem: 'Suspensão não encontrada.', detalhes: {} });
    }

    const susp = check.rows[0];

    if (susp.ESTADO_SUSPENSAO !== 'Activa') {
      return res.status(409).json({ erro: true, codigo: 'SUSPENSAO_INACTIVA', mensagem: 'Só é possível reduzir suspensões activas.', detalhes: { estado_atual: susp.ESTADO_SUSPENSAO } });
    }

    // nova_data_fim tem de ser antes da actual DATA_FIM (senão não é redução)
    await conn.execute(
      `UPDATE SUSPENSAO
          SET DATA_FIM      = TO_DATE(:nova_data_fim, 'YYYY-MM-DD'),
              DIAS_SUSPENSAO = TO_DATE(:nova_data_fim, 'YYYY-MM-DD') - DATA_INICIO,
              OBSERVACOES   = :obs
        WHERE ID_SUSPENSAO = :id`,
      { nova_data_fim, obs: observacoes.trim(), id }
    );

    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[SUSPENSOES PATCH /:id/reduzir]\x1b[0m');
    console.error('     BD: SUSPENSAO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message, detalhes: {} });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
