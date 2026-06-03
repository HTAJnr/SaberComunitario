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
-- Se um nó mudar de IP/alias, basta actualizar o tnsnames.ora
-- e correr ./switch_rede.sh — o backend não precisa de tocar.
-- ============================================================

-- ── BibliotecaNacionalDB (local — objectos próprios) ────────
-- Necessário para os visitor users acederem via dblink
-- sem prefixar o schema usr_NACIONALDB.
CREATE OR REPLACE PUBLIC SYNONYM funcao_funcionario     FOR usr_NACIONALDB.funcao_funcionario;
CREATE OR REPLACE PUBLIC SYNONYM funcionario            FOR usr_NACIONALDB.funcionario;
CREATE OR REPLACE PUBLIC SYNONYM funcionario_habilidade FOR usr_NACIONALDB.funcionario_habilidade;
CREATE OR REPLACE PUBLIC SYNONYM horario_funcionario    FOR usr_NACIONALDB.horario_funcionario;
CREATE OR REPLACE PUBLIC SYNONYM leitor                 FOR usr_NACIONALDB.leitor;
CREATE OR REPLACE PUBLIC SYNONYM adulto                 FOR usr_NACIONALDB.adulto;
CREATE OR REPLACE PUBLIC SYNONYM adulto_interesse       FOR usr_NACIONALDB.adulto_interesse;
CREATE OR REPLACE PUBLIC SYNONYM professor              FOR usr_NACIONALDB.professor;
CREATE OR REPLACE PUBLIC SYNONYM professor_disciplina   FOR usr_NACIONALDB.professor_disciplina;
CREATE OR REPLACE PUBLIC SYNONYM crianca                FOR usr_NACIONALDB.crianca;
CREATE OR REPLACE PUBLIC SYNONYM doador                 FOR usr_NACIONALDB.doador;
CREATE OR REPLACE PUBLIC SYNONYM doacao                 FOR usr_NACIONALDB.doacao;
CREATE OR REPLACE PUBLIC SYNONYM item_doacao            FOR usr_NACIONALDB.item_doacao;
CREATE OR REPLACE PUBLIC SYNONYM certificado_doacao     FOR usr_NACIONALDB.certificado_doacao;
CREATE OR REPLACE PUBLIC SYNONYM auditoria_operacoes    FOR usr_NACIONALDB.auditoria_operacoes;

-- ── VIEWS ───────────────────────────────────────────────────

-- Doações e certificados
CREATE OR REPLACE PUBLIC SYNONYM vw_doacoes_detalhadas        FOR usr_NACIONALDB.vw_doacoes_detalhadas;
CREATE OR REPLACE PUBLIC SYNONYM vw_doadores_ranking          FOR usr_NACIONALDB.vw_doadores_ranking;
CREATE OR REPLACE PUBLIC SYNONYM vw_certificados_emitidos     FOR usr_NACIONALDB.vw_certificados_emitidos;

-- Funcionários
CREATE OR REPLACE PUBLIC SYNONYM vw_funcionarios_ativos       FOR usr_NACIONALDB.vw_funcionarios_ativos;
CREATE OR REPLACE PUBLIC SYNONYM vw_acesso_funcionario        FOR usr_NACIONALDB.vw_acesso_funcionario;
CREATE OR REPLACE PUBLIC SYNONYM vw_horarios_funcionario_semana FOR usr_NACIONALDB.vw_horarios_funcionario_semana;
CREATE OR REPLACE PUBLIC SYNONYM vw_replica_funcionarios      FOR usr_NACIONALDB.vw_replica_funcionarios;

-- Fragmentos verticais de funcionário
CREATE OR REPLACE PUBLIC SYNONYM vw_func_activos_operacional  FOR usr_NACIONALDB.vw_func_activos_operacional;
CREATE OR REPLACE PUBLIC SYNONYM vw_func_activos_confidencial FOR usr_NACIONALDB.vw_func_activos_confidencial;
CREATE OR REPLACE PUBLIC SYNONYM vw_func_inactivos_operacional  FOR usr_NACIONALDB.vw_func_inactivos_operacional;
CREATE OR REPLACE PUBLIC SYNONYM vw_func_inactivos_confidencial FOR usr_NACIONALDB.vw_func_inactivos_confidencial;

-- Leitores
CREATE OR REPLACE PUBLIC SYNONYM vw_leitores_completos        FOR usr_NACIONALDB.vw_leitores_completos;
CREATE OR REPLACE PUBLIC SYNONYM vw_leitor_publico            FOR usr_NACIONALDB.vw_leitor_publico;
CREATE OR REPLACE PUBLIC SYNONYM vw_leitor_privado            FOR usr_NACIONALDB.vw_leitor_privado;

-- Fragmentos horizontais de leitor
CREATE OR REPLACE PUBLIC SYNONYM vw_frag_leitor_activos       FOR usr_NACIONALDB.vw_frag_leitor_activos;
CREATE OR REPLACE PUBLIC SYNONYM vw_frag_leitor_suspensos     FOR usr_NACIONALDB.vw_frag_leitor_suspensos;
CREATE OR REPLACE PUBLIC SYNONYM vw_frag_leitor_inactivos     FOR usr_NACIONALDB.vw_frag_leitor_inactivos;

-- Vistas globais (cross-node)
CREATE OR REPLACE PUBLIC SYNONYM vw_global_leitores_emprestimos  FOR usr_NACIONALDB.vw_global_leitores_emprestimos;
CREATE OR REPLACE PUBLIC SYNONYM vw_global_catalogo              FOR usr_NACIONALDB.vw_global_catalogo;
CREATE OR REPLACE PUBLIC SYNONYM vw_global_eventos_participacao  FOR usr_NACIONALDB.vw_global_eventos_participacao;

-- Auditoria
CREATE OR REPLACE PUBLIC SYNONYM vw_auditoria                 FOR usr_NACIONALDB.vw_auditoria;

-- Dashboard (métricas)
CREATE OR REPLACE PUBLIC SYNONYM vw_metricas_sistema          FOR usr_NACIONALDB.vw_metricas_sistema;
CREATE OR REPLACE PUBLIC SYNONYM vw_metricas_por_biblioteca   FOR usr_NACIONALDB.vw_metricas_por_biblioteca;

-- Snapshots (acesso directo pelo backend — sem schema prefix)
CREATE OR REPLACE PUBLIC SYNONYM snap_emp_activos             FOR usr_NACIONALDB.snap_emp_activos;
CREATE OR REPLACE PUBLIC SYNONYM snap_material_basico         FOR usr_NACIONALDB.snap_material_basico;
CREATE OR REPLACE PUBLIC SYNONYM snap_eventos                 FOR usr_NACIONALDB.snap_eventos;
CREATE OR REPLACE PUBLIC SYNONYM snap_transferencias          FOR usr_NACIONALDB.snap_transferencias;

-- ── SEQUÊNCIAS LOCAIS ────────────────────────────────────────
-- Necessário para app_NACIONALDB usar SEQ_*.NEXTVAL/CURRVAL sem prefixar o schema.

CREATE OR REPLACE PUBLIC SYNONYM seq_doador         FOR usr_NACIONALDB.seq_doador;
CREATE OR REPLACE PUBLIC SYNONYM seq_doacao         FOR usr_NACIONALDB.seq_doacao;
CREATE OR REPLACE PUBLIC SYNONYM seq_itemdoado      FOR usr_NACIONALDB.seq_itemdoado;
CREATE OR REPLACE PUBLIC SYNONYM seq_certificado    FOR usr_NACIONALDB.seq_certificado;
CREATE OR REPLACE PUBLIC SYNONYM seq_auditoria      FOR usr_NACIONALDB.seq_auditoria;
CREATE OR REPLACE PUBLIC SYNONYM seq_funcao         FOR usr_NACIONALDB.seq_funcao;
CREATE OR REPLACE PUBLIC SYNONYM seq_funcionario    FOR usr_NACIONALDB.seq_funcionario;
CREATE OR REPLACE PUBLIC SYNONYM seq_horario_func   FOR usr_NACIONALDB.seq_horario_func;
CREATE OR REPLACE PUBLIC SYNONYM seq_permissao      FOR usr_NACIONALDB.seq_permissao;

-- ── TABELAS LOCAIS EM FALTA ───────────────────────────────────

CREATE OR REPLACE PUBLIC SYNONYM permissao_cargo    FOR usr_NACIONALDB.permissao_cargo;

-- ── FUNCTION ────────────────────────────────────────────────

CREATE OR REPLACE PUBLIC SYNONYM total_doacoes_doador         FOR usr_NACIONALDB.total_doacoes_doador;

-- ── PROCEDURES ──────────────────────────────────────────────

CREATE OR REPLACE PUBLIC SYNONYM registrar_doacao_completa    FOR usr_NACIONALDB.registrar_doacao_completa;
CREATE OR REPLACE PUBLIC SYNONYM reemitir_certificado         FOR usr_NACIONALDB.reemitir_certificado;
CREATE OR REPLACE PUBLIC SYNONYM prc_registar_auditoria       FOR usr_NACIONALDB.prc_registar_auditoria;
CREATE OR REPLACE PUBLIC SYNONYM prc_apagar_leitor            FOR usr_NACIONALDB.prc_apagar_leitor;
CREATE OR REPLACE PUBLIC SYNONYM prc_emitir_honorifico        FOR usr_NACIONALDB.prc_emitir_honorifico;
CREATE OR REPLACE PUBLIC SYNONYM prc_atualizar_doacao_segura  FOR usr_NACIONALDB.prc_atualizar_doacao_segura;
CREATE OR REPLACE PUBLIC SYNONYM prc_demo_2pc                 FOR usr_NACIONALDB.prc_demo_2pc;
CREATE OR REPLACE PUBLIC SYNONYM prc_refresh_snapshots        FOR usr_NACIONALDB.prc_refresh_snapshots;

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
CREATE OR REPLACE PUBLIC SYNONYM vw_emprestimos_activos     FOR usr_emprestimosdb.vw_emprestimos_activos@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_suspensoes_activas      FOR usr_emprestimosdb.vw_suspensoes_activas@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_historico_emprestimos   FOR vw_historico_emprestimos@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM processar_devolucao        FOR processar_devolucao@emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM repl_funcionarios          FOR repl_funcionarios@emprestimosdb;

-- ── MateriaisDB (Yasin) ─────────────────────────────────────
CREATE OR REPLACE PUBLIC SYNONYM vw_mat_disponivel            FOR usr_materiaisdb.vw_mat_disponivel@materiaisdb;
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
CREATE OR REPLACE PUBLIC SYNONYM seq_evento                   FOR seq_evento@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_avaliacao                FOR seq_avaliacao@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_eventos_proximos          FOR vw_eventos_proximos@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_eventos_completos         FOR vw_eventos_completos@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM insere_participacao_evento   FOR insere_participacao_evento@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM biblioteca_responsavel       FOR biblioteca_responsavel@eventosdb;

-- biblioteca_snap é uma MV local que replica BIBLIOTECA do EventosDB
CREATE OR REPLACE PUBLIC SYNONYM biblioteca                   FOR biblioteca_snap;
