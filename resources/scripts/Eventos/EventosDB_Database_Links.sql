-- ============================================================
-- DATABASE LINKS - EventosBibliotecasDB (v4)
-- Executar como usr_eventosdb
-- ============================================================

-- Apagar links existentes
DROP DATABASE LINK link_nacionaldb;
DROP DATABASE LINK link_materiaisdb;
DROP DATABASE LINK link_emprestimosdb;

-- Recriar com visitor user app_eventosdb
CREATE DATABASE LINK link_nacionaldb
    CONNECT TO app_eventosdb IDENTIFIED BY appev1234
    USING 'Nacionaldb';

CREATE DATABASE LINK link_materiaisdb
    CONNECT TO app_eventosdb IDENTIFIED BY appev1234
    USING 'Materiaisdb';

CREATE DATABASE LINK link_emprestimosdb
    CONNECT TO app_eventosdb IDENTIFIED BY appev1234
    USING 'Emprestimosdb';

-- Verificar
SELECT DB_LINK, USERNAME, HOST FROM USER_DB_LINKS;

-- Testar conectividade (so funciona com VMs ligadas)
-- SELECT SYSDATE FROM DUAL@link_nacionaldb;
-- SELECT SYSDATE FROM DUAL@link_materiaisdb;
-- SELECT SYSDATE FROM DUAL@link_emprestimosdb;