-- ============================================================
-- MateriaisDB_Roles.sql
-- Executar como: SYSDBA
-- ============================================================

DROP ROLE role_materiaisdb_read;
CREATE ROLE role_materiaisdb_read;
DROP ROLE role_materiaisdb_write;
CREATE ROLE role_materiaisdb_write;

-- Roles para visitor users (outros nos)
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_mat_leitura';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE ROLE role_mat_leitura;
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_mat_completo'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE ROLE role_mat_completo;

-- Privilégios DDL ao utilizador principal
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE TRIGGER, CREATE PROCEDURE, CREATE SYNONYM,
      CREATE PUBLIC SYNONYM, CREATE DATABASE LINK,
      CREATE PUBLIC DATABASE LINK, DROP PUBLIC DATABASE LINK,
      CREATE MATERIALIZED VIEW
TO usr_materiaisdb;

-- Atribuir roles ao utilizador de aplicacao local
GRANT role_materiaisdb_read TO app_materiaisdb;

-- Atribuir roles de visitor aos outros nos
GRANT role_mat_leitura  TO app_emprestimosdb;
GRANT role_mat_leitura  TO app_eventosdb;
GRANT role_mat_completo TO app_nacionaldb;

