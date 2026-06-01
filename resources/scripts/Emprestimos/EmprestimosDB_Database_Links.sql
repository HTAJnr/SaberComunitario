-- ============================================================
-- EmprestimosDB_Database_Links.sql
-- Pré-requisito: usr_emprestimosdb precisa de CREATE PUBLIC DATABASE LINK
--   (concedido em EmprestimosDB_Roles.sql via sysdba)
-- Executar como: usr_emprestimosdb
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
  drop_link('nacionaldb');
  drop_link('materiaisdb');
  drop_link('eventosdb');
END;
/

CREATE PUBLIC DATABASE LINK nacionaldb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "YC20220156"
  USING 'NACIONALDB';

CREATE PUBLIC DATABASE LINK materiaisdb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "YC20220156"
  USING 'MATERIAISDB';

CREATE PUBLIC DATABASE LINK eventosdb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "YC20220156"
  USING 'EVENTOSDB';
