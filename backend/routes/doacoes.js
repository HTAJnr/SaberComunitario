const express = require('express');
const router = express.Router();
const doadoresRouter = express.Router();
const { getConnection, oracledb } = require('../db');
const { exigirNivel } = require('../middleware/permissoes');
const { registar } = require('../middleware/auditoria');

// ── Doadores ──────────────────────────────────────────────────────────────────
doadoresRouter.get('/', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { search } = req.query;
    const binds = {};
    let where = '';
    if (search) {
      where = `WHERE UPPER(NOME_DOADOR) LIKE UPPER(:search)`;
      binds.search = `%${search}%`;
    }
    const result = await conn.execute(
      `SELECT ID_DOADOR,
              NOME_DOADOR  AS NOME,
              TIPO_DOADOR  AS TIPO,
              CONTACTO
       FROM DOADOR ${where} ORDER BY NOME_DOADOR`,
      binds,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[DOADORES GET /] ERRO ao listar doadores\x1b[0m');
    console.error('     BD: DOADOR');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

doadoresRouter.post('/', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const { nome_doador, tipo_doador, contacto, endereco, observacoes } = req.body;
  if (!nome_doador || !tipo_doador) return res.status(400).json({ erro: 'Nome e tipo obrigatórios.' });
  let conn;
  try {
    conn = await getConnection();
    await conn.execute(
      `INSERT INTO DOADOR (ID_DOADOR, NOME_DOADOR, TIPO_DOADOR, CONTACTO, ENDERECO, OBSERVACOES)
       VALUES (SEQ_DOADOR.NEXTVAL, :nome, :tipo, :contacto, :endereco, :obs)`,
      { nome: nome_doador, tipo: tipo_doador,
        contacto: contacto || null, endereco: endereco || null, obs: observacoes || null }
    );
    const curDoador = await conn.execute(
      `SELECT SEQ_DOADOR.CURRVAL AS ID FROM DUAL`,
      [], { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    await conn.commit();
    res.status(201).json({ ok: true, id_doador: curDoador.rows[0].ID });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[DOADORES POST /] ERRO ao criar doador\x1b[0m');
    console.error('     BD: INSERT DOADOR');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── Doações ───────────────────────────────────────────────────────────────────
router.get('/', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { biblioteca } = req.query;
    const page  = Math.max(1, parseInt(req.query.page)  || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 20));
    const minRow = (page - 1) * limit;
    const maxRow = page * limit;

    const binds = { min_row: minRow, max_row: maxRow };
    let where = '';
    if (biblioteca) {
      where = `WHERE ID_DOACAO IN (SELECT ID_DOACAO FROM ITEM_DOACAO WHERE COD_BIBLIOTECA = :biblioteca)`;
      binds.biblioteca = biblioteca;
    }

    const result = await conn.execute(
      `SELECT * FROM (
         SELECT a.*, ROWNUM AS RN FROM (
           SELECT ID_DOACAO, DATA_DOACAO,
                  NOME_DOADOR,
                  TIPO_DOADOR,
                  VALOR_TOTAL_DOACAO       AS VALOR_TOTAL,
                  TOTAL_ITENS, CERTIFICADO_NUMERO
             FROM vw_doacoes_detalhadas ${where} ORDER BY DATA_DOACAO DESC
         ) a WHERE ROWNUM <= :max_row
       ) WHERE RN > :min_row`,
      binds,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const countBinds = {};
    let countWhere = '';
    if (biblioteca) {
      countWhere = `WHERE ID_DOACAO IN (SELECT ID_DOACAO FROM ITEM_DOACAO WHERE COD_BIBLIOTECA = :biblioteca)`;
      countBinds.biblioteca = biblioteca;
    }
    const countResult = await conn.execute(
      `SELECT COUNT(*) AS TOTAL FROM vw_doacoes_detalhadas ${countWhere}`,
      countBinds,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({
      dados: result.rows,
      total: countResult.rows[0].TOTAL,
      page,
      limit
    });
  } catch (err) {
    console.error('\x1b[31m[DOACOES GET /] ERRO ao listar doações\x1b[0m');
    console.error('     BD: VIEW vw_doacoes_detalhadas');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/certificados', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT NUM_CERTIFICADO  AS ID_CERTIFICADO,
              NUM_CERTIFICADO  AS NUMERO_SERIE,
              NOME_DOADOR,
              DATA_EMISSAO,
              TIPO_CERTIFICADO, VALOR_DOACAO
       FROM vw_certificados_emitidos ORDER BY DATA_EMISSAO DESC`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[DOACOES GET /certificados] ERRO ao listar certificados\x1b[0m');
    console.error('     BD: VIEW vw_certificados_emitidos');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/:id', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const dResult = await conn.execute(
      `SELECT d.*, dr.NOME_DOADOR, dr.TIPO_DOADOR, dr.CONTACTO, dr.ENDERECO
         FROM DOACAO d
         LEFT JOIN DOADOR dr ON dr.ID_DOADOR = d.ID_DOADOR
        WHERE d.ID_DOACAO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (dResult.rows.length === 0) return res.status(404).json({ erro: 'Doação não encontrada.' });
    const itensResult = await conn.execute(
      `SELECT i.*, b.NOME_BIBLIOTECA
         FROM ITEM_DOACAO i
         JOIN BIBLIOTECA b ON b.COD_BIBLIOTECA = i.COD_BIBLIOTECA
        WHERE i.ID_DOACAO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const certsResult = await conn.execute(
      `SELECT ID_CERTIFICADO, NUM_CERTIFICADO, TIPO_CERTIFICADO, DATA_EMISSAO, OBSERVACOES
         FROM CERTIFICADO_DOACAO
        WHERE ID_DOACAO = :id
        ORDER BY DATA_EMISSAO DESC`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json({ ...dResult.rows[0], itens: itensResult.rows, certs: certsResult.rows });
  } catch (err) {
    console.error(`\x1b[31m[DOACOES GET /${req.params.id}] ERRO ao buscar doação\x1b[0m`);
    console.error('     BD: DOACAO + DOADOR + ITEM_DOACAO + BIBLIOTECA');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  // itens: [{ cod_biblioteca, quantidade, valor_estimado, observacoes }]
  // id_doador: 0 significa doador anónimo (RN10)
  const { id_doador, data_doacao, itens } = req.body;
  if (id_doador == null || !itens || itens.length === 0) {
    return res.status(400).json({ erro: 'Doador (0 para anónimo) e pelo menos um item obrigatórios.' });
  }

  for (let i = 0; i < itens.length; i++) {
    const item = itens[i];
    if (!item.cod_biblioteca) {
      return res.status(400).json({ erro: `Item ${i + 1}: cod_biblioteca obrigatório.` });
    }
    const qtd = Number(item.quantidade);
    const val = Number(item.valor_estimado ?? 0);
    if (!Number.isInteger(qtd) || qtd <= 0) {
      return res.status(400).json({ erro: `Item ${i + 1}: quantidade deve ser um inteiro positivo.` });
    }
    if (isNaN(val) || val < 0) {
      return res.status(400).json({ erro: `Item ${i + 1}: valor_estimado não pode ser negativo.` });
    }
  }

  // id_doador === 0 → doação anónima (registo DOADOR com id=0 obrigatório como seed)
  const idDoadorBD = Number(id_doador);

  let conn;
  try {
    conn = await getConnection();

    await conn.execute(
      `INSERT INTO DOACAO (ID_DOACAO, ID_DOADOR, DATA_DOACAO)
       VALUES (SEQ_DOACAO.NEXTVAL, :id_doador, NVL(TO_DATE(:data,'YYYY-MM-DD'), SYSDATE))`,
      { id_doador: idDoadorBD, data: data_doacao || null }
    );
    const curDoacao = await conn.execute(
      `SELECT SEQ_DOACAO.CURRVAL AS ID FROM DUAL`,
      [], { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const idDoacao = curDoacao.rows[0].ID;

    for (const item of itens) {
      await conn.execute(
        `INSERT INTO ITEM_DOACAO (ID_ITEMDOADO, ID_DOACAO, COD_BIBLIOTECA, QUANTIDADE, VALOR_ESTIMADO, OBSERVACOES)
         VALUES (SEQ_ITEMDOADO.NEXTVAL, :id_doacao, :id_bib, :qtd, :val, :obs)`,
        { id_doacao: idDoacao,
          id_bib:  item.cod_biblioteca,
          qtd:     Number(item.quantidade),
          val:     Number(item.valor_estimado || 0),
          obs:     item.observacoes || null }
      );
    }

    await registar(conn, {
      cod_func: req.session.cod_funcionario,
      operacao: 'CRIAR',
      objeto: 'DOACAO:' + idDoacao,
      resultado: 'OK',
      nos: req.session.cod_biblioteca || 'NACIONAL'
    });
    await conn.commit();
    // O trigger gera_certificado_automatico insere o certificado automaticamente após ITEM_DOACAO
    res.status(201).json({ ok: true, id_doacao: idDoacao });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[DOACOES POST /] ERRO ao registar doação\x1b[0m');
    console.error('     BD: INSERT DOACAO + INSERT ITEM_DOACAO + INSERT CERTIFICADO_DOACAO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/:id/certificado', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const { tipo_certificado, observacoes } = req.body;
  if (!tipo_certificado) return res.status(400).json({ erro: 'tipo_certificado obrigatório.' });
  const tiposValidos = ['Original', 'Reemissao', 'Honorifico'];
  if (!tiposValidos.includes(tipo_certificado)) {
    return res.status(400).json({ erro: `tipo_certificado inválido. Valores aceites: ${tiposValidos.join(', ')}.` });
  }
  let conn;
  try {
    conn = await getConnection();
    const doacaoResult = await conn.execute(
      `SELECT ID_DOACAO FROM DOACAO WHERE ID_DOACAO = :id`,
      { id: parseInt(req.params.id) },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (doacaoResult.rows.length === 0)
      return res.status(404).json({ erro: 'Doação não encontrada.' });

    const existeResult = await conn.execute(
      `SELECT COUNT(*) AS TOTAL FROM CERTIFICADO_DOACAO WHERE ID_DOACAO = :id`,
      { id: parseInt(req.params.id) },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (existeResult.rows[0].TOTAL > 0)
      return res.status(409).json({ erro: 'Já existe um certificado para esta doação. Use a opção de reemissão.' });

    const seqResult = await conn.execute(
      `SELECT SEQ_CERTIFICADO.NEXTVAL AS SEQ FROM DUAL`,
      [], { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const seq = seqResult.rows[0].SEQ;
    const numCertificado = `CERT-${new Date().getFullYear()}-${String(seq).padStart(4, '0')}`;

    await conn.execute(
      `INSERT INTO CERTIFICADO_DOACAO
         (ID_CERTIFICADO, NUM_CERTIFICADO, ID_DOACAO, TIPO_CERTIFICADO, DATA_EMISSAO, OBSERVACOES)
       VALUES (SEQ_CERTIFICADO.NEXTVAL, :num_cert, :id_doacao, :tipo, SYSDATE, :obs)`,
      { num_cert: numCertificado, id_doacao: parseInt(req.params.id),
        tipo: tipo_certificado, obs: observacoes || null }
    );
    await registar(conn, {
      cod_func: req.session.cod_funcionario,
      operacao: 'EMITIR_CERTIFICADO',
      objeto: 'DOACAO:' + req.params.id,
      resultado: 'OK',
      nos: req.session.cod_biblioteca || 'NACIONAL'
    });
    await conn.commit();
    res.status(201).json({ ok: true, num_certificado: numCertificado });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[DOACOES POST /${req.params.id}/certificado] ERRO ao emitir certificado\x1b[0m`);
    console.error('     BD: INSERT CERTIFICADO_DOACAO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/certificados/:id/reemitir', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const { motivo } = req.body;
  let conn;
  try {
    conn = await getConnection();
    const certResult = await conn.execute(
      `SELECT ID_DOACAO FROM CERTIFICADO_DOACAO WHERE ID_CERTIFICADO = :id`,
      { id: parseInt(req.params.id) },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (certResult.rows.length === 0) {
      return res.status(404).json({ erro: 'Certificado não encontrado.' });
    }
    const idDoacao = certResult.rows[0].ID_DOACAO;

    await conn.execute(
      `BEGIN reemitir_certificado(:id_doacao, :motivo, :num_novo); END;`,
      {
        id_doacao: idDoacao,
        motivo: motivo || 'Reemissão solicitada',
        num_novo: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 30 }
      }
    );
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[DOACOES POST /certificados/${req.params.id}/reemitir] ERRO ao reemitir certificado\x1b[0m`);
    console.error('     BD: PROCEDURE reemitir_certificado');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = { doacoesRouter: router, doadoresRouter };
