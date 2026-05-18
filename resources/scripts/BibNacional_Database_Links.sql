-- ============================================================
-- BibNacional_DatabaseLinks.sql — Drop e recriação dos database links
-- Executar como usr_NACIONALDB (não como SYSDBA):
--   sqlplus usr_NACIONALDB/HTAJnr#020403 @/caminho/BibNacional_DatabaseLinks.sql
-- ============================================================

-- ============================================================
-- SECÇÃO 1: DROP DOS LINKS EXISTENTES
-- ============================================================

DROP DATABASE LINK materiaisdb;
DROP DATABASE LINK emprestimosdb;
DROP DATABASE LINK eventosdb;

DROP DATABASE LINK zmateriaisdb;
DROP DATABASE LINK zemprestimosdb;
DROP DATABASE LINK zeventosdb;

-- ============================================================
-- SECÇÃO 2: CRIAÇÃO — REDE LOCAL
-- Cada link conecta como app_nacionaldb — o visitor user criado
-- por cada colega no Oracle deles com a mesma password do app_ deles.
-- Assim não é necessário trocar passwords: cada um cria app_nacionaldb
-- com a password que já usa no próprio app_.
-- ============================================================

CREATE DATABASE LINK materiaisdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "YM20240260"
  USING 'MATERIAISDB';

CREATE DATABASE LINK emprestimosdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "YC20220156"
  USING 'EMPRESTIMOSDB';

CREATE DATABASE LINK eventosdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "appev1234"
  USING 'EVENTOSDB';

-- ============================================================
-- SECÇÃO 3: CRIAÇÃO — ZEROTIER (Para rede remota) Apagar antes de enviar o trabalho
-- ============================================================
/*
CREATE DATABASE LINK zmateriaisdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "YM20240260"
  USING 'ZMATERIAISDB';

CREATE DATABASE LINK zemprestimosdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "YC20220156"
  USING 'ZEMPRESTIMOSDB';

CREATE DATABASE LINK zeventosdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "appev1234"
  USING 'ZEVENTOSDB';
*/