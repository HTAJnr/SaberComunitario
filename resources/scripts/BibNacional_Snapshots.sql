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

-- ============================================================
-- TAREFA A1 — Mecanismo SNAPSHOT (Guia BD2 Tema 8.19)
--
-- Em Oracle 9i o nome "Snapshot" foi substituído por "Materialized View".
-- O mecanismo é IDÊNTICO — CREATE MATERIALIZED VIEW = Snapshot do guia.
-- A biblioteca_snap ACIMA é exactamente o Snapshot que o guia descreve.
--
-- COMPARAÇÃO DE MODOS DE REFRESH:
--   REFRESH COMPLETE: recalcula toda a MV a partir do zero.
--     Não exige snapshot log no nó remoto. Mais lento, mais robusto.
--   REFRESH FAST: propaga apenas as alterações (delta).
--     Exige MVIEW LOG criado no nó remoto — impossível em Oracle 10g XE
--     sem controlo sobre o schema do Gerson. Por isso COMPLETE é correcto.
--
-- PORQUÊ BUILD DEFERRED e não BUILD IMMEDIATE?
--   BUILD IMMEDIATE tenta ler biblioteca@eventosdb NO MOMENTO da criação.
--   Se o nó do Gerson estiver offline, o script falha antes de criar
--   qualquer objectos. BUILD DEFERRED cria a estrutura em vazio e
--   deixa o refresh para quando o nó estiver disponível.
-- ============================================================

-- ── VARIANTE COM REFRESH AUTOMÁTICO — Demonstração conceptual ──
-- (Manter comentado em produção — o nó do Gerson pode estar offline)
-- Num ambiente com disponibilidade garantida, este seria o padrão:
/*
CREATE MATERIALIZED VIEW biblioteca_snap_auto
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24   -- refrescar a cada hora
  AS SELECT * FROM biblioteca@eventosdb;
*/

-- ── Verificar MVs existentes no schema ───────────────────────
-- (Output para incluir no relatório)
SELECT MVIEW_NAME, REFRESH_MODE, REFRESH_METHOD, BUILD_MODE, LAST_REFRESH_DATE
  FROM USER_MVIEWS
 ORDER BY MVIEW_NAME;

-- ============================================================
-- REDE REMOTA (ZeroTier) — Descomentar apenas quando o Gerson
-- estiver em rede remota. Em rede local manter comentado.
-- ============================================================
/*
DROP MATERIALIZED VIEW biblioteca_snap;

CREATE MATERIALIZED VIEW biblioteca_snap
  BUILD IMMEDIATE
  REFRESH COMPLETE ON DEMAND
  AS SELECT * FROM usr_eventosdb.biblioteca@zeventosdb;

SELECT COUNT(*) AS BIBLIOTECAS_IMPORTADAS_REMOTO FROM biblioteca_snap;
*/
