const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');

const DIAS_PT = ['Domingo','Segunda','Terca','Quarta','Quinta','Sexta','Sabado'];

router.get('/', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { proximos } = req.query;
    const sql = proximos === '1'
      ? `SELECT ID_EVENTO,
                TITULO_EVENTO   AS NOME,
                DATA_EVENTO     AS DATA_INICIO,
                BIBLIOTECA_NOME AS NOME_BIBLIOTECA
         FROM vw_eventos_proximos ORDER BY DATA_EVENTO`
      : `SELECT e.ID_EVENTO,
                e.TITULO_EVENTO  AS NOME,
                e.DATA_EVENTO    AS DATA_INICIO,
                e.DESCRICAO_EVENTO, e.PUBLICO_ALVO, e.RECORRENTE, e.COD_BIBLIOTECA,
                b.NOME_BIBLIOTECA,
                (SELECT COUNT(*) FROM PARTICIPACAO_EVENTO p WHERE p.ID_EVENTO = e.ID_EVENTO) AS INSCRITOS
           FROM EVENTO e
           LEFT JOIN BIBLIOTECA b ON b.COD_BIBLIOTECA = e.COD_BIBLIOTECA
          ORDER BY e.DATA_EVENTO DESC`;
    const result = await conn.execute(sql, [], { outFormat: oracledb.OUT_FORMAT_OBJECT });
    res.json(result.rows);
  } catch (err) {
    const fonte = req.query.proximos === '1' ? 'VIEW vw_eventos_proximos' : 'EVENTO + BIBLIOTECA + PARTICIPACAO_EVENTO';
    console.error('\x1b[31m[EVENTOS GET /] ERRO ao listar eventos\x1b[0m');
    console.error(`     BD: ${fonte}`);
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
      `SELECT * FROM vw_eventos_completos WHERE id_evento = :id`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (result.rows.length === 0) return res.status(404).json({ erro: 'Evento não encontrado.' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(`\x1b[31m[EVENTOS GET /${req.params.id}] ERRO ao buscar evento\x1b[0m`);
    console.error('     BD: EVENTO + BIBLIOTECA + PARTICIPACAO_EVENTO (COUNT)');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/', async (req, res) => {
  const { titulo_evento, descricao_evento, data_evento, publico_alvo, recorrente, COD_biblioteca } = req.body;
  if (!titulo_evento || !data_evento) {
    return res.status(400).json({ erro: 'titulo_evento e data_evento obrigatórios.' });
  }

  let conn;
  try {
    conn = await getConnection();

    // Verificar horário da biblioteca: só bloqueia se houver horários definidos e o dia não constar
    if (COD_biblioteca && data_evento) {
      const diaSemana = DIAS_PT[new Date(data_evento).getDay()];
      const schedResult = await conn.execute(
        `SELECT COUNT(*) AS TOTAL,
                SUM(CASE WHEN DIA_SEMANA = :dia THEN 1 ELSE 0 END) AS NESTE_DIA
         FROM HORARIO_BIBLIOTECA
         WHERE COD_BIBLIOTECA = :cod_bib`,
        { dia: diaSemana, cod_bib: COD_biblioteca },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      const sched = schedResult.rows[0];
      if (sched.TOTAL > 0 && (sched.NESTE_DIA === 0 || sched.NESTE_DIA === null)) {
        return res.status(409).json({ erro: `Biblioteca não tem horário definido para ${diaSemana}.` });
      }
    }

    const result = await conn.execute(
      `INSERT INTO EVENTO (ID_EVENTO, TITULO_EVENTO, DESCRICAO_EVENTO, DATA_EVENTO, PUBLICO_ALVO, RECORRENTE, COD_BIBLIOTECA)
       VALUES (SEQ_EVENTO.NEXTVAL, :titulo, :desc, TO_DATE(:data,'YYYY-MM-DD'), :pub_alvo, NVL(:rec,'N'), :cod_bib)
       RETURNING ID_EVENTO INTO :id_out`,
      { titulo: titulo_evento, desc: descricao_evento || null,
        data: data_evento, pub_alvo: publico_alvo || null,
        rec: recorrente || 'N', cod_bib: COD_biblioteca || null,
        id_out: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER } }
    );
    await conn.commit();
    res.status(201).json({ ok: true, id_evento: result.outBinds.id_out[0] });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[EVENTOS POST /] ERRO ao criar evento\x1b[0m');
    console.error('     BD: HORARIO_BIBLIOTECA (validação) + INSERT EVENTO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.put('/:id', async (req, res) => {
  const { titulo_evento, descricao_evento, data_evento, publico_alvo, recorrente, COD_biblioteca } = req.body;
  let conn;
  try {
    conn = await getConnection();
    await conn.execute(
      `UPDATE EVENTO SET
         TITULO_EVENTO    = NVL(:titulo, TITULO_EVENTO),
         DESCRICAO_EVENTO = NVL(:desc, DESCRICAO_EVENTO),
         DATA_EVENTO      = NVL(TO_DATE(:data,'YYYY-MM-DD'), DATA_EVENTO),
         PUBLICO_ALVO     = NVL(:pub_alvo, PUBLICO_ALVO),
         RECORRENTE       = NVL(:rec, RECORRENTE),
         COD_BIBLIOTECA    = NVL(:cod_bib, COD_BIBLIOTECA)
       WHERE ID_EVENTO = :id`,
      { titulo: titulo_evento || null, desc: descricao_evento || null,
        data: data_evento || null, pub_alvo: publico_alvo || null,
        rec: recorrente !== undefined ? recorrente : null,
        cod_bib: COD_biblioteca || null, id: req.params.id }
    );
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[EVENTOS PUT /${req.params.id}] ERRO ao actualizar evento\x1b[0m`);
    console.error('     BD: UPDATE EVENTO');
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
    await conn.execute(`DELETE FROM EVENTO WHERE ID_EVENTO = :id`, { id: req.params.id });
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[EVENTOS DELETE /${req.params.id}] ERRO ao eliminar evento\x1b[0m`);
    console.error('     BD: DELETE EVENTO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/:id/participacoes', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT p.NUM_CARTAO, p.DATA_INSCRICAO, p.PRESENCA_CONFIRMACAO,
              l.NOME_COMPLETO AS NOME_LEITOR
         FROM PARTICIPACAO_EVENTO p
         JOIN LEITOR l ON l.NUM_CARTAO = p.NUM_CARTAO
        WHERE p.ID_EVENTO = :id
        ORDER BY p.DATA_INSCRICAO`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error(`\x1b[31m[EVENTOS GET /${req.params.id}/participacoes] ERRO ao listar participações\x1b[0m`);
    console.error('     BD: PARTICIPACAO_EVENTO + LEITOR');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/:id/participacoes', async (req, res) => {
  const { num_cartao, presenca_confirmacao } = req.body;
  if (!num_cartao) return res.status(400).json({ erro: 'Número de cartão obrigatório.' });

  let conn;
  try {
    conn = await getConnection();

    // 1. Verificar que o evento existe e não passou
    const eventoResult = await conn.execute(
      `SELECT DATA_EVENTO, PUBLICO_ALVO, COD_BIBLIOTECA FROM EVENTO WHERE ID_EVENTO = :id`,
      { id: parseInt(req.params.id) },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (eventoResult.rows.length === 0)
      return res.status(404).json({ erro: 'Evento não encontrado.' });

    const evento = eventoResult.rows[0];
    if (new Date(evento.DATA_EVENTO) < new Date()) {
      return res.status(409).json({ erro: 'Não é possível inscrever em evento já passado.' });
    }

    // 2. Verificar inscrição duplicada
    const dupResult = await conn.execute(
      `SELECT COUNT(*) AS N FROM PARTICIPACAO_EVENTO WHERE ID_EVENTO = :id AND NUM_CARTAO = :nc`,
      { id: parseInt(req.params.id), nc: num_cartao },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (dupResult.rows[0].N > 0) {
      return res.status(409).json({ erro: 'Leitor já inscrito neste evento.' });
    }

    // 3. Verificar público-alvo vs tipo de leitor
    if (evento.PUBLICO_ALVO && evento.PUBLICO_ALVO !== 'Todas as Idades') {
      const leitorResult = await conn.execute(
        `SELECT CASE WHEN p.NUM_CARTAO IS NOT NULL THEN 'PROFESSOR'
                     WHEN a.NUM_CARTAO IS NOT NULL THEN 'ADULTO'
                     WHEN cr.NUM_CARTAO IS NOT NULL THEN 'CRIANCA'
                     ELSE 'ADULTO' END AS TIPO_LEITOR
         FROM LEITOR l
         LEFT JOIN PROFESSOR p  ON p.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN ADULTO    a  ON a.NUM_CARTAO  = l.NUM_CARTAO
         LEFT JOIN CRIANCA   cr ON cr.NUM_CARTAO = l.NUM_CARTAO
         WHERE l.NUM_CARTAO = :nc`,
        { nc: num_cartao },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      if (leitorResult.rows.length === 0)
        return res.status(404).json({ erro: 'Leitor não encontrado.' });

      const tipo = leitorResult.rows[0].TIPO_LEITOR;
      const pub = evento.PUBLICO_ALVO;
      if (pub === 'Infantil' && tipo !== 'CRIANCA')
        return res.status(409).json({ erro: 'Este evento é destinado a crianças.' });
      if (pub === 'Adulto' && tipo === 'CRIANCA')
        return res.status(409).json({ erro: 'Este evento é destinado a adultos.' });
      if (pub === 'Professores' && tipo !== 'PROFESSOR')
        return res.status(409).json({ erro: 'Este evento é destinado a professores.' });
    }

    // 4. Chamar procedure (que ainda verifica duplicado como barreira de segurança na BD)
    await conn.execute(
      `BEGIN insere_participacao_evento(:nc, :id_ev, :presenca); END;`,
      { nc: num_cartao, id_ev: parseInt(req.params.id), presenca: presenca_confirmacao || 'N' }
    );
    await conn.commit();
    res.status(201).json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[EVENTOS POST /${req.params.id}/participacoes] ERRO ao inscrever participante\x1b[0m`);
    console.error('     BD: EVENTO + PARTICIPACAO_EVENTO + PROCEDURE insere_participacao_evento');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.delete('/:id/participacoes/:numCartao', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    await conn.execute(
      `DELETE FROM PARTICIPACAO_EVENTO WHERE ID_EVENTO = :id AND NUM_CARTAO = :nc`,
      { id: req.params.id, nc: req.params.numCartao }
    );
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[EVENTOS DELETE /${req.params.id}/participacoes/${req.params.numCartao}] ERRO ao remover participante\x1b[0m`);
    console.error('     BD: DELETE PARTICIPACAO_EVENTO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/:id/avaliacoes', async (req, res) => {
  const { num_cartao, nota, comentario } = req.body;
  if (!num_cartao || nota == null)
    return res.status(400).json({ erro: 'num_cartao e nota obrigatórios.' });
  if (nota < 1 || nota > 5)
    return res.status(400).json({ erro: 'Nota deve ser entre 1 e 5.' });

  let conn;
  try {
    conn = await getConnection();

    // 1. Verificar que o evento foi realizado
    const eventoResult = await conn.execute(
      `SELECT STATUS_EVENTO FROM EVENTO WHERE ID_EVENTO = :id`,
      { id: parseInt(req.params.id) },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (eventoResult.rows.length === 0)
      return res.status(404).json({ erro: 'Evento não encontrado.' });
    if (eventoResult.rows[0].STATUS_EVENTO !== 'Realizado')
      return res.status(409).json({ erro: 'Só é possível avaliar eventos com estado "Realizado".' });

    // 2. Verificar presença confirmada
    const presResult = await conn.execute(
      `SELECT PRESENCA_CONFIRMACAO FROM PARTICIPACAO_EVENTO
       WHERE ID_EVENTO = :id AND NUM_CARTAO = :nc`,
      { id: parseInt(req.params.id), nc: num_cartao },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (presResult.rows.length === 0)
      return res.status(409).json({ erro: 'Leitor não está inscrito neste evento.' });
    if (presResult.rows[0].PRESENCA_CONFIRMACAO !== 'S')
      return res.status(409).json({ erro: 'Presença não confirmada — não é possível avaliar.' });

    // 3. Verificar avaliação duplicada
    const dupResult = await conn.execute(
      `SELECT COUNT(*) AS N FROM AVALIACAO_EVENTO WHERE ID_EVENTO = :id AND NUM_CARTAO = :nc`,
      { id: parseInt(req.params.id), nc: num_cartao },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    if (dupResult.rows[0].N > 0)
      return res.status(409).json({ erro: 'Leitor já avaliou este evento.' });

    // 4. Inserir avaliação
    await conn.execute(
      `INSERT INTO AVALIACAO_EVENTO (ID_AVALIACAO, ID_EVENTO, NUM_CARTAO, NOTA, COMENTARIO, DATA_AVALIACAO)
       VALUES (SEQ_AVALIACAO.NEXTVAL, :id_ev, :nc, :nota, :coment, SYSDATE)`,
      { id_ev: parseInt(req.params.id), nc: num_cartao,
        nota: parseInt(nota), coment: comentario || null }
    );
    await conn.commit();
    res.status(201).json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[EVENTOS POST /${req.params.id}/avaliacoes] ERRO ao registar avaliação\x1b[0m`);
    console.error('     BD: EVENTO + PARTICIPACAO_EVENTO + INSERT AVALIACAO_EVENTO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
