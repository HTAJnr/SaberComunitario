const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');

router.get('/categorias', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT ID_CATEGORIA, NOME, AREA_TEMATICA, FAIXA_ETARIA, NIVEL_LEITURA FROM CATEGORIA ORDER BY NOME`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[MATERIAIS GET /categorias] ERRO ao listar categorias\x1b[0m');
    console.error('     BD: CATEGORIA');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { tipo, conservacao, disponivel, q, id_categoria } = req.query;
    let where = 'WHERE 1=1';
    const params = {};
    if (tipo) { where += ` AND TIPO_MATERIAL = :tipo`; params.tipo = tipo; }
    if (conservacao) { where += ` AND ESTADO_CONSERVACAO = :conservacao`; params.conservacao = conservacao; }
    if (disponivel) { where += ` AND DISPONIVEL_EMPRESTIMO = :disponivel`; params.disponivel = disponivel; }
    if (id_categoria) { where += ` AND ID_CATEGORIA = :idc`; params.idc = id_categoria; }
    if (q) { where += ` AND (UPPER(TITULO) LIKE UPPER(:q) OR UPPER(AUTOR) LIKE UPPER(:q))`; params.q = `%${q}%`; }
    const result = await conn.execute(
      `SELECT COD_MATERIAL, TITULO, AUTOR, EDITORA, ANO_PUBLICACAO, ISBN,
              TIPO_MATERIAL        AS TIPO,
              ESTADO_CONSERVACAO   AS ESTADO,
              DISPONIVEL_EMPRESTIMO, COD_BIBLIOTECA, BIBLIOTECA_NOME,
              LOCALIZACAO_FISICA, EBOOK_FORMATO, EBOOK_URL,
              PERIODICO_EDICAO, PERIODICO_PERIODICIDADE
       FROM vw_materiais_completos ${where} ORDER BY TITULO`,
      params,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[MATERIAIS GET /] ERRO ao listar materiais\x1b[0m');
    console.error('     BD: VIEW vw_materiais_completos');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/:id', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT m.*,
              lf.LOCALIZACAO, lf.NUM_EXEMPLARES, lf.CONDICAO,
              e.FORMATO, e.TAMANHO_MB, e.URL_ACESSO,
              pr.VOLUME, pr.NUMERO_EDICAO, pr.ISSN, pr.PERIODICIDADE
         FROM MATERIAL_BIBLIOGRAFICO m
         LEFT JOIN LIVRO_FISICO lf ON lf.COD_MATERIAL = m.COD_MATERIAL
         LEFT JOIN EBOOK e ON e.COD_MATERIAL = m.COD_MATERIAL
         LEFT JOIN PERIODICO pr ON pr.COD_MATERIAL = m.COD_MATERIAL
        WHERE m.COD_MATERIAL = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (result.rows.length === 0) return res.status(404).json({ erro: 'Material não encontrado.' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(`\x1b[31m[MATERIAIS GET /${req.params.id}] ERRO ao buscar material\x1b[0m`);
    console.error('     BD: MATERIAL_BIBLIOGRAFICO + LIVRO_FISICO + EBOOK + PERIODICO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/', async (req, res) => {
  const { titulo, autor, ano_pub, isbn, id_categoria, cod_biblioteca, estado, tipo,
          localizacao, num_exemplares, condicao,
          formato, tamanho_mb, url_acesso,
          volume, numero_edicao, issn, periodicidade } = req.body;
  if (!titulo || !tipo) return res.status(400).json({ erro: 'Título e tipo obrigatórios.' });

  let conn;
  try {
    conn = await getConnection();
    // Trigger gera COD_MATERIAL via SEQ_MATERIAL
    const matResult = await conn.execute(
      `INSERT INTO MATERIAL_BIBLIOGRAFICO (TITULO, AUTOR, ANO_PUB, ISBN, ID_CATEGORIA, COD_BIBLIOTECA, ESTADO, TIPO)
       VALUES (:titulo, :autor, :ano_pub, :isbn, :id_cat, :cod_bib, NVL(:estado,'DISPONIVEL'), :tipo)
       RETURNING COD_MATERIAL INTO :id_out`,
      { titulo, autor: autor || null, ano_pub: ano_pub || null, isbn: isbn || null,
        id_cat: id_categoria || null, cod_bib: cod_biblioteca || null,
        estado: estado || null, tipo,
        id_out: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER } }
    );
    const idMaterial = matResult.outBinds.id_out[0];

    if (tipo === 'LIVRO_FISICO') {
      await conn.execute(
        `INSERT INTO LIVRO_FISICO (COD_MATERIAL, LOCALIZACAO, NUM_EXEMPLARES, CONDICAO)
         VALUES (:id, :loc, :nexemp, NVL(:cond,'BOM'))`,
        { id: idMaterial, loc: localizacao || null, nexemp: num_exemplares || 1, cond: condicao || null }
      );
    } else if (tipo === 'EBOOK') {
      await conn.execute(
        `INSERT INTO EBOOK (COD_MATERIAL, FORMATO, TAMANHO_MB, URL_ACESSO)
         VALUES (:id, :fmt, :tmb, :url)`,
        { id: idMaterial, fmt: formato || null, tmb: tamanho_mb || null, url: url_acesso || null }
      );
    } else if (tipo === 'PERIODICO') {
      await conn.execute(
        `INSERT INTO PERIODICO (COD_MATERIAL, VOLUME, NUMERO_EDICAO, ISSN, PERIODICIDADE)
         VALUES (:id, :vol, :ned, :issn, :per)`,
        { id: idMaterial, vol: volume || null, ned: numero_edicao || null, issn: issn || null, per: periodicidade || null }
      );
    }

    await conn.commit();
    res.status(201).json({ ok: true, COD_material: idMaterial });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[MATERIAIS POST /] ERRO ao criar material\x1b[0m');
    console.error('     BD: INSERT MATERIAL_BIBLIOGRAFICO → INSERT LIVRO_FISICO/EBOOK/PERIODICO (SEQ_MATERIAL)');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.put('/:id', async (req, res) => {
  const { titulo, autor, ano_pub, isbn, id_categoria, cod_biblioteca, estado, tipo,
          localizacao, num_exemplares, condicao,
          formato, tamanho_mb, url_acesso,
          volume, numero_edicao, issn, periodicidade } = req.body;
  let conn;
  try {
    conn = await getConnection();
    await conn.execute(
      `UPDATE MATERIAL_BIBLIOGRAFICO SET
         TITULO = NVL(:titulo, TITULO),
         AUTOR = NVL(:autor, AUTOR),
         ANO_PUB = NVL(:ano_pub, ANO_PUB),
         ISBN = NVL(:isbn, ISBN),
         ID_CATEGORIA = NVL(:id_cat, ID_CATEGORIA),
         COD_BIBLIOTECA = NVL(:cod_bib, COD_BIBLIOTECA),
         ESTADO = NVL(:estado, ESTADO)
       WHERE COD_MATERIAL = :id`,
      { titulo: titulo || null, autor: autor || null, ano_pub: ano_pub || null, isbn: isbn || null,
        id_cat: id_categoria || null, cod_bib: cod_biblioteca || null,
        estado: estado || null, id: req.params.id }
    );

    if (tipo === 'LIVRO_FISICO') {
      await conn.execute(
        `UPDATE LIVRO_FISICO SET
           LOCALIZACAO = NVL(:loc, LOCALIZACAO),
           NUM_EXEMPLARES = NVL(:nexemp, NUM_EXEMPLARES),
           CONDICAO = NVL(:cond, CONDICAO)
         WHERE COD_MATERIAL = :id`,
        { loc: localizacao || null, nexemp: num_exemplares || null, cond: condicao || null, id: req.params.id }
      );
    } else if (tipo === 'EBOOK') {
      await conn.execute(
        `UPDATE EBOOK SET
           FORMATO = NVL(:fmt, FORMATO),
           TAMANHO_MB = NVL(:tmb, TAMANHO_MB),
           URL_ACESSO = NVL(:url, URL_ACESSO)
         WHERE COD_MATERIAL = :id`,
        { fmt: formato || null, tmb: tamanho_mb || null, url: url_acesso || null, id: req.params.id }
      );
    } else if (tipo === 'PERIODICO') {
      await conn.execute(
        `UPDATE PERIODICO SET
           VOLUME = NVL(:vol, VOLUME),
           NUMERO_EDICAO = NVL(:ned, NUMERO_EDICAO),
           ISSN = NVL(:issn, ISSN),
           PERIODICIDADE = NVL(:per, PERIODICIDADE)
         WHERE COD_MATERIAL = :id`,
        { vol: volume || null, ned: numero_edicao || null, issn: issn || null, per: periodicidade || null, id: req.params.id }
      );
    }

    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[MATERIAIS PUT /${req.params.id}] ERRO ao actualizar material\x1b[0m`);
    console.error('     BD: UPDATE MATERIAL_BIBLIOGRAFICO + UPDATE LIVRO_FISICO/EBOOK/PERIODICO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.delete('/:id', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const check = await conn.execute(
      `SELECT COUNT(*) AS N FROM EMPRESTIMO WHERE COD_MATERIAL = :id AND ESTADO = 'ACTIVO'`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (check.rows[0].N > 0) {
      return res.status(409).json({ erro: 'Material tem empréstimos activos.' });
    }
    await conn.execute(`DELETE FROM MATERIAL_BIBLIOGRAFICO WHERE COD_MATERIAL = :id`, { id: req.params.id });
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[MATERIAIS DELETE /${req.params.id}] ERRO ao eliminar material\x1b[0m`);
    console.error('     BD: EMPRESTIMO (check) → DELETE MATERIAL_BIBLIOGRAFICO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
