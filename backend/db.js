process.env.NLS_LANG = process.env.NLS_LANG || 'AMERICAN_AMERICA.AL32UTF8';  // Questão de acentos na bd

const oracledb = require('oracledb');

// Thick mode obrigatório para Oracle 10g/11g (thin mode exige Oracle 12.1+)
try {
  const libDir = process.env.INSTANT_CLIENT_PATH || undefined;
  oracledb.initOracleClient(libDir ? { libDir } : {});
} catch (err) {
  // NJS-077 / "already been initialized" — já estava init, ignorar
  if (!err.message.includes('NJS-077') && !err.message.includes('already been initialized')) {
    console.warn('[AVISO] Oracle Instant Client não encontrado no arranque.');
    console.warn('        O servidor vai arrancar, mas as operações de BD vão falhar.');
    console.warn('        Garante que o Instant Client está no PATH do Windows e reinicia.');
    console.warn('        Detalhe:', err.message);
  }
}

// ── Detecta erros de nó remoto offline (dblink ou ligação primária) ────────
// ORA-12154: TNS não resolve  ORA-12541: sem listener  ORA-12170: timeout
// ORA-02068: erro a seguir de dblink  ORA-03114/03135: ligação perdida
function isOfflineError(err) {
  const msg = (err && err.message) ? err.message : '';
  return /ORA-(12154|12541|12170|01033|02068|03114|03135|01017|28001)/.test(msg)
      || /NJS-(500|503|506)/.test(msg);
}

// ── Fábrica interna — lê prefixo do .env (ex: NACIONAL, MATERIAIS) ─────────
function buildConfig(prefix) {
  const host     = process.env[`${prefix}_HOST`]     || process.env.DB_HOST;
  const port     = process.env[`${prefix}_PORT`]     || process.env.DB_PORT     || '1521';
  const service  = process.env[`${prefix}_SERVICE`]  || process.env.DB_SERVICE  || 'XE';
  const user     = process.env[`${prefix}_USER`]     || process.env.DB_USER;
  const password = process.env[`${prefix}_PASSWORD`] || process.env.DB_PASSWORD;
  return { user, password, connectString: `${host}:${port}/${service}` };
}

async function _connect(prefix) {
  const config = buildConfig(prefix);
  try {
    return await oracledb.getConnection(config);
  } catch (err) {
    const label = prefix || 'BD';
    console.error(`\x1b[31m[DB] FALHA NA CONEXÃO — ${label}\x1b[0m`);
    console.error(`     Host:    ${config.connectString}`);
    console.error(`     User:    ${config.user}`);
    console.error(`     Detalhe: ${err.message}`);
    throw err;
  }
}

// ── 4 funções de ligação — uma por nó ─────────────────────────────────────
async function getConnectionNacional()    { return _connect('NACIONAL');    }
async function getConnectionMateriais()   { return _connect('MATERIAIS');   }
async function getConnectionEmprestimos() { return _connect('EMPRESTIMOS'); }
async function getConnectionEventos()     { return _connect('EVENTOS');     }

// Alias de compatibilidade: auth, dashboard e auditoria ligam ao NacionalDB
async function getConnection() { return getConnectionNacional(); }

// ── Utilitários de diagnóstico ─────────────────────────────────────────────
async function testConnection() {
  let conn;
  try {
    conn = await getConnectionNacional();
    const result = await conn.execute('SELECT SYSDATE, BANNER FROM V$VERSION WHERE ROWNUM = 1');
    const [sysdate, banner] = result.rows[0];
    const cfg = buildConfig('NACIONAL');
    return { ok: true, timestamp: sysdate, version: banner, host: cfg.connectString };
  } finally {
    if (conn) await conn.close();
  }
}

async function listUserTables() {
  let conn;
  try {
    conn = await getConnectionNacional();
    const result = await conn.execute(
      `SELECT owner, table_name
         FROM all_tables
        WHERE owner NOT IN ('SYS','SYSTEM','OUTLN','DBSNMP')
        ORDER BY owner, table_name`
    );
    return result.rows.map(([owner, tableName]) => ({ owner, tableName }));
  } finally {
    if (conn) await conn.close();
  }
}

// ── Identidade do nó ──────────────────────────────────────────────────────
const _NO_MAP = {
  'APP_NACIONALDB':    'BibliotecaNacionalDB',
  'APP_EMPRESTIMOSDB': 'EmpréstimosProgramasDB',
  'APP_MATERIAISDB':   'MateriaisDB',
  'APP_EVENTOSDB':     'EventosBibliotecasDB',
  'USR_NACIONALDB':    'BibliotecaNacionalDB',
  'USR_EMPRESTIMOSDB': 'EmpréstimosProgramasDB',
  'USR_MATERIAISDB':   'MateriaisDB',
  'USR_EVENTOSDB':     'EventosBibliotecasDB',
};

let _noOrigemCached = null;

async function inicializarNoOrigem() {
  let conn;
  try {
    conn = await getConnectionNacional();
    const r = await conn.execute('SELECT USER FROM DUAL', [], { outFormat: oracledb.OUT_FORMAT_OBJECT });
    const dbUser = (r.rows[0].USER || '').toUpperCase();
    _noOrigemCached = _NO_MAP[dbUser] || process.env.NODE_NAME || 'BibliotecaNacionalDB';
    console.log(`\x1b[36m[DB]\x1b[0m NacionalDB:    ${_noOrigemCached} (${dbUser})`);
  } catch (err) {
    _noOrigemCached = process.env.NODE_NAME || 'BibliotecaNacionalDB';
    console.warn(`\x1b[33m[DB] AVISO\x1b[0m NacionalDB offline no arranque: ${err.message}`);
    console.warn(`           Os outros nós podem ainda funcionar.`);
  } finally {
    if (conn) await conn.close();
  }
}

function getNoOrigem() {
  return _noOrigemCached || process.env.NODE_NAME || 'BibliotecaNacionalDB';
}

module.exports = {
  getConnection,
  getConnectionNacional,
  getConnectionMateriais,
  getConnectionEmprestimos,
  getConnectionEventos,
  isOfflineError,
  testConnection,
  listUserTables,
  inicializarNoOrigem,
  getNoOrigem,
  oracledb,
};
