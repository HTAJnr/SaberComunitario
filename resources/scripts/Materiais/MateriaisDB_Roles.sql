-- ============================================================
-- MateriaisDB_Roles.sql
-- Executar como: SYSDBA
-- ============================================================

DROP ROLE role_materiaisdb_read;
CREATE ROLE role_materiaisdb_read;
DROP ROLE role_materiaisdb_write;
CREATE ROLE role_materiaisdb_write;

-- Atribuir role de leitura ao utilizador de aplicação
GRANT role_materiaisdb_read TO app_materiaisdb;

