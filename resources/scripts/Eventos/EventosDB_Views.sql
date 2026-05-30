-- ============================================
-- VISTAS DE FRAGMENTO - EventosBibliotecasDB (v4)
-- ============================================
CREATE VIEW frag_evento_sul AS
    SELECT e.*
    FROM EVENTO e
    WHERE e.cod_biblioteca IN (
        SELECT cod_biblioteca FROM BIBLIOTECA
        WHERE provincia = 'Maputo Cidade'
           OR provincia = 'Maputo Provincia'
    );

CREATE VIEW frag_evento_centro AS
    SELECT e.*
    FROM EVENTO e
    WHERE e.cod_biblioteca IN (
        SELECT cod_biblioteca FROM BIBLIOTECA
        WHERE provincia IN ('Sofala','Manica','Tete','Zambezia')
    );

CREATE VIEW frag_evento_norte AS
    SELECT e.*
    FROM EVENTO e
    WHERE e.cod_biblioteca IN (
        SELECT cod_biblioteca FROM BIBLIOTECA
        WHERE provincia IN ('Nampula','Cabo Delgado','Niassa')
    );

CREATE VIEW v_evento_global AS
    SELECT * FROM frag_evento_sul
    UNION ALL
    SELECT * FROM frag_evento_centro
    UNION ALL
    SELECT * FROM frag_evento_norte;

-- ============================================
-- VISTAS DE SERVICO - EventosBibliotecasDB (v4)
-- ============================================
CREATE VIEW v_programacao_eventos AS
    SELECT e.id_evento, e.titulo_evento, e.status_evento,
           e.publico_alvo, e.local_evento, e.recorrente,
           b.nome_biblioteca, b.provincia,
           h.dia_semana, h.data_ocorrencia,
           h.hora_inicio, h.hora_fim
    FROM EVENTO e
    JOIN BIBLIOTECA b ON e.cod_biblioteca = b.cod_biblioteca
    LEFT JOIN HORARIO_EVENTO h ON e.id_evento = h.id_evento;

CREATE VIEW v_horarios_bibliotecas AS
    SELECT b.cod_biblioteca, b.nome_biblioteca,
           b.provincia, b.endereco,
           h.dia_semana, h.hora_abertura, h.hora_fecho
    FROM BIBLIOTECA b
    JOIN HORARIO_BIBLIOTECA h ON b.cod_biblioteca = h.cod_biblioteca;

CREATE VIEW v_bibliotecas_activas AS
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

-- A1 — Fragmento de eventos futuros
CREATE OR REPLACE VIEW vw_frag_evento_futuro AS
    SELECT * FROM EVENTO
    WHERE data_evento >= SYSDATE;

-- A1 — Fragmento de eventos passados
CREATE OR REPLACE VIEW vw_frag_evento_passado AS
    SELECT * FROM EVENTO
    WHERE data_evento < SYSDATE;

-- A2 — Fragmento derivado: participacoes em eventos futuros
CREATE OR REPLACE VIEW vw_frag_participacao_futuro AS
    SELECT pe.*
    FROM PARTICIPACAO_EVENTO pe
    WHERE EXISTS (
        SELECT 1
        FROM vw_frag_evento_futuro ef
        WHERE ef.id_evento = pe.id_evento
    );

-- A2 — Fragmento derivado: participacoes em eventos passados
CREATE OR REPLACE VIEW vw_frag_participacao_passado AS
    SELECT pe.*
    FROM PARTICIPACAO_EVENTO pe
    WHERE EXISTS (
        SELECT 1
        FROM vw_frag_evento_passado ep
        WHERE ep.id_evento = pe.id_evento
    );

-- Verificar
SELECT VIEW_NAME FROM USER_VIEWS ORDER BY VIEW_NAME;