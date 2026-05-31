-- ============================================================
-- MateriaisDB_Roles.sql
-- Executar como: SYSDBA
-- ============================================================

-- Limpar roles de versoes anteriores (tolerante a ORA-01919)
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_materiaisdb_read';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_materiaisdb_write'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_mat_leitura';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_mat_completo'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Roles locais do no (sessao directa — nao transitam por dblink)
CREATE ROLE role_materiaisdb_read;
CREATE ROLE role_materiaisdb_write;

-- Atribuir ao utilizador de aplicacao local
GRANT role_materiaisdb_read  TO app_materiaisdb;
GRANT role_materiaisdb_write TO app_materiaisdb;

-- Privilégios DDL ao utilizador principal
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE TRIGGER, CREATE PROCEDURE, CREATE SYNONYM,
      CREATE PUBLIC SYNONYM, CREATE DATABASE LINK,
      CREATE PUBLIC DATABASE LINK, DROP PUBLIC DATABASE LINK,
      CREATE MATERIALIZED VIEW
TO usr_materiaisdb;


