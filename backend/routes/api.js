const express = require('express');
const { testConnection, listUserTables } = require('../db');

const router = express.Router();

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
