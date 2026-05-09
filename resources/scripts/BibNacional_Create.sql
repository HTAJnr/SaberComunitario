-- Tabelas de associação e dependentes primeiro
DROP TABLE AUDITORIA_OPERACOES CASCADE CONSTRAINTS;
DROP TABLE CERTIFICADO_DOACAO CASCADE CONSTRAINTS;
DROP TABLE ITEM_DOACAO CASCADE CONSTRAINTS;
DROP TABLE DOACAO CASCADE CONSTRAINTS;
DROP TABLE DOADOR CASCADE CONSTRAINTS;
DROP TABLE ADULTO_INTERESSE CASCADE CONSTRAINTS;
DROP TABLE PROFESSOR_DISCIPLINA CASCADE CONSTRAINTS;
DROP TABLE PROFESSOR CASCADE CONSTRAINTS;
DROP TABLE CRIANCA CASCADE CONSTRAINTS;
DROP TABLE ADULTO CASCADE CONSTRAINTS;
DROP TABLE LEITOR CASCADE CONSTRAINTS;
DROP TABLE FUNCIONARIO_HABILIDADE CASCADE CONSTRAINTS;
DROP TABLE HORARIO_FUNCIONARIO CASCADE CONSTRAINTS;
DROP TABLE FUNCIONARIO CASCADE CONSTRAINTS;
DROP TABLE FUNCAO_FUNCIONARIO CASCADE CONSTRAINTS;

-- ============================================================
-- FUNCAO_FUNCIONARIO
-- ============================================================
CREATE TABLE FUNCAO_FUNCIONARIO (
    id_funcao   NUMBER              NOT NULL,
    nome_funcao VARCHAR2(15 BYTE)   NOT NULL,
    nivel_acesso VARCHAR2(15 BYTE)  NOT NULL
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE FUNCAO_FUNCIONARIO
    ADD CONSTRAINT FUNCAO_FUNCIONARIO_PK PRIMARY KEY (id_funcao);
ALTER TABLE FUNCAO_FUNCIONARIO
    ADD CONSTRAINT chk_nome_funcao
    CHECK (nome_funcao IN ('Administrador','Coordenador','Bibliotecario','Assistente'));
ALTER TABLE FUNCAO_FUNCIONARIO
    ADD CONSTRAINT chk_nivel_acesso
    CHECK (nivel_acesso IN ('Administrador','Coordenador','Bibliotecario','Assistente'));

-- ============================================================
-- FUNCIONARIO
-- ============================================================
CREATE TABLE FUNCIONARIO (
    cod_funcionario  VARCHAR2(12 BYTE)  NOT NULL,
    nome_funcionario VARCHAR2(100 BYTE) NOT NULL,
    genero           VARCHAR2(9 BYTE)   NOT NULL,
    data_nasc        DATE,
    contacto         VARCHAR2(50 BYTE)  NOT NULL,
    endereco         VARCHAR2(200 BYTE),
    formacao         VARCHAR2(100 BYTE),
    experiencia      VARCHAR2(300 BYTE),
    data_contratacao DATE               NOT NULL,
    data_demissao    DATE,
    cod_biblioteca   VARCHAR2(10 BYTE)  NOT NULL,
    id_funcao        NUMBER             NOT NULL,
    email            VARCHAR2(100 BYTE) NOT NULL,
    senha            VARCHAR2(64 BYTE)  NOT NULL
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE FUNCIONARIO
    ADD CONSTRAINT FUNCIONARIO_PK PRIMARY KEY (cod_funcionario);
ALTER TABLE FUNCIONARIO
    ADD CONSTRAINT uq_email_func UNIQUE (email);
ALTER TABLE FUNCIONARIO
    ADD CONSTRAINT chk_genero_func
    CHECK (genero IN ('Masculino','Feminino'));

-- ============================================================
-- FUNCIONARIO_HABILIDADE
-- ============================================================
CREATE TABLE FUNCIONARIO_HABILIDADE (
    cod_funcionario VARCHAR2(12 BYTE)  NOT NULL,
    habilidade      VARCHAR2(50 BYTE)  NOT NULL
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE FUNCIONARIO_HABILIDADE
    ADD CONSTRAINT FUNCIONARIO_HABILIDADE_PK PRIMARY KEY (cod_funcionario, habilidade);

-- ============================================================
-- HORARIO_FUNCIONARIO
-- ============================================================
CREATE TABLE HORARIO_FUNCIONARIO (
    id_horario_func  NUMBER              NOT NULL,
    cod_funcionario  VARCHAR2(12 BYTE)   NOT NULL,
    dia_semana       VARCHAR2(13 BYTE)   NOT NULL,
    hora_entrada     VARCHAR2(5 BYTE)    NOT NULL,
    hora_saida       VARCHAR2(5 BYTE)    NOT NULL
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE HORARIO_FUNCIONARIO
    ADD CONSTRAINT HORARIO_FUNCIONARIO_PK PRIMARY KEY (id_horario_func);

-- ============================================================
-- DOADOR
-- ============================================================
CREATE TABLE DOADOR (
    id_doador  NUMBER              NOT NULL,
    nome_doador VARCHAR2(100 BYTE) NOT NULL,
    tipo_doador VARCHAR2(13 BYTE)  NOT NULL,
    contacto   VARCHAR2(50 BYTE),
    endereco   VARCHAR2(200 BYTE),
    observacoes VARCHAR2(300 BYTE)
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE DOADOR
    ADD CONSTRAINT DOADOR_PK PRIMARY KEY (id_doador);
ALTER TABLE DOADOR
    ADD CONSTRAINT chk_tipo_doador
    CHECK (tipo_doador IN ('Individual','Institucional'));

-- ============================================================
-- DOACAO
-- ============================================================
CREATE TABLE DOACAO (
    id_doacao  NUMBER  NOT NULL,
    id_doador  NUMBER  NOT NULL,
    data_doacao DATE   NOT NULL
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE DOACAO
    ADD CONSTRAINT DOACAO_PK PRIMARY KEY (id_doacao);

-- ============================================================
-- ITEM_DOACAO
-- ============================================================
CREATE TABLE ITEM_DOACAO (
    id_itemDoado  NUMBER              NOT NULL,
    id_doacao     NUMBER              NOT NULL,
    cod_biblioteca VARCHAR2(10 BYTE)  NOT NULL,
    quantidade    NUMBER(4)           NOT NULL,
    valor_estimado NUMBER(10,2)       NOT NULL,
    observacoes   VARCHAR2(300 BYTE)
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE ITEM_DOACAO
    ADD CONSTRAINT ITEM_DOACAO_PK PRIMARY KEY (id_itemDoado);

-- ============================================================
-- CERTIFICADO_DOACAO
-- ============================================================
CREATE TABLE CERTIFICADO_DOACAO (
    id_certificado  NUMBER              NOT NULL,
    num_certificado VARCHAR2(20 BYTE)   NOT NULL,
    id_doacao       NUMBER              NOT NULL,
    original_numero VARCHAR2(20 BYTE),
    data_emissao    DATE                NOT NULL,
    tipo_certificado VARCHAR2(10 BYTE)  NOT NULL,
    observacoes     VARCHAR2(300 BYTE)
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE CERTIFICADO_DOACAO
    ADD CONSTRAINT CERTIFICADO_DOACAO_PK PRIMARY KEY (id_certificado);
ALTER TABLE CERTIFICADO_DOACAO
    ADD CONSTRAINT uq_num_certificado UNIQUE (num_certificado);
ALTER TABLE CERTIFICADO_DOACAO
    ADD CONSTRAINT chk_tipo_cert
    CHECK (tipo_certificado IN ('Original','Reemissao','Honorifico'));

-- ============================================================
-- AUDITORIA_OPERACOES
-- ============================================================
CREATE TABLE AUDITORIA_OPERACOES (
    id_auditoria     NUMBER          NOT NULL,
    data_operacao    DATE            DEFAULT SYSDATE NOT NULL,
    cod_funcionario  VARCHAR2(12)    NOT NULL,          -- quem executou
    operacao         VARCHAR2(50)    NOT NULL,          -- ex: 'APAGAR_LEITOR'
    objeto_afetado   VARCHAR2(100)   NOT NULL,          -- ex: num_cartao ou cod_funcionario alvo
    resultado        VARCHAR2(10)    NOT NULL,          -- 'SUCESSO' ou 'FALHA'
    motivo_falha     VARCHAR2(300),                     -- preenchido só em FALHA
    nos_afetados     VARCHAR2(200),                     -- ex: 'EmprestimosDB, EventosDB'
    observacoes      VARCHAR2(300)
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE AUDITORIA_OPERACOES
    ADD CONSTRAINT AUDITORIA_PK PRIMARY KEY (id_auditoria);
ALTER TABLE AUDITORIA_OPERACOES
    ADD CONSTRAINT chk_resultado_audit
    CHECK (resultado IN ('SUCESSO', 'FALHA'));

-- ============================================================
-- LEITOR
-- ============================================================
CREATE TABLE LEITOR (
    num_cartao               VARCHAR2(12 BYTE)  NOT NULL,
    nome_completo            VARCHAR2(100 BYTE) NOT NULL,
    data_nasc                DATE               NOT NULL,
    genero                   VARCHAR2(9 BYTE)   NOT NULL,
    nivel_escolar            VARCHAR2(20 BYTE)  NOT NULL,
    localizacao_leitor       VARCHAR2(200 BYTE) NOT NULL,
    contacto                 VARCHAR2(50 BYTE),
    foto_path                VARCHAR2(300 BYTE),
    distancia_biblioteca     NUMBER(6,2)        NOT NULL,
    historico_pontualidade   VARCHAR2(10 BYTE)  DEFAULT 'Pontual' NOT NULL,
    cod_biblioteca           VARCHAR2(10 BYTE)  NOT NULL,
    status_leitor            VARCHAR2(12 BYTE)  DEFAULT 'Activo' NOT NULL
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE LEITOR
    ADD CONSTRAINT LEITOR_PK PRIMARY KEY (num_cartao);
ALTER TABLE LEITOR
    ADD CONSTRAINT chk_status_leitor
    CHECK (status_leitor IN ('Activo','Suspenso','Bloqueado'));
ALTER TABLE LEITOR
    ADD CONSTRAINT chk_historico_pontualidade
    CHECK (historico_pontualidade IN ('Pontual','Irregular','Mau'));
ALTER TABLE LEITOR
    ADD CONSTRAINT chk_genero_leitor
    CHECK (genero IN ('Masculino','Feminino'));

-- ============================================================
-- ADULTO
-- ============================================================
CREATE TABLE ADULTO (
    num_cartao      VARCHAR2(12 BYTE) NOT NULL,
    profissao       VARCHAR2(50 BYTE),
    nivel_literacia VARCHAR2(15 BYTE) NOT NULL
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE ADULTO
    ADD CONSTRAINT ADULTO_PK PRIMARY KEY (num_cartao);
ALTER TABLE ADULTO
    ADD CONSTRAINT chk_nivel_literacia
    CHECK (nivel_literacia IN ('Basico','Funcional','Avancado'));

-- ============================================================
-- ADULTO_INTERESSE
-- ============================================================
CREATE TABLE ADULTO_INTERESSE (
    num_cartao VARCHAR2(12 BYTE) NOT NULL,
    interesse  VARCHAR2(50 BYTE) NOT NULL
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE ADULTO_INTERESSE
    ADD CONSTRAINT ADULTO_INTERESSE_PK PRIMARY KEY (num_cartao, interesse);

-- ============================================================
-- PROFESSOR
-- ============================================================
CREATE TABLE PROFESSOR (
    num_cartao       VARCHAR2(12 BYTE)  NOT NULL,
    escola_instituto VARCHAR2(100 BYTE),
    nivel_ensino     VARCHAR2(15 BYTE)  NOT NULL,
    num_alunos       NUMBER(5)
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE PROFESSOR
    ADD CONSTRAINT PROFESSOR_PK PRIMARY KEY (num_cartao);
ALTER TABLE PROFESSOR
    ADD CONSTRAINT chk_nivel_ensino
    CHECK (nivel_ensino IN ('Primario','Secundario','Tecnico','Universitario'));

-- ============================================================
-- PROFESSOR_DISCIPLINA
-- ============================================================
CREATE TABLE PROFESSOR_DISCIPLINA (
    num_cartao VARCHAR2(12 BYTE) NOT NULL,
    disciplina VARCHAR2(50 BYTE) NOT NULL
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE PROFESSOR_DISCIPLINA
    ADD CONSTRAINT PROFESSOR_DISCIPLINA_PK PRIMARY KEY (num_cartao, disciplina);

-- ============================================================
-- CRIANCA
-- ============================================================
CREATE TABLE CRIANCA (
    num_cartao           VARCHAR2(12 BYTE)  NOT NULL,
    nome_responsavel     VARCHAR2(100 BYTE) NOT NULL,
    telefone_responsavel VARCHAR2(20 BYTE),
    escola_frequenta     VARCHAR2(100 BYTE),
    classe               VARCHAR2(10 BYTE)
) TABLESPACE tbs_NACIONALDB;

ALTER TABLE CRIANCA
    ADD CONSTRAINT CRIANCA_PK PRIMARY KEY (num_cartao);

-- ============================================================
-- CONSTRAINTS DE FK's
-- ============================================================

-- FUNCIONARIO
ALTER TABLE FUNCIONARIO ADD CONSTRAINT FUNC_FUNCAO_FK
    FOREIGN KEY (id_funcao) REFERENCES FUNCAO_FUNCIONARIO (id_funcao);

-- FUNCIONARIO_HABILIDADE
ALTER TABLE FUNCIONARIO_HABILIDADE ADD CONSTRAINT FH_FUNCIONARIO_FK
    FOREIGN KEY (cod_funcionario) REFERENCES FUNCIONARIO (cod_funcionario) ON DELETE CASCADE;

-- HORARIO_FUNCIONARIO
ALTER TABLE HORARIO_FUNCIONARIO ADD CONSTRAINT HFUNC_FUNCIONARIO_FK
    FOREIGN KEY (cod_funcionario) REFERENCES FUNCIONARIO (cod_funcionario) ON DELETE CASCADE;

-- LEITOR (cod_biblioteca é FK lógica para BIBLIOTECA@eventosdb — sem DDL cross-node)
ALTER TABLE ADULTO ADD CONSTRAINT ADULTO_LEITOR_FK
    FOREIGN KEY (num_cartao) REFERENCES LEITOR (num_cartao) ON DELETE CASCADE;
ALTER TABLE ADULTO_INTERESSE ADD CONSTRAINT AI_ADULTO_FK
    FOREIGN KEY (num_cartao) REFERENCES ADULTO (num_cartao) ON DELETE CASCADE;
ALTER TABLE PROFESSOR ADD CONSTRAINT PROF_ADULTO_FK
    FOREIGN KEY (num_cartao) REFERENCES ADULTO (num_cartao) ON DELETE CASCADE;
ALTER TABLE PROFESSOR_DISCIPLINA ADD CONSTRAINT PD_PROFESSOR_FK
    FOREIGN KEY (num_cartao) REFERENCES PROFESSOR (num_cartao) ON DELETE CASCADE;
ALTER TABLE CRIANCA ADD CONSTRAINT CRIANCA_LEITOR_FK
    FOREIGN KEY (num_cartao) REFERENCES LEITOR (num_cartao) ON DELETE CASCADE;

-- DOACAO / ITEM_DOACAO / CERTIFICADO_DOACAO
ALTER TABLE DOACAO ADD CONSTRAINT DOA_DOADOR_FK
    FOREIGN KEY (id_doador) REFERENCES DOADOR (id_doador);
ALTER TABLE ITEM_DOACAO ADD CONSTRAINT ITEM_DOACAO_FK
    FOREIGN KEY (id_doacao) REFERENCES DOACAO (id_doacao) ON DELETE CASCADE;
ALTER TABLE CERTIFICADO_DOACAO ADD CONSTRAINT CERT_DOACAO_FK
    FOREIGN KEY (id_doacao) REFERENCES DOACAO (id_doacao) ON DELETE CASCADE;


