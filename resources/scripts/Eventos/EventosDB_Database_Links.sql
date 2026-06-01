-- ============================================================
-- EventosDB_Database_Links.sql
-- Pré-requisito: usr_eventosdb precisa de CREATE PUBLIC DATABASE LINK
--   (concedido em EventosDB_Roles.sql via sysdba)
-- Executar como: usr_eventosdb
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
  drop_link('link_nacionaldb');
  drop_link('link_materiaisdb');
  drop_link('link_emprestimosdb');
END;
/

CREATE PUBLIC DATABASE LINK link_nacionaldb
  CONNECT TO app_eventosdb IDENTIFIED BY "appev1234"
  USING 'NACIONALDB';

CREATE PUBLIC DATABASE LINK link_materiaisdb
  CONNECT TO app_eventosdb IDENTIFIED BY "appev1234"
  USING 'MATERIAISDB';

CREATE PUBLIC DATABASE LINK link_emprestimosdb
  CONNECT TO app_eventosdb IDENTIFIED BY "appev1234"
  USING 'EMPRESTIMOSDB';
