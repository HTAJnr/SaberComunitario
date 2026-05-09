-- Roles
DROP ROLE role_NACIONALDB_read;
CREATE ROLE role_NACIONALDB_read;

DROP ROLE role_NACIONALDB_write;
CREATE ROLE role_NACIONALDB_write;

-- Privilégios de sessão

REVOKE role_NACIONALDB_read FROM app_NACIONALDB;
REVOKE CREATE SESSION FROM usr_NACIONALDB;
REVOKE CREATE SESSION FROM app_NACIONALDB;
REVOKE CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
CREATE TRIGGER, CREATE PROCEDURE, CREATE SYNONYM
FROM usr_NACIONALDB;

GRANT CREATE SESSION TO usr_NACIONALDB;
GRANT CREATE SESSION TO app_NACIONALDB;

-- Privilégios DDL ao utilizador principal
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE TRIGGER, CREATE PROCEDURE, CREATE SYNONYM
TO usr_NACIONALDB;

-- Role de leitura ao utilizador de aplicação
GRANT role_NACIONALDB_read TO app_NACIONALDB;

-- ============================================================
-- GRANTS SOBRE VISTAS — executar após BibNacional_Views.sql
-- ============================================================
-- IMPORTANTE: roles Oracle não propagam através de database links.
-- Acesso cross-node via @bibliotecanacionaldb exige GRANT directo
-- ao utilizador de conexão (app_NACIONALDB).
-- Os outros nós (EmpréstimosProgramasDB, MateriaisDB, EventosBibliotecasDB)
-- criam database links que conectam como app_NACIONALDB a este nó.

GRANT SELECT ON usr_NACIONALDB.vw_leitor_publico TO app_NACIONALDB;