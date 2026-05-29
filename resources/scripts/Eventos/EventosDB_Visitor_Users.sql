-- ============================================================
-- VISITOR USERS - EventosBibliotecasDB
-- Utilizadores que os outros nos usam para se ligar a este Oracle
-- Executar como SYSDBA
-- ============================================================

-- Para o Helder (BibliotecaNacionalDB)
DROP USER app_nacionaldb CASCADE;
CREATE USER app_nacionaldb IDENTIFIED BY HTAJnr#22041
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_nacionaldb;

-- Para o Yannis (EmprestimosDB)
DROP USER app_emprestimosdb CASCADE;
CREATE USER app_emprestimosdb IDENTIFIED BY YC20220156
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_emprestimosdb;

-- Para o Yasin (MateriaisDB)
DROP USER app_materiaisdb CASCADE;
CREATE USER app_materiaisdb IDENTIFIED BY YM20240260
    DEFAULT TABLESPACE tbs_eventosdb
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_materiaisdb;

-- Verificar
SELECT USERNAME, ACCOUNT_STATUS, DEFAULT_TABLESPACE
FROM DBA_USERS
WHERE USERNAME IN ('APP_NACIONALDB','APP_EMPRESTIMOSDB','APP_MATERIAISDB');