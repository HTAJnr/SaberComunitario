-- ============================================================
-- MateriaisDB_Roles.sql
-- Executar como: SYSDBA
-- ============================================================

DROP ROLE role_materiaisdb_read;
CREATE ROLE role_materiaisdb_read;
DROP ROLE role_materiaisdb_write;
CREATE ROLE role_materiaisdb_write;

-- Privilégios DDL ao utilizador principal
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE TRIGGER, CREATE PROCEDURE, CREATE SYNONYM,
      CREATE PUBLIC SYNONYM, CREATE DATABASE LINK,
      CREATE PUBLIC DATABASE LINK, DROP PUBLIC DATABASE LINK,
      CREATE MATERIALIZED VIEW
TO usr_materiaisdb;

-- Atribuir role de leitura ao utilizador de aplicação
GRANT role_materiaisdb_read TO app_materiaisdb;

