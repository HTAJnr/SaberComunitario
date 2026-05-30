-- Roles
DROP ROLE role_NACIONALDB_read;
CREATE ROLE role_NACIONALDB_read;

DROP ROLE role_NACIONALDB_write;
CREATE ROLE role_NACIONALDB_write;

-- Roles para visitor users (outros nos)
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_nac_visitante';   EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE ROLE role_nac_visitante;
BEGIN EXECUTE IMMEDIATE 'DROP ROLE role_nac_leitor_tipo'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE ROLE role_nac_leitor_tipo;

-- Privilégios de sessão

REVOKE role_NACIONALDB_read FROM app_NACIONALDB;
REVOKE CREATE SESSION FROM usr_NACIONALDB;
REVOKE CREATE SESSION FROM app_NACIONALDB;
REVOKE CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
CREATE TRIGGER, CREATE PROCEDURE, CREATE SYNONYM, CREATE PUBLIC SYNONYM,
CREATE MATERIALIZED VIEW, CREATE DATABASE LINK, CREATE PUBLIC DATABASE LINK
FROM usr_NACIONALDB;

GRANT CREATE SESSION TO usr_NACIONALDB;
GRANT CREATE SESSION TO app_NACIONALDB;

-- Privilégios DDL ao utilizador principal
-- CREATE PUBLIC DATABASE LINK é necessário para que app_NACIONALDB (user da app)
-- possa resolver os links usados pelos PUBLIC synonyms.
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE TRIGGER, CREATE PROCEDURE, CREATE SYNONYM,
      CREATE PUBLIC SYNONYM, CREATE MATERIALIZED VIEW,
      CREATE DATABASE LINK, CREATE PUBLIC DATABASE LINK,
      DROP PUBLIC DATABASE LINK TO usr_NACIONALDB;

-- Roles ao utilizador de aplicacao local
-- SYSDBA é obrigatorio aqui — usr_NACIONALDB nao tem ADMIN OPTION nestes roles.
GRANT role_NACIONALDB_read  TO app_NACIONALDB;
GRANT role_NACIONALDB_write TO app_NACIONALDB;

-- Roles de visitor aos outros nos
GRANT role_nac_visitante   TO app_emprestimosdb;
GRANT role_nac_visitante   TO app_materiaisdb;
GRANT role_nac_visitante   TO app_eventosdb;
GRANT role_nac_leitor_tipo TO app_emprestimosdb;
GRANT role_nac_leitor_tipo TO app_eventosdb;