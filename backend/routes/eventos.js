const express = require('express');
const router = express.Router();
const { getConnection, oracledb } = require('../db');
const { autenticar, exigirNivel } = require('../middleware/permissoes');

const DIAS_PT = ['Domingo','Segunda','Terca','Quarta','Quinta','Sexta','Sabado'];

router.get('/', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const { proximos, biblioteca, status } = req.query;

    if (proximos === '1') {
      const result = await conn.execute(
        `SELECT ID_EVENTO,
                TITULO_EVENTO   AS NOME,
                DATA_EVENTO     AS DATA_INICIO,
                BIBLIOTECA_NOME AS NOME_BIBLIOTECA
           FROM vw_eventos_proximos ORDER BY DATA_EVENTO`,
        [], { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      return res.json(result.rows);
    }

    const binds = {};
    const conditions = [];
    if (biblioteca) { conditions.push('e.COD_BIBLIOTECA = :biblioteca'); binds.biblioteca = biblioteca; }
    if (status)     { conditions.push('e.STATUS_EVENTO = :status');      binds.status = status; }
    const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';

    const result = await conn.execute(
      `SELECT e.ID_EVENTO,
              e.TITULO_EVENTO  AS NOME,
              e.DATA_EVENTO    AS DATA_INICIO,
              e.LOCAL_EVENTO, e.CAPACIDADE,
              e.DESCRICAO_EVENTO, e.PUBLICO_ALVO, e.RECORRENTE,
              e.STATUS_EVENTO, e.COD_BIBLIOTECA,
              b.NOME_BIBLIOTECA,
              (SELECT COUNT(*) FROM PARTICIPACAO_EVENTO p WHERE p.ID_EVENTO = e.ID_EVENTO) AS INSCRITOS
         FROM EVENTO e
         LEFT JOIN BIBLIOTECA b ON b.COD_BIBLIOTECA = e.COD_BIBLIOTECA
         ${where}
        ORDER BY e.DATA_EVENTO DESC`,
      binds, { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[EVENTOS GET /] ERRO ao listar eventos\x1b[0m');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/:id', autenticar, async (req, res) => {
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
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  const {
    titulo_evento, descricao_evento, local_evento,
    data_evento, publico_alvo, capacidade, recorrente,
    cod_biblioteca, horarios, recursos
  } = req.body;

  if (!titulo_evento || !data_evento || !publico_alvo || !cod_biblioteca) {
    return res.status(400).json({ erro: 'titulo_evento, data_evento, publico_alvo e cod_biblioteca obrigatórios.' });
  }

  let conn;
  try {
    conn = await getConnection();

    // RN07: verificar horário da biblioteca para o dia do evento
    const diaSemana = DIAS_PT[new Date(data_evento).getDay()];
    const schedResult = await conn.execute(
      `SELECT COUNT(*) AS TOTAL,
              SUM(CASE WHEN DIA_SEMANA = :dia THEN 1 ELSE 0 END) AS NESTE_DIA
         FROM HORARIO_BIBLIOTECA
        WHERE COD_BIBLIOTECA = :cod_bib`,
      { dia: diaSemana, cod_bib: cod_biblioteca },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const sched = schedResult.rows[0];
    if (sched.TOTAL > 0 && (sched.NESTE_DIA === 0 || sched.NESTE_DIA === null)) {
      return res.status(409).json({ erro: `Biblioteca não tem horário definido para ${diaSemana}.` });
    }

    const result = await conn.execute(
      `INSERT INTO EVENTO
         (ID_EVENTO, TITULO_EVENTO, DESCRICAO_EVENTO, LOCAL_EVENTO, DATA_EVENTO,
          PUBLICO_ALVO, CAPACIDADE, STATUS_EVENTO, RECORRENTE, COD_BIBLIOTECA)
       VALUES
         (SEQ_EVENTO.NEXTVAL, :titulo, :desc, :local, TO_DATE(:data,'YYYY-MM-DD'),
          :pub_alvo, :cap, 'Planeado', NVL(:rec,'N'), :cod_bib)
       RETURNING ID_EVENTO INTO :id_out`,
      {
        titulo: titulo_evento, desc: descricao_evento || null, local: local_evento || null,
        data: data_evento, pub_alvo: publico_alvo, cap: capacidade || null,
        rec: recorrente || 'N', cod_bib: cod_biblioteca,
        id_out: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      }
    );
    const idEvento = result.outBinds.id_out[0];

    // Inserir horários do evento
    if (Array.isArray(horarios) && horarios.length > 0) {
      const maxRes = await conn.execute(
        `SELECT NVL(MAX(ID_HORARIO_EV),0) AS M FROM HORARIO_EVENTO`,
        [], { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      let nextId = maxRes.rows[0].M + 1;
      for (const h of horarios) {
        await conn.execute(
          `INSERT INTO HORARIO_EVENTO
             (ID_HORARIO_EV, ID_EVENTO, DIA_SEMANA, DATA_OCORRENCIA, HORA_INICIO, HORA_FIM)
           VALUES (:id, :ev, :dia, TO_DATE(:data,'YYYY-MM-DD'), :inicio, :fim)`,
          { id: nextId++, ev: idEvento, dia: h.dia_semana,
            data: h.data_ocorrencia, inicio: h.hora_inicio, fim: h.hora_fim }
        );
      }
    }

    // Inserir recursos do evento
    if (Array.isArray(recursos) && recursos.length > 0) {
      const maxRes = await conn.execute(
        `SELECT NVL(MAX(ID_RECURSO),0) AS M FROM EVENTO_RECURSO`,
        [], { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      let nextId = maxRes.rows[0].M + 1;
      for (const r of recursos) {
        await conn.execute(
          `INSERT INTO EVENTO_RECURSO (ID_RECURSO, ID_EVENTO, NOME_RECURSO, QUANTIDADE)
           VALUES (:id, :ev, :nome, :qtd)`,
          { id: nextId++, ev: idEvento, nome: r.nome_recurso, qtd: r.quantidade }
        );
      }
    }

    await conn.commit();
    res.status(201).json({ ok: true, id_evento: idEvento });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[EVENTOS POST /] ERRO ao criar evento\x1b[0m');
    console.error('     BD: HORARIO_BIBLIOTECA + INSERT EVENTO + HORARIO_EVENTO + EVENTO_RECURSO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.put('/:id', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  const { titulo_evento, descricao_evento, local_evento, data_evento, publico_alvo, capacidade, recorrente, cod_biblioteca } = req.body;
  let conn;
  try {
    conn = await getConnection();
    await conn.execute(
      `UPDATE EVENTO SET
         TITULO_EVENTO    = NVL(:titulo, TITULO_EVENTO),
         DESCRICAO_EVENTO = NVL(:desc, DESCRICAO_EVENTO),
         LOCAL_EVENTO     = NVL(:local, LOCAL_EVENTO),
         DATA_EVENTO      = NVL(TO_DATE(:data,'YYYY-MM-DD'), DATA_EVENTO),
         PUBLICO_ALVO     = NVL(:pub_alvo, PUBLICO_ALVO),
         CAPACIDADE       = NVL(:cap, CAPACIDADE),
         RECORRENTE       = NVL(:rec, RECORRENTE),
         COD_BIBLIOTECA   = NVL(:cod_bib, COD_BIBLIOTECA)
       WHERE ID_EVENTO = :id`,
      { titulo: titulo_evento || null, desc: descricao_evento || null, local: local_evento || null,
        data: data_evento || null, pub_alvo: publico_alvo || null, cap: capacidade || null,
        rec: recorrente !== undefined ? recorrente : null,
        cod_bib: cod_biblioteca || null, id: req.params.id }
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

router.patch('/:id/status', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
  const { status_evento } = req.body;
  if (!status_evento) return res.status(400).json({ erro: 'status_evento obrigatório.' });
  const statusValidos = ['Planeado', 'Realizado', 'Cancelado'];
  if (!statusValidos.includes(status_evento)) {
    return res.status(400).json({ erro: `Status inválido. Valores aceites: ${statusValidos.join(', ')}.` });
  }
  let conn;
  try {
    conn = await getConnection();
    const upd = await conn.execute(
      `UPDATE EVENTO SET STATUS_EVENTO = :status WHERE ID_EVENTO = :id`,
      { status: status_evento, id: req.params.id }
    );
    if (upd.rowsAffected === 0) return res.status(404).json({ erro: 'Evento não encontrado.' });
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[EVENTOS PATCH /${req.params.id}/status] ERRO ao actualizar status\x1b[0m`);
    console.error('     BD: UPDATE EVENTO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.delete('/:id', exigirNivel('Administrador', 'Coordenador', 'Bibliotecario'), async (req, res) => {
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

router.get('/:id/participantes', autenticar, async (req, res) => {
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
    console.error(`\x1b[31m[EVENTOS GET /${req.params.id}/participantes] ERRO ao listar participantes\x1b[0m`);
    console.error('     BD: PARTICIPACAO_EVENTO + LEITOR');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/:id/participantes', autenticar, async (req, res) => {
  const { num_cartao, presenca_confirmacao } = req.body;
  if (!num_cartao) return res.status(400).json({ erro: 'Número de cartão obrigatório.' });

  let conn;
  try {
    conn = await getConnection();

    // 1. Verificar que o evento existe e não passou
    const eventoResult = await conn.execute(
      `SELECT DATA_EVENTO, PUBLICO_ALVO, COD_BIBLIOTECA, CAPACIDADE FROM EVENTO WHERE ID_EVENTO = :id`,
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

    // 2b. Verificar capacidade do evento
    if (evento.CAPACIDADE != null) {
      const capResult = await conn.execute(
        `SELECT COUNT(*) AS N FROM PARTICIPACAO_EVENTO WHERE ID_EVENTO = :id`,
        { id: parseInt(req.params.id) },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      if (capResult.rows[0].N >= evento.CAPACIDADE) {
        return res.status(409).json({ erro: `Evento sem vagas disponíveis (capacidade: ${evento.CAPACIDADE}).` });
      }
    }

    // 3. Verificar público-alvo vs tipo de leitor
    if (evento.PUBLICO_ALVO && evento.PUBLICO_ALVO !== 'Todos') {
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
    }

    // 4. Chamar procedure
    await conn.execute(
      `BEGIN insere_participacao_evento(:nc, :id_ev, :presenca); END;`,
      { nc: num_cartao, id_ev: parseInt(req.params.id), presenca: presenca_confirmacao || 'N' }
    );
    await conn.commit();
    res.status(201).json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[EVENTOS POST /${req.params.id}/participantes] ERRO ao inscrever participante\x1b[0m`);
    console.error('     BD: EVENTO + PARTICIPACAO_EVENTO + PROCEDURE insere_participacao_evento');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.delete('/:id/participantes/:num_cartao', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    await conn.execute(
      `DELETE FROM PARTICIPACAO_EVENTO WHERE ID_EVENTO = :id AND NUM_CARTAO = :nc`,
      { id: req.params.id, nc: req.params.num_cartao }
    );
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[EVENTOS DELETE /${req.params.id}/participantes/${req.params.num_cartao}] ERRO ao remover participante\x1b[0m`);
    console.error('     BD: DELETE PARTICIPACAO_EVENTO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.post('/:id/avaliacoes', autenticar, async (req, res) => {
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

router.get('/:id/horarios', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT ID_HORARIO_EV, DIA_SEMANA,
              TO_CHAR(DATA_OCORRENCIA,'YYYY-MM-DD') AS DATA_OCORRENCIA,
              HORA_INICIO, HORA_FIM
         FROM HORARIO_EVENTO
        WHERE ID_EVENTO = :id
        ORDER BY DATA_OCORRENCIA, HORA_INICIO`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error(`\x1b[31m[EVENTOS GET /${req.params.id}/horarios] ERRO\x1b[0m`);
    console.error('     BD: HORARIO_EVENTO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.get('/:id/avaliacoes', autenticar, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT av.ID_AVALIACAO, av.NUM_CARTAO, av.NOTA, av.COMENTARIO,
              TO_CHAR(av.DATA_AVALIACAO,'YYYY-MM-DD') AS DATA_AVALIACAO,
              l.NOME_COMPLETO AS NOME_LEITOR
         FROM AVALIACAO_EVENTO av
         JOIN LEITOR l ON l.NUM_CARTAO = av.NUM_CARTAO
        WHERE av.ID_EVENTO = :id
        ORDER BY av.DATA_AVALIACAO DESC`,
      { id: req.params.id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows);
  } catch (err) {
    console.error(`\x1b[31m[EVENTOS GET /${req.params.id}/avaliacoes] ERRO\x1b[0m`);
    console.error('     BD: AVALIACAO_EVENTO + LEITOR');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

router.patch('/:id/participantes/:num_cartao/presenca', autenticar, async (req, res) => {
  const { presenca } = req.body;
  if (!presenca || !['S', 'N'].includes(presenca))
    return res.status(400).json({ erro: 'presenca deve ser "S" ou "N".' });
  let conn;
  try {
    conn = await getConnection();
    const upd = await conn.execute(
      `UPDATE PARTICIPACAO_EVENTO
          SET PRESENCA_CONFIRMACAO = :presenca
        WHERE ID_EVENTO = :id AND NUM_CARTAO = :nc`,
      { presenca, id: req.params.id, nc: req.params.num_cartao }
    );
    if (upd.rowsAffected === 0)
      return res.status(404).json({ erro: 'Inscrição não encontrada.' });
    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(`\x1b[31m[EVENTOS PATCH /${req.params.id}/participantes/${req.params.num_cartao}/presenca] ERRO\x1b[0m`);
    console.error('     BD: UPDATE PARTICIPACAO_EVENTO');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
