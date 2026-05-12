-- ============================================================
-- BibNacional_Snapshots.sql
-- Materialized view local de BIBLIOTECA (nó EventosBibliotecasDB).
--
-- PROPÓSITO: O login faz LEFT JOIN BIBLIOTECA — se o nó do Gerson
-- estiver offline, o login falharia. A MV local garante que a
-- autenticação funciona independentemente do estado remoto.
--
-- Executar após BibNacional_Database_Links.sql.
-- O synonym BIBLIOTECA em BibNacional_Synonyms.sql aponta para
-- esta MV (não directamente para @eventosdb).
-- ============================================================

-- ── Drop da MV se existir ───────────────────────────────────
DROP MATERIALIZED VIEW biblioteca_snap;

-- ── Criação da MV ───────────────────────────────────────────
-- REFRESH COMPLETE ON DEMAND: não exige snapshot log no nó remoto.
-- Executar manualmente quando necessário:
--   EXEC DBMS_MVIEW.REFRESH('BIBLIOTECA_SNAP', 'C');
-- BUILD DEFERRED: cria a estrutura sem conectar ao nó remoto.
-- A MV fica vazia até ao primeiro refresh manual:
--   EXEC DBMS_MVIEW.REFRESH('BIBLIOTECA_SNAP', 'C');
CREATE MATERIALIZED VIEW biblioteca_snap
  BUILD DEFERRED
  REFRESH COMPLETE ON DEMAND
  AS
SELECT * FROM biblioteca@eventosdb;

-- ── Verificação ─────────────────────────────────────────────
SELECT COUNT(*) AS BIBLIOTECAS_IMPORTADAS FROM biblioteca_snap;
