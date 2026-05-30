-- ============================================
-- UTILIZADORES - EventosBibliotecasDB
-- Executar como SYSDBA
-- ============================================

-- Utilizadores principais
DROP USER usr_eventosdb CASCADE;
CREATE USER usr_eventosdb IDENTIFIED BY eventos1234
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON tbs_eventosdb
    QUOTA UNLIMITED ON tbs_eventosdb_idx;

DROP USER app_eventosdb CASCADE;
CREATE USER app_eventosdb IDENTIFIED BY appev1234
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP;

-- Utilizadores remotos (visitor users — os outros nos ligam-se com estes)
DROP USER app_nacionaldb CASCADE;
CREATE USER app_nacionaldb IDENTIFIED BY "HTAJnr#22041"
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_nacionaldb;

DROP USER app_materiaisdb CASCADE;
CREATE USER app_materiaisdb IDENTIFIED BY "YM20240260"
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_materiaisdb;

DROP USER app_emprestimosdb CASCADE;
CREATE USER app_emprestimosdb IDENTIFIED BY "YC20220156"
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_emprestimosdb;

-- Verificar
SELECT USERNAME, DEFAULT_TABLESPACE, ACCOUNT_STATUS
FROM DBA_USERS
WHERE USERNAME IN (
    'USR_EVENTOSDB','APP_EVENTOSDB',
    'APP_NACIONALDB','APP_MATERIAISDB','APP_EMPRESTIMOSDB'
);