const express = require('express');
const router  = express.Router();
const { getConnection, oracledb } = require('../db');
const { exigirNivel } = require('../middleware/permissoes');

// GET /api/transferencias?biblioteca=X&direcao=enviadas|recebidas|todas&estado=X
router.get('/', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    const nivel     = req.session.nivel_acesso || '';
    const sessBib   = req.session.cod_biblioteca || null;
    const { biblioteca, direcao, estado } = req.query;
    const page  = Math.max(1, parseInt(req.query.page)  || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 20);
    const offset = (page - 1) * limit;

    // Resolver biblioteca efectiva
    let bibEfectiva = null;
    if (nivel === 'Administrador') {
      bibEfectiva = biblioteca || null; // null = toda a rede
    } else {
      bibEfectiva = sessBib;
    }

    const binds = { rn_max: offset + limit, rn_min: offset };
    let whereClause = '';

    if (bibEfectiva) {
      const dir = direcao || 'todas';
      if (dir === 'enviadas') {
        whereClause += ' AND cod_biblioteca_origem = :lib';
      } else if (dir === 'recebidas') {
        whereClause += ' AND cod_biblioteca_destino = :lib';
      } else {
        whereClause += ' AND (cod_biblioteca_origem = :lib OR cod_biblioteca_destino = :lib)';
      }
      binds.lib = bibEfectiva;
    }

    if (estado) {
      whereClause += ' AND estado_transferencia = :estado';
      binds.estado = estado;
    }

    conn = await getConnection();
    const result = await conn.execute(
      `SELECT * FROM (
         SELECT t.*, ROWNUM AS RN FROM (
           SELECT id_transferencia, estado_transferencia, motivo,
                  data_solicitacao, data_aprovacao, data_conclusao, dias_pendente,
                  material_titulo, material_codigo, material_estado,
                  biblioteca_origem_nome, biblioteca_origem_localizacao,
                  biblioteca_destino_nome, biblioteca_destino_localizacao,
                  funcionario_solicitante_nome, contacto,
                  funcionario_aprovador_nome, funcionario_aprovador_contacto
             FROM vw_transferencias_detalhadas
            WHERE 1=1${whereClause}
            ORDER BY data_solicitacao DESC
         ) t WHERE ROWNUM <= :rn_max
       ) WHERE RN > :rn_min`,
      binds,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json(result.rows);
  } catch (err) {
    console.error('\x1b[31m[TRANSFERENCIAS GET /]\x1b[0m');
    console.error('     BD: vw_transferencias_detalhadas');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/transferencias — solicitar transferência
router.post('/', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    const cod_funcionario = req.session.cod_funcionario;

    if (cod_funcionario === 0) {
      return res.status(400).json({ erro: 'Utilizador demo não pode solicitar transferências.' });
    }

    const { cod_material, cod_biblioteca_destino, motivo } = req.body;

    if (!cod_material || !cod_biblioteca_destino) {
      return res.status(400).json({ erro: 'cod_material e cod_biblioteca_destino são obrigatórios.' });
    }

    conn = await getConnection();

    // Resolver biblioteca de origem a partir do material
    const matResult = await conn.execute(
      `SELECT COD_BIBLIOTECA FROM MATERIAL_BIBLIOGRAFICO WHERE COD_MATERIAL = :id`,
      { id: cod_material },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    if (matResult.rows.length === 0) {
      return res.status(404).json({ erro: 'Material não encontrado.' });
    }

    const cod_biblioteca_origem = matResult.rows[0].COD_BIBLIOTECA;

    if (cod_biblioteca_origem === cod_biblioteca_destino) {
      return res.status(409).json({ erro: 'Biblioteca de origem e destino são iguais.' });
    }

    await conn.execute(
      `INSERT INTO TRANSFERENCIA (
         id_transferencia, data_solicitacao, estado_transferencia,
         motivo, cod_material, cod_biblioteca_origem,
         cod_biblioteca_destino, cod_funcionario_solicitante
       ) VALUES (
         SEQ_TRANSFERENCIA.NEXTVAL, SYSDATE, 'Pendente',
         :motivo, :cod_mat, :cod_orig, :cod_dest, :cod_func
       )`,
      {
        motivo:   motivo || null,
        cod_mat:  cod_material,
        cod_orig: cod_biblioteca_origem,
        cod_dest: cod_biblioteca_destino,
        cod_func: cod_funcionario
      }
    );
    const curResult = await conn.execute(
      `SELECT SEQ_TRANSFERENCIA.CURRVAL AS ID FROM DUAL`,
      [], { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const newId = curResult.rows[0].ID;

    await conn.commit();

    res.status(201).json({
      ok: true,
      id_transferencia: newId
    });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[TRANSFERENCIAS POST /]\x1b[0m');
    console.error('     BD: TRANSFERENCIA INSERT');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /api/transferencias/:id/aprovar
router.patch('/:id/aprovar', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    const cod_funcionario = req.session.cod_funcionario;

    if (cod_funcionario === 0) {
      return res.status(400).json({ erro: 'Utilizador demo não pode aprovar transferências.' });
    }

    const id = parseInt(req.params.id);
    conn = await getConnection();

    const check = await conn.execute(
      `SELECT estado_transferencia FROM TRANSFERENCIA WHERE id_transferencia = :id`,
      { id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    if (check.rows.length === 0) {
      return res.status(404).json({ erro: 'Transferência não encontrada.' });
    }
    if (check.rows[0].ESTADO_TRANSFERENCIA !== 'Pendente') {
      return res.status(409).json({
        erro: 'Apenas transferências Pendentes podem ser aprovadas.',
        estado_atual: check.rows[0].ESTADO_TRANSFERENCIA
      });
    }

    await conn.execute(
      `UPDATE TRANSFERENCIA
          SET estado_transferencia      = 'Aprovada',
              data_aprovacao_destino    = SYSDATE,
              cod_funcionario_aprovador = :cod_func
        WHERE id_transferencia = :id`,
      { cod_func: cod_funcionario, id }
    );

    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[TRANSFERENCIAS PATCH /:id/aprovar]\x1b[0m');
    console.error('     BD: TRANSFERENCIA UPDATE');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /api/transferencias/:id/rejeitar
router.patch('/:id/rejeitar', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    const cod_funcionario = req.session.cod_funcionario;

    if (cod_funcionario === 0) {
      return res.status(400).json({ erro: 'Utilizador demo não pode rejeitar transferências.' });
    }

    const { motivo } = req.body;
    if (!motivo || !motivo.trim()) {
      return res.status(400).json({ erro: 'motivo é obrigatório para rejeição.' });
    }

    const id = parseInt(req.params.id);
    conn = await getConnection();

    const check = await conn.execute(
      `SELECT estado_transferencia FROM TRANSFERENCIA WHERE id_transferencia = :id`,
      { id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    if (check.rows.length === 0) {
      return res.status(404).json({ erro: 'Transferência não encontrada.' });
    }
    if (check.rows[0].ESTADO_TRANSFERENCIA !== 'Pendente') {
      return res.status(409).json({
        erro: 'Apenas transferências Pendentes podem ser rejeitadas.',
        estado_atual: check.rows[0].ESTADO_TRANSFERENCIA
      });
    }

    await conn.execute(
      `UPDATE TRANSFERENCIA
          SET estado_transferencia      = 'Rejeitada',
              motivo                    = :motivo,
              cod_funcionario_aprovador = :cod_func
        WHERE id_transferencia = :id`,
      { motivo, cod_func: cod_funcionario, id }
    );

    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[TRANSFERENCIAS PATCH /:id/rejeitar]\x1b[0m');
    console.error('     BD: TRANSFERENCIA UPDATE');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /api/transferencias/:id/concluir
router.patch('/:id/concluir', exigirNivel('Administrador', 'Coordenador'), async (req, res) => {
  let conn;
  try {
    const id = parseInt(req.params.id);
    conn = await getConnection();

    const check = await conn.execute(
      `SELECT estado_transferencia, cod_material, cod_biblioteca_destino
         FROM TRANSFERENCIA
        WHERE id_transferencia = :id`,
      { id },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    if (check.rows.length === 0) {
      return res.status(404).json({ erro: 'Transferência não encontrada.' });
    }
    if (check.rows[0].ESTADO_TRANSFERENCIA !== 'Aprovada') {
      return res.status(409).json({
        erro: 'Apenas transferências Aprovadas podem ser concluídas.',
        estado_atual: check.rows[0].ESTADO_TRANSFERENCIA
      });
    }

    const { COD_MATERIAL, COD_BIBLIOTECA_DESTINO } = check.rows[0];

    // Mover material para biblioteca de destino
    await conn.execute(
      `UPDATE MATERIAL_BIBLIOGRAFICO
          SET cod_biblioteca = :cod_dest
        WHERE cod_material   = :cod_mat`,
      { cod_dest: COD_BIBLIOTECA_DESTINO, cod_mat: COD_MATERIAL }
    );

    // Fechar transferência
    await conn.execute(
      `UPDATE TRANSFERENCIA
          SET estado_transferencia = 'Concluida',
              data_conclusao       = SYSDATE
        WHERE id_transferencia = :id`,
      { id }
    );

    await conn.commit();
    res.json({ ok: true });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('\x1b[31m[TRANSFERENCIAS PATCH /:id/concluir]\x1b[0m');
    console.error('     BD: MATERIAL_BIBLIOGRAFICO + TRANSFERENCIA UPDATE');
    console.error('     Detalhe:', err.message);
    res.status(500).json({ erro: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
