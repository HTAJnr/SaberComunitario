-- ============================================================
-- EmprestimosProg_Roles.sql
-- Executar como SYSDBA
-- ============================================================

-- Roles
DROP ROLE role_emprestimosdb_read;
CREATE ROLE role_emprestimosdb_read;
DROP ROLE role_emprestimosdb_write;
CREATE ROLE role_emprestimosdb_write;

-- Roles para visitor users (outros nos)
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_emp_visitante'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE ROLE role_emp_visitante;
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_emp_programas'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE ROLE role_emp_programas;

-- Privilegios de sessao
GRANT CREATE SESSION TO usr_emprestimosdb;
GRANT CREATE SESSION TO app_emprestimosdb;
GRANT CREATE SESSION TO app_nacionaldb;
GRANT CREATE SESSION TO app_materiaisdb;
GRANT CREATE SESSION TO app_eventosdb;

-- Privilegios DDL ao utilizador principal
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE TRIGGER, CREATE PROCEDURE, CREATE SYNONYM,
      CREATE PUBLIC SYNONYM, DROP PUBLIC SYNONYM,
      CREATE DATABASE LINK, CREATE PUBLIC DATABASE LINK,
      DROP PUBLIC DATABASE LINK, CREATE MATERIALIZED VIEW
TO usr_emprestimosdb;

-- Roles ao utilizador de aplicacao local
GRANT role_emprestimosdb_read TO app_emprestimosdb;

-- Roles de visitor aos outros nos
GRANT role_emp_visitante TO app_materiaisdb;
GRANT role_emp_programas TO app_nacionaldb;
GRANT role_emp_programas TO app_eventosdb;