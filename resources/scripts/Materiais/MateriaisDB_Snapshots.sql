-- ============================================================
-- MateriaisDB_Snapshots.sql — Snapshots (Materialized Views)
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Database_Links.sql
--
-- NOTA: Os nos remotos devem estar online durante a criacao
-- BUILD IMMEDIATE popula o snapshot imediatamente
-- REFRESH COMPLETE a cada hora (NEXT SYSDATE + 1/24)
-- ============================================================


-- ============================================================
-- SNAPSHOT 1 — repl_funcionarios
-- Replica funcionarios do BibliotecaNacionalDB (Helder)
-- Permite verificar dados de funcionarios sem depender
-- da disponibilidade do no do Helder
-- ============================================================
CREATE MATERIALIZED VIEW repl_funcionarios
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT cod_funcionario, nome_funcionario, cod_biblioteca, nivel_acesso
FROM vw_replica_funcionarios@link_nacionaldb;


-- ============================================================
-- SNAPSHOT 2 — biblioteca_snap
-- Replica bibliotecas do EventosBibliotecasDB (Gerson)
-- Permite verificar dados de bibliotecas sem depender
-- da disponibilidade do no do Gerson
-- ============================================================
CREATE MATERIALIZED VIEW biblioteca_snap
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT * FROM biblioteca@link_eventosdb;


-- ============================================================
-- SNAPSHOT 3 — snap_leitor_publico
-- Replica leitores publicos do BibliotecaNacionalDB (Helder)
-- Permite verificar dados de leitores sem depender
-- da disponibilidade do no do Helder
-- ============================================================
CREATE MATERIALIZED VIEW snap_leitor_publico
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT num_cartao, nome_completo, cod_biblioteca,
       status_leitor, historico_pontualidade, distancia_biblioteca
FROM vw_leitor_publico@link_nacionaldb;


