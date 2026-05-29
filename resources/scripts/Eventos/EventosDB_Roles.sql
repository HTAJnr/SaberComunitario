-- ============================================
-- ROLES E PRIVILÉGIOS - EventosBibliotecasDB
-- Executar como SYSDBA
-- ============================================

CREATE ROLE role_eventosdb_read;
CREATE ROLE role_eventosdb_write;

-- Privilégios de sessão
GRANT CREATE SESSION TO usr_eventosdb;
GRANT CREATE SESSION TO app_eventosdb;

-- Privilégios DDL ao utilizador principal
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE TRIGGER, CREATE PROCEDURE, CREATE SYNONYM
TO usr_eventosdb;

-- Privilégio para database links
GRANT CREATE DATABASE LINK TO usr_eventosdb;

-- Privilégio para materialized views (snapshots)
GRANT CREATE MATERIALIZED VIEW TO usr_eventosdb;

-- Role de leitura ao utilizador de aplicação
GRANT role_eventosdb_read TO app_eventosdb;

-- Verificar
SELECT GRANTEE, GRANTED_ROLE FROM DBA_ROLE_PRIVS
WHERE GRANTEE IN ('USR_EVENTOSDB','APP_EVENTOSDB');