-- ============================================================
-- EmprestimosDB_Main.sql — Script de instalação completo
-- EmprestimosDB — Sistema de Gestão de Bibliotecas Comunitárias Distribuído
--
-- Executar como SYSDBA:
--   sqlplus sys/"bd2.isctem" as sysdba @/root/TP/EmprestimosDB_Main.sql
--
-- PRÉ-REQUISITO (1 vez, antes do primeiro install):
--   ALTER SYSTEM SET audit_trail = 'DB' SCOPE = SPFILE;
--   SHUTDOWN IMMEDIATE; STARTUP;
-- ============================================================


-- ============================================================
-- FASE 0A — LIMPEZA DE SINÓNIMOS PÚBLICOS (SYSDBA)
-- Ignora ORA-01432 (sinónimo inexistente) em primeira instalação.
-- ============================================================
DECLARE
  PROCEDURE drop_syn(p_syn IN VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'DROP PUBLIC SYNONYM ' || p_syn;
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -1432 THEN RAISE; END IF;
  END;
BEGIN
  -- BibliotecaNacionalDB (Helder)
  drop_syn('leitor');
  drop_syn('adulto');
  drop_syn('adulto_interesse');
  drop_syn('professor');
  drop_syn('professor_disciplina');
  drop_syn('crianca');
  -- Snapshots locais
  drop_syn('funcao_funcionario');
  drop_syn('funcionario');
  drop_syn('biblioteca');
  -- MateriaisDB (Yasin)
  drop_syn('material_bibliografico');
  drop_syn('categoria');
  drop_syn('transferencia');
  -- Objectos e views locais
  drop_syn('emprestimo');
  drop_syn('suspensao');
  drop_syn('repl_funcionarios');
  drop_syn('programa_alfabetizacao');
  drop_syn('nivel_progressao');
  drop_syn('programa_material');
  drop_syn('programa_funcionario');
  drop_syn('participacao_programa');
  drop_syn('vw_emprestimos_activos');
  drop_syn('vw_suspensoes_activas');
  drop_syn('frag_emp_activos_op');
  drop_syn('vw_auditoria');
  drop_syn('vw_relatorio_programas');
END;
/


-- ============================================================
-- FASE 0B — LIMPEZA DE UTILIZADORES (SYSDBA)
-- Mata sessoes activas antes de DROP para evitar ORA-01940.
-- Ignora ORA-01918 (utilizador inexistente) em re-installs.
-- ============================================================
DECLARE
  PROCEDURE kill_sessions(p_user IN VARCHAR2) IS
  BEGIN
    FOR s IN (SELECT sid, serial# FROM v$session
              WHERE username = UPPER(p_user)
                AND sid != SYS_CONTEXT('USERENV','SID')) LOOP
      BEGIN
        EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION ''' || s.sid || ',' || s.serial# || ''' IMMEDIATE';
      EXCEPTION WHEN OTHERS THEN NULL;
      END;
    END LOOP;
  END;
  PROCEDURE drop_user_safe(p_user IN VARCHAR2) IS
  BEGIN
    IF UPPER(p_user) = USER THEN RETURN; END IF;
    kill_sessions(p_user);
    EXECUTE IMMEDIATE 'DROP USER ' || p_user || ' CASCADE';
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -1918 THEN RAISE; END IF;
  END;
BEGIN
  drop_user_safe('usr_emprestimosdb');
  drop_user_safe('app_emprestimosdb');
  drop_user_safe('app_nacionaldb');
  drop_user_safe('app_materiaisdb');
  drop_user_safe('app_eventosdb');
END;
/


-- ============================================================
-- FASE 1 — INFRAESTRUTURA (SYSDBA)
-- ============================================================

-- 1. Tablespaces
@/root/TP/EmprestimosDB_Tablespaces.sql

-- 2. Utilizadores e visitor users
@/root/TP/EmprestimosDB_Users.sql

-- 3. Roles e privilégios
@/root/TP/EmprestimosDB_Roles.sql


-- ============================================================
-- FASE 2 — OBJECTOS DO SCHEMA (usr_emprestimosdb)
-- ============================================================
CONNECT usr_emprestimosdb/"YC20220156"

-- 4. Database Links
@/root/TP/EmprestimosDB_Database_Links.sql

-- 5. Placeholders para snapshots cross-node
-- Tabelas temporárias que permitem compilar views e triggers antes do
-- BibliotecaNacionalDB e MateriaisDB estarem activos.
-- São substituídas pelas Materialized Views reais em EmprestimosDB_Snapshots.sql.
CREATE TABLE snap_leitor (
    num_cartao               VARCHAR2(12),
    nome_completo            VARCHAR2(100),
    cod_biblioteca           VARCHAR2(10),
    status_leitor            VARCHAR2(12),
    historico_pontualidade   VARCHAR2(10),
    distancia_biblioteca     NUMBER(6,2)
) TABLESPACE tbs_emprestimosdb;

CREATE TABLE snap_adulto (
    num_cartao      VARCHAR2(12),
    nivel_literacia VARCHAR2(15)
) TABLESPACE tbs_emprestimosdb;

CREATE TABLE snap_professor (
    num_cartao VARCHAR2(12)
) TABLESPACE tbs_emprestimosdb;

CREATE TABLE snap_crianca (
    num_cartao VARCHAR2(12)
) TABLESPACE tbs_emprestimosdb;

CREATE TABLE snap_material (
    cod_material                VARCHAR2(12),
    titulo                      VARCHAR2(200),
    autor                       VARCHAR2(200),
    cod_biblioteca              VARCHAR2(10),
    estado_material_conservacao VARCHAR2(15),
    motivo_indisponibilidade    VARCHAR2(200),
    valor_aquisicao             NUMBER(10,2),
    cod_categoria               NUMBER
) TABLESPACE tbs_emprestimosdb;

CREATE TABLE snap_categoria (
    id_categoria  NUMBER,
    area_tematica VARCHAR2(100),
    faixa_etaria  VARCHAR2(15),
    nivel_leitura VARCHAR2(15)
) TABLESPACE tbs_emprestimosdb;

CREATE TABLE repl_funcionarios (
    cod_funcionario  VARCHAR2(12),
    nome_funcionario VARCHAR2(100),
    email            VARCHAR2(100),
    contacto         VARCHAR2(20),
    id_funcao        NUMBER,
    cod_biblioteca   VARCHAR2(10),
    nivel_acesso     VARCHAR2(15),
    nome_funcao      VARCHAR2(15),
    senha            VARCHAR2(100),
    genero           VARCHAR2(9),
    data_nasc        DATE,
    endereco         VARCHAR2(200),
    formacao         VARCHAR2(100),
    experiencia      VARCHAR2(300),
    data_contratacao DATE,
    data_demissao    DATE
) TABLESPACE tbs_emprestimosdb;

CREATE TABLE repl_funcao_funcionario (
    id_funcao    NUMBER,
    nome_funcao  VARCHAR2(15),
    nivel_acesso VARCHAR2(15),
    descricao    VARCHAR2(200)
) TABLESPACE tbs_emprestimosdb;

CREATE TABLE biblioteca_snap (
    cod_biblioteca      VARCHAR2(10),
    nome_biblioteca     VARCHAR2(100),
    endereco            VARCHAR2(200),
    latitude            NUMBER(9,6),
    longitude           NUMBER(9,6),
    contacto_biblioteca VARCHAR2(50),
    data_inauguracao    DATE,
    capacidade          NUMBER(5),
    infraestrutura      VARCHAR2(500),
    servicos            VARCHAR2(500),
    provincia           VARCHAR2(17),
    estado              VARCHAR2(10)
) TABLESPACE tbs_emprestimosdb;

-- 6. Sinónimos (depende dos database links e placeholders)
@/root/TP/EmprestimosDB_Synonyms.sql

-- 7. Tabelas e constraints
@/root/TP/EmprestimosDB_Create.sql

-- 8. Sequências
@/root/TP/EmprestimosDB_Sequences.sql

-- 9. Vistas
@/root/TP/EmprestimosDB_Views.sql

-- 10. Funções
@/root/TP/EmprestimosDB_Functions.sql

-- 11. Procedimentos
@/root/TP/EmprestimosDB_Procedures.sql

-- 12. Triggers
@/root/TP/EmprestimosDB_Triggers.sql

-- 13. Índices
@/root/TP/EmprestimosDB_Indexes.sql

-- 14. Grants e permissões
@/root/TP/EmprestimosDB_Grants.sql

-- 15. Dados iniciais
@/root/TP/EmprestimosDB_Intro.sql


-- ============================================================
-- FASE 3 — AUDITORIA (SYSDBA)
-- ============================================================
CONNECT sys/"bd2.isctem" as sysdba

-- 16. Auditoria Oracle nativa
@/root/TP/EmprestimosDB_Auditoria.sql
