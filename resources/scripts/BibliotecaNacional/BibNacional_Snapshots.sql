-- ============================================================
-- BibNacional_Snapshots.sql
-- Materialized Views (snapshots) do nó BibliotecaNacionalDB.
-- Guia BD2 Tema 8.19 — parâmetros START WITH / NEXT
--
-- MV 1 — biblioteca_snap
--   Master: EventosDB (Gerson). Replica a tabela BIBLIOTECA.
--   Requer: nó do Gerson online no momento da criação.
--   Requer: app_nacionaldb com SELECT ON BIBLIOTECA no EventosDB.
--
-- MV 2 — mv_relatorio_programas
--   Master: EmprestimosDB (Yannis). Agrega programas + participantes.
--   Requer: nó do Yannis online no momento da criação.
--   Requer: app_nacionaldb com SELECT ON PROGRAMA_ALFABETIZACAO,
--           PARTICIPACAO_PROGRAMA, NIVEL_PROGRESSAO no EmprestimosDB.
-- ============================================================


-- ============================================================
-- MV 1: biblioteca_snap
-- ============================================================

DROP MATERIALIZED VIEW biblioteca_snap;

CREATE MATERIALIZED VIEW biblioteca_snap
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT * FROM usr_eventosdb.biblioteca@eventosdb;


-- ============================================================
-- MV 2: mv_relatorio_programas
-- FIX ORA-00904: cada tabela remota encapsulada em inline view.
-- O Oracle executa cada subquery no nó remoto, devolve resultado
-- local, e o JOIN é resolvido localmente — sem ambiguidade de alias.
-- ============================================================

DROP MATERIALIZED VIEW mv_relatorio_programas;

CREATE MATERIALIZED VIEW mv_relatorio_programas
  REFRESH COMPLETE ON DEMAND
AS
SELECT
    p.cod_programa,
    p.cod_biblioteca,
    p.nome_programa,
    p.publico_alvo,
    p.duracao_semanas,
    p.estado_programa,
    COUNT(pp.num_cartao)                                                   AS total_participantes,
    SUM(CASE WHEN pp.estado_participacao = 'Activo'    THEN 1 ELSE 0 END) AS participantes_activos,
    SUM(CASE WHEN pp.estado_participacao = 'Concluido' THEN 1 ELSE 0 END) AS participantes_concluidos,
    SUM(CASE WHEN pp.estado_participacao = 'Desistiu'  THEN 1 ELSE 0 END) AS participantes_desistiram
FROM usr_emprestimosdb.PROGRAMA_ALFABETIZACAO@emprestimosdb p
LEFT JOIN usr_emprestimosdb.PARTICIPACAO_PROGRAMA@emprestimosdb pp
    ON p.cod_programa = pp.cod_programa
GROUP BY
    p.cod_programa, p.cod_biblioteca, p.nome_programa,
    p.publico_alvo, p.duracao_semanas, p.estado_programa;


-- ============================================================
-- MV 3: snap_material_basico
-- Master: MateriaisDB. Replica colunas mínimas de MATERIAL_BIBLIOGRAFICO
-- para joins no dashboard sem depender de MATERIAISDB estar online.
-- Requer: app_nacionaldb com SELECT ON MATERIAL_BIBLIOGRAFICO no MateriaisDB.
-- ============================================================

DROP MATERIALIZED VIEW snap_material_basico;

CREATE MATERIALIZED VIEW snap_material_basico
  REFRESH COMPLETE ON DEMAND
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT cod_material, titulo, cod_biblioteca, estado_material_conservacao
FROM usr_materiaisdb.material_bibliografico@materiaisdb;


-- ============================================================
-- MV 4: snap_emp_activos
-- Master: EmprestimosDB. Replica empréstimos sem devolução.
-- Dashboard usa este snapshot em vez do link live — funciona
-- mesmo com EMPRESTIMOSDB offline (dados da última actualização).
-- Requer: app_nacionaldb com SELECT ON EMPRESTIMO no EmprestimosDB.
-- ============================================================

DROP MATERIALIZED VIEW snap_emp_activos;

CREATE MATERIALIZED VIEW snap_emp_activos
  REFRESH COMPLETE ON DEMAND
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT id_emprestimo, num_cartao, cod_material,
       data_retirada, prazo_devolucao, multa_valor, multa_paga
FROM usr_emprestimosdb.emprestimo@emprestimosdb
WHERE data_devolucao IS NULL;


-- ============================================================
-- MV 5: snap_eventos
-- Master: EventosDB. Replica eventos (todos — filtragem por data
-- em tempo de execução para não desactualizar o snapshot).
-- Requer: app_nacionaldb com SELECT ON EVENTO no EventosDB.
-- ============================================================

DROP MATERIALIZED VIEW snap_eventos;

CREATE MATERIALIZED VIEW snap_eventos
  REFRESH COMPLETE ON DEMAND
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT id_evento, titulo_evento, data_evento, status_evento, cod_biblioteca
FROM usr_eventosdb.evento@eventosdb;


-- ============================================================
-- MV 6: snap_transferencias
-- Master: MateriaisDB. Replica transferências (estado + bibliotecas)
-- para o dashboard admin não depender de MATERIAISDB estar online.
-- Requer: app_nacionaldb com SELECT ON TRANSFERENCIA no MateriaisDB.
-- ============================================================

DROP MATERIALIZED VIEW snap_transferencias;

CREATE MATERIALIZED VIEW snap_transferencias
  REFRESH COMPLETE ON DEMAND
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT id_transferencia, cod_material, estado_transferencia,
       cod_biblioteca_origem, cod_biblioteca_destino
FROM usr_materiaisdb.transferencia@materiaisdb;