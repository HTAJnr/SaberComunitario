-- ============================================================
-- EmprestimosProg_Roles.sql
-- Executar como SYSDBA
-- ============================================================

-- Roles
CREATE ROLE role_emprestimosdb_read;
CREATE ROLE role_emprestimosdb_write;

-- Privilegios de sessao
GRANT CREATE SESSION TO usr_emprestimosdb;
GRANT CREATE SESSION TO app_emprestimosdb;
GRANT CREATE SESSION TO app_nacionaldb;
GRANT CREATE SESSION TO app_materiaisdb;

-- Privilegios DDL ao utilizador principal
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE TRIGGER, CREATE PROCEDURE, CREATE SYNONYM,
      CREATE PUBLIC SYNONYM, CREATE DATABASE LINK,
      CREATE MATERIALIZED VIEW
TO usr_emprestimosdb;

-- Role de leitura ao utilizador de aplicacao
GRANT role_emprestimosdb_read TO app_emprestimosdb;