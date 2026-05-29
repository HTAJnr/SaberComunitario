const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();
const { getConnection, oracledb } = require('../db');
const { autenticar, exigirNivel, exigirNo } = require('../middleware/permissoes');

// Gera email a partir do nome: "Ana Beatriz Machava" → "ana.machava@sabercomunitario.mz"
function gerarEmail(nome) {
  const partes = nome.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().split(/\s+/).filter(Boolean);
  const primeiro = partes[0] || 'funcionario';
  const ultimo = partes.length > 1 ? partes[partes.length - 1] : '';
  const local = ultimo ? `${primeiro}.${ultimo}` : primeiro;
  return `${local}@sabercomunitario.mz`;
}

router.get('/funcoes', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
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

router.get('/bibliotecas', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT COD_BIBLIOTECA, NOME_BIBLIOTECA AS NOME, PROVINCIA, ENDERECO FROM BIBLIOTECA ORDER BY NOME_BIBLIOTECA`,
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

// GET / — lista de funcionários com filtro ?biblioteca (Coordenador restrito à sua)
router.get('/', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const user = req.session.funcionario;
  const nivelUser = user.NIVEL_ACESSO;
  // Coordenador só vê a sua biblioteca; Admin pode filtrar ou ver todas
  const codBib = nivelUser === 'Coordenador' ? user.COD_BIBLIOTECA : (req.query.biblioteca || null);

  let sql = `SELECT f.COD_FUNCIONARIO,
                    f.NOME_FUNCIONARIO  AS NOME,
                    f.EMAIL,
                    ff.NOME_FUNCAO      AS FUNCAO,
                    ff.NIVEL_ACESSO,
                    b.NOME_BIBLIOTECA
             FROM FUNCIONARIO f
             LEFT JOIN FUNCAO_FUNCIONARIO ff ON ff.ID_FUNCAO = f.ID_FUNCAO
             LEFT JOIN BIBLIOTECA b ON b.COD_BIBLIOTECA = f.COD_BIBLIOTECA
             WHERE f.DATA_DEMISSAO IS NULL`;
  const binds = {};
  if (codBib) {
    sql += ` AND f.COD_BIBLIOTECA = :cod_bib`;
    binds.cod_bib = codBib;
  }
  sql += ` ORDER BY f.NOME_FUNCIONARIO`;

  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(sql, binds, { outFormat: oracledb.OUT_FORMAT_OBJECT });
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

// GET /:id — inclui habilidades + horários
router.get('/:id', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const [funcRes, habilRes, horRes] = await Promise.all([
      conn.execute(
        `SELECT f.COD_FUNCIONARIO, f.NOME_FUNCIONARIO, f.EMAIL, f.CONTACTO, f.GENERO,
                f.DATA_NASC, f.FORMACAO, f.EXPERIENCIA,
                f.DATA_CONTRATACAO, f.DATA_DEMISSAO, f.ID_FUNCAO, f.COD_BIBLIOTECA,
                ff.NOME_FUNCAO AS FUNCAO, ff.NIVEL_ACESSO, b.NOME_BIBLIOTECA
           FROM FUNCIONARIO f
           LEFT JOIN FUNCAO_FUNCIONARIO ff ON ff.ID_FUNCAO = f.ID_FUNCAO
           LEFT JOIN BIBLIOTECA b ON b.COD_BIBLIOTECA = f.COD_BIBLIOTECA
          WHERE f.COD_FUNCIONARIO = :id`,
        { id: req.params.id },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      ),
      conn.execute(
        `SELECT HABILIDADE FROM FUNCIONARIO_HABILIDADE WHERE COD_FUNCIONARIO = :id`,
        { id: req.params.id },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      ),
      conn.execute(
        `SELECT DIA_SEMANA, HORA_ENTRADA, HORA_SAIDA
           FROM HORARIO_FUNCIONARIO
          WHERE COD_FUNCIONARIO = :id
          ORDER BY DIA_SEMANA`,
        { id: req.params.id },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      ),
    ]);

    if (funcRes.rows.length === 0) return res.status(404).json({ erro: 'Funcionário não encontrado.' });

    const funcionario = funcRes.rows[0];
    funcionario.HABILIDADES = habilRes.rows.map(r => r.HABILIDADE);
    funcionario.HORARIO = horRes.rows;
    res.json(funcionario);
  } catch (err) {
    console.error(`\x1b[31m[FUNCIONARIOS GET /${req.params.id}] ERRO ao buscar funcionário\x1b[0m`);
    console.error('     BD: FUNCIONARIO + FUNCAO_FUNCIONARIO + BIBLIOTECA + FUNCIONARIO_HABILIDADE + HORARIO_FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// POST / — cria funcionário; gera cod, email e senha auto; insere habilidades + horários
router.post('/', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const { nome_funcionario, contacto, genero, data_nasc, id_funcao, cod_biblioteca,
          data_contratacao, endereco, formacao, experiencia,
          habilidades, horarios } = req.body;

  if (!nome_funcionario) {
    return res.status(400).json({ erro: 'Nome é obrigatório.' });
  }
  if (!contacto) {
    return res.status(400).json({ erro: 'contacto é obrigatório.' });
  }

  const user = req.session.funcionario;
  // Coordenador só pode criar funcionários na sua biblioteca
  const codBib = user.NIVEL_ACESSO === 'Coordenador' ? user.COD_BIBLIOTECA : (cod_biblioteca || null);

  let conn;
  try {
    if (user.NIVEL_ACESSO === 'Coordenador' && id_funcao) {
      conn = await getConnection();
      const funcRes = await conn.execute(
        `SELECT NIVEL_ACESSO FROM FUNCAO_FUNCIONARIO WHERE ID_FUNCAO = :id`,
        { id: id_funcao },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      if (funcRes.rows[0]?.NIVEL_ACESSO === 'Administrador') {
        await conn.close(); conn = null;
        return res.status(403).json({ erro: 'Coordenador não pode contratar Administrador.' });
      }
      await conn.close(); conn = null;
    }
    const crypto = require('crypto');
    const senhaTemporaria = crypto.randomBytes(6).toString('base64').slice(0, 10);
    const senhaHash = await bcrypt.hash(senhaTemporaria, 10);
    const email = gerarEmail(nome_funcionario);

    conn = await getConnection();
    const result = await conn.execute(
      `INSERT INTO FUNCIONARIO
         (COD_FUNCIONARIO, NOME_FUNCIONARIO, EMAIL, SENHA, CONTACTO, GENERO, DATA_NASC,
          ENDERECO, FORMACAO, EXPERIENCIA,
          ID_FUNCAO, COD_BIBLIOTECA, DATA_CONTRATACAO)
       VALUES
         ('FUC' || TO_CHAR(SYSDATE,'YYYY') || LPAD(TO_CHAR(SEQ_FUNCIONARIO.NEXTVAL),4,'0'),
          :nome, :email, :senha, :contacto, :genero, TO_DATE(:dnasc,'YYYY-MM-DD'),
          :endereco, :formacao, :experiencia,
          :id_funcao, :cod_bib, NVL(TO_DATE(:dent,'YYYY-MM-DD'), SYSDATE))
       RETURNING COD_FUNCIONARIO INTO :cod_out`,
      {
        nome: nome_funcionario, email, senha: senhaHash,
        contacto: contacto || null, genero: genero || 'Masculino',
        dnasc: data_nasc || null,
        endereco: endereco || null, formacao: formacao || null, experiencia: experiencia || null,
        id_funcao: id_funcao || null, cod_bib: codBib,
        dent: data_contratacao || null,
        cod_out: { dir: oracledb.BIND_OUT, type: oracledb.STRING }
      }
    );

    const codFuncionario = result.outBinds.cod_out[0];

    if (Array.isArray(habilidades) && habilidades.length > 0) {
      for (const h of habilidades) {
        await conn.execute(
          `INSERT INTO FUNCIONARIO_HABILIDADE (COD_FUNCIONARIO, HABILIDADE) VALUES (:cod, :h)`,
          { cod: codFuncionario, h }
        );
      }
    }

    if (Array.isArray(horarios) && horarios.length > 0) {
      for (const hor of horarios) {
        await conn.execute(
          `INSERT INTO HORARIO_FUNCIONARIO (COD_FUNCIONARIO, DIA_SEMANA, HORA_ENTRADA, HORA_SAIDA)
           VALUES (:cod, :dia, :entrada, :saida)`,
          { cod: codFuncionario, dia: hor.dia_semana, entrada: hor.hora_entrada, saida: hor.hora_saida }
        );
      }
    }

    await conn.commit();
    res.status(201).json({ ok: true, cod_funcionario: codFuncionario, email, senha_temporaria: senhaTemporaria });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[FUNCIONARIOS POST /] ERRO ao criar funcionário\x1b[0m');
    console.error('     BD: INSERT FUNCIONARIO + FUNCIONARIO_HABILIDADE + HORARIO_FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /:id/senha — altera senha do funcionário
router.patch('/:id/senha', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const { nova_senha } = req.body;
  if (!nova_senha || nova_senha.length < 6) {
    return res.status(400).json({ erro: 'A senha deve ter pelo menos 6 caracteres.' });
  }
  let conn;
  try {
    const senhaHash = await bcrypt.hash(nova_senha, 10);
    conn = await getConnection();
    const result = await conn.execute(
      `UPDATE FUNCIONARIO SET SENHA = :senha WHERE COD_FUNCIONARIO = :id`,
      { senha: senhaHash, id: req.params.id }
    );
    if (result.rowsAffected === 0) return res.status(404).json({ erro: 'Funcionário não encontrado.' });
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[FUNCIONARIOS PATCH /:id/senha]\x1b[0m');
    console.error('     BD: FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /:id — edita dados pessoais, habilidades, horários (email e nivel_acesso nunca editáveis aqui)
router.patch('/:id', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const { nome_funcionario, contacto, genero, data_nasc, endereco, formacao, experiencia,
          id_funcao, cod_biblioteca, habilidades, horarios } = req.body;
  let conn;
  try {
    conn = await getConnection();
    await conn.execute(
      `UPDATE FUNCIONARIO SET
         NOME_FUNCIONARIO = NVL(:nome, NOME_FUNCIONARIO),
         CONTACTO         = NVL(:contacto, CONTACTO),
         GENERO           = NVL(:genero, GENERO),
         DATA_NASC        = CASE WHEN :dnasc IS NOT NULL THEN TO_DATE(:dnasc,'YYYY-MM-DD') ELSE DATA_NASC END,
         ENDERECO         = NVL(:endereco, ENDERECO),
         FORMACAO         = NVL(:formacao, FORMACAO),
         EXPERIENCIA      = NVL(:experiencia, EXPERIENCIA),
         ID_FUNCAO        = NVL(:id_funcao, ID_FUNCAO),
         COD_BIBLIOTECA   = NVL(:cod_bib, COD_BIBLIOTECA)
       WHERE COD_FUNCIONARIO = :id`,
      {
        nome: nome_funcionario || null, contacto: contacto || null,
        genero: genero || null, dnasc: data_nasc || null,
        endereco: endereco || null,
        formacao: formacao || null, experiencia: experiencia || null,
        id_funcao: id_funcao || null, cod_bib: cod_biblioteca || null,
        id: req.params.id
      }
    );

    if (Array.isArray(habilidades)) {
      await conn.execute(
        `DELETE FROM FUNCIONARIO_HABILIDADE WHERE COD_FUNCIONARIO = :id`,
        { id: req.params.id }
      );
      for (const h of habilidades) {
        await conn.execute(
          `INSERT INTO FUNCIONARIO_HABILIDADE (COD_FUNCIONARIO, HABILIDADE) VALUES (:cod, :h)`,
          { cod: req.params.id, h }
        );
      }
    }

    if (Array.isArray(horarios)) {
      await conn.execute(
        `DELETE FROM HORARIO_FUNCIONARIO WHERE COD_FUNCIONARIO = :id`,
        { id: req.params.id }
      );
      for (const hor of horarios) {
        await conn.execute(
          `INSERT INTO HORARIO_FUNCIONARIO (COD_FUNCIONARIO, DIA_SEMANA, HORA_ENTRADA, HORA_SAIDA)
           VALUES (:cod, :dia, :entrada, :saida)`,
          { cod: req.params.id, dia: hor.dia_semana, entrada: hor.hora_entrada, saida: hor.hora_saida }
        );
      }
    }

    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[FUNCIONARIOS PATCH /${req.params.id}] ERRO ao actualizar funcionário\x1b[0m`);
    console.error('     BD: UPDATE FUNCIONARIO + FUNCIONARIO_HABILIDADE + HORARIO_FUNCIONARIO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.delete('/:id', exigirNivel('Administrador'), exigirNo('BibliotecaNacionalDB'), async (req, res) => {
  if (String(req.params.id) === String(req.session.cod_funcionario)) {
    return res.status(403).json({ erro: 'Não pode desactivar a sua própria conta.' });
  }
  let conn;
  try {
    conn = await getConnection();
    // Soft delete: define DATA_DEMISSAO em vez de apagar
    await conn.execute(
      `UPDATE FUNCIONARIO SET DATA_DEMISSAO = SYSDATE WHERE COD_FUNCIONARIO = :id AND DATA_DEMISSAO IS NULL`,
      { id: req.params.id }
    );
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[FUNCIONARIOS DELETE /${req.params.id}] ERRO ao desactivar funcionário\x1b[0m`);
    console.error('     BD: UPDATE FUNCIONARIO SET DATA_DEMISSAO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /:id/acesso — altera nível de acesso (muda ID_FUNCAO); só Administrador
router.patch('/:id/acesso', exigirNivel('Administrador'), exigirNo('BibliotecaNacionalDB'), async (req, res) => {
  if (String(req.params.id) === String(req.session.cod_funcionario)) {
    return res.status(403).json({ erro: 'Não pode alterar as suas próprias permissões.' });
  }
  const { id_funcao } = req.body;
  if (!id_funcao) {
    return res.status(400).json({ erro: 'id_funcao é obrigatório.' });
  }
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `UPDATE FUNCIONARIO SET ID_FUNCAO = :id_funcao WHERE COD_FUNCIONARIO = :id`,
      { id_funcao, id: req.params.id }
    );
    if (result.rowsAffected === 0) {
      return res.status(404).json({ erro: 'Funcionário não encontrado.' });
    }
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[FUNCIONARIOS PATCH /${req.params.id}/acesso] ERRO ao alterar nível de acesso\x1b[0m`);
    console.error('     BD: UPDATE FUNCIONARIO SET ID_FUNCAO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
