-- ============================================================
-- EventosDB_Main.sql — Script de instalação completo
-- EventosBibliotecasDB — Sistema de Gestão de Bibliotecas Comunitárias Distribuído
--
-- Executar como SYSDBA:
--   sqlplus sys/"bd2.isctem" as sysdba @/root/TP/EventosDB_Main.sql
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
  drop_syn('BIBLIOTECA');
  drop_syn('HORARIO_BIBLIOTECA');
  drop_syn('BIBLIOTECA_RESPONSAVEL');
  drop_syn('EVENTO');
  drop_syn('HORARIO_EVENTO');
  drop_syn('PARTICIPACAO_EVENTO');
  drop_syn('AVALIACAO_EVENTO');
  drop_syn('EVENTO_RECURSO');
  drop_syn('AUDITORIA_EVENTOS');
  drop_syn('REPL_FUNCIONARIOS');
  drop_syn('SNAP_LEITOR');
  drop_syn('FUNCIONARIO');
  drop_syn('FUNCAO_FUNCIONARIO');
  drop_syn('V_PROGRAMACAO_EVENTOS');
  drop_syn('V_HORARIOS_BIBLIOTECAS');
  drop_syn('V_BIBLIOTECAS_ACTIVAS');
  drop_syn('V_EVENTO_GLOBAL');
  drop_syn('FRAG_EVENTO_SUL');
  drop_syn('FRAG_EVENTO_CENTRO');
  drop_syn('FRAG_EVENTO_NORTE');
  drop_syn('VW_FRAG_EVENTO_FUTURO');
  drop_syn('VW_FRAG_EVENTO_PASSADO');
  drop_syn('VW_FRAG_PARTICIPACAO_FUTURO');
  drop_syn('VW_FRAG_PARTICIPACAO_PASSADO');
  drop_syn('VW_EVENTOS_PROXIMOS');
  drop_syn('VW_EVENTOS_COMPLETOS');
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
  drop_user_safe('usr_eventosdb');
  drop_user_safe('app_eventosdb');
  drop_user_safe('app_nacionaldb');
  drop_user_safe('app_materiaisdb');
  drop_user_safe('app_emprestimosdb');
END;
/


-- ============================================================
-- FASE 1 — INFRAESTRUTURA (SYSDBA)
-- ============================================================

-- 1. Tablespaces
@/root/TP/EventosDB_Tablespaces.sql

-- 2. Utilizadores e visitor users
@/root/TP/EventosDB_Users.sql

-- 3. Roles e privilégios
@/root/TP/EventosDB_Roles.sql


-- ============================================================
-- FASE 2 — OBJECTOS DO SCHEMA (usr_eventosdb)
-- ============================================================
CONNECT usr_eventosdb/"eventos1234"

-- 4. Database Links
@/root/TP/EventosDB_Database_Links.sql

-- 5. Tabelas e constraints
@/root/TP/EventosDB_Create.sql

-- 6. Sequências
@/root/TP/EventosDB_Sequences.sql

-- Placeholders para repl_funcionarios e snap_leitor:
-- vw_eventos_completos faz LEFT JOIN nestes nomes.
-- O snapshot real (Fase 3) substitui estas tabelas com DROP TABLE antes do CREATE MV.
CREATE TABLE repl_funcionarios (
    cod_funcionario  VARCHAR2(12),
    nome_funcionario VARCHAR2(100),
    cod_biblioteca   VARCHAR2(10),
    id_funcao        NUMBER,
    nivel_acesso     VARCHAR2(15),
    nome_funcao      VARCHAR2(15),
    email            VARCHAR2(100),
    contacto         VARCHAR2(20),
    senha            VARCHAR2(100),
    data_demissao    DATE
) TABLESPACE tbs_eventosdb;

-- Placeholder para repl_funcao_funcionario — substituido por MV em EventosDB_Snapshots.sql.
-- Necessario para que o sinonimo FUNCAO_FUNCIONARIO resolva antes de os snapshots serem criados.
CREATE TABLE repl_funcao_funcionario (
    id_funcao    NUMBER,
    nome_funcao  VARCHAR2(15),
    nivel_acesso VARCHAR2(15),
    descricao    VARCHAR2(200)
) TABLESPACE tbs_eventosdb;

CREATE TABLE snap_leitor (
    num_cartao               VARCHAR2(12),
    nome_completo            VARCHAR2(100),
    cod_biblioteca           VARCHAR2(10),
    status_leitor            VARCHAR2(12),
    historico_pontualidade   VARCHAR2(10),
    distancia_biblioteca     NUMBER(6,2)
) TABLESPACE tbs_eventosdb;

-- 7. Vistas
@/root/TP/EventosDB_Views.sql

-- 8. Funções
@/root/TP/EventosDB_Functions.sql

-- 9. Procedimentos
@/root/TP/EventosDB_Procedures.sql

-- 10. Triggers
@/root/TP/EventosDB_Triggers.sql

-- 11. Índices
@/root/TP/EventosDB_Indexes.sql

-- 12. Grants e permissões
@/root/TP/EventosDB_Grants.sql

-- 13. Dados iniciais
@/root/TP/EventosDB_Intro.sql


-- ============================================================
-- FASE 3 — SNAPSHOTS (usr_eventosdb)
-- Executar MANUALMENTE após o Helder confirmar:
--   GRANT SELECT ON vw_replica_funcionarios TO app_eventosdb
--   GRANT SELECT ON vw_leitor_publico       TO app_eventosdb
-- O EventosDB_Snapshots.sql já faz DROP TABLE antes do CREATE MV,
-- substituindo os placeholders criados na Fase 2.
-- ============================================================
-- @/root/TP/EventosDB_Snapshots.sql


-- ============================================================
-- FASE 4 — SINÓNIMOS E AUDITORIA (SYSDBA)
-- ============================================================
CONNECT sys/"bd2.isctem" as sysdba

-- 14. Sinónimos públicos
@/root/TP/EventosDB_Synonyms.sql

-- 15. Auditoria Oracle nativa
@/root/TP/EventosDB_Auditoria.sql
