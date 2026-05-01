const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');

router.get('/funcoes', async (req, res) => {
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

router.get('/bibliotecas', async (req, res) => {
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

router.get('/', async (req, res) => {
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

router.get('/:id', async (req, res) => {
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

router.post('/', async (req, res) => {
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

router.put('/:id', async (req, res) => {
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

router.delete('/:id', async (req, res) => {
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
router.post('/:id/acesso', async (req, res) => {
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
