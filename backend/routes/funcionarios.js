const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();
const { getConnection, oracledb } = require('../db');
const { autenticar, exigirNivel } = require('../middleware/permissoes');

router.get('/funcoes', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT ID_FUNCAO, NOME_FUNCAO AS DESCRICAO, NIVEL_ACESSO FROM FUNCAO_FUNCIONARIO ORDER BY NOME_FUNCAO`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[FUNCIONARIOS GET /funcoes] ERRO ao listar funções\x1b[0m');
    console.error('     BD: FUNCAO_FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/bibliotecas', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT COD_BIBLIOTECA, NOME_BIBLIOTECA AS NOME, PROVINCIA, LOCALIZACAO FROM BIBLIOTECA ORDER BY NOME_BIBLIOTECA`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[FUNCIONARIOS GET /bibliotecas] ERRO ao listar bibliotecas\x1b[0m');
    console.error('     BD: BIBLIOTECA');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT f.COD_FUNCIONARIO,
              f.NOME_FUNCIONARIO  AS NOME,
              f.EMAIL,
              ff.NOME_FUNCAO      AS FUNCAO,
              ff.NIVEL_ACESSO,
              b.NOME_BIBLIOTECA
       FROM FUNCIONARIO f
       LEFT JOIN FUNCAO_FUNCIONARIO ff ON ff.ID_FUNCAO = f.ID_FUNCAO
       LEFT JOIN BIBLIOTECA b ON b.COD_BIBLIOTECA = f.COD_BIBLIOTECA
       WHERE f.DATA_DEMISSAO IS NULL
       ORDER BY f.NOME_FUNCIONARIO`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[FUNCIONARIOS GET /] ERRO ao listar funcionários\x1b[0m');
    console.error('     BD: FUNCIONARIO + FUNCAO_FUNCIONARIO + BIBLIOTECA');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ─── Secção 2: Perfil do utilizador logado ───────────────────────────────────

router.get('/me', autenticar, async (req, res) => {

  // Demo user — sem registo na BD
  if (req.session.funcionario.COD_FUNCIONARIO === 0) {
    return res.json({ ...req.session.funcionario, habilidades: [], horarios: [] });
  }

  const cod = req.session.funcionario.COD_FUNCIONARIO;
  let conn;
  try {
    conn = await getConnection();

    const [perfilRes, habilRes, horRes] = await Promise.all([
      conn.execute(
        `SELECT f.COD_FUNCIONARIO, f.NOME_FUNCIONARIO, f.GENERO, f.DATA_NASC,
                f.CONTACTO, f.ENDERECO, f.FORMACAO, f.EXPERIENCIA,
                f.DATA_CONTRATACAO, f.EMAIL,
                ff.NOME_FUNCAO, ff.NIVEL_ACESSO,
                b.NOME_BIBLIOTECA
           FROM FUNCIONARIO f
           LEFT JOIN FUNCAO_FUNCIONARIO ff ON ff.ID_FUNCAO = f.ID_FUNCAO
           LEFT JOIN BIBLIOTECA b ON b.COD_BIBLIOTECA = f.COD_BIBLIOTECA
          WHERE f.COD_FUNCIONARIO = :cod`,
        { cod },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      ),
      conn.execute(
        `SELECT HABILIDADE FROM FUNCIONARIO_HABILIDADE WHERE COD_FUNCIONARIO = :cod`,
        { cod },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      ),
      conn.execute(
        `SELECT DIA_SEMANA, HORA_ENTRADA, HORA_SAIDA
           FROM HORARIO_FUNCIONARIO
          WHERE COD_FUNCIONARIO = :cod
          ORDER BY DIA_SEMANA`,
        { cod },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      ),
    ]);

    if (perfilRes.rows.length === 0) return res.status(404).json({ erro: 'Funcionário não encontrado.' });

    const perfil = perfilRes.rows[0];
    perfil.habilidades = habilRes.rows.map(r => r.HABILIDADE);
    perfil.horarios = horRes.rows;
    res.json(perfil);
  } catch (err) {
    console.error('\x1b[31m[FUNCIONARIOS GET /me] ERRO ao carregar perfil\x1b[0m');
    console.error('     BD: FUNCIONARIO + FUNCAO_FUNCIONARIO + BIBLIOTECA + FUNCIONARIO_HABILIDADE + HORARIO_FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.patch('/me', autenticar, async (req, res) => {
  if (req.session.funcionario.COD_FUNCIONARIO === 0) {
    return res.status(403).json({ erro: 'Conta demo não permite edição de perfil.' });
  }

  const { contacto, endereco } = req.body;
  const cod = req.session.funcionario.COD_FUNCIONARIO;

  let conn;
  try {
    conn = await getConnection();
    await conn.execute(
      `UPDATE FUNCIONARIO
          SET CONTACTO = NVL(:contacto, CONTACTO),
              ENDERECO = NVL(:endereco, ENDERECO)
        WHERE COD_FUNCIONARIO = :cod`,
      { contacto: contacto ?? null, endereco: endereco ?? null, cod }
    );
    await conn.commit();

    if (contacto !== undefined) req.session.funcionario.CONTACTO = contacto;
    if (endereco !== undefined) req.session.funcionario.ENDERECO = endereco;

    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[FUNCIONARIOS PATCH /me] ERRO ao actualizar perfil\x1b[0m');
    console.error('     BD: UPDATE FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.patch('/me/senha', autenticar, async (req, res) => {
  if (req.session.funcionario.COD_FUNCIONARIO === 0) {
    return res.status(403).json({ erro: 'Conta demo não permite alteração de senha.' });
  }

  const { senha_atual, nova_senha } = req.body;
  if (!senha_atual || !nova_senha) {
    return res.status(400).json({ erro: 'senha_atual e nova_senha são obrigatórias.' });
  }

  const cod = req.session.funcionario.COD_FUNCIONARIO;
  let conn;
  try {
    conn = await getConnection();

    const result = await conn.execute(
      `SELECT SENHA FROM FUNCIONARIO WHERE COD_FUNCIONARIO = :cod`,
      { cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (result.rows.length === 0) return res.status(404).json({ erro: 'Funcionário não encontrado.' });

    const senhaValida = await bcrypt.compare(senha_atual, result.rows[0].SENHA);
    if (!senhaValida) return res.status(401).json({ erro: 'Senha actual incorrecta.' });

    const novoHash = await bcrypt.hash(nova_senha, 10);
    await conn.execute(
      `UPDATE FUNCIONARIO SET SENHA = :hash WHERE COD_FUNCIONARIO = :cod`,
      { hash: novoHash, cod }
    );
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[FUNCIONARIOS PATCH /me/senha] ERRO ao alterar senha\x1b[0m');
    console.error('     BD: FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// ─────────────────────────────────────────────────────────────────────────────

router.get('/:id', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT f.COD_FUNCIONARIO, f.NOME_FUNCIONARIO, f.EMAIL, f.CONTACTO, f.GENERO,
              f.DATA_CONTRATACAO, f.DATA_DEMISSAO, f.ID_FUNCAO, f.COD_BIBLIOTECA,
              ff.NOME_FUNCAO AS FUNCAO, ff.NIVEL_ACESSO, b.NOME_BIBLIOTECA
         FROM FUNCIONARIO f
         LEFT JOIN FUNCAO_FUNCIONARIO ff ON ff.ID_FUNCAO = f.ID_FUNCAO
         LEFT JOIN BIBLIOTECA b ON b.COD_BIBLIOTECA = f.COD_BIBLIOTECA
        WHERE f.COD_FUNCIONARIO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (result.rows.length === 0) return res.status(404).json({ erro: 'Funcionário não encontrado.' });

    const horarioResult = await conn.execute(
      `SELECT dia_semana, hora_entrada, hora_saida
         FROM HORARIO_FUNCIONARIO
        WHERE cod_funcionario = :cod
        ORDER BY dia_semana`,
      { cod: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const funcionario = result.rows[0];
    funcionario.HORARIO = horarioResult.rows;
    res.json(funcionario);
  } catch (err) {
    console.error(`\x1b[31m[FUNCIONARIOS GET /${req.params.id}] ERRO ao buscar funcionário\x1b[0m`);
    console.error('     BD: FUNCIONARIO + FUNCAO_FUNCIONARIO + BIBLIOTECA + HORARIO_FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const { nome_funcionario, email, senha, contacto, genero, id_funcao, COD_biblioteca, data_contratacao } = req.body;
  if (!nome_funcionario || !email || !senha) {
    return res.status(400).json({ erro: 'Nome, email e senha obrigatórios.' });
  }

  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `INSERT INTO FUNCIONARIO
         (COD_FUNCIONARIO, NOME_FUNCIONARIO, EMAIL, SENHA, CONTACTO, GENERO,
          ID_FUNCAO, COD_BIBLIOTECA, DATA_CONTRATACAO)
       VALUES
         (SEQ_FUNCIONARIO.NEXTVAL, :nome, :email, :senha, :contacto, :genero,
          :id_funcao, :cod_bib, NVL(TO_DATE(:dent,'YYYY-MM-DD'), SYSDATE))
       RETURNING COD_FUNCIONARIO INTO :id_out`,
      { nome: nome_funcionario, email, senha,
        contacto: contacto || null, genero: genero || 'Masculino',
        id_funcao: id_funcao || null, cod_bib: COD_biblioteca || null,
        dent: data_contratacao || null,
        id_out: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER } }
    );
    await conn.commit();
    res.status(201).json({ ok: true, COD_funcionario: result.outBinds.id_out[0] });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[FUNCIONARIOS POST /] ERRO ao criar funcionário\x1b[0m');
    console.error('     BD: INSERT FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.put('/:id', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const { nome_funcionario, email, senha, contacto, genero, id_funcao, COD_biblioteca } = req.body;
  let conn;
  try {
    conn = await getConnection();
    await conn.execute(
      `UPDATE FUNCIONARIO SET
         NOME_FUNCIONARIO = NVL(:nome, NOME_FUNCIONARIO),
         EMAIL            = NVL(:email, EMAIL),
         SENHA            = NVL(:senha, SENHA),
         CONTACTO         = NVL(:contacto, CONTACTO),
         GENERO           = NVL(:genero, GENERO),
         ID_FUNCAO        = NVL(:id_funcao, ID_FUNCAO),
         COD_BIBLIOTECA    = NVL(:cod_bib, COD_BIBLIOTECA)
       WHERE COD_FUNCIONARIO = :id`,
      { nome: nome_funcionario || null, email: email || null, senha: senha || null,
        contacto: contacto || null, genero: genero || null,
        id_funcao: id_funcao || null, cod_bib: COD_biblioteca || null,
        id: req.params.id }
    );
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[FUNCIONARIOS PUT /${req.params.id}] ERRO ao actualizar funcionário\x1b[0m`);
    console.error('     BD: UPDATE FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.delete('/:id', exigirNivel('Administrador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    // Desactivar: define DATA_DEMISSAO em vez de apagar (trigger impede_exclusao_coordenador protege coordenadores)
    await conn.execute(
      `UPDATE FUNCIONARIO SET DATA_DEMISSAO = SYSDATE WHERE COD_FUNCIONARIO = :id AND DATA_DEMISSAO IS NULL`,
      { id: req.params.id }
    );
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[FUNCIONARIOS DELETE /${req.params.id}] ERRO ao desactivar funcionário\x1b[0m`);
    console.error('     BD: UPDATE FUNCIONARIO SET DATA_DEMISSAO (TRIGGER impede_exclusao_coordenador pode estar a bloquear)');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Endpoint BD2-READY: gerir acesso Oracle do funcionário via proc_gerir_acesso_bd
router.post('/:id/acesso', exigirNivel('Administrador'), async (req, res) => {
  const { acao } = req.body;
  if (!acao || !['GRANT', 'REVOKE'].includes(acao.toUpperCase())) {
    return res.status(400).json({ erro: 'acao deve ser "GRANT" ou "REVOKE".' });
  }
  let conn;
  try {
    conn = await getConnection();
    await conn.execute(
      `BEGIN proc_gerir_acesso_bd(:id_func, :acao); END;`,
      { id_func: req.params.id, acao: acao.toUpperCase() }
    );
    res.json({ ok: true, mensagem: `${acao.toUpperCase()} de acesso BD aplicado ao funcionário ${req.params.id}.` });
  } catch (err) {
    console.error(`\x1b[31m[FUNCIONARIOS POST /${req.params.id}/acesso] ERRO ao gerir acesso\x1b[0m`);
    console.error('     BD: PROCEDURE proc_gerir_acesso_bd');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
