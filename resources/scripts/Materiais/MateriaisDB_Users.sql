-- ============================================================
-- MateriaisDB_Users.sql
-- Executar como: SYSDBA
-- ============================================================

-- Utilizador principal (dono dos objectos)
CREATE USER usr_materiaisdb IDENTIFIED BY YM20240260
  DEFAULT TABLESPACE tbs_MATERIAISDB
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON tbs_MATERIAISDB
  QUOTA UNLIMITED ON tbs_MATERIAISDB_idx;

-- Utilizador de aplicacao (acesso remoto via database link)
CREATE USER app_materiaisdb IDENTIFIED BY YM20240260
  DEFAULT TABLESPACE tbs_MATERIAISDB
  TEMPORARY TABLESPACE TEMP;

-- Privilegios de sessao
GRANT CREATE SESSION TO usr_materiaisdb;
GRANT CREATE SESSION TO app_materiaisdb;

-- Privilegios DDL ao utilizador principal
GRANT CREATE TABLE         TO usr_materiaisdb;
GRANT CREATE VIEW          TO usr_materiaisdb;
GRANT CREATE SEQUENCE      TO usr_materiaisdb;
GRANT CREATE TRIGGER       TO usr_materiaisdb;
GRANT CREATE PROCEDURE     TO usr_materiaisdb;
GRANT CREATE SYNONYM       TO usr_materiaisdb;
GRANT CREATE DATABASE LINK TO usr_materiaisdb;
GRANT CREATE MATERIALIZED VIEW TO usr_materiaisdb;

-- Privilegio para sinonimos publicos
GRANT CREATE PUBLIC SYNONYM TO usr_materiaisdb;
GRANT DROP PUBLIC SYNONYM   TO usr_materiaisdb;

-- ============================================================
-- VISITOR USERS
-- Utilizadores criados para outros nos acederem a este Oracle
-- Cada colega usa a password do seu proprio sistema
-- ============================================================

-- Para o Helder (BibliotecaNacionalDB)
CREATE USER app_nacionaldb IDENTIFIED BY "HTAJnr#22041"
  DEFAULT TABLESPACE tbs_MATERIAISDB
  TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_nacionaldb;

-- Para o Yannis (EmprestimosDB)
CREATE USER app_emprestimosdb IDENTIFIED BY "YC20220156"
  DEFAULT TABLESPACE tbs_MATERIAISDB
  TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_emprestimosdb;

-- Para o Gerson (EventosBibliotecasDB)
CREATE USER app_eventosdb IDENTIFIED BY "appev1234"
  DEFAULT TABLESPACE tbs_MATERIAISDB
  TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_eventosdb;

-- Verificacao
SELECT USERNAME, DEFAULT_TABLESPACE, ACCOUNT_STATUS
FROM DBA_USERS
WHERE USERNAME IN (
    'USR_MATERIAISDB','APP_MATERIAISDB',
    'APP_NACIONALDB','APP_EMPRESTIMOSDB','APP_EVENTOSDB'
)
ORDER BY USERNAME;
