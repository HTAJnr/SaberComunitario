-- ============================================
-- UTILIZADORES - EventosBibliotecasDB
-- ============================================
CREATE USER usr_eventosdb IDENTIFIED BY eventos1234
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON tbs_eventosdb
    QUOTA UNLIMITED ON tbs_eventosdb_idx;

CREATE USER app_eventosdb IDENTIFIED BY appev1234
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP;

-- Utilizadores remotos (para GRANTs cross-node)
CREATE USER app_nacionaldb   IDENTIFIED BY HTAJnr#22041
    DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;
CREATE USER app_materiaisdb  IDENTIFIED BY YM20240260
    DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;
CREATE USER app_emprestimosdb IDENTIFIED BY YC20220156
    DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;

GRANT CREATE SESSION TO app_nacionaldb;
GRANT CREATE SESSION TO app_materiaisdb;
GRANT CREATE SESSION TO app_emprestimosdb;
