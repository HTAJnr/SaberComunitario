const express = require('express');
const router  = express.Router();
const { getConnectionEmprestimos: getConnection, oracledb, isOfflineError } = require('../db');
const { autenticar, exigirNivel } = require('../middleware/permissoes');

const PUBLICOS_VALIDOS     = ['Iniciantes', 'Intermedios', 'Avancados', 'Todos'];
const ESTADOS_PROG_VALIDOS = ['Activo', 'Concluido', 'Suspenso'];
const PAPEIS_VALIDOS       = ['Responsavel', 'Instrutor', 'Auxiliar'];
const ESTADOS_PART_VALIDOS = ['Activo', 'Concluido', 'Desistiu'];

function erroInterno(res, err, contexto) {
  console.error(`\x1b[31m[PROGRAMAS ${contexto}]\x1b[0m`, err.message);
  res.status(500).json({ erro: true, codigo: 'ERRO_INTERNO', mensagem: err.message });
}

async function gerarCodPrograma(conn) {
  const year   = new Date().getFullYear();
  const prefix = 'PRG' + year;
  const r = await conn.execute(
    `SELECT COUNT(*) AS N FROM PROGRAMA_ALFABETIZACAO WHERE COD_PROGRAMA LIKE :pat`,
    { pat: prefix + '%' },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );
  const seq = r.rows[0].N + 1;
  return prefix + String(seq).padStart(4, '0');
}

// GET /api/programas?biblioteca=X&estado=X&page=1&limit=20
router.get('/', autenticar, async (req, res) => {
  let conn;
  try {
    const nivel   = req.session.nivel_acesso || '';
    const sessBib = req.session.cod_biblioteca || null;
    const { biblioteca, estado } = req.query;
    const page   = Math.max(1, parseInt(req.query.page)  || 1);
    const limit  = Math.min(100, parseInt(req.query.limit) || 20);
    const offset = (page - 1) * limit;

    let bibEfectiva = null;
    if (nivel === 'Administrador') {
      bibEfectiva = biblioteca || null;
    } else {
      bibEfectiva = sessBib;
    }

    const binds = { rn_max: offset + limit, rn_min: offset };
    let whereClause = '';

    if (bibEfectiva) {
      whereClause += ' AND p.cod_biblioteca = :bib';
      binds.bib = bibEfectiva;
    }
    if (estado) {
      whereClause += ' AND p.estado_programa = :estado';
      binds.estado = estado;
    }

    conn = await getConnection();
    const result = await conn.execute(
      `SELECT * FROM (
         SELECT t.*, ROWNUM AS RN FROM (
           SELECT p.cod_programa, p.nome_programa, p.descricao, p.publico_alvo,
                  p.duracao_semanas, p.metodologia, p.resultados_esperados, p.estado_programa,
                  p.cod_biblioteca,
                  b.nome_biblioteca,
                  (SELECT COUNT(*) FROM PARTICIPACAO_PROGRAMA pp
                    WHERE pp.cod_programa = p.cod_programa
                      AND pp.estado_participacao = 'Activo') AS total_participantes_activos
             FROM PROGRAMA_ALFABETIZACAO p
             JOIN BIBLIOTECA b ON b.cod_biblioteca = p.cod_biblioteca
            WHERE 1=1${whereClause}
            ORDER BY p.nome_programa
         ) t WHERE ROWNUM <= :rn_max
       ) WHERE RN > :rn_min`,
      binds,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json(result.rows);
  } catch (err) {
    erroInterno(res, err, 'GET /');
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/programas — criar programa
router.post('/', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  let conn;
  try {
    const cod_funcionario = req.session.cod_funcionario;
    if (cod_funcionario === 0) {
      return res.status(400).json({ erro: true, codigo: 'DEMO_BLOQUEADO', mensagem: 'Utilizador demo não pode criar programas.' });
    }

    const nivel   = req.session.nivel_acesso || '';
    const sessBib = req.session.cod_biblioteca || null;

    const {
      nome_programa, descricao, publico_alvo, duracao_semanas,
      metodologia, resultados_esperados, estado_programa,
      cod_biblioteca: bibBody,
      niveis = [], materiais = [], funcionarios = []
    } = req.body;

    if (!nome_programa || !publico_alvo) {
      return res.status(400).json({ erro: true, codigo: 'CAMPOS_OBRIGATORIOS', mensagem: 'nome_programa e publico_alvo são obrigatórios.' });
    }
    if (!PUBLICOS_VALIDOS.includes(publico_alvo)) {
      return res.status(400).json({ erro: true, codigo: 'PUBLICO_INVALIDO', mensagem: `publico_alvo deve ser um de: ${PUBLICOS_VALIDOS.join(', ')}.` });
    }

    const codBib = (nivel === 'Administrador' && bibBody) ? bibBody : sessBib;
    if (!codBib) {
      return res.status(400).json({ erro: true, codigo: 'BIBLIOTECA_INVALIDA', mensagem: 'cod_biblioteca é obrigatório.' });
    }

    conn = await getConnection();

    // Validar materiais antes de qualquer insert
    for (const m of materiais) {
      const matCheck = await conn.execute(
        `SELECT COUNT(*) AS N FROM MATERIAL_BIBLIOGRAFICO WHERE COD_MATERIAL = :mat`,
        { mat: m.cod_material },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      if (matCheck.rows[0].N === 0) {
        return res.status(404).json({ erro: true, codigo: 'MATERIAL_NAO_ENCONTRADO', mensagem: `Material '${m.cod_material}' não encontrado.` });
      }
    }

    const codPrograma = await gerarCodPrograma(conn);

    await conn.execute(
      `INSERT INTO PROGRAMA_ALFABETIZACAO (
         cod_programa, cod_biblioteca, nome_programa, descricao,
         publico_alvo, duracao_semanas, metodologia, resultados_esperados, estado_programa
       ) VALUES (
         :cod, :bib, :nome, :descricao,
         :publico, :duracao, :metodologia, :resultados, :estado
       )`,
      {
        cod:        codPrograma,
        bib:        codBib,
        nome:       nome_programa,
        descricao:  descricao || null,
        publico:    publico_alvo,
        duracao:    duracao_semanas || null,
        metodologia: metodologia || null,
        resultados: resultados_esperados || null,
        estado:     estado_programa || 'Activo'
      }
    );

    for (const n of niveis) {
      await conn.execute(
        `INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
         VALUES (SEQ_NIVEL.NEXTVAL, :cod, :nome, :descricao, :ordem)`,
        {
          cod:       codPrograma,
          nome:      n.nome_nivel,
          descricao: n.descricao || null,
          ordem:     n.ordem
        }
      );
    }

    for (const m of materiais) {
      await conn.execute(
        `INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
         VALUES (:cod, :mat, :obs)`,
        { cod: codPrograma, mat: m.cod_material, obs: m.observacoes || null }
      );
    }

    for (const f of funcionarios) {
      if (!PAPEIS_VALIDOS.includes(f.papel)) continue;
      await conn.execute(
        `INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
         VALUES (:cod, :func, :papel)`,
        { cod: codPrograma, func: f.cod_funcionario, papel: f.papel }
      );
    }

    await conn.commit();
    res.status(201).json({ ok: true, cod_programa: codPrograma });
  } catch (err) {
    if (conn) await conn.rollback();
    erroInterno(res, err, 'POST /');
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/programas/relatorio-nacional — MV mv_relatorio_programas (NacionalDB only, Admin)
router.get('/relatorio-nacional', autenticar, exigirNivel('Administrador'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT cod_programa, cod_biblioteca, nome_programa, publico_alvo,
              duracao_semanas, estado_programa,
              total_participantes, participantes_activos,
              participantes_concluidos, participantes_desistiram
       FROM mv_relatorio_programas
       ORDER BY cod_biblioteca, nome_programa`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    if (err.message?.includes('ORA-00942') || err.message?.includes('ORA-04043')) {
      return res.json([]);
    }
    console.error('\x1b[31m[PROGRAMAS /relatorio-nacional]\x1b[0m', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/programas/:cod — detalhe completo
router.get('/:cod', autenticar, async (req, res) => {
  let conn;
  try {
    const cod = req.params.cod;
    conn = await getConnection();

    const progResult = await conn.execute(
      `SELECT p.cod_programa, p.nome_programa, p.descricao, p.publico_alvo,
              p.duracao_semanas, p.metodologia, p.resultados_esperados, p.estado_programa,
              p.cod_biblioteca, b.nome_biblioteca
         FROM PROGRAMA_ALFABETIZACAO p
         JOIN BIBLIOTECA b ON b.cod_biblioteca = p.cod_biblioteca
        WHERE p.cod_programa = :cod`,
      { cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (progResult.rows.length === 0) {
      return res.status(404).json({ erro: true, codigo: 'PROGRAMA_NAO_ENCONTRADO', mensagem: 'Programa não encontrado.' });
    }

    const niveisResult = await conn.execute(
      `SELECT id_nivel, nome_nivel, descricao, ordem
         FROM NIVEL_PROGRESSAO
        WHERE cod_programa = :cod
        ORDER BY ordem`,
      { cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const matResult = await conn.execute(
      `SELECT pm.cod_material, pm.observacoes, m.titulo, m.autor
         FROM PROGRAMA_MATERIAL pm
         JOIN MATERIAL_BIBLIOGRAFICO m ON m.cod_material = pm.cod_material
        WHERE pm.cod_programa = :cod`,
      { cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const funcResult = await conn.execute(
      `SELECT pf.papel, f.cod_funcionario, f.nome_funcionario AS nome_completo
         FROM PROGRAMA_FUNCIONARIO pf
         JOIN FUNCIONARIO f ON f.cod_funcionario = pf.cod_funcionario
        WHERE pf.cod_programa = :cod`,
      { cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({
      programa:     progResult.rows[0],
      niveis:       niveisResult.rows,
      materiais:    matResult.rows,
      funcionarios: funcResult.rows
    });
  } catch (err) {
    erroInterno(res, err, 'GET /:cod');
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /api/programas/:cod — editar campos / mudar estado
router.patch('/:cod', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    const cod_funcionario = req.session.cod_funcionario;
    if (cod_funcionario === 0) {
      return res.status(400).json({ erro: true, codigo: 'DEMO_BLOQUEADO', mensagem: 'Utilizador demo não pode editar programas.' });
    }

    const cod = req.params.cod;
    const { nome_programa, descricao, publico_alvo, duracao_semanas,
            metodologia, resultados_esperados, estado_programa } = req.body;

    if (publico_alvo && !PUBLICOS_VALIDOS.includes(publico_alvo)) {
      return res.status(400).json({ erro: true, codigo: 'PUBLICO_INVALIDO', mensagem: `publico_alvo deve ser um de: ${PUBLICOS_VALIDOS.join(', ')}.` });
    }
    if (estado_programa && !ESTADOS_PROG_VALIDOS.includes(estado_programa)) {
      return res.status(400).json({ erro: true, codigo: 'ESTADO_INVALIDO', mensagem: `estado_programa deve ser um de: ${ESTADOS_PROG_VALIDOS.join(', ')}.` });
    }

    conn = await getConnection();

    const check = await conn.execute(
      `SELECT cod_programa FROM PROGRAMA_ALFABETIZACAO WHERE cod_programa = :cod`,
      { cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (check.rows.length === 0) {
      return res.status(404).json({ erro: true, codigo: 'PROGRAMA_NAO_ENCONTRADO', mensagem: 'Programa não encontrado.' });
    }

    const setClauses = [];
    const binds = { cod };

    if (nome_programa)         { setClauses.push('nome_programa = :nome');           binds.nome       = nome_programa; }
    if (descricao !== undefined){ setClauses.push('descricao = :desc');               binds.desc       = descricao || null; }
    if (publico_alvo)          { setClauses.push('publico_alvo = :publico');          binds.publico    = publico_alvo; }
    if (duracao_semanas !== undefined) { setClauses.push('duracao_semanas = :dur');   binds.dur        = duracao_semanas || null; }
    if (metodologia !== undefined)     { setClauses.push('metodologia = :met');       binds.met        = metodologia || null; }
    if (resultados_esperados !== undefined) { setClauses.push('resultados_esperados = :res'); binds.res = resultados_esperados || null; }
    if (estado_programa)       { setClauses.push('estado_programa = :estado');        binds.estado     = estado_programa; }

    if (setClauses.length === 0) {
      return res.status(400).json({ erro: true, codigo: 'NADA_A_ACTUALIZAR', mensagem: 'Nenhum campo para actualizar.' });
    }

    await conn.execute(
      `UPDATE PROGRAMA_ALFABETIZACAO SET ${setClauses.join(', ')} WHERE cod_programa = :cod`,
      binds
    );

    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    erroInterno(res, err, 'PATCH /:cod');
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/programas/:cod/participantes
router.get('/:cod/participantes', autenticar, async (req, res) => {
  let conn;
  try {
    const cod = req.params.cod;
    conn = await getConnection();

    const check = await conn.execute(
      `SELECT cod_programa FROM PROGRAMA_ALFABETIZACAO WHERE cod_programa = :cod`,
      { cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (check.rows.length === 0) {
      return res.status(404).json({ erro: true, codigo: 'PROGRAMA_NAO_ENCONTRADO', mensagem: 'Programa não encontrado.' });
    }

    const result = await conn.execute(
      `SELECT pp.num_cartao, l.nome_completo, pp.id_nivel_atual,
              np.nome_nivel, pp.estado_participacao,
              pp.data_inscricao, pp.data_conclusao
         FROM PARTICIPACAO_PROGRAMA pp
         JOIN LEITOR l ON l.num_cartao = pp.num_cartao
         LEFT JOIN NIVEL_PROGRESSAO np ON np.id_nivel = pp.id_nivel_atual
        WHERE pp.cod_programa = :cod
        ORDER BY l.nome_completo`,
      { cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json(result.rows);
  } catch (err) {
    erroInterno(res, err, 'GET /:cod/participantes');
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/programas/:cod/participantes — inscrever leitor
router.post('/:cod/participantes', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  let conn;
  try {
    const cod_funcionario = req.session.cod_funcionario;
    if (cod_funcionario === 0) {
      return res.status(400).json({ erro: true, codigo: 'DEMO_BLOQUEADO', mensagem: 'Utilizador demo não pode inscrever participantes.' });
    }

    const cod = req.params.cod;
    const { num_cartao, id_nivel_inicial } = req.body;

    if (!num_cartao) {
      return res.status(400).json({ erro: true, codigo: 'CAMPOS_OBRIGATORIOS', mensagem: 'num_cartao é obrigatório.' });
    }

    conn = await getConnection();

    const progCheck = await conn.execute(
      `SELECT cod_programa FROM PROGRAMA_ALFABETIZACAO WHERE cod_programa = :cod`,
      { cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (progCheck.rows.length === 0) {
      return res.status(404).json({ erro: true, codigo: 'PROGRAMA_NAO_ENCONTRADO', mensagem: 'Programa não encontrado.' });
    }

    const leitCheck = await conn.execute(
      `SELECT num_cartao FROM LEITOR WHERE num_cartao = :nc`,
      { nc: num_cartao },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (leitCheck.rows.length === 0) {
      return res.status(404).json({ erro: true, codigo: 'LEITOR_NAO_ENCONTRADO', mensagem: 'Leitor não encontrado.' });
    }

    const dupCheck = await conn.execute(
      `SELECT num_cartao FROM PARTICIPACAO_PROGRAMA WHERE num_cartao = :nc AND cod_programa = :cod`,
      { nc: num_cartao, cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (dupCheck.rows.length > 0) {
      return res.status(409).json({ erro: true, codigo: 'JA_INSCRITO', mensagem: 'Leitor já está inscrito neste programa.' });
    }

    await conn.execute(
      `INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual, data_inscricao, estado_participacao)
       VALUES (:nc, :cod, :nivel, SYSDATE, 'Activo')`,
      { nc: num_cartao, cod, nivel: id_nivel_inicial || null }
    );

    await conn.commit();
    res.status(201).json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    erroInterno(res, err, 'POST /:cod/participantes');
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /api/programas/:cod/participantes/:num_cartao — actualizar nível/estado
router.patch('/:cod/participantes/:num_cartao', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  let conn;
  try {
    const cod       = req.params.cod;
    const num_cartao = req.params.num_cartao;
    const { id_nivel_atual, estado_participacao, data_conclusao } = req.body;

    if (estado_participacao && !ESTADOS_PART_VALIDOS.includes(estado_participacao)) {
      return res.status(400).json({ erro: true, codigo: 'ESTADO_INVALIDO', mensagem: `estado_participacao deve ser um de: ${ESTADOS_PART_VALIDOS.join(', ')}.` });
    }

    conn = await getConnection();

    const check = await conn.execute(
      `SELECT num_cartao FROM PARTICIPACAO_PROGRAMA WHERE num_cartao = :nc AND cod_programa = :cod`,
      { nc: num_cartao, cod },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (check.rows.length === 0) {
      return res.status(404).json({ erro: true, codigo: 'PARTICIPACAO_NAO_ENCONTRADA', mensagem: 'Participação não encontrada.' });
    }

    const setClauses = [];
    const binds = { nc: num_cartao, cod };

    if (id_nivel_atual !== undefined) {
      setClauses.push('id_nivel_atual = :nivel');
      binds.nivel = id_nivel_atual;
    }
    if (estado_participacao) {
      setClauses.push('estado_participacao = :estado');
      binds.estado = estado_participacao;
    }
    if (data_conclusao) {
      setClauses.push('data_conclusao = TO_DATE(:data_conc, \'YYYY-MM-DD\')');
      binds.data_conc = data_conclusao;
    }

    if (setClauses.length === 0) {
      return res.status(400).json({ erro: true, codigo: 'NADA_A_ACTUALIZAR', mensagem: 'Nenhum campo para actualizar.' });
    }

    await conn.execute(
      `UPDATE PARTICIPACAO_PROGRAMA
          SET ${setClauses.join(', ')}
        WHERE num_cartao = :nc AND cod_programa = :cod`,
      binds
    );

    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    erroInterno(res, err, 'PATCH /:cod/participantes/:num_cartao');
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
