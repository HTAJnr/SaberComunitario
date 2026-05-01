const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');

function normalizarTelefone(tel) {
  if (!tel) return tel;
  const digits = tel.replace(/\D/g, '');
  if (digits.length === 12 && digits.startsWith('258')) return '+' + digits;
  if (digits.length === 9) return '+258' + digits;
  return tel;
}

function validarNumCartao(nc) {
  return /^[A-Z]{3}\d{9}$/.test(nc);
}

async function gerarNumCartao(conn, cod_biblioteca) {
  const bibResult = await conn.execute(
    `SELECT NOME_BIBLIOTECA FROM BIBLIOTECA WHERE cod_BIBLIOTECA = :id`,
    { id: cod_biblioteca },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );
  if (bibResult.rows.length === 0) throw new Error('Biblioteca não encontrada.');

  const prefix = bibResult.rows[0].NOME_BIBLIOTECA
    .toUpperCase()
    .replace(/[^A-Z]/g, '')
    .substring(0, 3)
    .padEnd(3, 'X');

  const year = new Date().getFullYear();
  const pattern = prefix + year;

  const countResult = await conn.execute(
    `SELECT COUNT(*) AS N FROM LEITOR WHERE NUM_CARTAO LIKE :pat`,
    { pat: pattern + '%' },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );
  const seq = countResult.rows[0].N + 1;
  return pattern + String(seq).padStart(5, '0');
}

function isAdmin(req) {
  return (req.session.nivel_acesso || req.session.funcionario?.FUNCAO) === 'Administrador';
}

router.get('/', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { tipo, estado, q } = req.query;
    let where = 'WHERE 1=1';
    const params = {};
    if (tipo)   { where += ` AND TIPO_LEITOR = :tipo`;              params.tipo   = tipo; }
    if (estado) { where += ` AND STATUS_LEITOR = :estado`;          params.estado = estado; }
    if (q)      { where += ` AND UPPER(NOME_COMPLETO) LIKE UPPER(:q)`; params.q   = `%${q}%`; }
    if (!isAdmin(req) && req.session.cod_biblioteca) {
      where += ` AND cod_BIBLIOTECA = :cod_bib`;
      params.cod_bib = req.session.cod_biblioteca;
    }
    const result = await conn.execute(
      `SELECT NUM_CARTAO,
              NOME_COMPLETO       AS NOME,
              TIPO_LEITOR         AS TIPO,
              STATUS_LEITOR       AS ESTADO,
              CONTACTO, GENERO, NIVEL_ESCOLAR, LOCALIZACAO,
              EMPRESTIMOS_ATIVOS, LIMITE_EMPRESTIMO,
              cod_BIBLIOTECA, NOME_BIBLIOTECA
       FROM vw_leitores_completos ${where} ORDER BY NOME_COMPLETO`,
      params,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[LEITORES GET /] ERRO ao listar leitores\x1b[0m');
    console.error('     BD: VIEW vw_leitores_completos');
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
    const lResult = await conn.execute(
      `SELECT l.NUM_CARTAO, l.NOME_COMPLETO, l.DATA_NASC, l.GENERO, l.NIVEL_ESCOLAR,
              l.LOCALIZACAO_LEITOR, l.CONTACTO, l.cod_BIBLIOTECA, l.STATUS_LEITOR,
              l.DISTANCIA_BIBLIOTECA, l.HISTORICO_PONTUALIDADE,
              a.PROFISSAO,
              cr.NOME_RESPONSAVEL, cr.TELEFONE_RESPONSAVEL,
              cr.ESCOLA_FREQUENTA AS ESCOLA_CRIANCA,
              cr.CLASSE,
              p.ESCOLA_INSTITUTO AS ESCOLA_PROFESSOR,
              p.TIPO_ENSINO, p.NUM_ALUNOS
         FROM LEITOR l
         LEFT JOIN ADULTO  a  ON a.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN CRIANCA cr ON cr.NUM_CARTAO = l.NUM_CARTAO
         LEFT JOIN PROFESSOR p ON p.NUM_CARTAO = l.NUM_CARTAO
        WHERE l.NUM_CARTAO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (lResult.rows.length === 0) return res.status(404).json({ erro: 'Leitor não encontrado.' });

    const leitor = lResult.rows[0];

    // Buscar disciplinas do professor (PROFESSOR_DISCIPLINA é multi-valor)
    const discResult = await conn.execute(
      `SELECT DISCIPLINA FROM PROFESSOR_DISCIPLINA WHERE NUM_CARTAO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    leitor.DISCIPLINAS = discResult.rows.map(r => r.DISCIPLINA);

    res.json(leitor);
  } catch (err) {
    console.error(`\x1b[31m[LEITORES GET /${req.params.id}] ERRO ao buscar leitor\x1b[0m`);
    console.error('     BD: LEITOR + ADULTO + CRIANCA + PROFESSOR + PROFESSOR_DISCIPLINA');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/', async (req, res) => {
  let { nome_completo, data_nasc, genero, contacto, nivel_escolar, localizacao_leitor,
        num_cartao, tipo, cod_biblioteca,
        distancia_biblioteca, historico_pontualidade,
        profissao, nome_responsavel, telefone_responsavel, escola_frequenta, classe,
        escola_instituto, disciplina, tipo_ensino, num_alunos } = req.body;

  if (!nome_completo || !tipo) {
    return res.status(400).json({ erro: 'nome_completo e tipo obrigatórios.' });
  }
  if (!cod_biblioteca) {
    return res.status(400).json({ erro: 'cod_biblioteca é obrigatório.' });
  }

  // Normalizar contacto
  contacto = normalizarTelefone(contacto);

  let conn;
  try {
    conn = await getConnection();

    // Gerar num_cartao se não fornecido; validar formato se fornecido
    if (!num_cartao) {
      num_cartao = await gerarNumCartao(conn, Number(cod_biblioteca));
    } else {
      num_cartao = num_cartao.toUpperCase();
      if (!validarNumCartao(num_cartao)) {
        return res.status(400).json({ erro: 'Formato de cartão inválido. Esperado: 3 letras + 9 dígitos (ex: BCM20240001).' });
      }
    }

    await conn.execute(
      `INSERT INTO LEITOR
         (NUM_CARTAO, NOME_COMPLETO, DATA_NASC, GENERO, NIVEL_ESCOLAR,
          LOCALIZACAO_LEITOR, CONTACTO, cod_BIBLIOTECA,
          DISTANCIA_BIBLIOTECA, HISTORICO_PONTUALIDADE)
       VALUES
         (:num_cartao, :nome_completo, TO_DATE(:data_nasc,'YYYY-MM-DD'), :genero,
          :nivel_escolar, :localizacao, :contacto, :cod_biblioteca,
          :dist_bib, NVL(:hist_pont, 'Pontual'))`,
      {
        num_cartao,
        nome_completo,
        data_nasc:   data_nasc || null,
        genero:      genero || 'Masculino',
        nivel_escolar: nivel_escolar || 'Basico',
        localizacao: localizacao_leitor || null,
        contacto:    contacto || null,
        cod_biblioteca: Number(cod_biblioteca),
        dist_bib:    distancia_biblioteca ? Number(distancia_biblioteca) : null,
        hist_pont:   historico_pontualidade || null
      }
    );

    if (tipo === 'ADULTO') {
      await conn.execute(
        `INSERT INTO ADULTO (NUM_CARTAO, PROFISSAO) VALUES (:nc, :prof)`,
        { nc: num_cartao, prof: profissao || null }
      );
    } else if (tipo === 'CRIANCA') {
      await conn.execute(
        `INSERT INTO CRIANCA (NUM_CARTAO, NOME_RESPONSAVEL, TELEFONE_RESPONSAVEL, ESCOLA_FREQUENTA, CLASSE)
         VALUES (:nc, :nr, :tel, :escola, :classe)`,
        { nc: num_cartao, nr: nome_responsavel || null,
          tel: normalizarTelefone(telefone_responsavel) || null,
          escola: escola_frequenta || null,
          classe: classe || null }
      );
    } else if (tipo === 'PROFESSOR') {
      await conn.execute(
        `INSERT INTO ADULTO (NUM_CARTAO) VALUES (:nc)`,
        { nc: num_cartao }
      );
      await conn.execute(
        `INSERT INTO PROFESSOR (NUM_CARTAO, ESCOLA_INSTITUTO, TIPO_ENSINO, NUM_ALUNOS)
         VALUES (:nc, :escola, :te, :nalunos)`,
        { nc: num_cartao, escola: escola_instituto || null,
          te: tipo_ensino || 'Primario',
          nalunos: num_alunos ? Number(num_alunos) : null }
      );
      if (disciplina) {
        await conn.execute(
          `INSERT INTO PROFESSOR_DISCIPLINA (NUM_CARTAO, DISCIPLINA) VALUES (:nc, :disc)`,
          { nc: num_cartao, disc: disciplina }
        );
      }
    }

    await conn.commit();
    res.status(201).json({ ok: true, num_cartao });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[LEITORES POST /] ERRO ao criar leitor\x1b[0m');
    console.error('     BD: INSERT LEITOR → INSERT ADULTO/CRIANCA/PROFESSOR');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.put('/:id', async (req, res) => {
  let { nome_completo, data_nasc, genero, contacto, nivel_escolar, localizacao_leitor,
        tipo, cod_biblioteca, status_leitor,
        distancia_biblioteca, historico_pontualidade,
        profissao, nome_responsavel, telefone_responsavel, escola_frequenta, classe,
        escola_instituto, disciplina, tipo_ensino, num_alunos } = req.body;

  contacto = normalizarTelefone(contacto);

  let conn;
  try {
    conn = await getConnection();
    await conn.execute(
      `UPDATE LEITOR SET
         NOME_COMPLETO          = NVL(:nome, NOME_COMPLETO),
         DATA_NASC              = NVL(TO_DATE(:data_nasc,'YYYY-MM-DD'), DATA_NASC),
         GENERO                 = NVL(:genero, GENERO),
         NIVEL_ESCOLAR          = NVL(:nivel, NIVEL_ESCOLAR),
         LOCALIZACAO_LEITOR     = NVL(:loc, LOCALIZACAO_LEITOR),
         CONTACTO               = NVL(:contacto, CONTACTO),
         cod_BIBLIOTECA          = NVL(:cod_bib, cod_BIBLIOTECA),
         STATUS_LEITOR          = NVL(:status, STATUS_LEITOR),
         DISTANCIA_BIBLIOTECA   = NVL(:dist_bib, DISTANCIA_BIBLIOTECA),
         HISTORICO_PONTUALIDADE = NVL(:hist_pont, HISTORICO_PONTUALIDADE)
       WHERE NUM_CARTAO = :id`,
      {
        nome:      nome_completo || null,
        data_nasc: data_nasc || null,
        genero:    genero || null,
        nivel:     nivel_escolar || null,
        loc:       localizacao_leitor || null,
        contacto:  contacto || null,
        cod_bib:    cod_biblioteca ? Number(cod_biblioteca) : null,
        status:    status_leitor || null,
        dist_bib:  distancia_biblioteca != null ? Number(distancia_biblioteca) : null,
        hist_pont: historico_pontualidade || null,
        id:        req.params.id
      }
    );

    if (tipo === 'ADULTO' && profissao !== undefined) {
      await conn.execute(
        `UPDATE ADULTO SET PROFISSAO = :prof WHERE NUM_CARTAO = :id`,
        { prof: profissao, id: req.params.id }
      );
    } else if (tipo === 'CRIANCA') {
      await conn.execute(
        `UPDATE CRIANCA SET
           NOME_RESPONSAVEL     = NVL(:nr, NOME_RESPONSAVEL),
           TELEFONE_RESPONSAVEL = NVL(:tel, TELEFONE_RESPONSAVEL),
           ESCOLA_FREQUENTA     = NVL(:escola, ESCOLA_FREQUENTA),
           CLASSE               = NVL(:classe, CLASSE)
         WHERE NUM_CARTAO = :id`,
        { nr: nome_responsavel || null,
          tel: normalizarTelefone(telefone_responsavel) || null,
          escola: escola_frequenta || null,
          classe: classe || null,
          id: req.params.id }
      );
    } else if (tipo === 'PROFESSOR') {
      await conn.execute(
        `UPDATE PROFESSOR SET
           ESCOLA_INSTITUTO = NVL(:escola, ESCOLA_INSTITUTO),
           TIPO_ENSINO      = NVL(:te, TIPO_ENSINO),
           NUM_ALUNOS       = NVL(:nalunos, NUM_ALUNOS)
         WHERE NUM_CARTAO = :id`,
        { escola: escola_instituto || null,
          te: tipo_ensino || null,
          nalunos: num_alunos != null ? Number(num_alunos) : null,
          id: req.params.id }
      );
    }

    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[LEITORES PUT /${req.params.id}] ERRO ao actualizar leitor\x1b[0m`);
    console.error('     BD: UPDATE LEITOR + UPDATE ADULTO/CRIANCA/PROFESSOR');
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
      `SELECT COUNT(*) AS N FROM EMPRESTIMO WHERE NUM_CARTAO = :id AND DATA_DEVOLUCAO IS NULL`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (check.rows[0].N > 0) {
      return res.status(409).json({ erro: 'Leitor tem empréstimos activos. Faça a devolução primeiro.' });
    }
    await conn.execute(`DELETE FROM LEITOR WHERE NUM_CARTAO = :id`, { id: req.params.id });
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[LEITORES DELETE /${req.params.id}] ERRO ao eliminar leitor\x1b[0m`);
    console.error('     BD: EMPRESTIMO (check) → DELETE LEITOR');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
