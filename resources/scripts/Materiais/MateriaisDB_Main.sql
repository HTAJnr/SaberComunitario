-- ============================================================
-- MateriaisDB_Main.sql — Script de instalação completo
-- MateriaisDB — Sistema de Gestão de Bibliotecas Comunitárias Distribuído
--
-- Executar como SYSDBA:
--   sqlplus sys/"bd2.isctem" as sysdba @/root/TP/MateriaisDB_Main.sql
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
  -- EmprestimosDB (Yannis)
  drop_syn('emprestimo_activo');
  -- EventosBibliotecasDB (Gerson)
  drop_syn('biblioteca_remota');
  -- BibliotecaNacionalDB (Helder)
  drop_syn('leitor_remoto');
  drop_syn('leitor_publico');
  -- Snapshots locais
  drop_syn('funcionario');
  drop_syn('funcao_funcionario');
  drop_syn('biblioteca');
  -- Objectos e views locais
  drop_syn('CATEGORIA');
  drop_syn('MATERIAL_BIBLIOGRAFICO');
  drop_syn('LIVRO_FISICO');
  drop_syn('EBOOK');
  drop_syn('PERIODICO');
  drop_syn('TRANSFERENCIA');
  drop_syn('AUDITORIA_MATERIAIS');
  drop_syn('VW_MAT_DISPONIVEL');
  drop_syn('VW_MAT_GLOBAL');
  drop_syn('VW_AUDITORIA');
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
  drop_user_safe('usr_materiaisdb');
  drop_user_safe('app_materiaisdb');
  drop_user_safe('app_nacionaldb');
  drop_user_safe('app_emprestimosdb');
  drop_user_safe('app_eventosdb');
END;
/


-- ============================================================
-- FASE 1 — INFRAESTRUTURA (SYSDBA)
-- ============================================================

-- 1. Tablespaces
@/root/TP/MateriaisDB_Tablespaces.sql

-- 2. Utilizadores e visitor users
@/root/TP/MateriaisDB_Users.sql

-- 3. Roles e privilégios
@/root/TP/MateriaisDB_Roles.sql


-- ============================================================
-- FASE 2 — OBJECTOS DO SCHEMA (usr_materiaisdb)
-- ============================================================
CONNECT usr_materiaisdb/"YM20240260"

-- 4. Database Links
@/root/TP/MateriaisDB_Database_Links.sql

-- 5. Placeholders para snapshots cross-node
-- Tabelas temporárias que permitem compilar views e triggers antes do
-- BibliotecaNacionalDB e EventosBibliotecasDB estarem activos.
-- São substituídas pelas Materialized Views reais em MateriaisDB_Snapshots.sql.
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
) TABLESPACE tbs_MATERIAISDB;

CREATE TABLE repl_funcao_funcionario (
    id_funcao    NUMBER,
    nome_funcao  VARCHAR2(15),
    nivel_acesso VARCHAR2(15),
    descricao    VARCHAR2(200)
) TABLESPACE tbs_MATERIAISDB;

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
) TABLESPACE tbs_MATERIAISDB;

CREATE TABLE snap_leitor_publico (
    num_cartao               VARCHAR2(12),
    nome_completo            VARCHAR2(100),
    cod_biblioteca           VARCHAR2(10),
    status_leitor            VARCHAR2(12),
    historico_pontualidade   VARCHAR2(10),
    distancia_biblioteca     NUMBER(6,2)
) TABLESPACE tbs_MATERIAISDB;

-- 6. Sinónimos (depende dos database links e placeholders)
@/root/TP/MateriaisDB_Synonyms.sql

-- 7. Tabelas e constraints
@/root/TP/MateriaisDB_Create.sql

-- 8. Sequências
@/root/TP/MateriaisDB_Sequences.sql

-- 9. Vistas
@/root/TP/MateriaisDB_Views.sql

-- 10. Funções
@/root/TP/MateriaisDB_Functions.sql

-- 11. Procedimentos
@/root/TP/MateriaisDB_Procedures.sql

-- 12. Triggers
@/root/TP/MateriaisDB_Triggers.sql

-- 13. Índices
@/root/TP/MateriaisDB_Indexes.sql

-- 14. Grants e permissões
@/root/TP/MateriaisDB_Grants.sql

-- 15. Dados iniciais
@/root/TP/MateriaisDB_Intro.sql


-- ============================================================
-- FASE 3 — AUDITORIA (SYSDBA)
-- ============================================================
CONNECT sys/"bd2.isctem" as sysdba

-- 16. Auditoria Oracle nativa
@/root/TP/MateriaisDB_Auditoria.sql
