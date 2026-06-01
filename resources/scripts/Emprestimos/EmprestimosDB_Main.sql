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

-- 5. Snapshots (depende dos database links)
@/root/TP/EmprestimosDB_Snapshots.sql

-- 6. Sinónimos (depende dos database links e snapshots)
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
