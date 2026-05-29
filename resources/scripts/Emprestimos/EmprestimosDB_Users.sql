-- ============================================================
-- EmprestimosProg_Users.sql
-- Executar como SYSDBA
-- ============================================================

-- Utilizador principal (dono dos objectos)
CREATE USER usr_emprestimosdb IDENTIFIED BY "YC20220156"
  DEFAULT TABLESPACE tbs_emprestimosdb
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON tbs_emprestimosdb
  QUOTA UNLIMITED ON tbs_emprestimosdb_idx;

-- Utilizador de aplicacao (backend Node.js)
CREATE USER app_emprestimosdb IDENTIFIED BY "YC20220156"
  DEFAULT TABLESPACE tbs_emprestimosdb
  TEMPORARY TABLESPACE TEMP;

-- Visitor user do Helder (BibliotecaNacionalDB)
DROP USER app_nacionaldb CASCADE;
CREATE USER app_nacionaldb IDENTIFIED BY "HTAJnr#22041"
  DEFAULT TABLESPACE tbs_emprestimosdb
  TEMPORARY TABLESPACE TEMP;

-- Visitor user do Yasin (MateriaisDB)
DROP USER app_materiaisdb CASCADE;
CREATE USER app_materiaisdb IDENTIFIED BY "YM20240260"
  DEFAULT TABLESPACE tbs_emprestimosdb
  TEMPORARY TABLESPACE TEMP;