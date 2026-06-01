-- ============================================
-- VISTAS DE FRAGMENTO - EventosBibliotecasDB (v4)
-- ============================================
CREATE OR REPLACE VIEW frag_evento_sul AS
    SELECT e.*
    FROM EVENTO e
    WHERE e.cod_biblioteca IN (
        SELECT cod_biblioteca FROM BIBLIOTECA
        WHERE provincia = 'Maputo Cidade'
           OR provincia = 'Maputo Provincia'
    );

CREATE OR REPLACE VIEW frag_evento_centro AS
    SELECT e.*
    FROM EVENTO e
    WHERE e.cod_biblioteca IN (
        SELECT cod_biblioteca FROM BIBLIOTECA
        WHERE provincia IN ('Sofala','Manica','Tete','Zambezia')
    );

CREATE OR REPLACE VIEW frag_evento_norte AS
    SELECT e.*
    FROM EVENTO e
    WHERE e.cod_biblioteca IN (
        SELECT cod_biblioteca FROM BIBLIOTECA
        WHERE provincia IN ('Nampula','Cabo Delgado','Niassa')
    );

CREATE OR REPLACE VIEW v_evento_global AS
    SELECT * FROM frag_evento_sul
    UNION ALL
    SELECT * FROM frag_evento_centro
    UNION ALL
    SELECT * FROM frag_evento_norte;

-- ============================================
-- VISTAS DE SERVICO - EventosBibliotecasDB (v4)
-- ============================================
CREATE OR REPLACE VIEW v_programacao_eventos AS
    SELECT e.id_evento, e.titulo_evento, e.status_evento,
           e.publico_alvo, e.local_evento, e.recorrente,
           b.nome_biblioteca, b.provincia,
           h.dia_semana, h.data_ocorrencia,
           h.hora_inicio, h.hora_fim
    FROM EVENTO e
    JOIN BIBLIOTECA b ON e.cod_biblioteca = b.cod_biblioteca
    LEFT JOIN HORARIO_EVENTO h ON e.id_evento = h.id_evento;

CREATE OR REPLACE VIEW v_horarios_bibliotecas AS
    SELECT b.cod_biblioteca, b.nome_biblioteca,
           b.provincia, b.endereco,
           h.dia_semana, h.hora_abertura, h.hora_fecho
    FROM BIBLIOTECA b
    JOIN HORARIO_BIBLIOTECA h ON b.cod_biblioteca = h.cod_biblioteca;

CREATE OR REPLACE VIEW v_bibliotecas_activas AS
    SELECT cod_biblioteca, nome_biblioteca,
           endereco, provincia, contacto_biblioteca
    FROM BIBLIOTECA;

-- ============================================================
-- VISTAS DE SERVICO PARA O BACKEND
-- ============================================================

-- vw_eventos_proximos
-- Usada pelo backend: GET /api/eventos?proximos=1
CREATE OR REPLACE VIEW vw_eventos_proximos AS
SELECT
    e.id_evento,
    e.titulo_evento,
    e.descricao_evento,
    e.data_evento,
    b.nome_biblioteca AS biblioteca_nome
FROM EVENTO e
JOIN BIBLIOTECA b ON e.cod_biblioteca = b.cod_biblioteca
WHERE e.data_evento >= SYSDATE;

-- vw_eventos_completos
-- Usada pelo backend: GET /api/eventos/:id
-- NOTA: usa repl_funcionarios (snapshot local do BibliotecaNacionalDB)
--       em vez de FUNCIONARIO (que e' cross-node e nao existe localmente).
--       Se o snapshot ainda nao foi criado (Helder offline), o LEFT JOIN
--       devolve NULL para cod_funcionario e nome_responsavel sem erros.
CREATE OR REPLACE VIEW vw_eventos_completos AS
SELECT
    e.id_evento,
    e.titulo_evento,
    e.descricao_evento,
    e.local_evento,
    e.publico_alvo,
    e.data_evento,
    e.capacidade,
    e.status_evento,
    e.recorrente,
    b.cod_biblioteca,
    b.nome_biblioteca,
    f.cod_funcionario,
    f.nome_funcionario AS nome_responsavel,
    COUNT(pe.num_cartao) AS total_inscritos,
    ROUND(AVG(av.nota), 1) AS media_avaliacao
FROM EVENTO e
JOIN BIBLIOTECA b ON e.cod_biblioteca = b.cod_biblioteca
LEFT JOIN repl_funcionarios f ON e.cod_funcionario_responsavel = f.cod_funcionario
LEFT JOIN PARTICIPACAO_EVENTO pe ON e.id_evento = pe.id_evento
LEFT JOIN AVALIACAO_EVENTO av ON e.id_evento = av.id_evento
GROUP BY
    e.id_evento, e.titulo_evento, e.descricao_evento, e.local_evento,
    e.publico_alvo, e.data_evento, e.capacidade, e.status_evento, e.recorrente,
    b.cod_biblioteca, b.nome_biblioteca, f.cod_funcionario, f.nome_funcionario;

-- ============================================================
-- FRAGMENTACAO HORIZONTAL (A1 + A2)
-- A1: Fragmento temporal de EVENTO (futuros vs passados)
-- A2: Fragmentacao derivada de PARTICIPACAO_EVENTO
-- ============================================================

-- A1 � Fragmento de eventos futuros
CREATE OR REPLACE VIEW vw_frag_evento_futuro AS
    SELECT * FROM EVENTO
    WHERE data_evento >= SYSDATE;

-- A1 � Fragmento de eventos passados
CREATE OR REPLACE VIEW vw_frag_evento_passado AS
    SELECT * FROM EVENTO
    WHERE data_evento < SYSDATE;

-- A2 � Fragmento derivado: participacoes em eventos futuros
CREATE OR REPLACE VIEW vw_frag_participacao_futuro AS
    SELECT pe.*
    FROM PARTICIPACAO_EVENTO pe
    WHERE EXISTS (
        SELECT 1
        FROM vw_frag_evento_futuro ef
        WHERE ef.id_evento = pe.id_evento
    );

-- A2 � Fragmento derivado: participacoes em eventos passados
CREATE OR REPLACE VIEW vw_frag_participacao_passado AS
    SELECT pe.*
    FROM PARTICIPACAO_EVENTO pe
    WHERE EXISTS (
        SELECT 1
        FROM vw_frag_evento_passado ep
        WHERE ep.id_evento = pe.id_evento
    );

-- ============================================================
-- VISTAS PARA O BACKEND
-- BIBLIOTECA e HORARIO_BIBLIOTECA sao locais neste no.
-- FUNCIONARIO usa sinónimo → repl_funcionarios (MV local, resiliente).
-- snap_leitor referenciado directamente (sem sinónimo LEITOR neste no).
-- ============================================================

-- Horários de abertura/fecho de cada biblioteca (100% local)
CREATE OR REPLACE VIEW vw_horarios_biblioteca_semana AS
SELECT
    b.cod_biblioteca,
    b.nome_biblioteca,
    h.dia_semana,
    h.hora_abertura,
    h.hora_fecho
FROM BIBLIOTECA b
LEFT JOIN HORARIO_BIBLIOTECA h ON b.cod_biblioteca = h.cod_biblioteca;
/

-- Participações em eventos com dados do leitor (snap_leitor é MV local)
CREATE OR REPLACE VIEW vw_participacoes_eventos AS
SELECT
    e.id_evento,
    e.titulo_evento,
    e.data_evento,
    b.nome_biblioteca AS biblioteca_nome,
    l.num_cartao,
    l.nome_completo   AS nome_leitor,
    p.data_inscricao,
    p.presenca_confirmacao AS presenca_confirmada,
    e.publico_alvo,
    e.recorrente
FROM PARTICIPACAO_EVENTO p
JOIN EVENTO e ON p.id_evento = e.id_evento
LEFT JOIN BIBLIOTECA b ON e.cod_biblioteca = b.cod_biblioteca
LEFT JOIN snap_leitor l ON p.num_cartao = l.num_cartao;
/

-- Dados operacionais de cada biblioteca com coordenador responsável
CREATE OR REPLACE VIEW vw_bibliotecas_operacionais AS
SELECT
    b.cod_biblioteca,
    b.nome_biblioteca,
    b.provincia,
    b.endereco,
    f.nome_funcionario AS coordenador_nome,
    f.contacto         AS coordenador_contacto
FROM BIBLIOTECA b
LEFT JOIN BIBLIOTECA_RESPONSAVEL br
    ON b.cod_biblioteca = br.cod_biblioteca
   AND br.papel = 'Principal'
   AND br.data_fim IS NULL
LEFT JOIN repl_funcionarios f ON br.cod_funcionario = f.cod_funcionario;
/

-- ============================================================
-- VISTA DE AUDITORIA
-- Padrao identico ao EmprestimosDB, MateriaisDB e BibliotecaNacionalDB.
-- Acedida pelo backend via sinonimo publico VW_AUDITORIA.
-- ============================================================
CREATE OR REPLACE VIEW VW_AUDITORIA AS
SELECT
    id_auditoria,
    data_operacao,
    operacao,
    resultado,
    motivo_falha,
    nos_afetados,
    observacoes,
    'EVENTOS' AS no_origem
FROM AUDITORIA_EVENTOS;
/