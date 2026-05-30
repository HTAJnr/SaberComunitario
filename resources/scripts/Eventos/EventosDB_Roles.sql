-- ============================================
-- ROLES E PRIVIL�GIOS - EventosBibliotecasDB
-- Executar como SYSDBA
-- ============================================

DROP ROLE role_eventosdb_read;
CREATE ROLE role_eventosdb_read;
DROP ROLE role_eventosdb_write;
CREATE ROLE role_eventosdb_write;

-- Roles para visitor users (outros nos)
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_evt_visitante'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE ROLE role_evt_visitante;

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

-- Role de leitura ao utilizador de aplicacao local
GRANT role_eventosdb_read TO app_eventosdb;

-- Roles de visitor aos outros nos
GRANT role_evt_visitante TO app_emprestimosdb;
GRANT role_evt_visitante TO app_materiaisdb;
GRANT role_evt_visitante TO app_nacionaldb;

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
