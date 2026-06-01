-- ============================================================
-- MateriaisDB_Database_Links.sql
-- Pré-requisito: usr_materiaisdb precisa de CREATE PUBLIC DATABASE LINK
--   (concedido em MateriaisDB_Roles.sql via sysdba)
-- Executar como: usr_materiaisdb
-- Ignora ORA-02024 (link inexistente) em primeira instalação.
-- ============================================================
DECLARE
  PROCEDURE drop_link(p_link IN VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'DROP PUBLIC DATABASE LINK ' || p_link;
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -2024 THEN RAISE; END IF;
  END;
BEGIN
  drop_link('link_emprestimosdb');
  drop_link('link_eventosdb');
  drop_link('link_nacionaldb');
END;
/

CREATE PUBLIC DATABASE LINK link_emprestimosdb
  CONNECT TO app_materiaisdb IDENTIFIED BY "YM20240260"
  USING 'EMPRESTIMOSDB';

CREATE PUBLIC DATABASE LINK link_eventosdb
  CONNECT TO app_materiaisdb IDENTIFIED BY "YM20240260"
  USING 'EVENTOSDB';

CREATE PUBLIC DATABASE LINK link_nacionaldb
  CONNECT TO app_materiaisdb IDENTIFIED BY "YM20240260"
  USING 'NACIONALDB';
