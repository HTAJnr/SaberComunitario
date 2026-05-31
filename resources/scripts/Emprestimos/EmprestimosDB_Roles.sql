-- ============================================================
-- EmprestimosProg_Roles.sql
-- Executar como SYSDBA
-- ============================================================

-- Limpar roles de versoes anteriores (tolerante a ORA-01919)
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_emprestimosdb_read';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_emprestimosdb_write'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Roles locais do no (sessao directa — nao transitam por dblink)
CREATE ROLE role_emprestimosdb_read;
CREATE ROLE role_emprestimosdb_write;

-- Atribuir ao utilizador de aplicacao local
GRANT role_emprestimosdb_read  TO app_emprestimosdb;
GRANT role_emprestimosdb_write TO app_emprestimosdb;

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

