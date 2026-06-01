-- ============================================================
-- EmprestimosProg_Users.sql
-- Executar como SYSDBA
-- ============================================================

-- Utilizador principal (dono dos objectos)
BEGIN EXECUTE IMMEDIATE 'DROP USER usr_emprestimosdb CASCADE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1918 THEN RAISE; END IF; END;
/
CREATE USER usr_emprestimosdb IDENTIFIED BY "YC20220156"
  DEFAULT TABLESPACE tbs_emprestimosdb
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON tbs_emprestimosdb
  QUOTA UNLIMITED ON tbs_emprestimosdb_idx;

-- Utilizador de aplicacao (backend Node.js)
BEGIN EXECUTE IMMEDIATE 'DROP USER app_emprestimosdb CASCADE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1918 THEN RAISE; END IF; END;
/
CREATE USER app_emprestimosdb IDENTIFIED BY "YC20220156"
  DEFAULT TABLESPACE tbs_emprestimosdb
  TEMPORARY TABLESPACE TEMP;

-- Visitor user do Helder (BibliotecaNacionalDB)
BEGIN EXECUTE IMMEDIATE 'DROP USER app_nacionaldb CASCADE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1918 THEN RAISE; END IF; END;
/
CREATE USER app_nacionaldb IDENTIFIED BY "HTAJnr#22041"
  DEFAULT TABLESPACE tbs_emprestimosdb
  TEMPORARY TABLESPACE TEMP;

-- Visitor user do Yasin (MateriaisDB)
BEGIN EXECUTE IMMEDIATE 'DROP USER app_materiaisdb CASCADE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1918 THEN RAISE; END IF; END;
/
CREATE USER app_materiaisdb IDENTIFIED BY "YM20240260"
  DEFAULT TABLESPACE tbs_emprestimosdb
  TEMPORARY TABLESPACE TEMP;

-- Visitor user do Gerson (EventosBibliotecasDB)
BEGIN EXECUTE IMMEDIATE 'DROP USER app_eventosdb CASCADE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1918 THEN RAISE; END IF; END;
/
CREATE USER app_eventosdb IDENTIFIED BY "appev1234"
  DEFAULT TABLESPACE tbs_emprestimosdb
  TEMPORARY TABLESPACE TEMP;
