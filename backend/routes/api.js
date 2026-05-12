const express = require('express');
const { testConnection, listUserTables, getConnection, oracledb } = require('../db');

const router = express.Router();

// Mapa de utilizador Oracle → nome canónico do nó
const NO_MAP = {
  'USR_NACIONALDB':    'BibliotecaNacionalDB',
  'USR_EMPRESTIMOSDB': 'EmpréstimosProgramasDB',
  'USR_MATERIAISDB':   'MateriaisDB',
  'USR_EVENTOSDB':     'EventosBibliotecasDB',
};

// GET /api/no/info — identidade do nó verificada via Oracle (SELECT USER FROM DUAL)
// Não depende só do NODE_NAME do .env; o utilizador Oracle activo não se falsifica mudando o .env
router.get('/no/info', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const r = await conn.execute('SELECT USER FROM DUAL', [], { outFormat: oracledb.OUT_FORMAT_OBJECT });
    const dbUser  = (r.rows[0].USER || '').toUpperCase();
    const no_nome = NO_MAP[dbUser] || process.env.NODE_NAME || 'BibliotecaNacionalDB';
    res.json({ no_nome, db_user: dbUser });
  } catch {
    res.json({ no_nome: process.env.NODE_NAME || 'BibliotecaNacionalDB', db_user: null });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/test-connection', async (req, res) => {
  try {
    const result = await testConnection();
    res.json(result);
  } catch (err) {
    res.status(500).json({
      ok: false,
      error: err.message,
      host: process.env.DB_HOST,
      service: process.env.DB_SERVICE,
    });
  }
});

router.get('/tables', async (req, res) => {
  try {
    const tables = await listUserTables();
    res.json({ ok: true, total: tables.length, tables });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

module.exports = router;
