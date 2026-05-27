-- ============================================================
-- SNAPSHOT COM INTERVALO DE REFRESCAMENTO AUTOMÁTICO
-- Guia BD2 Tema 8.19 — parâmetros START WITH / NEXT
--
-- AVISO: BUILD IMMEDIATE tenta ler @eventosdb no momento da
-- criação. Só executar quando o nó do Gerson estiver online.
-- ============================================================

DROP MATERIALIZED VIEW biblioteca_snap;

/*
CREATE MATERIALIZED VIEW biblioteca_snap
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24 
AS
SELECT * FROM biblioteca@eventosdb;
*/

-- ── Versão remota ZEROTIER (Comentar quando estiver em rede local e não esquecer de apagar antes de enviar o trabalho) ─

CREATE MATERIALIZED VIEW biblioteca_snap
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24 
AS
SELECT * FROM biblioteca@zeventosdb;