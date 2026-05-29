-- ============================================================
-- MateriaisDB_Create.sql — Criacao das tabelas do no MateriaisDB
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Tablespaces.sql
-- ============================================================


-- ============================================================
-- CATEGORIA
-- ============================================================
CREATE TABLE CATEGORIA (
    id_categoria  NUMBER              NOT NULL,
    area_tematica VARCHAR2(50 BYTE)   NOT NULL,
    faixa_etaria  VARCHAR2(17 BYTE)   NOT NULL,
    nivel_leitura VARCHAR2(12 BYTE)   NOT NULL
)
TABLESPACE tbs_MATERIAISDB;

ALTER TABLE CATEGORIA
    ADD CONSTRAINT CATEGORIA_PK PRIMARY KEY (id_categoria)
    USING INDEX TABLESPACE tbs_MATERIAISDB_idx;
ALTER TABLE CATEGORIA
    ADD CONSTRAINT chk_faixa_etaria
    CHECK (faixa_etaria IN ('Infantil','Juvenil','Adulto','Todas as Idades'));
ALTER TABLE CATEGORIA
    ADD CONSTRAINT chk_nivel_leitura
    CHECK (nivel_leitura IN ('Basico','Intermedio','Avancado'));


-- ============================================================
-- MATERIAL_BIBLIOGRAFICO
-- ============================================================
CREATE TABLE MATERIAL_BIBLIOGRAFICO (
    cod_material                VARCHAR2(12 BYTE)  NOT NULL,
    titulo                      VARCHAR2(200 BYTE) NOT NULL,
    autor                       VARCHAR2(200 BYTE) NOT NULL,
    editora                     VARCHAR2(80 BYTE)  NOT NULL,
    ano_publicacao              NUMBER(4)          NOT NULL,
    ISBN                        VARCHAR2(17 BYTE),
    idioma                      VARCHAR2(30 BYTE)  NOT NULL,
    num_paginas                 NUMBER(5)          NOT NULL,
    estado_material_conservacao VARCHAR2(13 BYTE)  NOT NULL,
    motivo_indisponibilidade    VARCHAR2(100 BYTE),
    origem_material             VARCHAR2(12 BYTE)  NOT NULL,
    data_aquisicao              DATE,
    valor_aquisicao             NUMBER(10,2),
    localizacao_estante         VARCHAR2(50 BYTE),
    cod_categoria               NUMBER             NOT NULL,
    cod_biblioteca              VARCHAR2(10 BYTE)  NOT NULL,
    id_itemDoado                NUMBER
)
TABLESPACE tbs_MATERIAISDB;

ALTER TABLE MATERIAL_BIBLIOGRAFICO
    ADD CONSTRAINT MATERIAL_BIBLIOGRAFICO_PK PRIMARY KEY (cod_material)
    USING INDEX TABLESPACE tbs_MATERIAISDB_idx;
ALTER TABLE MATERIAL_BIBLIOGRAFICO
    ADD CONSTRAINT chk_origem_material
    CHECK (origem_material IN ('Comprado','Doado','Transferido'));
ALTER TABLE MATERIAL_BIBLIOGRAFICO
    ADD CONSTRAINT chk_estado_conservacao
    CHECK (estado_material_conservacao IN ('Bom','Degradado','Indisponivel'));
ALTER TABLE MATERIAL_BIBLIOGRAFICO
    ADD CONSTRAINT chk_doado_item
    CHECK (origem_material != 'Doado' OR id_itemDoado IS NOT NULL);
ALTER TABLE MATERIAL_BIBLIOGRAFICO
    ADD CONSTRAINT chk_motivo_indisponivel
    CHECK (estado_material_conservacao != 'Indisponivel' OR motivo_indisponibilidade IS NOT NULL);
ALTER TABLE MATERIAL_BIBLIOGRAFICO ADD CONSTRAINT MB_CATEGORIA_FK
    FOREIGN KEY (cod_categoria) REFERENCES CATEGORIA (id_categoria);


-- ============================================================
-- LIVRO_FISICO
-- ============================================================
CREATE TABLE LIVRO_FISICO (
    cod_material VARCHAR2(12 BYTE) NOT NULL
)
TABLESPACE tbs_MATERIAISDB;

ALTER TABLE LIVRO_FISICO
    ADD CONSTRAINT LIVRO_FISICO_PK PRIMARY KEY (cod_material)
    USING INDEX TABLESPACE tbs_MATERIAISDB_idx;
ALTER TABLE LIVRO_FISICO ADD CONSTRAINT LF_MATERIAL_FK
    FOREIGN KEY (cod_material) REFERENCES MATERIAL_BIBLIOGRAFICO (cod_material) ON DELETE CASCADE;


-- ============================================================
-- EBOOK
-- ============================================================
CREATE TABLE EBOOK (
    cod_material    VARCHAR2(12 BYTE)  NOT NULL,
    formato         VARCHAR2(4 BYTE)   NOT NULL,
    tamanho_arquivo NUMBER(8,2),
    url_acesso      VARCHAR2(300 BYTE)
)
TABLESPACE tbs_MATERIAISDB;

ALTER TABLE EBOOK
    ADD CONSTRAINT EBOOK_PK PRIMARY KEY (cod_material)
    USING INDEX TABLESPACE tbs_MATERIAISDB_idx;
ALTER TABLE EBOOK
    ADD CONSTRAINT chk_url_formato
    CHECK (formato NOT IN ('PDF','EPUB','MOBI') OR url_acesso IS NOT NULL);
ALTER TABLE EBOOK ADD CONSTRAINT EB_MATERIAL_FK
    FOREIGN KEY (cod_material) REFERENCES MATERIAL_BIBLIOGRAFICO (cod_material) ON DELETE CASCADE;


-- ============================================================
-- PERIODICO
-- ============================================================
CREATE TABLE PERIODICO (
    cod_material    VARCHAR2(12 BYTE) NOT NULL,
    edicao          VARCHAR2(50 BYTE) NOT NULL,
    periodicidade   VARCHAR2(10 BYTE) NOT NULL,
    data_publicacao DATE              NOT NULL,
    ISSN            VARCHAR2(9 BYTE)
)
TABLESPACE tbs_MATERIAISDB;

ALTER TABLE PERIODICO
    ADD CONSTRAINT PERIODICO_PK PRIMARY KEY (cod_material)
    USING INDEX TABLESPACE tbs_MATERIAISDB_idx;
ALTER TABLE PERIODICO
    ADD CONSTRAINT chk_periodicidade
    CHECK (periodicidade IN ('Mensal','Trimestral','Anual'));
ALTER TABLE PERIODICO ADD CONSTRAINT PER_MATERIAL_FK
    FOREIGN KEY (cod_material) REFERENCES MATERIAL_BIBLIOGRAFICO (cod_material) ON DELETE CASCADE;


-- ============================================================
-- TRANSFERENCIA
-- ============================================================
CREATE TABLE TRANSFERENCIA (
    id_transferencia             NUMBER              NOT NULL,
    data_solicitacao             DATE                NOT NULL,
    data_aprovacao_destino       DATE,
    data_conclusao               DATE,
    motivo                       VARCHAR2(300 BYTE),
    estado_transferencia         VARCHAR2(10 BYTE)   NOT NULL,
    cod_material                 VARCHAR2(12 BYTE)   NOT NULL,
    cod_biblioteca_origem        VARCHAR2(10 BYTE)   NOT NULL,
    cod_biblioteca_destino       VARCHAR2(10 BYTE)   NOT NULL,
    cod_funcionario_solicitante  VARCHAR2(12 BYTE)   NOT NULL,
    cod_funcionario_aprovador    VARCHAR2(12 BYTE)
)
TABLESPACE tbs_MATERIAISDB;

ALTER TABLE TRANSFERENCIA
    ADD CONSTRAINT TRANSFERENCIA_PK PRIMARY KEY (id_transferencia)
    USING INDEX TABLESPACE tbs_MATERIAISDB_idx;
ALTER TABLE TRANSFERENCIA
    ADD CONSTRAINT chk_estado_transferencia
    CHECK (estado_transferencia IN ('Pendente','Aprovada','Rejeitada','Concluida'));
ALTER TABLE TRANSFERENCIA
    ADD CONSTRAINT chk_origem_destino
    CHECK (cod_biblioteca_origem <> cod_biblioteca_destino);
ALTER TABLE TRANSFERENCIA
    ADD CONSTRAINT chk_motivo_rejeitada
    CHECK (estado_transferencia != 'Rejeitada' OR motivo IS NOT NULL);
ALTER TABLE TRANSFERENCIA ADD CONSTRAINT TRANS_MATERIAL_FK
    FOREIGN KEY (cod_material) REFERENCES MATERIAL_BIBLIOGRAFICO (cod_material);


-- ============================================================
-- AUDITORIA_MATERIAIS
-- ============================================================
CREATE TABLE AUDITORIA_MATERIAIS (
    id_auditoria      NUMBER          NOT NULL,
    data_operacao     DATE            DEFAULT SYSDATE NOT NULL,
    operacao          VARCHAR2(50)    NOT NULL,
    cod_material      VARCHAR2(12),
    id_transferencia  NUMBER,
    estado_anterior   VARCHAR2(13),
    estado_novo       VARCHAR2(13),
    resultado         VARCHAR2(10)    NOT NULL,
    motivo_falha      VARCHAR2(300),
    nos_afetados      VARCHAR2(200),
    observacoes       VARCHAR2(300)
) TABLESPACE tbs_MATERIAISDB;

ALTER TABLE AUDITORIA_MATERIAIS
    ADD CONSTRAINT AUDITORIA_MAT_PK PRIMARY KEY (id_auditoria)
    USING INDEX TABLESPACE tbs_MATERIAISDB_idx;
ALTER TABLE AUDITORIA_MATERIAIS
    ADD CONSTRAINT chk_resultado_mat
    CHECK (resultado IN ('SUCESSO', 'FALHA'));


-- ============================================================
-- INDICES NA TABLESPACE DE INDICES
-- ============================================================
CREATE INDEX idx_mat_titulo
    ON MATERIAL_BIBLIOGRAFICO (titulo)
    TABLESPACE tbs_MATERIAISDB_idx;

CREATE INDEX idx_mat_biblioteca
    ON MATERIAL_BIBLIOGRAFICO (cod_biblioteca)
    TABLESPACE tbs_MATERIAISDB_idx;

CREATE INDEX idx_mat_estado
    ON MATERIAL_BIBLIOGRAFICO (estado_material_conservacao)
    TABLESPACE tbs_MATERIAISDB_idx;

CREATE INDEX idx_mat_categoria
    ON MATERIAL_BIBLIOGRAFICO (cod_categoria)
    TABLESPACE tbs_MATERIAISDB_idx;

CREATE INDEX iaud_mat_material
    ON AUDITORIA_MATERIAIS (cod_material)
    TABLESPACE tbs_MATERIAISDB_idx;

CREATE INDEX iaud_mat_transf
    ON AUDITORIA_MATERIAIS (id_transferencia)
    TABLESPACE tbs_MATERIAISDB_idx;

CREATE INDEX iaud_mat_data
    ON AUDITORIA_MATERIAIS (data_operacao)
    TABLESPACE tbs_MATERIAISDB_idx;

CREATE INDEX iaud_mat_res
    ON AUDITORIA_MATERIAIS (resultado)
    TABLESPACE tbs_MATERIAISDB_idx;


