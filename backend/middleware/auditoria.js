const { oracledb } = require('../db');

async function registar(conn, { cod_func, operacao, objeto, resultado, motivo = null, nos = 'NACIONAL' }) {
  try {
    await conn.execute(
      `INSERT INTO AUDITORIA_OPERACOES
         (id_auditoria, data_operacao, cod_funcionario, operacao, objeto_afetado, resultado, motivo_falha, nos_afetados)
       VALUES (SEQ_AUDITORIA.NEXTVAL, SYSDATE, :func, :op, :obj, :res, :motivo, :nos)`,
      { func: String(cod_func), op: operacao, obj: objeto, res: resultado, motivo: motivo || null, nos }
    );
  } catch (e) {
    console.warn('[AUDITORIA]', e.message);
  }
}

module.exports = { registar };
