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
CREATE OR REPLACE PUBLIC SYNONYM emprestimo                 FOR emprestimo@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM suspensao                  FOR suspensao@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_emprestimo             FOR seq_emprestimo@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM programa_alfabetizacao     FOR programa_alfabetizacao@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM nivel_progressao           FOR nivel_progressao@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM programa_material          FOR programa_material@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM programa_funcionario       FOR programa_funcionario@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM participacao_programa      FOR participacao_programa@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_nivel                  FOR seq_nivel@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_emprestimos_ativos      FOR vw_emprestimos_ativos@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_historico_emprestimos   FOR vw_historico_emprestimos@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM processar_devolucao        FOR processar_devolucao@emprestimosdb;

-- ── MateriaisDB (Yasin) ─────────────────────────────────────
CREATE OR REPLACE PUBLIC SYNONYM material_bibliografico       FOR material_bibliografico@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM categoria                    FOR categoria@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM livro_fisico                 FOR livro_fisico@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM ebook                        FOR ebook@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM periodico                    FOR periodico@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM transferencia                FOR transferencia@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_transferencia            FOR seq_transferencia@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_materiais_completos       FOR vw_materiais_completos@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_transferencias_detalhadas FOR vw_transferencias_detalhadas@materiaisdb;

-- ── EventosBibliotecasDB (Gerson) ───────────────────────────
CREATE OR REPLACE PUBLIC SYNONYM evento                       FOR evento@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM participacao_evento          FOR participacao_evento@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM avaliacao_evento             FOR avaliacao_evento@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM horario_evento               FOR horario_evento@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM horario_biblioteca           FOR horario_biblioteca@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM evento_recurso               FOR evento_recurso@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM biblioteca                   FOR biblioteca_snap;
CREATE OR REPLACE PUBLIC SYNONYM seq_evento                   FOR seq_evento@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_avaliacao                FOR seq_avaliacao@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_eventos_proximos          FOR vw_eventos_proximos@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_eventos_completos         FOR vw_eventos_completos@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM insere_participacao_evento   FOR insere_participacao_evento@eventosdb;

-- ============================================================
-- REDE REMOTA (ZeroTier) — APAGAR esta secção quando voltares a rede local
-- Sobrepõe os sinónimos locais com as versões Z (ZeroTier).
-- Correr apenas quando os colegas estiverem em rede remota.
-- ============================================================
/*
-- ── EmpréstimosDB remoto (Yannis — @zemprestimosdb)
CREATE OR REPLACE PUBLIC SYNONYM emprestimo                 FOR emprestimo@zemprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM suspensao                  FOR suspensao@zemprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_emprestimo             FOR seq_emprestimo@zemprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM programa_alfabetizacao     FOR programa_alfabetizacao@zemprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM nivel_progressao           FOR nivel_progressao@zemprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM programa_material          FOR programa_material@zemprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM programa_funcionario       FOR programa_funcionario@zemprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM participacao_programa      FOR participacao_programa@zemprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_nivel                  FOR seq_nivel@zemprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_emprestimos_ativos      FOR vw_emprestimos_ativos@zemprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_historico_emprestimos   FOR vw_historico_emprestimos@zemprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM processar_devolucao        FOR processar_devolucao@zemprestimosdb;

-- ── MateriaisDB remoto (Yasin — @zmateriaisdb)
CREATE OR REPLACE PUBLIC SYNONYM material_bibliografico       FOR material_bibliografico@zmateriaisdb;
CREATE OR REPLACE PUBLIC SYNONYM categoria                    FOR categoria@zmateriaisdb;
CREATE OR REPLACE PUBLIC SYNONYM livro_fisico                 FOR livro_fisico@zmateriaisdb;
CREATE OR REPLACE PUBLIC SYNONYM ebook                        FOR ebook@zmateriaisdb;
CREATE OR REPLACE PUBLIC SYNONYM periodico                    FOR periodico@zmateriaisdb;
CREATE OR REPLACE PUBLIC SYNONYM transferencia                FOR transferencia@zmateriaisdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_transferencia            FOR seq_transferencia@zmateriaisdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_materiais_completos       FOR vw_materiais_completos@zmateriaisdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_transferencias_detalhadas FOR vw_transferencias_detalhadas@zmateriaisdb;

-- ── EventosBibliotecasDB remoto (Gerson — @zeventosdb)
CREATE OR REPLACE PUBLIC SYNONYM evento                       FOR evento@zeventosdb;
CREATE OR REPLACE PUBLIC SYNONYM participacao_evento          FOR participacao_evento@zeventosdb;
CREATE OR REPLACE PUBLIC SYNONYM avaliacao_evento             FOR avaliacao_evento@zeventosdb;
CREATE OR REPLACE PUBLIC SYNONYM horario_evento               FOR horario_evento@zeventosdb;
CREATE OR REPLACE PUBLIC SYNONYM horario_biblioteca           FOR horario_biblioteca@zeventosdb;
CREATE OR REPLACE PUBLIC SYNONYM evento_recurso               FOR evento_recurso@zeventosdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_evento                   FOR seq_evento@zeventosdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_avaliacao                FOR seq_avaliacao@zeventosdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_eventos_proximos          FOR vw_eventos_proximos@zeventosdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_eventos_completos         FOR vw_eventos_completos@zeventosdb;
CREATE OR REPLACE PUBLIC SYNONYM insere_participacao_evento   FOR insere_participacao_evento@zeventosdb;
-- biblioteca_snap já é local — ver BibNacional_Snapshots.sql para a versão remota
*/