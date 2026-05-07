const express = require('express');
const router  = express.Router();
const { getConnection, oracledb } = require('../db');
const { exigirNivel, autenticar } = require('../middleware/permissoes');

const PROVINCIAS_VALIDAS = [
  'Cabo Delgado', 'Gaza', 'Inhambane', 'Manica',
  'Maputo Provincia', 'Maputo Cidade',
  'Nampula', 'Niassa', 'Sofala', 'Tete', 'Zambezia'
];

const PROVINCIA_ABREV = {
  'Cabo Delgado':    'CAB',
  'Gaza':            'GAZ',
  'Inhambane':       'INH',
  'Manica':          'MAN',
  'Maputo Provincia':'MPV',
  'Maputo Cidade':   'MPC',
  'Nampula':         'NAM',
  'Niassa':          'NIA',
  'Sofala':          'SOF',
  'Tete':            'TET',
  'Zambezia':        'ZAM'
};

async function gerarCodBiblioteca(conn, provincia) {
  const abrev  = PROVINCIA_ABREV[provincia];
  const prefix = 'BIB' + abrev;
  const r = await conn.execute(
    `SELECT COUNT(*) AS N FROM BIBLIOTECA WHERE COD_BIBLIOTECA LIKE :pat`,
    { pat: prefix + '%' },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );
  const seq = r.rows[0].N + 1;
  return prefix + String(seq).padStart(4, '0');
}

// GET /api/bibliotecas/minha — qualquer utilizador autenticado (a sua própria biblioteca)
router.get('/minha', autenticar, async (req, res) => {
  const cod = req.session.cod_biblioteca;
  if (!cod) return res.status(404).json({ erro: 'Biblioteca não associada à sessão.' });
  let conn;
  try {
    conn = await getConnection();
    const bibRes = await conn.execute(
      `SELECT COD_BIBLIOTECA, NOME_BIBLIOTECA, PROVINCIA, ENDERECO,
              LATITUDE, LONGITUDE, CONTACTO_BIBLIOTECA,
              DATA_INAUGURACAO, CAPACIDADE, INFRAESTRUTURA, SERVICOS
         FROM BIBLIOTECA
        WHERE COD_BIBLIOTECA = :cod`,
      { cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (bibRes.rows.length === 0) {
      return res.status(404).json({ erro: 'Biblioteca não encontrada.' });
    }
    const [horariosRes, responsaveisRes, statsRes] = await Promise.all([
      conn.execute(
        `SELECT ID_HORARIO_BIB, DIA_SEMANA, HORA_ABERTURA, HORA_FECHO
           FROM HORARIO_BIBLIOTECA
          WHERE COD_BIBLIOTECA = :cod
          ORDER BY DIA_SEMANA`,
        { cod },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      ),
      conn.execute(
        `SELECT br.COD_FUNCIONARIO, f.NOME_FUNCIONARIO, br.DATA_INICIO, br.DATA_FIM, br.PAPEL
           FROM BIBLIOTECA_RESPONSAVEL br
           JOIN FUNCIONARIO f ON f.COD_FUNCIONARIO = br.COD_FUNCIONARIO
          WHERE br.COD_BIBLIOTECA = :cod
          ORDER BY br.DATA_INICIO DESC`,
        { cod },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      ),
      conn.execute(
        `SELECT
           (SELECT COUNT(*) FROM MATERIAL_BIBLIOGRAFICO WHERE COD_BIBLIOTECA = :cod) AS TOTAL_MATERIAIS,
           (SELECT COUNT(*) FROM LEITOR WHERE COD_BIBLIOTECA = :cod) AS TOTAL_LEITORES,
           (SELECT COUNT(*)
              FROM EMPRESTIMO e
              JOIN LEITOR l ON l.NUM_CARTAO = e.NUM_CARTAO
             WHERE l.COD_BIBLIOTECA = :cod
               AND e.DATA_DEVOLUCAO IS NULL) AS EMPRESTIMOS_ACTIVOS
           FROM DUAL`,
        { cod },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      )
    ]);
    const bib        = bibRes.rows[0];
    bib.HORARIOS     = horariosRes.rows;
    bib.RESPONSAVEIS = responsaveisRes.rows;
    bib.STATS        = statsRes.rows[0];
    res.json(bib);
  } catch (err) {
    console.error('\x1b[31m[BIBLIOTECAS GET /minha]\x1b[0m');
    console.error('     BD: BIBLIOTECA + HORARIO_BIBLIOTECA + BIBLIOTECA_RESPONSAVEL + FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/bibliotecas — só Administrador
router.get('/', exigirNivel('Administrador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT b.COD_BIBLIOTECA,
              b.NOME_BIBLIOTECA,
              b.PROVINCIA,
              b.ENDERECO,
              b.LATITUDE,
              b.LONGITUDE,
              b.CONTACTO_BIBLIOTECA,
              b.DATA_INAUGURACAO,
              b.CAPACIDADE,
              b.INFRAESTRUTURA,
              b.SERVICOS,
              (SELECT f.NOME_FUNCIONARIO
                 FROM BIBLIOTECA_RESPONSAVEL br
                 JOIN FUNCIONARIO f ON f.COD_FUNCIONARIO = br.COD_FUNCIONARIO
                WHERE br.COD_BIBLIOTECA = b.COD_BIBLIOTECA
                  AND br.PAPEL = 'Principal'
                  AND br.DATA_FIM IS NULL
                  AND ROWNUM = 1) AS RESPONSAVEL_ACTUAL,
              (SELECT COUNT(*)
                 FROM MATERIAL_BIBLIOGRAFICO
                WHERE COD_BIBLIOTECA = b.COD_BIBLIOTECA) AS TOTAL_MATERIAIS,
              (SELECT COUNT(*)
                 FROM LEITOR
                WHERE COD_BIBLIOTECA = b.COD_BIBLIOTECA) AS TOTAL_LEITORES
         FROM BIBLIOTECA b
        ORDER BY b.NOME_BIBLIOTECA`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[BIBLIOTECAS GET /]\x1b[0m');
    console.error('     BD: BIBLIOTECA + BIBLIOTECA_RESPONSAVEL + FUNCIONARIO + MATERIAL_BIBLIOGRAFICO + LEITOR');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/bibliotecas/:cod_biblioteca — só Administrador e Coordenador (§3)
router.get('/:cod_biblioteca', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const cod = req.params.cod_biblioteca;
  let conn;
  try {
    conn = await getConnection();

    const bibRes = await conn.execute(
      `SELECT COD_BIBLIOTECA, NOME_BIBLIOTECA, PROVINCIA, ENDERECO,
              LATITUDE, LONGITUDE, CONTACTO_BIBLIOTECA,
              DATA_INAUGURACAO, CAPACIDADE, INFRAESTRUTURA, SERVICOS
         FROM BIBLIOTECA
        WHERE COD_BIBLIOTECA = :cod`,
      { cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (bibRes.rows.length === 0) {
      return res.status(404).json({ erro: 'Biblioteca não encontrada.' });
    }

    const [horariosRes, responsaveisRes, statsRes] = await Promise.all([
      conn.execute(
        `SELECT ID_HORARIO_BIB, DIA_SEMANA, HORA_ABERTURA, HORA_FECHO
           FROM HORARIO_BIBLIOTECA
          WHERE COD_BIBLIOTECA = :cod
          ORDER BY DIA_SEMANA`,
        { cod },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      ),
      conn.execute(
        `SELECT br.COD_FUNCIONARIO,
                f.NOME_FUNCIONARIO,
                br.DATA_INICIO,
                br.DATA_FIM,
                br.PAPEL
           FROM BIBLIOTECA_RESPONSAVEL br
           JOIN FUNCIONARIO f ON f.COD_FUNCIONARIO = br.COD_FUNCIONARIO
          WHERE br.COD_BIBLIOTECA = :cod
          ORDER BY br.DATA_INICIO DESC`,
        { cod },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      ),
      conn.execute(
        `SELECT
           (SELECT COUNT(*) FROM MATERIAL_BIBLIOGRAFICO WHERE COD_BIBLIOTECA = :cod) AS TOTAL_MATERIAIS,
           (SELECT COUNT(*) FROM LEITOR WHERE COD_BIBLIOTECA = :cod) AS TOTAL_LEITORES,
           (SELECT COUNT(*)
              FROM EMPRESTIMO e
              JOIN LEITOR l ON l.NUM_CARTAO = e.NUM_CARTAO
             WHERE l.COD_BIBLIOTECA = :cod
               AND e.DATA_DEVOLUCAO IS NULL) AS EMPRESTIMOS_ACTIVOS
           FROM DUAL`,
        { cod },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      )
    ]);

    const bib        = bibRes.rows[0];
    bib.HORARIOS     = horariosRes.rows;
    bib.RESPONSAVEIS = responsaveisRes.rows;
    bib.STATS        = statsRes.rows[0];

    res.json(bib);
  } catch (err) {
    console.error('\x1b[31m[BIBLIOTECAS GET /:cod_biblioteca]\x1b[0m');
    console.error('     BD: BIBLIOTECA + HORARIO_BIBLIOTECA + BIBLIOTECA_RESPONSAVEL + FUNCIONARIO + MATERIAL_BIBLIOGRAFICO + LEITOR + EMPRESTIMO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/bibliotecas — só Administrador
router.post('/', exigirNivel('Administrador'), async (req, res) => {
  const {
    nome_biblioteca, provincia, endereco, contacto_biblioteca,
    latitude, longitude, data_inauguracao,
    capacidade, infraestrutura, servicos
  } = req.body;

  if (!nome_biblioteca || !provincia || !endereco || !contacto_biblioteca) {
    return res.status(400).json({ erro: 'nome_biblioteca, provincia, endereco e contacto_biblioteca são obrigatórios.' });
  }
  if (!PROVINCIAS_VALIDAS.includes(provincia)) {
    return res.status(400).json({ erro: `Provincia inválida. Valores aceites: ${PROVINCIAS_VALIDAS.join(', ')}.` });
  }

  let conn;
  try {
    conn = await getConnection();
    const codBiblioteca = await gerarCodBiblioteca(conn, provincia);

    await conn.execute(
      `INSERT INTO BIBLIOTECA
         (COD_BIBLIOTECA, NOME_BIBLIOTECA, PROVINCIA, ENDERECO,
          LATITUDE, LONGITUDE, CONTACTO_BIBLIOTECA,
          DATA_INAUGURACAO, CAPACIDADE, INFRAESTRUTURA, SERVICOS)
       VALUES
         (:cod, :nome, :provincia, :endereco,
          :latitude, :longitude, :contacto,
          TO_DATE(:data_inauguracao, 'YYYY-MM-DD'),
          :capacidade, :infraestrutura, :servicos)`,
      {
        cod:              codBiblioteca,
        nome:             nome_biblioteca,
        provincia,
        endereco,
        latitude:         latitude      != null ? Number(latitude)   : null,
        longitude:        longitude     != null ? Number(longitude)  : null,
        contacto:         contacto_biblioteca,
        data_inauguracao: data_inauguracao || null,
        capacidade:       capacidade    != null ? Number(capacidade) : null,
        infraestrutura:   infraestrutura || null,
        servicos:         servicos      || null
      }
    );
    await conn.commit();
    res.status(201).json({ ok: true, cod_biblioteca: codBiblioteca });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[BIBLIOTECAS POST /]\x1b[0m');
    console.error('     BD: INSERT BIBLIOTECA');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /api/bibliotecas/:cod_biblioteca — Administrador ou Coordenador
router.patch('/:cod_biblioteca', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const nivel  = req.session.nivel_acesso;
  const codBib = req.params.cod_biblioteca;

  if (nivel === 'Coordenador') {
    if (req.session.cod_biblioteca !== codBib) {
      return res.status(403).json({ erro: 'Coordenador só pode editar a sua própria biblioteca.' });
    }
    const camposPermitidos = new Set(['infraestrutura', 'servicos']);
    const camposProibidos  = Object.keys(req.body).filter(k => !camposPermitidos.has(k));
    if (camposProibidos.length > 0) {
      return res.status(403).json({ erro: `Coordenador não pode editar: ${camposProibidos.join(', ')}.` });
    }
  }

  const setClauses = [];
  const binds      = { cod: codBib };

  const { nome_biblioteca, endereco, latitude, longitude, contacto_biblioteca,
          data_inauguracao, capacidade, infraestrutura, servicos } = req.body;

  if (nome_biblioteca    !== undefined) { setClauses.push('NOME_BIBLIOTECA = :nome');         binds.nome         = nome_biblioteca; }
  if (endereco           !== undefined) { setClauses.push('ENDERECO = :endereco');             binds.endereco     = endereco; }
  if (latitude           !== undefined) { setClauses.push('LATITUDE = :latitude');             binds.latitude     = latitude != null ? Number(latitude) : null; }
  if (longitude          !== undefined) { setClauses.push('LONGITUDE = :longitude');           binds.longitude    = longitude != null ? Number(longitude) : null; }
  if (contacto_biblioteca !== undefined) { setClauses.push('CONTACTO_BIBLIOTECA = :contacto'); binds.contacto     = contacto_biblioteca; }
  if (data_inauguracao   !== undefined) { setClauses.push(`DATA_INAUGURACAO = TO_DATE(:data_inau, 'YYYY-MM-DD')`); binds.data_inau = data_inauguracao || null; }
  if (capacidade         !== undefined) { setClauses.push('CAPACIDADE = :capacidade');         binds.capacidade   = capacidade != null ? Number(capacidade) : null; }
  if (infraestrutura     !== undefined) { setClauses.push('INFRAESTRUTURA = :infraestrutura'); binds.infraestrutura = infraestrutura || null; }
  if (servicos           !== undefined) { setClauses.push('SERVICOS = :servicos');             binds.servicos     = servicos || null; }

  if (setClauses.length === 0) {
    return res.status(400).json({ erro: 'Nenhum campo para actualizar.' });
  }

  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `UPDATE BIBLIOTECA SET ${setClauses.join(', ')} WHERE COD_BIBLIOTECA = :cod`,
      binds
    );
    if (result.rowsAffected === 0) {
      return res.status(404).json({ erro: 'Biblioteca não encontrada.' });
    }
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[BIBLIOTECAS PATCH /:cod_biblioteca]\x1b[0m');
    console.error('     BD: UPDATE BIBLIOTECA');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /api/bibliotecas/:cod_biblioteca/desactivar — só Administrador
router.patch('/:cod_biblioteca/desactivar', exigirNivel('Administrador'), async (req, res) => {
  const cod = req.params.cod_biblioteca;
  let conn;
  try {
    conn = await getConnection();

    const check = await conn.execute(
      `SELECT
         (SELECT COUNT(*) FROM MATERIAL_BIBLIOGRAFICO WHERE COD_BIBLIOTECA = :cod AND ESTADO != 'Inactivo') AS MAT_ACTIVOS,
         (SELECT COUNT(*) FROM EMPRESTIMO WHERE COD_BIBLIOTECA = :cod AND ESTADO = 'Activo') AS EMP_ACTIVOS
       FROM DUAL`,
      { cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const row = check.rows[0];
    if (row.MAT_ACTIVOS > 0)
      return res.status(409).json({ erro: 'Existem materiais activos associados a esta biblioteca.' });
    if (row.EMP_ACTIVOS > 0)
      return res.status(409).json({ erro: 'Existem empréstimos activos nesta biblioteca.' });

    const result = await conn.execute(
      `UPDATE BIBLIOTECA SET ESTADO = 'Inactivo' WHERE COD_BIBLIOTECA = :cod`,
      { cod }
    );
    if (result.rowsAffected === 0)
      return res.status(404).json({ erro: 'Biblioteca não encontrada.' });

    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[BIBLIOTECAS PATCH /desactivar]\x1b[0m');
    console.error('     BD: UPDATE BIBLIOTECA');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
