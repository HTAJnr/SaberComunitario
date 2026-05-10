-- ============================================================
-- BibNacional_Synonyms.sql
-- Sinónimos privados no schema usr_NACIONALDB para todos os
-- objectos cross-node acedidos pelo backend Node.js.
--
-- Executar após BibNacional_Database_Links.sql (os links têm
-- de existir antes dos sinónimos que lhes apontam).
--
-- PROPÓSITO: Transparência de localização.
-- O backend escreve apenas nomes simples (EMPRESTIMO, BIBLIOTECA…)
-- e o Oracle resolve silenciosamente onde estão os dados.
-- Se um nó mudar de IP/alias, basta actualizar o database link —
-- o backend não precisa de tocar.
-- ============================================================

-- ── EmpréstimosDB (Yannis) ──────────────────────────────────
CREATE OR REPLACE SYNONYM emprestimo                 FOR emprestimo@emprestimosdb;
CREATE OR REPLACE SYNONYM suspensao                  FOR suspensao@emprestimosdb;
CREATE OR REPLACE SYNONYM seq_emprestimo             FOR seq_emprestimo@emprestimosdb;
CREATE OR REPLACE SYNONYM programa_alfabetizacao     FOR programa_alfabetizacao@emprestimosdb;
CREATE OR REPLACE SYNONYM nivel_progressao           FOR nivel_progressao@emprestimosdb;
CREATE OR REPLACE SYNONYM programa_material          FOR programa_material@emprestimosdb;
CREATE OR REPLACE SYNONYM programa_funcionario       FOR programa_funcionario@emprestimosdb;
CREATE OR REPLACE SYNONYM participacao_programa      FOR participacao_programa@emprestimosdb;
CREATE OR REPLACE SYNONYM seq_nivel                  FOR seq_nivel@emprestimosdb;
CREATE OR REPLACE SYNONYM vw_emprestimos_ativos      FOR vw_emprestimos_ativos@emprestimosdb;
CREATE OR REPLACE SYNONYM vw_historico_emprestimos   FOR vw_historico_emprestimos@emprestimosdb;
CREATE OR REPLACE SYNONYM processar_devolucao        FOR processar_devolucao@emprestimosdb;

-- ── MateriaisDB (Yasin) ─────────────────────────────────────
CREATE OR REPLACE SYNONYM material_bibliografico       FOR material_bibliografico@materiaisdb;
CREATE OR REPLACE SYNONYM categoria                    FOR categoria@materiaisdb;
CREATE OR REPLACE SYNONYM livro_fisico                 FOR livro_fisico@materiaisdb;
CREATE OR REPLACE SYNONYM ebook                        FOR ebook@materiaisdb;
CREATE OR REPLACE SYNONYM periodico                    FOR periodico@materiaisdb;
CREATE OR REPLACE SYNONYM transferencia                FOR transferencia@materiaisdb;
CREATE OR REPLACE SYNONYM seq_transferencia            FOR seq_transferencia@materiaisdb;
CREATE OR REPLACE SYNONYM vw_materiais_completos       FOR vw_materiais_completos@materiaisdb;
CREATE OR REPLACE SYNONYM vw_transferencias_detalhadas FOR vw_transferencias_detalhadas@materiaisdb;

-- ── EventosBibliotecasDB (Gerson) ───────────────────────────
CREATE OR REPLACE SYNONYM evento                       FOR evento@eventosdb;
CREATE OR REPLACE SYNONYM participacao_evento          FOR participacao_evento@eventosdb;
CREATE OR REPLACE SYNONYM avaliacao_evento             FOR avaliacao_evento@eventosdb;
CREATE OR REPLACE SYNONYM horario_evento               FOR horario_evento@eventosdb;
CREATE OR REPLACE SYNONYM horario_biblioteca           FOR horario_biblioteca@eventosdb;
CREATE OR REPLACE SYNONYM evento_recurso               FOR evento_recurso@eventosdb;
CREATE OR REPLACE SYNONYM biblioteca                   FOR biblioteca@eventosdb;
CREATE OR REPLACE SYNONYM seq_evento                   FOR seq_evento@eventosdb;
CREATE OR REPLACE SYNONYM seq_avaliacao                FOR seq_avaliacao@eventosdb;
CREATE OR REPLACE SYNONYM vw_eventos_proximos          FOR vw_eventos_proximos@eventosdb;
CREATE OR REPLACE SYNONYM vw_eventos_completos         FOR vw_eventos_completos@eventosdb;
CREATE OR REPLACE SYNONYM insere_participacao_evento   FOR insere_participacao_evento@eventosdb;

-- Verificação apagar apos testes
SELECT SYNONYM_NAME, TABLE_OWNER, DB_LINK
  FROM USER_SYNONYMS
 ORDER BY DB_LINK, SYNONYM_NAME;

