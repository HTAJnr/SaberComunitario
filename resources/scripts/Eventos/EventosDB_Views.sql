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

-- Verificar
SELECT VIEW_NAME FROM USER_VIEWS ORDER BY VIEW_NAME;
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
