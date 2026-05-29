-- ============================================================
-- BibNacional_Audit.sql
-- Auditoria Oracle nativa para o nó BibliotecaNacionalDB.
-- Executar como SYSDBA, após todos os objectos criados.
--
-- Tarefa 2.4 — Auditoria Oracle nativa (Fase 2)
-- Requisito: AUDIT_TRAIL = DB (verificar com SHOW PARAMETER AUDIT_TRAIL)
-- ============================================================

-- ── Auditoria de sessões ─────────────────────────────────────
-- Regista cada login/logoff dos utilizadores principais.
AUDIT CREATE SESSION BY usr_NACIONALDB;
AUDIT CREATE SESSION BY app_NACIONALDB;

-- ── Auditoria de operações por tabela ────────────────────────
-- WHENEVER SUCCESSFUL: só regista operações que correm sem erro.
-- DOADOR não tem WHENEVER SUCCESSFUL para capturar também tentativas
-- falhadas (ex: tentativa de apagar o doador anónimo id=0).

AUDIT INSERT, UPDATE, DELETE ON usr_NACIONALDB.FUNCIONARIO       BY SESSION WHENEVER SUCCESSFUL;
AUDIT INSERT, UPDATE, DELETE ON usr_NACIONALDB.LEITOR            BY SESSION WHENEVER SUCCESSFUL;
AUDIT INSERT, UPDATE, DELETE ON usr_NACIONALDB.CERTIFICADO_DOACAO BY SESSION WHENEVER SUCCESSFUL;
AUDIT DELETE                  ON usr_NACIONALDB.DOADOR            BY SESSION;

