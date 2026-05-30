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
DROP MATERIALIZED VIEW repl_funcionarios;

CREATE MATERIALIZED VIEW repl_funcionarios
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT f.cod_funcionario, f.nome_funcionario, f.cod_biblioteca,
       fn.nivel_acesso
FROM funcionario@link_nacionaldb f,
     funcao_funcionario@link_nacionaldb fn
WHERE f.id_funcao = fn.id_funcao AND f.data_demissao IS NULL;

-- ============================================================
-- SNAPSHOT 2 — biblioteca_snap
-- Replica bibliotecas do EventosBibliotecasDB (Gerson)
-- Permite verificar dados de bibliotecas sem depender
-- da disponibilidade do no do Gerson
-- ============================================================
DROP MATERIALIZED VIEW biblioteca_snap;

CREATE MATERIALIZED VIEW biblioteca_snap
  BUILD IMMEDIATE
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
DROP MATERIALIZED VIEW snap_leitor_publico;

CREATE MATERIALIZED VIEW snap_leitor_publico
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT num_cartao, nome_completo, cod_biblioteca,
       status_leitor, historico_pontualidade, distancia_biblioteca
FROM leitor@link_nacionaldb;

-- RECOMPILAR O TRIGGER QUE DEPENDE DO SNAP 1
ALTER TRIGGER trg_valida_transferencia COMPILE;