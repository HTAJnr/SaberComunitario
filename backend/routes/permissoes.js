// ════════════════════════════════════════════════
// ROTAS — Permissões granulares por cargo (FASE 10)
// ════════════════════════════════════════════════
const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');
const { autenticar, exigirNivel } = require('../middleware/permissoes');
const { registar } = require('../middleware/auditoria');

const NIVEIS_VALIDOS = ['Administrador','Coordenador','Bibliotecario','Assistente'];

// ── GET /cargos — lista cargos com contagem de funcionários ──
router.get('/cargos', exigirNivel('Administrador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT ff.ID_FUNCAO, ff.NOME_FUNCAO, ff.NIVEL_ACESSO, ff.DESCRICAO,
              COUNT(f.COD_FUNCIONARIO) AS NUM_FUNCIONARIOS
         FROM FUNCAO_FUNCIONARIO ff
         LEFT JOIN FUNCIONARIO f ON f.ID_FUNCAO = ff.ID_FUNCAO
        GROUP BY ff.ID_FUNCAO, ff.NOME_FUNCAO, ff.NIVEL_ACESSO, ff.DESCRICAO
        ORDER BY ff.ID_FUNCAO`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[PERMISSOES GET /cargos]\x1b[0m');
    console.error('     BD: FUNCAO_FUNCIONARIO + FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── POST /cargos — criar cargo (Admin only) ──
router.post('/cargos', exigirNivel('Administrador'), async (req, res) => {
  if (req.session.cod_funcionario === 0) {
    return res.status(400).json({ erro: 'Utilizador demo não pode realizar esta acção.' });
  }
  const { nome_funcao, nivel_acesso, descricao } = req.body;
  if (!nome_funcao || !nivel_acesso) {
    return res.status(400).json({ erro: 'nome_funcao e nivel_acesso são obrigatórios.' });
  }
  if (!NIVEIS_VALIDOS.includes(nome_funcao)) {
    return res.status(400).json({ erro: `nome_funcao inválido. Valores aceites: ${NIVEIS_VALIDOS.join(', ')}.` });
  }
  if (!NIVEIS_VALIDOS.includes(nivel_acesso)) {
    return res.status(400).json({ erro: `nivel_acesso inválido. Valores aceites: ${NIVEIS_VALIDOS.join(', ')}.` });
  }
  let conn;
  try {
    conn = await getConnection();
    await conn.execute(
      `INSERT INTO FUNCAO_FUNCIONARIO (ID_FUNCAO, NOME_FUNCAO, NIVEL_ACESSO, DESCRICAO)
       VALUES (SEQ_FUNCAO.NEXTVAL, :nome, :nivel, :desc)`,
      { nome: nome_funcao, nivel: nivel_acesso, desc: descricao || null }
    );
    const cur = await conn.execute(
      `SELECT SEQ_FUNCAO.CURRVAL AS ID FROM DUAL`,
      [], { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const newId = cur.rows[0].ID;
    await registar(conn, {
      cod_func: req.session.cod_funcionario,
      operacao: 'CRIAR_CARGO',
      objeto: 'FUNCAO_FUNCIONARIO:' + newId,
      resultado: 'SUCESSO',
      nos: 'NACIONAL'
    });
    await conn.commit();
    res.status(201).json({ ok: true, id_funcao: newId });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[PERMISSOES POST /cargos]\x1b[0m');
    console.error('     BD: INSERT FUNCAO_FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── PATCH /cargos/:id — editar cargo (Admin only) ──
router.patch('/cargos/:id', exigirNivel('Administrador'), async (req, res) => {
  if (req.session.cod_funcionario === 0) {
    return res.status(400).json({ erro: 'Utilizador demo não pode realizar esta acção.' });
  }
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ erro: 'id inválido.' });
  const { nome_funcao, nivel_acesso, descricao } = req.body;
  if (nome_funcao && !NIVEIS_VALIDOS.includes(nome_funcao)) {
    return res.status(400).json({ erro: `nome_funcao inválido.` });
  }
  if (nivel_acesso && !NIVEIS_VALIDOS.includes(nivel_acesso)) {
    return res.status(400).json({ erro: `nivel_acesso inválido.` });
  }
  let conn;
  try {
    conn = await getConnection();
    const chk = await conn.execute(
      `SELECT ID_FUNCAO FROM FUNCAO_FUNCIONARIO WHERE ID_FUNCAO = :id`,
      { id }, { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (chk.rows.length === 0) return res.status(404).json({ erro: 'Cargo não encontrado.' });

    // construir UPDATE dinâmico
    const sets = [];
    const binds = { id };
    if (nome_funcao !== undefined)  { sets.push('NOME_FUNCAO = :nome');  binds.nome  = nome_funcao; }
    if (nivel_acesso !== undefined) { sets.push('NIVEL_ACESSO = :nivel'); binds.nivel = nivel_acesso; }
    if (descricao !== undefined)    { sets.push('DESCRICAO = :desc');    binds.desc  = descricao || null; }
    if (!sets.length) return res.status(400).json({ erro: 'Nenhum campo para actualizar.' });

    await conn.execute(
      `UPDATE FUNCAO_FUNCIONARIO SET ${sets.join(', ')} WHERE ID_FUNCAO = :id`,
      binds
    );
    await registar(conn, {
      cod_func: req.session.cod_funcionario,
      operacao: 'EDITAR_CARGO',
      objeto: 'FUNCAO_FUNCIONARIO:' + id,
      resultado: 'SUCESSO',
      nos: 'NACIONAL'
    });
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[PERMISSOES PATCH /cargos/${req.params.id}]\x1b[0m`);
    console.error('     BD: UPDATE FUNCAO_FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── DELETE /cargos/:id — eliminar cargo (Admin only) ──
router.delete('/cargos/:id', exigirNivel('Administrador'), async (req, res) => {
  if (req.session.cod_funcionario === 0) {
    return res.status(400).json({ erro: 'Utilizador demo não pode realizar esta acção.' });
  }
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ erro: 'id inválido.' });
  let conn;
  try {
    conn = await getConnection();
    const cntResult = await conn.execute(
      `SELECT COUNT(*) AS TOTAL FROM FUNCIONARIO WHERE ID_FUNCAO = :id`,
      { id }, { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (cntResult.rows[0].TOTAL > 0) {
      return res.status(409).json({ erro: 'Cargo tem funcionários associados — não pode ser eliminado.' });
    }
    const chk = await conn.execute(
      `SELECT ID_FUNCAO FROM FUNCAO_FUNCIONARIO WHERE ID_FUNCAO = :id`,
      { id }, { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (chk.rows.length === 0) return res.status(404).json({ erro: 'Cargo não encontrado.' });

    // apaga permissões associadas primeiro (caso a FK não esteja em CASCADE)
    await conn.execute(`DELETE FROM PERMISSAO_CARGO WHERE ID_FUNCAO = :id`, { id });
    await conn.execute(`DELETE FROM FUNCAO_FUNCIONARIO WHERE ID_FUNCAO = :id`, { id });

    await registar(conn, {
      cod_func: req.session.cod_funcionario,
      operacao: 'ELIMINAR_CARGO',
      objeto: 'FUNCAO_FUNCIONARIO:' + id,
      resultado: 'SUCESSO',
      nos: 'NACIONAL'
    });
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[PERMISSOES DELETE /cargos/${req.params.id}]\x1b[0m`);
    console.error('     BD: DELETE FUNCAO_FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── GET /cargos/:id/matriz — ler matriz de permissões do cargo ──
router.get('/cargos/:id/matriz', exigirNivel('Administrador'), async (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ erro: 'id inválido.' });
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT MODULO, ACCAO, PERMITIDO
         FROM PERMISSAO_CARGO
        WHERE ID_FUNCAO = :id
        ORDER BY MODULO, ACCAO`,
      { id }, { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error(`\x1b[31m[PERMISSOES GET /cargos/${req.params.id}/matriz]\x1b[0m`);
    console.error('     BD: PERMISSAO_CARGO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ── PUT /cargos/:id/matriz — substituir matriz inteira (Admin only) ──
router.put('/cargos/:id/matriz', exigirNivel('Administrador'), async (req, res) => {
  if (req.session.cod_funcionario === 0) {
    return res.status(400).json({ erro: 'Utilizador demo não pode realizar esta acção.' });
  }
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ erro: 'id inválido.' });
  const { permissoes } = req.body;
  if (!Array.isArray(permissoes)) {
    return res.status(400).json({ erro: 'permissoes deve ser um array.' });
  }
  for (let i = 0; i < permissoes.length; i++) {
    const p = permissoes[i];
    if (!p.modulo || !p.accao) {
      return res.status(400).json({ erro: `Linha ${i + 1}: modulo e accao são obrigatórios.` });
    }
    if (p.permitido !== 0 && p.permitido !== 1) {
      return res.status(400).json({ erro: `Linha ${i + 1}: permitido deve ser 0 ou 1.` });
    }
  }
  let conn;
  try {
    conn = await getConnection();
    const chk = await conn.execute(
      `SELECT ID_FUNCAO FROM FUNCAO_FUNCIONARIO WHERE ID_FUNCAO = :id`,
      { id }, { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (chk.rows.length === 0) return res.status(404).json({ erro: 'Cargo não encontrado.' });

    await conn.execute(`DELETE FROM PERMISSAO_CARGO WHERE ID_FUNCAO = :id`, { id });

    for (const p of permissoes) {
      await conn.execute(
        `INSERT INTO PERMISSAO_CARGO (ID_PERMISSAO, ID_FUNCAO, MODULO, ACCAO, PERMITIDO)
         VALUES (SEQ_PERMISSAO.NEXTVAL, :id, :modulo, :accao, :permitido)`,
        { id, modulo: p.modulo, accao: p.accao, permitido: p.permitido }
      );
    }

    await registar(conn, {
      cod_func: req.session.cod_funcionario,
      operacao: 'GUARDAR_MATRIZ_PERMISSOES',
      objeto: 'FUNCAO_FUNCIONARIO:' + id,
      resultado: 'SUCESSO',
      nos: 'NACIONAL'
    });
    await conn.commit();
    res.json({ ok: true, total: permissoes.length });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[PERMISSOES PUT /cargos/${req.params.id}/matriz]\x1b[0m`);
    console.error('     BD: PERMISSAO_CARGO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
