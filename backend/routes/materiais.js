const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');
const { autenticar, exigirNivel } = require('../middleware/permissoes');

const TIPOS_VALIDOS = ['Livro', 'Ebook', 'Periodico'];
const ORIGENS_VALIDAS = ['Comprado', 'Doado', 'Transferido'];
const ESTADOS_VALIDOS = ['Bom', 'Degradado', 'Indisponivel'];
const FORMATOS_DIGITAIS = ['PDF', 'EPUB', 'MOBI'];

function getNivel(req) {
  return req.session.nivel_acesso || req.session.funcionario?.NIVEL_ACESSO || '';
}

function erroInterno(res, err, contexto) {
  console.error(`\x1b[31m[MATERIAIS ${contexto}]\x1b[0m`, err.message);
  res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message });
}

async function gerarCodMaterial(conn) {
  const year = new Date().getFullYear();
  const prefix = 'MAT' + year;
  const r = await conn.execute(
    `SELECT COUNT(*) AS N FROM MATERIAL_BIBLIOGRAFICO WHERE COD_MATERIAL LIKE :pat`,
    { pat: prefix + '%' },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );
  const seq = r.rows[0].N + 1;
  return prefix + String(seq).padStart(4, '0');
}

function parseIncludes(includeStr) {
  const result = { emprestimos: false, transferencias: false, doacao: false };
  if (!includeStr) return result;
  includeStr.split(',').forEach(part => {
    const [key, val] = part.trim().split(':');
    if (key === 'emprestimos') result.emprestimos = parseInt(val) || 5;
    if (key === 'transferencias') result.transferencias = true;
    if (key === 'doacao') result.doacao = true;
  });
  return result;
}

// ── GET /categorias ────────────────────────────────────────────
router.get('/categorias', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT ID_CATEGORIA, AREA_TEMATICA, FAIXA_ETARIA, NIVEL_LEITURA
         FROM CATEGORIA        ORDER BY AREA_TEMATICA`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    erroInterno(res, err, 'GET /categorias');
  } finally {
    if (conn) await conn.close();
  }
});

// ── GET / — listar materiais ───────────────────────────────────
router.get('/', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { tipo, estado, disponivel, search, cod_categoria, biblioteca } = req.query;
    const page  = Math.max(1, parseInt(req.query.page)  || 1);
    const limit = Math.max(1, parseInt(req.query.limit) || 20);

    let where = 'WHERE 1=1';
    const params = {};

    if (tipo && TIPOS_VALIDOS.includes(tipo)) {
      const mapa = { Livro: 'LIVRO_FISICO', Ebook: 'EBOOK', Periodico: 'PERIODICO' };
      where += ` AND TIPO_MATERIAL = :tipo`;
      params.tipo = mapa[tipo];
    }
    if (estado && ESTADOS_VALIDOS.includes(estado)) {
      where += ` AND ESTADO_CONSERVACAO = :estado`;
      params.estado = estado;
    }
    if (disponivel === 'true') {
      where += ` AND DISPONIVEL_EMPRESTIMO = 'S'`;
    }
    if (cod_categoria) {
      where += ` AND COD_MATERIAL IN (SELECT COD_MATERIAL FROM MATERIAL_BIBLIOGRAFICO WHERE COD_CATEGORIA = :cod_cat)`;
      params.cod_cat = Number(cod_categoria);
    }
    if (search) {
      where += ` AND (UPPER(TITULO) LIKE UPPER(:search) OR UPPER(AUTOR) LIKE UPPER(:search))`;
      params.search = `%${search}%`;
    }

    const nivel = getNivel(req);
    if (nivel === 'Administrador') {
      if (biblioteca) { where += ` AND COD_BIBLIOTECA = :cod_bib`; params.cod_bib = biblioteca; }
    } else {
      const codBib = req.session.cod_biblioteca || req.session.funcionario?.COD_BIBLIOTECA;
      if (codBib) { where += ` AND COD_BIBLIOTECA = :cod_bib`; params.cod_bib = codBib; }
    }

    const rowmin = (page - 1) * limit;
    const rowmax = page * limit;
    params.rowmin = rowmin;
    params.rowmax = rowmax;

    const sql = `
      SELECT * FROM (
        SELECT t.*, ROWNUM AS RN FROM (
          SELECT COD_MATERIAL, TITULO, AUTOR, EDITORA, ANO_PUBLICACAO, ISBN, IDIOMA,
                 TIPO_MATERIAL        AS TIPO,
                 ESTADO_CONSERVACAO   AS ESTADO,
                 DISPONIVEL_EMPRESTIMO,
                 COD_BIBLIOTECA, BIBLIOTECA_NOME,
                 CATEGORIA_AREA_TEMATICA, CATEGORIA_FAIXA_ETARIA,
                 LOCALIZACAO_ESTANTE,
                 EBOOK_FORMATO, EBOOK_URL, EBOOK_TAMANHO,
                 PERIODICO_EDICAO, PERIODICO_PERIODICIDADE, PERIODICO_ISSN
            FROM vw_materiais_completos ${where}
           ORDER BY TITULO
        ) t WHERE ROWNUM <= :rowmax
      ) WHERE RN > :rowmin`;

    const result = await conn.execute(sql, params, { outFormat: oracledb.OUT_FORMAT_OBJECT });

    const totalResult = await conn.execute(
      `SELECT COUNT(*) AS N FROM vw_materiais_completos ${where}`,
      Object.fromEntries(Object.entries(params).filter(([k]) => !['rowmin', 'rowmax'].includes(k))),
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const total = totalResult.rows[0].N;

    res.json({ total, page, limit, materiais: result.rows });
  } catch (err) {
    erroInterno(res, err, 'GET /');
  } finally {
    if (conn) await conn.close();
  }
});

// ── GET /:id — detalhe do material ────────────────────────────
router.get('/:id', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const id = req.params.id;
    const includes = parseIncludes(req.query.include);

    const matResult = await conn.execute(
      `SELECT m.COD_MATERIAL, m.TITULO, m.AUTOR, m.EDITORA, m.ANO_PUBLICACAO,
              m.ISBN, m.IDIOMA, m.NUM_PAGINAS,
              m.ESTADO_MATERIAL_CONSERVACAO, m.MOTIVO_INDISPONIBILIDADE,
              m.ORIGEM_MATERIAL, m.DATA_AQUISICAO, m.VALOR_AQUISICAO,
              m.LOCALIZACAO_ESTANTE, m.COD_CATEGORIA, m.COD_BIBLIOTECA,
              m.ID_ITEMDOADO,
              cat.AREA_TEMATICA  AS CATEGORIA_AREA_TEMATICA,
              cat.FAIXA_ETARIA   AS CATEGORIA_FAIXA_ETARIA,
              cat.NIVEL_LEITURA  AS CATEGORIA_NIVEL_LEITURA,
              CASE WHEN lf.COD_MATERIAL IS NOT NULL THEN 'Livro'
                   WHEN e.COD_MATERIAL  IS NOT NULL THEN 'Ebook'
                   WHEN p.COD_MATERIAL  IS NOT NULL THEN 'Periodico'
              END AS TIPO,
              e.FORMATO        AS EBOOK_FORMATO,
              e.TAMANHO_ARQUIVO AS EBOOK_TAMANHO,
              e.URL_ACESSO     AS EBOOK_URL,
              p.EDICAO          AS PERIODICO_EDICAO,
              p.PERIODICIDADE   AS PERIODICO_PERIODICIDADE,
              p.DATA_PUBLICACAO AS PERIODICO_DATA_PUBLICACAO,
              p.ISSN            AS PERIODICO_ISSN
         FROM MATERIAL_BIBLIOGRAFICO m
         LEFT JOIN CATEGORIA cat    ON cat.ID_CATEGORIA = m.COD_CATEGORIA
         LEFT JOIN LIVRO_FISICO lf  ON lf.COD_MATERIAL  = m.COD_MATERIAL
         LEFT JOIN EBOOK e          ON e.COD_MATERIAL   = m.COD_MATERIAL
         LEFT JOIN PERIODICO p      ON p.COD_MATERIAL   = m.COD_MATERIAL
        WHERE m.COD_MATERIAL = :id`,
      { id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    if (matResult.rows.length === 0) {
      return res.status(404).json({ erro: true, codigo: 'NAO_ENCONTRADO', mensagem: 'Material não encontrado.' });
    }

    const material = matResult.rows[0];
    const resposta = { ...material };

    const empResult = await conn.execute(
      `SELECT * FROM (
         SELECT ID_EMPRESTIMO, NUM_CARTAO, COD_FUNCIONARIO,
                DATA_RETIRADA, PRAZO_DEVOLUCAO, DATA_DEVOLUCAO,
                MULTA_VALOR, MULTA_PAGA
           FROM EMPRESTIMO          WHERE COD_MATERIAL = :id
          ORDER BY DATA_RETIRADA DESC
       ) WHERE ROWNUM <= 5`,
      { id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    resposta.emprestimos = empResult.rows;

    const tResult = await conn.execute(
      `SELECT ID_TRANSFERENCIA, ESTADO_TRANSFERENCIA, DATA_SOLICITACAO,
              DATA_CONCLUSAO, COD_BIBLIOTECA_ORIGEM, COD_BIBLIOTECA_DESTINO
         FROM TRANSFERENCIA        WHERE COD_MATERIAL = :id
        ORDER BY DATA_SOLICITACAO DESC`,
      { id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    resposta.transferencias = tResult.rows;

    if (material.ID_ITEMDOADO) {
      const dResult = await conn.execute(
        `SELECT it.ID_ITEMDOADO, it.VALOR_ESTIMADO, it.QUANTIDADE,
                d.DATA_DOACAO, dor.NOME_DOADOR, dor.TIPO_DOADOR
           FROM ITEM_DOACAO it
           JOIN DOACAO d   ON d.ID_DOACAO  = it.ID_DOACAO
           JOIN DOADOR dor ON dor.ID_DOADOR = d.ID_DOADOR
          WHERE it.ID_ITEMDOADO = :id_item`,
        { id_item: material.ID_ITEMDOADO },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      resposta.doacao = dResult.rows[0] || null;
    } else {
      resposta.doacao = null;
    }

    res.json(resposta);
  } catch (err) {
    erroInterno(res, err, `GET /${req.params.id}`);
  } finally {
    if (conn) await conn.close();
  }
});

// ── POST / — criar material ────────────────────────────────────
router.post('/', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  const {
    titulo, tipo, cod_categoria, cod_biblioteca, origem_material,
    autor, editora, ano_publicacao, isbn, idioma, num_paginas,
    estado_material_conservacao, motivo_indisponibilidade,
    localizacao_estante, valor_aquisicao, data_aquisicao, id_itemDoado,
    formato, tamanho_arquivo, url_acesso,
    edicao, periodicidade, data_publicacao, issn
  } = req.body;

  // Validações obrigatórias
  if (!titulo || !tipo || !cod_categoria || !cod_biblioteca || !origem_material) {
    return res.status(400).json({ erro: true, codigo: 'CAMPOS_OBRIGATORIOS', mensagem: 'titulo, tipo, cod_categoria, cod_biblioteca e origem_material são obrigatórios.' });
  }
  if (!TIPOS_VALIDOS.includes(tipo)) {
    return res.status(400).json({ erro: true, codigo: 'TIPO_INVALIDO', mensagem: `tipo deve ser um de: ${TIPOS_VALIDOS.join(', ')}.` });
  }
  if (!ORIGENS_VALIDAS.includes(origem_material)) {
    return res.status(400).json({ erro: true, codigo: 'ORIGEM_INVALIDA', mensagem: `origem_material deve ser um de: ${ORIGENS_VALIDAS.join(', ')}.` });
  }

  const estado = estado_material_conservacao || 'Bom';
  if (!ESTADOS_VALIDOS.includes(estado)) {
    return res.status(400).json({ erro: true, codigo: 'ESTADO_INVALIDO', mensagem: `estado_material_conservacao deve ser um de: ${ESTADOS_VALIDOS.join(', ')}.` });
  }
  if (estado === 'Indisponivel' && !motivo_indisponibilidade) {
    return res.status(400).json({ erro: true, codigo: 'MOTIVO_OBRIGATORIO', mensagem: 'motivo_indisponibilidade é obrigatório quando estado é Indisponivel.' });
  }
  if (origem_material === 'Doado' && !id_itemDoado) {
    return res.status(400).json({ erro: true, codigo: 'ITEM_DOADO_OBRIGATORIO', mensagem: 'id_itemDoado é obrigatório quando origem_material é Doado.' });
  }
  if (tipo === 'Ebook') {
    if (!formato) {
      return res.status(400).json({ erro: true, codigo: 'FORMATO_OBRIGATORIO', mensagem: 'formato é obrigatório para Ebook.' });
    }
    if (FORMATOS_DIGITAIS.includes(formato) && !url_acesso) {
      return res.status(400).json({ erro: true, codigo: 'URL_OBRIGATORIO', mensagem: `url_acesso é obrigatório para Ebook com formato ${formato}.` });
    }
  }
  if (tipo === 'Periodico') {
    if (!edicao || !periodicidade || !data_publicacao) {
      return res.status(400).json({ erro: true, codigo: 'CAMPOS_PERIODICO', mensagem: 'edicao, periodicidade e data_publicacao são obrigatórios para Periódico.' });
    }
  }

  let conn;
  try {
    conn = await getConnection();

    let dataAqFinal = data_aquisicao || null;
    let valorAqFinal = valor_aquisicao || null;

    if (origem_material === 'Doado' && id_itemDoado) {
      const itemResult = await conn.execute(
        `SELECT it.VALOR_ESTIMADO, d.DATA_DOACAO
           FROM ITEM_DOACAO it
           JOIN DOACAO d ON d.ID_DOACAO = it.ID_DOACAO
          WHERE it.ID_ITEMDOADO = :id_item`,
        { id_item: Number(id_itemDoado) },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      if (itemResult.rows.length === 0) {
        return res.status(400).json({ erro: true, codigo: 'ITEM_DOADO_INVALIDO', mensagem: 'id_itemDoado não encontrado.' });
      }
      dataAqFinal = itemResult.rows[0].DATA_DOACAO;
      valorAqFinal = itemResult.rows[0].VALOR_ESTIMADO;
    }

    const codMaterial = await gerarCodMaterial(conn);

    await conn.execute(
      `INSERT INTO MATERIAL_BIBLIOGRAFICO (
         COD_MATERIAL, TITULO, AUTOR, EDITORA, ANO_PUBLICACAO, ISBN, IDIOMA, NUM_PAGINAS,
         ESTADO_MATERIAL_CONSERVACAO, MOTIVO_INDISPONIBILIDADE, ORIGEM_MATERIAL,
         DATA_AQUISICAO, VALOR_AQUISICAO, LOCALIZACAO_ESTANTE,
         COD_CATEGORIA, COD_BIBLIOTECA, ID_ITEMDOADO
       ) VALUES (
         :cod, :titulo, :autor, :editora, :ano, :isbn, :idioma, :num_pag,
         :estado, :motivo, :origem,
         :data_aq, :val_aq, :loc_est,
         :cod_cat, :cod_bib, :id_item
       )`,
      {
        cod: codMaterial,
        titulo,
        autor: autor || null,
        editora: editora || null,
        ano: ano_publicacao || null,
        isbn: isbn || null,
        idioma: idioma || null,
        num_pag: num_paginas || null,
        estado,
        motivo: motivo_indisponibilidade || null,
        origem: origem_material,
        data_aq: dataAqFinal,
        val_aq: valorAqFinal,
        loc_est: localizacao_estante || null,
        cod_cat: Number(cod_categoria),
        cod_bib: cod_biblioteca,
        id_item: id_itemDoado ? Number(id_itemDoado) : null
      }
    );

    if (tipo === 'Livro') {
      await conn.execute(
        `INSERT INTO LIVRO_FISICO (COD_MATERIAL) VALUES (:cod)`,
        { cod: codMaterial }
      );
    } else if (tipo === 'Ebook') {
      await conn.execute(
        `INSERT INTO EBOOK (COD_MATERIAL, FORMATO, TAMANHO_ARQUIVO, URL_ACESSO)
         VALUES (:cod, :fmt, :tam, :url)`,
        {
          cod: codMaterial,
          fmt: formato,
          tam: tamanho_arquivo || null,
          url: url_acesso || null
        }
      );
    } else if (tipo === 'Periodico') {
      await conn.execute(
        `INSERT INTO PERIODICO (COD_MATERIAL, EDICAO, PERIODICIDADE, DATA_PUBLICACAO, ISSN)
         VALUES (:cod, :edicao, :per, :data_pub, :issn)`,
        {
          cod: codMaterial,
          edicao,
          per: periodicidade,
          data_pub: data_publicacao,
          issn: issn || null
        }
      );
    }

    await conn.commit();
    res.status(201).json({ ok: true, cod_material: codMaterial });
  } catch (err) {
    if (conn) await conn.rollback();
    erroInterno(res, err, 'POST /');
  } finally {
    if (conn) await conn.close();
  }
});

// ── PATCH /:id — actualizar material ──────────────────────────
router.patch('/:id', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  const {
    titulo, autor, editora, ano_publicacao, isbn, idioma, num_paginas,
    estado_material_conservacao, motivo_indisponibilidade,
    localizacao_estante, cod_categoria,
    tipo,
    formato, tamanho_arquivo, url_acesso,
    edicao, periodicidade, data_publicacao, issn
  } = req.body;

  if (estado_material_conservacao === 'Indisponivel' && !motivo_indisponibilidade) {
    return res.status(400).json({ erro: true, codigo: 'MOTIVO_OBRIGATORIO', mensagem: 'motivo_indisponibilidade é obrigatório quando estado é Indisponivel.' });
  }

  let conn;
  try {
    conn = await getConnection();

    await conn.execute(
      `UPDATE MATERIAL_BIBLIOGRAFICO SET
         TITULO                      = NVL(:titulo, TITULO),
         AUTOR                       = NVL(:autor, AUTOR),
         EDITORA                     = NVL(:editora, EDITORA),
         ANO_PUBLICACAO              = NVL(:ano, ANO_PUBLICACAO),
         ISBN                        = NVL(:isbn, ISBN),
         IDIOMA                      = NVL(:idioma, IDIOMA),
         NUM_PAGINAS                 = NVL(:num_pag, NUM_PAGINAS),
         ESTADO_MATERIAL_CONSERVACAO = NVL(:estado, ESTADO_MATERIAL_CONSERVACAO),
         MOTIVO_INDISPONIBILIDADE    = NVL(:motivo, MOTIVO_INDISPONIBILIDADE),
         LOCALIZACAO_ESTANTE         = NVL(:loc_est, LOCALIZACAO_ESTANTE),
         COD_CATEGORIA               = NVL(:cod_cat, COD_CATEGORIA)
       WHERE COD_MATERIAL = :id`,
      {
        titulo: titulo || null,
        autor: autor || null,
        editora: editora || null,
        ano: ano_publicacao || null,
        isbn: isbn || null,
        idioma: idioma || null,
        num_pag: num_paginas || null,
        estado: estado_material_conservacao || null,
        motivo: motivo_indisponibilidade || null,
        loc_est: localizacao_estante || null,
        cod_cat: cod_categoria ? Number(cod_categoria) : null,
        id: req.params.id
      }
    );

    if (tipo === 'Ebook') {
      await conn.execute(
        `UPDATE EBOOK SET
           FORMATO         = NVL(:fmt, FORMATO),
           TAMANHO_ARQUIVO = NVL(:tam, TAMANHO_ARQUIVO),
           URL_ACESSO      = NVL(:url, URL_ACESSO)
         WHERE COD_MATERIAL = :id`,
        {
          fmt: formato || null,
          tam: tamanho_arquivo || null,
          url: url_acesso || null,
          id: req.params.id
        }
      );
    } else if (tipo === 'Periodico') {
      await conn.execute(
        `UPDATE PERIODICO SET
           EDICAO          = NVL(:edicao, EDICAO),
           PERIODICIDADE   = NVL(:per, PERIODICIDADE),
           DATA_PUBLICACAO = NVL(:data_pub, DATA_PUBLICACAO),
           ISSN            = NVL(:issn, ISSN)
         WHERE COD_MATERIAL = :id`,
        {
          edicao: edicao || null,
          per: periodicidade || null,
          data_pub: data_publicacao || null,
          issn: issn || null,
          id: req.params.id
        }
      );
    }

    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    erroInterno(res, err, `PATCH /${req.params.id}`);
  } finally {
    if (conn) await conn.close();
  }
});

// ── DELETE /:id ────────────────────────────────────────────────
router.delete('/:id', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const id = req.params.id;

    const empCheck = await conn.execute(
      `SELECT COUNT(*) AS N FROM EMPRESTIMO        WHERE COD_MATERIAL = :id AND DATA_DEVOLUCAO IS NULL`,
      { id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (empCheck.rows[0].N > 0) {
      return res.status(409).json({ erro: true, codigo: 'EMPRESTIMO_ACTIVO', mensagem: 'Material tem empréstimos activos e não pode ser eliminado.' });
    }

    const transCheck = await conn.execute(
      `SELECT COUNT(*) AS N FROM TRANSFERENCIA        WHERE COD_MATERIAL = :id
          AND ESTADO_TRANSFERENCIA IN ('Pendente', 'Aprovada')`,
      { id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (transCheck.rows[0].N > 0) {
      return res.status(409).json({ erro: true, codigo: 'TRANSFERENCIA_ACTIVA', mensagem: 'Material tem transferência pendente ou aprovada e não pode ser eliminado.' });
    }

    await conn.execute(
      `DELETE FROM MATERIAL_BIBLIOGRAFICO WHERE COD_MATERIAL = :id`,
      { id }
    );
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    erroInterno(res, err, `DELETE /${req.params.id}`);
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
