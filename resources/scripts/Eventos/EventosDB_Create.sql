-- ============================================
-- TABELAS - EventosBibliotecasDB (v4)
-- ============================================

-- BIBLIOTECA
CREATE TABLE BIBLIOTECA (
    cod_biblioteca      VARCHAR2(10) NOT NULL,
    nome_biblioteca     VARCHAR2(100) NOT NULL,
    endereco            VARCHAR2(200),
    latitude            NUMBER(9,6),
    longitude           NUMBER(9,6),
    contacto_biblioteca VARCHAR2(50),
    data_inauguracao    DATE,
    capacidade          NUMBER(5),
    infraestrutura      VARCHAR2(500),
    servicos            VARCHAR2(500),
    provincia           VARCHAR2(17),
    CONSTRAINT pk_biblioteca PRIMARY KEY (cod_biblioteca),
    CONSTRAINT uq_nome_biblioteca UNIQUE (nome_biblioteca)
) TABLESPACE tbs_eventosdb;

-- HORARIO_BIBLIOTECA
CREATE TABLE HORARIO_BIBLIOTECA (
    id_horario_bib  NUMBER NOT NULL,
    cod_biblioteca  VARCHAR2(10) NOT NULL,
    dia_semana      VARCHAR2(13) NOT NULL,
    hora_abertura   VARCHAR2(5) NOT NULL,
    hora_fecho      VARCHAR2(5) NOT NULL,
    CONSTRAINT pk_horario_bib PRIMARY KEY (id_horario_bib),
    CONSTRAINT fk_hor_bib FOREIGN KEY (cod_biblioteca)
        REFERENCES BIBLIOTECA(cod_biblioteca) ON DELETE CASCADE,
    CONSTRAINT ck_horario_dia CHECK (dia_semana IN (
        'Segunda-feira','Terca-feira','Quarta-feira',
        'Quinta-feira','Sexta-feira','Sabado','Domingo'))
) TABLESPACE tbs_eventosdb;

-- BIBLIOTECA_RESPONSAVEL
CREATE TABLE BIBLIOTECA_RESPONSAVEL (
    cod_biblioteca  VARCHAR2(10) NOT NULL,
    cod_funcionario VARCHAR2(12) NOT NULL,
    data_inicio     DATE,
    data_fim        DATE,
    papel           VARCHAR2(12)
        CHECK (papel IN ('Principal','Substituto')),
    CONSTRAINT pk_bib_resp PRIMARY KEY (cod_biblioteca, cod_funcionario),
    CONSTRAINT fk_resp_bib FOREIGN KEY (cod_biblioteca)
        REFERENCES BIBLIOTECA(cod_biblioteca) ON DELETE CASCADE
    -- FK para FUNCIONARIO e' logica (cross-node, sem DDL formal)
) TABLESPACE tbs_eventosdb;

-- EVENTO
CREATE TABLE EVENTO (
    id_evento                    NUMBER NOT NULL,
    cod_biblioteca               VARCHAR2(10) NOT NULL,
    cod_funcionario_responsavel  VARCHAR2(12),
    titulo_evento                VARCHAR2(100) NOT NULL,
    descricao_evento             VARCHAR2(500),
    local_evento                 VARCHAR2(200),
    publico_alvo                 VARCHAR2(22)
        CHECK (publico_alvo IN ('Iniciantes','Intermedios','Avancados','Todos')),
    data_evento                  DATE,
    capacidade                   NUMBER(4),
    status_evento                VARCHAR2(10) DEFAULT 'Planeado'
        CHECK (status_evento IN ('Planeado','Realizado','Cancelado')),
    recorrente                   CHAR(1) DEFAULT 'N'
        CHECK (recorrente IN ('S','N')),
    CONSTRAINT pk_evento PRIMARY KEY (id_evento),
    CONSTRAINT fk_evento_bib FOREIGN KEY (cod_biblioteca)
        REFERENCES BIBLIOTECA(cod_biblioteca)
    -- FK cod_funcionario_responsavel e' logica (cross-node, sem DDL formal)
) TABLESPACE tbs_eventosdb;

-- HORARIO_EVENTO (substitui HORARIO_EV_BIB)
CREATE TABLE HORARIO_EVENTO (
    id_horario_ev   NUMBER NOT NULL,
    id_evento       NUMBER NOT NULL,
    dia_semana      VARCHAR2(13),
    data_ocorrencia DATE,
    hora_inicio     VARCHAR2(5) NOT NULL,
    hora_fim        VARCHAR2(5) NOT NULL,
    CONSTRAINT pk_hor_ev PRIMARY KEY (id_horario_ev),
    CONSTRAINT fk_hor_ev FOREIGN KEY (id_evento)
        REFERENCES EVENTO(id_evento) ON DELETE CASCADE
) TABLESPACE tbs_eventosdb;

-- PARTICIPACAO_EVENTO
CREATE TABLE PARTICIPACAO_EVENTO (
    num_cartao           VARCHAR2(12) NOT NULL,
    id_evento            NUMBER NOT NULL,
    data_inscricao       DATE,
    presenca_confirmacao CHAR(1) DEFAULT 'N'
        CHECK (presenca_confirmacao IN ('S','N')),
    CONSTRAINT pk_participacao PRIMARY KEY (num_cartao, id_evento),
    CONSTRAINT fk_part_evento FOREIGN KEY (id_evento)
        REFERENCES EVENTO(id_evento) ON DELETE CASCADE
    -- FK num_cartao -> LEITOR e' logica (cross-node, sem DDL formal)
) TABLESPACE tbs_eventosdb;

-- AVALIACAO_EVENTO
CREATE TABLE AVALIACAO_EVENTO (
    id_avaliacao   NUMBER NOT NULL,
    id_evento      NUMBER NOT NULL,
    num_cartao     VARCHAR2(12),
    nota           NUMBER(2) NOT NULL CHECK (nota BETWEEN 1 AND 5),
    comentario     VARCHAR2(300),
    data_avaliacao DATE,
    CONSTRAINT pk_avaliacao   PRIMARY KEY (id_avaliacao),
    CONSTRAINT fk_aval_evento FOREIGN KEY (id_evento)
        REFERENCES EVENTO(id_evento) ON DELETE CASCADE
    -- FK num_cartao -> LEITOR e' logica (cross-node, sem DDL formal)
) TABLESPACE tbs_eventosdb;

-- EVENTO_RECURSO
CREATE TABLE EVENTO_RECURSO (
    id_recurso   NUMBER NOT NULL,
    id_evento    NUMBER NOT NULL,
    nome_recurso VARCHAR2(100) NOT NULL,
    quantidade   NUMBER(4),
    CONSTRAINT pk_evento_rec PRIMARY KEY (id_recurso),
    CONSTRAINT fk_rec_evento FOREIGN KEY (id_evento)
        REFERENCES EVENTO(id_evento) ON DELETE CASCADE
) TABLESPACE tbs_eventosdb;

-- AUDITORIA_EVENTOS
CREATE TABLE AUDITORIA_EVENTOS (
    id_auditoria    NUMBER NOT NULL,
    data_operacao   DATE DEFAULT SYSDATE NOT NULL,
    operacao        VARCHAR2(50) NOT NULL,
    id_evento       NUMBER,
    cod_biblioteca  VARCHAR2(10),
    num_cartao      VARCHAR2(12),
    resultado       VARCHAR2(10) NOT NULL
        CHECK (resultado IN ('SUCESSO','FALHA')),
    motivo_falha    VARCHAR2(300),
    nos_afetados    VARCHAR2(200),
    observacoes     VARCHAR2(300),
    CONSTRAINT pk_auditoria_evt PRIMARY KEY (id_auditoria),
    CONSTRAINT chk_resultado_evt CHECK (resultado IN ('SUCESSO','FALHA'))
) TABLESPACE tbs_eventosdb;

-- Verificar
SELECT TABLE_NAME, TABLESPACE_NAME
FROM USER_TABLES
ORDER BY TABLE_NAME;