const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();
const { getConnection, oracledb } = require('../db');
const { registar } = require('../middleware/auditoria');

const DEMO_USER = {
  COD_FUNCIONARIO: 0,
  NOME_FUNCIONARIO: 'Demo',
  EMAIL: 'demo@biblioteca.mz',
  CONTACTO: null,
  ID_FUNCAO: null,
  FUNCAO: 'Administrador',
  NIVEL_ACESSO: 'Administrador',
  COD_BIBLIOTECA: null,
  NOME_BIBLIOTECA: 'Biblioteca Demo',
  PROVINCIA: 'Maputo Cidade',
};

router.post('/login', async (req, res) => {
  const { email, senha } = req.body;
  if (!email || !senha) return res.status(400).json({ erro: 'Email e senha obrigatórios.' });

  if (email === 'demo@biblioteca.mz' && senha === 'demo') {
    req.session.funcionario = DEMO_USER;
    req.session.cod_funcionario = DEMO_USER.COD_FUNCIONARIO;
    req.session.cod_biblioteca = DEMO_USER.COD_BIBLIOTECA;
    req.session.nivel_acesso = DEMO_USER.NIVEL_ACESSO;
    req.session.provincia = DEMO_USER.PROVINCIA;
    res.json({ ok: true, funcionario: DEMO_USER });
    return;
  }

  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT f.COD_FUNCIONARIO, f.NOME_FUNCIONARIO, f.EMAIL, f.CONTACTO, f.ID_FUNCAO,
              f.SENHA,
              ff.NOME_FUNCAO AS FUNCAO, ff.NIVEL_ACESSO,
              f.COD_BIBLIOTECA
         FROM FUNCIONARIO f
         LEFT JOIN FUNCAO_FUNCIONARIO ff ON ff.ID_FUNCAO = f.ID_FUNCAO
        WHERE LOWER(f.EMAIL) = LOWER(:email)
          AND f.DATA_DEMISSAO IS NULL`,
      { email },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    if (result.rows.length === 0) {
      await registar(conn, { cod_func: '0', operacao: 'LOGIN_FALHA', objeto: email, resultado: 'FALHA', motivo: 'Utilizador não encontrado' });
      await conn.commit();
      return res.status(401).json({ erro: 'Credenciais inválidas ou conta inactiva.' });
    }

    const func = result.rows[0];
    const senhaValida = await bcrypt.compare(senha, func.SENHA);
    if (!senhaValida) {
      await registar(conn, { cod_func: String(func.COD_FUNCIONARIO), operacao: 'LOGIN_FALHA', objeto: email, resultado: 'FALHA', motivo: 'Senha incorrecta' });
      await conn.commit();
      return res.status(401).json({ erro: 'Credenciais inválidas ou conta inactiva.' });
    }

    delete func.SENHA;
    await registar(conn, { cod_func: String(func.COD_FUNCIONARIO), operacao: 'LOGIN_SUCESSO', objeto: email, resultado: 'SUCESSO' });
    await conn.commit();
    req.session.funcionario = func;
    req.session.cod_funcionario = func.COD_FUNCIONARIO;
    req.session.cod_biblioteca = func.COD_BIBLIOTECA;
    req.session.nivel_acesso = func.NIVEL_ACESSO;
    req.session.provincia = func.PROVINCIA;
    res.json({ ok: true, funcionario: func });
  } catch (err) {
    console.error('\x1b[31m[AUTH POST /login] ERRO ao autenticar funcionário\x1b[0m');
    console.error('     BD: FUNCIONARIO + FUNCAO_FUNCIONARIO + BIBLIOTECA');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/me', (req, res) => {
  if (!req.session.funcionario) return res.status(401).json({ erro: 'Não autenticado.' });
  res.json(req.session.funcionario);
});

router.post('/logout', async (req, res) => {
  const func = req.session.funcionario;
  const codFunc = req.session.cod_funcionario;

  if (func && codFunc !== 0) {
    let conn;
    try {
      conn = await getConnection();
      await registar(conn, {
        cod_func: String(codFunc),
        operacao: 'LOGOUT',
        objeto: func.EMAIL || '',
        resultado: 'SUCESSO',
      });
      await conn.commit();
    } catch (err) {
      console.warn('[AUTH logout] auditoria falhou:', err.message);
    } finally {
      if (conn) await conn.close();
    }
  }

  req.session.destroy(() => res.json({ ok: true }));
});

module.exports = router;
