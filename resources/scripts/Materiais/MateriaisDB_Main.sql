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

-- 5. Snapshots (depende dos database links)
@/root/TP/MateriaisDB_Snapshots.sql

-- 6. Sinónimos (depende dos database links e snapshots)
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
