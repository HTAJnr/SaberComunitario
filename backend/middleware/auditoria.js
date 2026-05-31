const { getConnection } = require('../db');

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

// Abre a própria ligação — usar quando não há conn disponível (middlewares, background tasks)
function registarBackground({ cod_func, operacao, objeto, resultado, motivo = null, nos = 'NACIONAL' }) {
  getConnection().then(async conn => {
    try {
      await registar(conn, { cod_func, operacao, objeto, resultado, motivo, nos });
      await conn.commit();
    } catch (e) {
      console.warn('[AUDITORIA BG]', e.message);
    } finally {
      await conn.close().catch(() => {});
    }
  }).catch(e => console.warn('[AUDITORIA BG conn]', e.message));
}

module.exports = { registar, registarBackground };
