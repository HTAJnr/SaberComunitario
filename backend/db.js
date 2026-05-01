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

function buildConnectString() {
  return `${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_SERVICE}`;
}

async function getConnection() {
  const config = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    connectString: buildConnectString(),
  };
  if (process.env.DB_PRIVILEGE === 'SYSDBA') {
    config.privilege = oracledb.SYSDBA;
  }
  try {
    const conn = await oracledb.getConnection(config);
    return conn;
  } catch (err) {
    console.error('\x1b[31m[DB] FALHA NA CONEXÃO ORACLE\x1b[0m');
    console.error(`     Host:    ${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_SERVICE}`);
    console.error(`     User:    ${process.env.DB_USER}`);
    console.error(`     Detalhe: ${err.message}`);
    throw err;
  }
}

async function testConnection() {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute('SELECT SYSDATE, BANNER FROM V$VERSION WHERE ROWNUM = 1');
    const [sysdate, banner] = result.rows[0];
    return {
      ok: true,
      timestamp: sysdate,
      version: banner,
      host: process.env.DB_HOST,
      service: process.env.DB_SERVICE,
    };
  } finally {
    if (conn) await conn.close();
  }
}

async function listUserTables() {
  let conn;
  try {
    conn = await getConnection();
    // ALL_TABLES porque SYS vê tudo; USER_TABLES mostraria só as do schema actual
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

module.exports = { getConnection, testConnection, listUserTables, oracledb };
