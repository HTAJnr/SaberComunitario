-- ============================================================
-- SNAPSHOTS (MATERIALIZED VIEWS) - EventosBibliotecasDB
-- Executar como usr_eventosdb
-- Executar DEPOIS de: EventosDB_Database_Links.sql
--
-- Pre-requisitos:
--   Helder: GRANT SELECT ON vw_replica_funcionarios TO app_eventosdb
--   Helder: GRANT SELECT ON vw_leitor_publico       TO app_eventosdb
--
-- BUILD IMMEDIATE popula o snapshot no momento da criacao
-- REFRESH COMPLETE a cada hora (NEXT SYSDATE + 1/24)
-- ============================================================


-- ============================================================
-- SNAPSHOT 1 — repl_funcionarios
-- Replica funcionarios do BibliotecaNacionalDB (Helder)
-- Se o Helder estiver offline, os dados locais continuam disponiveis
-- ============================================================
DROP MATERIALIZED VIEW repl_funcionarios;

CREATE MATERIALIZED VIEW repl_funcionarios
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT cod_funcionario, nome_funcionario,
       cod_biblioteca, nivel_acesso
FROM vw_replica_funcionarios@link_nacionaldb;


-- ============================================================
-- SNAPSHOT 2 — snap_leitor
-- Replica leitores do BibliotecaNacionalDB (Helder)
-- Necessario para: inscrever participantes em eventos,
-- listar participantes com nome, validar existencia de leitor
-- Se o Helder estiver offline, as inscricoes em eventos continuam
-- ============================================================
DROP MATERIALIZED VIEW snap_leitor;

CREATE MATERIALIZED VIEW snap_leitor
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT num_cartao, nome_completo, cod_biblioteca,
       status_leitor, historico_pontualidade, distancia_biblioteca
FROM vw_leitor_publico@link_nacionaldb;
