-- ============================================================
-- EmprestimosProg_Create.sql
-- Executar como: usr_emprestimosdb
-- ============================================================
DROP TABLE PARTICIPACAO_PROGRAMA  CASCADE CONSTRAINTS;
DROP TABLE PROGRAMA_FUNCIONARIO   CASCADE CONSTRAINTS;
DROP TABLE PROGRAMA_MATERIAL      CASCADE CONSTRAINTS;
DROP TABLE NIVEL_PROGRESSAO       CASCADE CONSTRAINTS;
DROP TABLE PROGRAMA_ALFABETIZACAO CASCADE CONSTRAINTS;
DROP TABLE SUSPENSAO              CASCADE CONSTRAINTS;
DROP TABLE EMPRESTIMO             CASCADE CONSTRAINTS;
DROP TABLE REPL_FUNCIONARIOS      CASCADE CONSTRAINTS;
DROP TABLE AUDITORIA_EMPRESTIMOS  CASCADE CONSTRAINTS;

-- ------------------------------------------------------------
-- REPL_FUNCIONARIOS
-- Replica parcial de FUNCIONARIO vinda do BibliotecaNacionalDB
-- Actualizada pelo app_nacionaldb via GRANT INSERT/UPDATE/DELETE
-- ------------------------------------------------------------
CREATE TABLE REPL_FUNCIONARIOS (
    cod_funcionario  VARCHAR2(12)  NOT NULL,
    nome_funcionario VARCHAR2(100),
    nivel_acesso     VARCHAR2(15),
    id_funcao        NUMBER,
    cod_biblioteca   VARCHAR2(10),
    nome_funcao      VARCHAR2(15)
) TABLESPACE tbs_emprestimosdb;
ALTER TABLE REPL_FUNCIONARIOS ADD CONSTRAINT pk_repl_funcionarios
    PRIMARY KEY (cod_funcionario);

-- ------------------------------------------------------------
-- EMPRESTIMO
-- ------------------------------------------------------------
CREATE TABLE EMPRESTIMO (
    id_emprestimo           NUMBER        NOT NULL,
    num_cartao              VARCHAR2(12)  NOT NULL,
    cod_funcionario         VARCHAR2(12)  NOT NULL,
    cod_material            VARCHAR2(12)  NOT NULL,
    data_retirada           DATE          NOT NULL,
    prazo_devolucao         DATE          NOT NULL,
    data_devolucao          DATE,
    estado_material_saida   VARCHAR2(10)  NOT NULL,
    estado_material_retorno VARCHAR2(10),
    observacoes_devolucao   VARCHAR2(300),
    multa_valor             NUMBER(8,2),
    multa_paga              CHAR(1)       DEFAULT 'N' NOT NULL,
    data_pagamento_multa    DATE
) TABLESPACE tbs_emprestimosdb;
ALTER TABLE EMPRESTIMO ADD CONSTRAINT emprestimo_pk
    PRIMARY KEY (id_emprestimo);
ALTER TABLE EMPRESTIMO ADD CONSTRAINT chk_estado_saida
    CHECK (estado_material_saida IN ('Bom','Degradado'));
ALTER TABLE EMPRESTIMO ADD CONSTRAINT chk_estado_retorno
    CHECK (estado_material_retorno IN ('Bom','Degradado','Destruido','Perdido'));
ALTER TABLE EMPRESTIMO ADD CONSTRAINT chk_multa_paga
    CHECK (multa_paga IN ('S','N'));
ALTER TABLE EMPRESTIMO ADD CONSTRAINT chk_data_devolucao
    CHECK (data_devolucao IS NULL OR data_devolucao >= data_retirada);

-- ------------------------------------------------------------
-- SUSPENSAO
-- Suspensoes aplicadas por atraso na devolucao (RN03)
-- ------------------------------------------------------------
CREATE TABLE SUSPENSAO (
    id_suspensao     NUMBER        NOT NULL,
    num_cartao       VARCHAR2(12)  NOT NULL,
    id_emprestimo    NUMBER        NOT NULL,
    data_inicio      DATE          NOT NULL,
    data_fim         DATE          NOT NULL,
    dias_suspensao   NUMBER(3)     NOT NULL,
    estado_suspensao VARCHAR2(10)  DEFAULT 'Activa' NOT NULL,
    observacoes      VARCHAR2(300)
) TABLESPACE tbs_emprestimosdb;
ALTER TABLE SUSPENSAO ADD CONSTRAINT suspensao_pk
    PRIMARY KEY (id_suspensao);
ALTER TABLE SUSPENSAO ADD CONSTRAINT fk_suspensao_emprestimo
    FOREIGN KEY (id_emprestimo) REFERENCES EMPRESTIMO(id_emprestimo);
ALTER TABLE SUSPENSAO ADD CONSTRAINT chk_estado_suspensao
    CHECK (estado_suspensao IN ('Activa','Cumprida','Reduzida'));
ALTER TABLE SUSPENSAO ADD CONSTRAINT chk_dias_suspensao
    CHECK (dias_suspensao IN (7,15,30,60));
ALTER TABLE SUSPENSAO ADD CONSTRAINT chk_data_fim_suspensao
    CHECK (data_fim > data_inicio);

-- ------------------------------------------------------------
-- PROGRAMA_ALFABETIZACAO
-- PK: cod_programa VARCHAR2(18) formato PROBIBXXX20XXYYYY
--     gerado pelo backend e passado no INSERT
-- ------------------------------------------------------------
CREATE TABLE PROGRAMA_ALFABETIZACAO (
    cod_programa        VARCHAR2(18)  NOT NULL,
    cod_biblioteca      VARCHAR2(10)  NOT NULL,
    nome_programa       VARCHAR2(100) NOT NULL,
    descricao           VARCHAR2(500),
    publico_alvo        VARCHAR2(22),
    duracao_semanas     NUMBER(3),
    metodologia         VARCHAR2(300),
    resultados_esperados VARCHAR2(300),
    estado_programa     VARCHAR2(10)  DEFAULT 'Activo' NOT NULL
) TABLESPACE tbs_emprestimosdb;
ALTER TABLE PROGRAMA_ALFABETIZACAO ADD CONSTRAINT programa_pk
    PRIMARY KEY (cod_programa);
ALTER TABLE PROGRAMA_ALFABETIZACAO ADD CONSTRAINT chk_publico_alvo_prog
    CHECK (publico_alvo IN ('Iniciantes','Intermedios','Avancados','Todos'));
ALTER TABLE PROGRAMA_ALFABETIZACAO ADD CONSTRAINT chk_estado_programa
    CHECK (estado_programa IN ('Activo','Concluido','Suspenso'));

-- ------------------------------------------------------------
-- NIVEL_PROGRESSAO
-- Cada nivel pertence a um programa (CASCADE ao apagar programa)
-- ------------------------------------------------------------
CREATE TABLE NIVEL_PROGRESSAO (
    id_nivel     NUMBER        NOT NULL,
    cod_programa VARCHAR2(18)  NOT NULL,
    nome_nivel   VARCHAR2(50)  NOT NULL,
    descricao    VARCHAR2(300),
    ordem        NUMBER(2)     NOT NULL
) TABLESPACE tbs_emprestimosdb;
ALTER TABLE NIVEL_PROGRESSAO ADD CONSTRAINT nivel_pk
    PRIMARY KEY (id_nivel);
ALTER TABLE NIVEL_PROGRESSAO ADD CONSTRAINT fk_nivel_programa
    FOREIGN KEY (cod_programa) REFERENCES PROGRAMA_ALFABETIZACAO(cod_programa)
    ON DELETE CASCADE;

-- ------------------------------------------------------------
-- PROGRAMA_MATERIAL (N:M)
-- Materiais associados a programas (cod_material logico � sem FK DDL)
-- ------------------------------------------------------------
CREATE TABLE PROGRAMA_MATERIAL (
    cod_programa VARCHAR2(18)  NOT NULL,
    cod_material VARCHAR2(12)  NOT NULL,
    observacoes  VARCHAR2(200)
) TABLESPACE tbs_emprestimosdb;
ALTER TABLE PROGRAMA_MATERIAL ADD CONSTRAINT programa_material_pk
    PRIMARY KEY (cod_programa, cod_material);
ALTER TABLE PROGRAMA_MATERIAL ADD CONSTRAINT fk_pm_programa
    FOREIGN KEY (cod_programa) REFERENCES PROGRAMA_ALFABETIZACAO(cod_programa)
    ON DELETE CASCADE;

-- ------------------------------------------------------------
-- PROGRAMA_FUNCIONARIO (N:M)
-- Funcionarios responsaveis por programas
-- ------------------------------------------------------------
CREATE TABLE PROGRAMA_FUNCIONARIO (
    cod_programa    VARCHAR2(18) NOT NULL,
    cod_funcionario VARCHAR2(12) NOT NULL,
    papel           VARCHAR2(20) NOT NULL
) TABLESPACE tbs_emprestimosdb;
ALTER TABLE PROGRAMA_FUNCIONARIO ADD CONSTRAINT programa_funcionario_pk
    PRIMARY KEY (cod_programa, cod_funcionario);
ALTER TABLE PROGRAMA_FUNCIONARIO ADD CONSTRAINT fk_pf_programa
    FOREIGN KEY (cod_programa) REFERENCES PROGRAMA_ALFABETIZACAO(cod_programa)
    ON DELETE CASCADE;
ALTER TABLE PROGRAMA_FUNCIONARIO ADD CONSTRAINT chk_papel_prog_func
    CHECK (papel IN ('Responsavel','Instrutor','Auxiliar'));

-- ------------------------------------------------------------
-- PARTICIPACAO_PROGRAMA
-- PK composta (num_cartao, cod_programa) � sem sequencia
-- estado_participacao: 'Activo','Concluido','Desistiu'
-- ------------------------------------------------------------
CREATE TABLE PARTICIPACAO_PROGRAMA (
    num_cartao          VARCHAR2(12)  NOT NULL,
    cod_programa        VARCHAR2(18)  NOT NULL,
    id_nivel_atual      NUMBER,
    data_inscricao      DATE          NOT NULL,
    data_conclusao      DATE,
    estado_participacao VARCHAR2(10)  DEFAULT 'Activo' NOT NULL
) TABLESPACE tbs_emprestimosdb;
ALTER TABLE PARTICIPACAO_PROGRAMA ADD CONSTRAINT participacao_pk
    PRIMARY KEY (num_cartao, cod_programa);
ALTER TABLE PARTICIPACAO_PROGRAMA ADD CONSTRAINT fk_part_programa
    FOREIGN KEY (cod_programa) REFERENCES PROGRAMA_ALFABETIZACAO(cod_programa)
    ON DELETE CASCADE;
ALTER TABLE PARTICIPACAO_PROGRAMA ADD CONSTRAINT fk_part_nivel
    FOREIGN KEY (id_nivel_atual) REFERENCES NIVEL_PROGRESSAO(id_nivel);
ALTER TABLE PARTICIPACAO_PROGRAMA ADD CONSTRAINT chk_estado_participacao
    CHECK (estado_participacao IN ('Activo','Concluido','Desistiu'));

-- ------------------------------------------------------------
-- AUDITORIA_EMPRESTIMOS
-- Registo manual de operacoes criticas (criacao, devolucao, suspensao)
-- Populada pela procedure prc_registar_auditoria (AUTONOMOUS_TRANSACTION)
-- ------------------------------------------------------------
CREATE TABLE AUDITORIA_EMPRESTIMOS (
    id_auditoria   NUMBER        NOT NULL,
    data_operacao  DATE          DEFAULT SYSDATE NOT NULL,
    operacao       VARCHAR2(50)  NOT NULL,
    num_cartao     VARCHAR2(12),
    cod_material   VARCHAR2(12),
    id_emprestimo  NUMBER,
    resultado      VARCHAR2(10)  NOT NULL,
    motivo_falha   VARCHAR2(300),
    nos_afetados   VARCHAR2(200),
    observacoes    VARCHAR2(300)
) TABLESPACE tbs_emprestimosdb;
ALTER TABLE AUDITORIA_EMPRESTIMOS ADD CONSTRAINT auditoria_emp_pk
    PRIMARY KEY (id_auditoria);
ALTER TABLE AUDITORIA_EMPRESTIMOS ADD CONSTRAINT chk_resultado_emp
    CHECK (resultado IN ('SUCESSO','FALHA'));

COMMIT;