const { getConnection } = require('../db');

// Detectar nó activo via NODE_NAME do .env (ex: "EventosDB", "EmprestimosDB", "MateriaisDB", "NACIONAL")
const _raw = (process.env.NODE_NAME || '').toUpperCase();
let _NODE;
if      (_raw.includes('EVENTOS'))     _NODE = 'EVENTOS';
else if (_raw.includes('EMPRESTIMOS')) _NODE = 'EMPRESTIMOS';
else if (_raw.includes('MATERIAIS'))   _NODE = 'MATERIAIS';
else                                   _NODE = 'NACIONAL';

// Configuração por nó: SQL de INSERT + mapeamento de binds
// Nós visitantes (não-NacionalDB) não têm cod_funcionario/objeto_afetado —
// esses valores são compactados em observacoes para rastreabilidade.
const _AUDIT = {
  NACIONAL: {
    sql: `INSERT INTO AUDITORIA_OPERACOES
           (id_auditoria, data_operacao, cod_funcionario, operacao, objeto_afetado, resultado, motivo_falha, nos_afetados)
         VALUES (SEQ_AUDITORIA.NEXTVAL, SYSDATE, :func, :op, :obj, :res, :motivo, :nos)`,
    binds: (p) => ({ func: String(p.cod_func), op: p.operacao, obj: p.objeto, res: p.resultado, motivo: p.motivo || null, nos: p.nos }),
  },
  EVENTOS: {
    sql: `INSERT INTO AUDITORIA_EVENTOS
           (id_auditoria, data_operacao, operacao, id_evento, cod_biblioteca, num_cartao, resultado, motivo_falha, nos_afetados, observacoes)
         VALUES (SEQ_AUDITORIA_EVT.NEXTVAL, SYSDATE, :op, NULL, NULL, NULL, :res, :motivo, :nos, :obs)`,
    binds: (p) => ({ op: p.operacao, res: p.resultado, motivo: p.motivo || null, nos: p.nos, obs: String(p.cod_func) + ': ' + p.objeto }),
  },
  EMPRESTIMOS: {
    sql: `INSERT INTO AUDITORIA_EMPRESTIMOS
           (id_auditoria, data_operacao, operacao, num_cartao, cod_material, id_emprestimo, resultado, motivo_falha, nos_afetados, observacoes)
         VALUES (SEQ_AUDITORIA_EMP.NEXTVAL, SYSDATE, :op, NULL, NULL, NULL, :res, :motivo, :nos, :obs)`,
    binds: (p) => ({ op: p.operacao, res: p.resultado, motivo: p.motivo || null, nos: p.nos, obs: String(p.cod_func) + ': ' + p.objeto }),
  },
  MATERIAIS: {
    sql: `INSERT INTO AUDITORIA_MATERIAIS
           (id_auditoria, data_operacao, operacao, cod_material, id_transferencia, estado_anterior, estado_novo, resultado, motivo_falha, nos_afetados, observacoes)
         VALUES (SEQ_AUDITORIA_MAT.NEXTVAL, SYSDATE, :op, NULL, NULL, NULL, NULL, :res, :motivo, :nos, :obs)`,
    binds: (p) => ({ op: p.operacao, res: p.resultado, motivo: p.motivo || null, nos: p.nos, obs: String(p.cod_func) + ': ' + p.objeto }),
  },
};

async function registar(conn, { cod_func, operacao, objeto, resultado, motivo = null, nos = 'NACIONAL' }) {
  const cfg = _AUDIT[_NODE] || _AUDIT.NACIONAL;
  try {
    await conn.execute(cfg.sql, cfg.binds({ cod_func, operacao, objeto, resultado, motivo, nos }));
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
