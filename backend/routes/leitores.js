const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');
const { autenticar, exigirNivel } = require('../middleware/permissoes');

function normalizarTelefone(tel) {
  if (!tel) return tel;
  const digits = tel.replace(/\D/g, '');
  if (digits.length === 12 && digits.startsWith('258')) return '+' + digits;
  if (digits.length === 9) return '+258' + digits;
  return tel;
}

function normalizarTipo(tipo) {
  if (!tipo) return '';
  const map = { adulto: 'ADULTO', professor: 'PROFESSOR', crianca: 'CRIANCA', criança: 'CRIANCA' };
  return map[tipo.toLowerCase()] || tipo.toUpperCase();
}

function erroInterno(res, err, contexto) {
  console.error(`\x1b[31m[LEITORES ${contexto}]\x1b[0m`, err.message);
  res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message });
}

async function gerarNumCartao(conn, cod_biblioteca) {
  const bibResult = await conn.execute(
    `SELECT NOME_BIBLIOTECA FROM BIBLIOTECA WHERE COD_BIBLIOTECA = :id`,
    { id: cod_biblioteca },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );
  if (bibResult.rows.length === 0) throw new Error('Biblioteca não encontrada: ' + cod_biblioteca);

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
  return pattern + String(seq).padStart(4, '0');
}

function getNivel(req) {
  return req.session.nivel_acesso || req.session.funcionario?.NIVEL_ACESSO || '';
}

// ── GET / — listar leitores ──────────────────────────────────
router.get('/', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { tipo, status, historico, search, biblioteca } = req.query;
    const page  = Math.max(1, parseInt(req.query.page)  || 1);
    const limit = Math.max(1, parseInt(req.query.limit) || 20);

    let where = 'WHERE 1=1';
    const params = {};

    if (tipo)      { where += ` AND TIPO_LEITOR = :tipo`;                 params.tipo      = tipo; }
    if (status)    { where += ` AND STATUS_LEITOR = :status`;             params.status    = status; }
    if (historico) { where += ` AND HISTORICO_PONTUALIDADE = :historico`; params.historico = historico; }
    if (search)    { where += ` AND UPPER(NOME_COMPLETO) LIKE UPPER(:search)`; params.search = `%${search}%`; }

    const nivel = getNivel(req);
    if (nivel === 'Administrador') {
      if (biblioteca) { where += ` AND COD_BIBLIOTECA = :cod_bib`; params.cod_bib = biblioteca; }
    } else {
      const codBib = req.session.cod_biblioteca || req.session.funcionario?.COD_BIBLIOTECA;
      if (codBib) { where += ` AND COD_BIBLIOTECA = :cod_bib`; params.cod_bib = codBib; }
    }

    const totalResult = await conn.execute(
      `SELECT COUNT(*) AS TOTAL FROM VW_LEITORES_COMPLETOS ${where}`,
      params,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const total = totalResult.rows[0].TOTAL;

    const startRow = (page - 1) * limit;
    const endRow   = page * limit;

    const paginaParams = { ...params, start_row: startRow, end_row: endRow };

    const result = await conn.execute(
      `SELECT * FROM (
         SELECT t.*, ROWNUM AS RN FROM (
           SELECT NUM_CARTAO, NOME_COMPLETO, TIPO_LEITOR, STATUS_LEITOR,
                  HISTORICO_PONTUALIDADE, CONTACTO, COD_BIBLIOTECA, NOME_BIBLIOTECA
             FROM VW_LEITORES_COMPLETOS ${where}
            ORDER BY NOME_COMPLETO
         ) t WHERE ROWNUM <= :end_row
       ) WHERE RN > :start_row`,
      paginaParams,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({ total, leitores: result.rows });
  } catch (err) {
    erroInterno(res, err, 'GET /');
  } finally {
    if (conn) await conn.close();
  }
});

// ── GET /:id — perfil completo ───────────────────────────────
router.get('/:id/emprestimo-ativo', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT e.ID_EMPRESTIMO, m.TITULO, e.DATA_RETIRADA, e.PRAZO_DEVOLUCAO,
              (e.PRAZO_DEVOLUCAO - SYSDATE) AS DIAS_RESTANTES
         FROM EMPRESTIMO e
         JOIN MATERIAL_BIBLIOGRAFICO m ON m.COD_MATERIAL = e.COD_MATERIAL
        WHERE e.NUM_CARTAO = :id AND e.DATA_DEVOLUCAO IS NULL
          AND ROWNUM = 1`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows[0] || null);
  } catch (err) {
    erroInterno(res, err, 'GET /:id/emprestimo-ativo');
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/:id/historico', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT * FROM (
         SELECT e.ID_EMPRESTIMO, m.TITULO, e.DATA_RETIRADA, e.DATA_DEVOLUCAO,
                CASE WHEN e.DATA_DEVOLUCAO > e.PRAZO_DEVOLUCAO
                     THEN TRUNC(e.DATA_DEVOLUCAO) - TRUNC(e.PRAZO_DEVOLUCAO)
                     ELSE 0 END AS DIAS_ATRASO,
                e.MULTA_VALOR, e.MULTA_PAGA
           FROM EMPRESTIMO e
           JOIN MATERIAL_BIBLIOGRAFICO m ON m.COD_MATERIAL = e.COD_MATERIAL
          WHERE e.NUM_CARTAO = :id AND e.DATA_DEVOLUCAO IS NOT NULL
          ORDER BY e.DATA_DEVOLUCAO DESC
       ) WHERE ROWNUM <= 10`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    erroInterno(res, err, 'GET /:id/historico');
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/:id/suspensoes', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    // ?todas=true retorna histórico completo; por defeito só activas (spec §14)
    const todasParam = req.query.todas === 'true';
    const filtroAtiva = todasParam ? '' : `AND ESTADO_SUSPENSAO = 'Activa' AND SYSDATE <= DATA_FIM`;
    const result = await conn.execute(
      `SELECT ID_SUSPENSAO, DATA_INICIO, DATA_FIM, DIAS_SUSPENSAO,
              ESTADO_SUSPENSAO, ID_EMPRESTIMO, OBSERVACOES
         FROM SUSPENSAO
        WHERE NUM_CARTAO = :id ${filtroAtiva}
        ORDER BY DATA_INICIO DESC`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    erroInterno(res, err, 'GET /:id/suspensoes');
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/:id/multas', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT e.ID_EMPRESTIMO, m.TITULO, e.MULTA_VALOR, e.DATA_RETIRADA, e.DATA_DEVOLUCAO
         FROM EMPRESTIMO e
         JOIN MATERIAL_BIBLIOGRAFICO m ON m.COD_MATERIAL = e.COD_MATERIAL
        WHERE e.NUM_CARTAO = :id AND e.MULTA_VALOR > 0 AND e.MULTA_PAGA = 'N'
        ORDER BY e.DATA_RETIRADA DESC`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    erroInterno(res, err, 'GET /:id/multas');
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/:id', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    const lResult = await conn.execute(
      `SELECT l.NUM_CARTAO, l.NOME_COMPLETO, l.DATA_NASC, l.GENERO, l.NIVEL_ESCOLAR,
              l.LOCALIZACAO_LEITOR, l.CONTACTO, l.COD_BIBLIOTECA, l.STATUS_LEITOR,
              l.DISTANCIA_BIBLIOTECA, l.HISTORICO_PONTUALIDADE,
              a.PROFISSAO, a.NIVEL_LITERACIA,
              cr.NOME_RESPONSAVEL, cr.TELEFONE_RESPONSAVEL,
              cr.ESCOLA_FREQUENTA, cr.CLASSE,
              p.ESCOLA_INSTITUTO, p.NIVEL_ENSINO, p.NUM_ALUNOS,
              CASE WHEN p.NUM_CARTAO IS NOT NULL THEN 'Professor'
                   WHEN a.NUM_CARTAO IS NOT NULL THEN 'Adulto'
                   WHEN cr.NUM_CARTAO IS NOT NULL THEN 'Crianca'
              END AS TIPO_LEITOR
         FROM LEITOR l
         LEFT JOIN ADULTO    a  ON a.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN CRIANCA   cr ON cr.NUM_CARTAO = l.NUM_CARTAO
         LEFT JOIN PROFESSOR p  ON p.NUM_CARTAO  = l.NUM_CARTAO
        WHERE l.NUM_CARTAO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (lResult.rows.length === 0) {
      return res.status(404).json({ erro: true, codigo: 'LEITOR_NAO_ENCONTRADO', mensagem: 'Leitor não encontrado.' });
    }

    const leitor = lResult.rows[0];

    const discResult = await conn.execute(
      `SELECT DISCIPLINA FROM PROFESSOR_DISCIPLINA WHERE NUM_CARTAO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const intResult = await conn.execute(
      `SELECT INTERESSE FROM ADULTO_INTERESSE WHERE NUM_CARTAO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const empAtivoResult = await conn.execute(
      `SELECT e.ID_EMPRESTIMO, m.TITULO, m.COD_MATERIAL, e.DATA_RETIRADA,
              e.PRAZO_DEVOLUCAO, (e.PRAZO_DEVOLUCAO - SYSDATE) AS DIAS_RESTANTES
         FROM EMPRESTIMO e
         JOIN MATERIAL_BIBLIOGRAFICO m ON m.COD_MATERIAL = e.COD_MATERIAL
        WHERE e.NUM_CARTAO = :id AND e.DATA_DEVOLUCAO IS NULL
          AND ROWNUM = 1`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const historicoResult = await conn.execute(
      `SELECT * FROM (
         SELECT e.ID_EMPRESTIMO, m.TITULO, e.DATA_RETIRADA, e.DATA_DEVOLUCAO,
                CASE WHEN e.DATA_DEVOLUCAO > e.PRAZO_DEVOLUCAO
                     THEN TRUNC(e.DATA_DEVOLUCAO) - TRUNC(e.PRAZO_DEVOLUCAO)
                     ELSE 0 END AS DIAS_ATRASO,
                e.MULTA_VALOR, e.MULTA_PAGA
           FROM EMPRESTIMO e
           JOIN MATERIAL_BIBLIOGRAFICO m ON m.COD_MATERIAL = e.COD_MATERIAL
          WHERE e.NUM_CARTAO = :id AND e.DATA_DEVOLUCAO IS NOT NULL
          ORDER BY e.DATA_DEVOLUCAO DESC
       ) WHERE ROWNUM <= 10`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const suspResult = await conn.execute(
      `SELECT ID_SUSPENSAO, DATA_INICIO, DATA_FIM, DIAS_SUSPENSAO,
              ESTADO_SUSPENSAO, ID_EMPRESTIMO, OBSERVACOES
         FROM SUSPENSAO
        WHERE NUM_CARTAO = :id
          AND ESTADO_SUSPENSAO = 'Activa'
          AND SYSDATE <= DATA_FIM
        ORDER BY DATA_INICIO DESC`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const multasResult = await conn.execute(
      `SELECT e.ID_EMPRESTIMO, m.TITULO, e.MULTA_VALOR, e.DATA_RETIRADA, e.DATA_DEVOLUCAO
         FROM EMPRESTIMO e
         JOIN MATERIAL_BIBLIOGRAFICO m ON m.COD_MATERIAL = e.COD_MATERIAL
        WHERE e.NUM_CARTAO = :id AND e.MULTA_VALOR > 0 AND e.MULTA_PAGA = 'N'
        ORDER BY e.DATA_RETIRADA DESC`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    leitor.DISCIPLINAS       = discResult.rows.map(r => r.DISCIPLINA);
    leitor.INTERESSES        = intResult.rows.map(r => r.INTERESSE);
    leitor.EMPRESTIMO_ATIVO  = empAtivoResult.rows[0] || null;
    leitor.HISTORICO         = historicoResult.rows;
    leitor.SUSPENSOES_ATIVAS = suspResult.rows;
    leitor.MULTAS_ABERTAS    = multasResult.rows;

    res.json(leitor);
  } catch (err) {
    erroInterno(res, err, `GET /:id (${req.params.id})`);
  } finally {
    if (conn) await conn.close();
  }
});

// ── POST / — criar leitor ────────────────────────────────────
router.post('/', autenticar, async (req, res) => {
  let { nome_completo, data_nasc, genero, contacto, nivel_escolar, localizacao_leitor,
        num_cartao, cod_biblioteca,
        distancia_biblioteca,
        nivel_literacia,
        profissao, interesses,
        nome_responsavel, telefone_responsavel, escola_frequenta, classe,
        escola_instituto, nivel_ensino, num_alunos, disciplinas } = req.body;

  const tipo = normalizarTipo(req.body.tipo);

  if (!nome_completo) return res.status(400).json({ erro: true, codigo: 'CAMPO_OBRIGATORIO', mensagem: 'nome_completo é obrigatório.' });
  if (!tipo)          return res.status(400).json({ erro: true, codigo: 'CAMPO_OBRIGATORIO', mensagem: 'tipo é obrigatório.' });
  if (!['ADULTO', 'PROFESSOR', 'CRIANCA'].includes(tipo)) {
    return res.status(400).json({ erro: true, codigo: 'TIPO_INVALIDO', mensagem: 'tipo deve ser Adulto, Professor ou Crianca.' });
  }

  if (!cod_biblioteca) {
    cod_biblioteca = req.session.cod_biblioteca || req.session.funcionario?.COD_BIBLIOTECA;
    if (!cod_biblioteca) return res.status(400).json({ erro: true, codigo: 'CAMPO_OBRIGATORIO', mensagem: 'cod_biblioteca é obrigatório.' });
  }

  contacto = normalizarTelefone(contacto);

  let conn;
  try {
    conn = await getConnection();

    if (!num_cartao) {
      num_cartao = await gerarNumCartao(conn, cod_biblioteca);
    } else {
      num_cartao = num_cartao.toUpperCase();
    }

    await conn.execute(
      `INSERT INTO LEITOR
         (NUM_CARTAO, NOME_COMPLETO, DATA_NASC, GENERO, NIVEL_ESCOLAR,
          LOCALIZACAO_LEITOR, CONTACTO, COD_BIBLIOTECA,
          DISTANCIA_BIBLIOTECA, HISTORICO_PONTUALIDADE)
       VALUES
         (:num_cartao, :nome_completo, TO_DATE(:data_nasc,'YYYY-MM-DD'), :genero,
          :nivel_escolar, :localizacao, :contacto, :cod_biblioteca,
          :dist_bib, 'Pontual')`,
      {
        num_cartao,
        nome_completo,
        data_nasc:     data_nasc || null,
        genero:        genero || 'Masculino',
        nivel_escolar: nivel_escolar || null,
        localizacao:   localizacao_leitor || null,
        contacto:      contacto || null,
        cod_biblioteca,
        dist_bib:      distancia_biblioteca ? Number(distancia_biblioteca) : 0,
      }
    );

    if (tipo === 'ADULTO') {
      await conn.execute(
        `INSERT INTO ADULTO (NUM_CARTAO, PROFISSAO, NIVEL_LITERACIA)
         VALUES (:nc, :prof, :nlit)`,
        { nc: num_cartao, prof: profissao || null, nlit: nivel_literacia || 'Basico' }
      );
      for (const int of (interesses || [])) {
        await conn.execute(
          `INSERT INTO ADULTO_INTERESSE (NUM_CARTAO, INTERESSE) VALUES (:nc, :int)`,
          { nc: num_cartao, int: String(int).substring(0, 50) }
        );
      }

    } else if (tipo === 'PROFESSOR') {
      await conn.execute(
        `INSERT INTO ADULTO (NUM_CARTAO, PROFISSAO, NIVEL_LITERACIA)
         VALUES (:nc, :prof, :nlit)`,
        { nc: num_cartao, prof: profissao || null, nlit: nivel_literacia || 'Basico' }
      );
      for (const int of (interesses || [])) {
        await conn.execute(
          `INSERT INTO ADULTO_INTERESSE (NUM_CARTAO, INTERESSE) VALUES (:nc, :int)`,
          { nc: num_cartao, int: String(int).substring(0, 50) }
        );
      }
      await conn.execute(
        `INSERT INTO PROFESSOR (NUM_CARTAO, ESCOLA_INSTITUTO, NIVEL_ENSINO, NUM_ALUNOS)
         VALUES (:nc, :escola, :ne, :nalunos)`,
        { nc: num_cartao,
          escola:  escola_instituto || null,
          ne:      nivel_ensino || 'Primario',
          nalunos: num_alunos ? Number(num_alunos) : null }
      );
      for (const disc of (disciplinas || [])) {
        await conn.execute(
          `INSERT INTO PROFESSOR_DISCIPLINA (NUM_CARTAO, DISCIPLINA) VALUES (:nc, :disc)`,
          { nc: num_cartao, disc: String(disc).substring(0, 50) }
        );
      }

    } else if (tipo === 'CRIANCA') {
      await conn.execute(
        `INSERT INTO CRIANCA (NUM_CARTAO, NOME_RESPONSAVEL, TELEFONE_RESPONSAVEL, ESCOLA_FREQUENTA, CLASSE)
         VALUES (:nc, :nr, :tel, :escola, :classe)`,
        { nc: num_cartao,
          nr:     nome_responsavel || null,
          tel:    normalizarTelefone(telefone_responsavel) || null,
          escola: escola_frequenta || null,
          classe: classe || null }
      );
    }

    await conn.commit();
    res.status(201).json({ ok: true, num_cartao });
  } catch (err) {
    if (conn) await conn.rollback();
    erroInterno(res, err, 'POST /');
  } finally {
    if (conn) await conn.close();
  }
});

// ── PATCH /:id — editar leitor ───────────────────────────────
router.patch('/:id', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  let { nome_completo, data_nasc, genero, contacto, nivel_escolar, localizacao_leitor,
        cod_biblioteca, distancia_biblioteca,
        nivel_literacia,
        profissao, interesses,
        nome_responsavel, telefone_responsavel, escola_frequenta, classe,
        escola_instituto, nivel_ensino, num_alunos, disciplinas } = req.body;

  const tipo = normalizarTipo(req.body.tipo);
  contacto = normalizarTelefone(contacto);

  let conn;
  try {
    conn = await getConnection();

    const check = await conn.execute(
      `SELECT NUM_CARTAO FROM LEITOR WHERE NUM_CARTAO = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (check.rows.length === 0) {
      return res.status(404).json({ erro: true, codigo: 'LEITOR_NAO_ENCONTRADO', mensagem: 'Leitor não encontrado.' });
    }

    await conn.execute(
      `UPDATE LEITOR SET
         NOME_COMPLETO        = NVL(:nome,     NOME_COMPLETO),
         DATA_NASC            = NVL(TO_DATE(:data_nasc,'YYYY-MM-DD'), DATA_NASC),
         GENERO               = NVL(:genero,   GENERO),
         NIVEL_ESCOLAR        = NVL(:nivel,    NIVEL_ESCOLAR),
         LOCALIZACAO_LEITOR   = NVL(:loc,      LOCALIZACAO_LEITOR),
         CONTACTO             = NVL(:contacto, CONTACTO),
         COD_BIBLIOTECA       = NVL(:cod_bib,  COD_BIBLIOTECA),
         DISTANCIA_BIBLIOTECA = NVL(:dist_bib, DISTANCIA_BIBLIOTECA)
       WHERE NUM_CARTAO = :id`,
      {
        nome:     nome_completo || null,
        data_nasc: data_nasc || null,
        genero:   genero || null,
        nivel:    nivel_escolar || null,
        loc:      localizacao_leitor || null,
        contacto: contacto || null,
        cod_bib:  cod_biblioteca || null,
        dist_bib: distancia_biblioteca != null ? Number(distancia_biblioteca) : null,
        id:       req.params.id
      }
    );

    if (tipo === 'ADULTO' || tipo === 'PROFESSOR') {
      await conn.execute(
        `UPDATE ADULTO SET
           PROFISSAO       = NVL(:prof, PROFISSAO),
           NIVEL_LITERACIA = NVL(:nlit, NIVEL_LITERACIA)
         WHERE NUM_CARTAO = :id`,
        { prof: profissao || null, nlit: nivel_literacia || null, id: req.params.id }
      );
      if (Array.isArray(interesses)) {
        await conn.execute(`DELETE FROM ADULTO_INTERESSE WHERE NUM_CARTAO = :id`, { id: req.params.id });
        for (const int of interesses) {
          await conn.execute(
            `INSERT INTO ADULTO_INTERESSE (NUM_CARTAO, INTERESSE) VALUES (:nc, :int)`,
            { nc: req.params.id, int: String(int).substring(0, 50) }
          );
        }
      }
    }

    if (tipo === 'PROFESSOR') {
      await conn.execute(
        `UPDATE PROFESSOR SET
           ESCOLA_INSTITUTO = NVL(:escola, ESCOLA_INSTITUTO),
           NIVEL_ENSINO     = NVL(:ne,     NIVEL_ENSINO),
           NUM_ALUNOS       = NVL(:nalunos, NUM_ALUNOS)
         WHERE NUM_CARTAO = :id`,
        { escola:  escola_instituto || null,
          ne:      nivel_ensino || null,
          nalunos: num_alunos != null ? Number(num_alunos) : null,
          id:      req.params.id }
      );
      if (Array.isArray(disciplinas)) {
        await conn.execute(`DELETE FROM PROFESSOR_DISCIPLINA WHERE NUM_CARTAO = :id`, { id: req.params.id });
        for (const disc of disciplinas) {
          await conn.execute(
            `INSERT INTO PROFESSOR_DISCIPLINA (NUM_CARTAO, DISCIPLINA) VALUES (:nc, :disc)`,
            { nc: req.params.id, disc: String(disc).substring(0, 50) }
          );
        }
      }
    }

    if (tipo === 'CRIANCA') {
      await conn.execute(
        `UPDATE CRIANCA SET
           NOME_RESPONSAVEL     = NVL(:nr,    NOME_RESPONSAVEL),
           TELEFONE_RESPONSAVEL = NVL(:tel,   TELEFONE_RESPONSAVEL),
           ESCOLA_FREQUENTA     = NVL(:escola, ESCOLA_FREQUENTA),
           CLASSE               = NVL(:classe, CLASSE)
         WHERE NUM_CARTAO = :id`,
        { nr:     nome_responsavel || null,
          tel:    normalizarTelefone(telefone_responsavel) || null,
          escola: escola_frequenta || null,
          classe: classe || null,
          id:     req.params.id }
      );
    }

    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    erroInterno(res, err, `PATCH /:id (${req.params.id})`);
  } finally {
    if (conn) await conn.close();
  }
});

// ── PATCH /:id/status — alterar estado ──────────────────────
router.patch('/:id/status', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  const { status_leitor, observacoes } = req.body;
  if (!status_leitor) return res.status(400).json({ erro: true, codigo: 'CAMPO_OBRIGATORIO', mensagem: 'status_leitor é obrigatório.' });
  if (!observacoes)   return res.status(400).json({ erro: true, codigo: 'CAMPO_OBRIGATORIO', mensagem: 'observacoes são obrigatórias.' });

  const validos = ['Activo', 'Suspenso', 'Bloqueado'];
  if (!validos.includes(status_leitor)) {
    return res.status(400).json({ erro: true, codigo: 'STATUS_INVALIDO', mensagem: `status_leitor deve ser: ${validos.join(', ')}.` });
  }

  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `UPDATE LEITOR SET STATUS_LEITOR = :status WHERE NUM_CARTAO = :id`,
      { status: status_leitor, id: req.params.id }
    );
    if (result.rowsAffected === 0) {
      return res.status(404).json({ erro: true, codigo: 'LEITOR_NAO_ENCONTRADO', mensagem: 'Leitor não encontrado.' });
    }
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    erroInterno(res, err, `PATCH /:id/status (${req.params.id})`);
  } finally {
    if (conn) await conn.close();
  }
});

// ── DELETE /:id — eliminar leitor ────────────────────────────
router.delete('/:id', exigirNivel('Administrador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    const empCheck = await conn.execute(
      `SELECT COUNT(*) AS N FROM EMPRESTIMO WHERE NUM_CARTAO = :id AND DATA_DEVOLUCAO IS NULL`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (empCheck.rows[0].N > 0) {
      return res.status(409).json({ erro: true, codigo: 'EMPRESTIMO_ACTIVO', mensagem: 'Leitor tem empréstimos activos. Faça a devolução primeiro.' });
    }

    const multaCheck = await conn.execute(
      `SELECT COUNT(*) AS N FROM EMPRESTIMO WHERE NUM_CARTAO = :id AND MULTA_VALOR > 0 AND MULTA_PAGA = 'N'`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (multaCheck.rows[0].N > 0) {
      return res.status(409).json({ erro: true, codigo: 'MULTAS_POR_PAGAR', mensagem: 'Leitor tem multas por pagar. Regularize as multas antes de eliminar.' });
    }

    await conn.execute(`DELETE FROM LEITOR WHERE NUM_CARTAO = :id`, { id: req.params.id });
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    erroInterno(res, err, `DELETE /:id (${req.params.id})`);
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
