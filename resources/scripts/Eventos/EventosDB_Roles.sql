-- ============================================
-- ROLES E PRIVIL�GIOS - EventosBibliotecasDB
-- Executar como SYSDBA
-- ============================================

-- Limpar roles de versoes anteriores (tolerante a ORA-01919)
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_eventosdb_read';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_eventosdb_write'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_evt_visitante'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Roles locais do no (sessao directa — nao transitam por dblink)
CREATE ROLE role_eventosdb_read;
CREATE ROLE role_eventosdb_write;

-- Atribuir ao utilizador de aplicacao local
GRANT role_eventosdb_read  TO app_eventosdb;
GRANT role_eventosdb_write TO app_eventosdb;

-- Privil�gios de sess�o
GRANT CREATE SESSION TO usr_eventosdb;
GRANT CREATE SESSION TO app_eventosdb;

-- Privil�gios DDL ao utilizador principal
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE TRIGGER, CREATE PROCEDURE, CREATE SYNONYM
TO usr_eventosdb;

-- Privilégio para database links (PUBLIC para que app_eventosdb os resolva)
GRANT CREATE DATABASE LINK TO usr_eventosdb;
GRANT CREATE PUBLIC DATABASE LINK TO usr_eventosdb;
GRANT DROP PUBLIC DATABASE LINK TO usr_eventosdb;

-- Privil�gio para materialized views (snapshots)
GRANT CREATE MATERIALIZED VIEW TO usr_eventosdb;


-- ============================================================
-- VISITOR USERS — utilizadores criados neste no para os outros nos
-- Executar como SYSDBA
-- ============================================================

-- Para o Helder (BibliotecaNacionalDB)
DROP USER app_nacionaldb CASCADE;
CREATE USER app_nacionaldb IDENTIFIED BY HTAJnr#22041
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_nacionaldb;

-- Para o Yannis (EmprestimosDB)
DROP USER app_emprestimosdb CASCADE;
CREATE USER app_emprestimosdb IDENTIFIED BY YC20220156
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_emprestimosdb;

-- Para o Yasin (MateriaisDB)
DROP USER app_materiaisdb CASCADE;
CREATE USER app_materiaisdb IDENTIFIED BY YM20240260
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_materiaisdb;
