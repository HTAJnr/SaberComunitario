-- ============================================================
-- SINONIMOS PUBLICOS - EventosBibliotecasDB (v4)
-- Executar como SYSDBA
-- ============================================================

-- Tabelas
CREATE OR REPLACE PUBLIC SYNONYM BIBLIOTECA
    FOR usr_eventosdb.BIBLIOTECA;
CREATE OR REPLACE PUBLIC SYNONYM HORARIO_BIBLIOTECA
    FOR usr_eventosdb.HORARIO_BIBLIOTECA;
CREATE OR REPLACE PUBLIC SYNONYM BIBLIOTECA_RESPONSAVEL
    FOR usr_eventosdb.BIBLIOTECA_RESPONSAVEL;
CREATE OR REPLACE PUBLIC SYNONYM EVENTO
    FOR usr_eventosdb.EVENTO;
CREATE OR REPLACE PUBLIC SYNONYM HORARIO_EVENTO
    FOR usr_eventosdb.HORARIO_EVENTO;
CREATE OR REPLACE PUBLIC SYNONYM PARTICIPACAO_EVENTO
    FOR usr_eventosdb.PARTICIPACAO_EVENTO;
CREATE OR REPLACE PUBLIC SYNONYM AVALIACAO_EVENTO
    FOR usr_eventosdb.AVALIACAO_EVENTO;
CREATE OR REPLACE PUBLIC SYNONYM EVENTO_RECURSO
    FOR usr_eventosdb.EVENTO_RECURSO;
CREATE OR REPLACE PUBLIC SYNONYM AUDITORIA_EVENTOS
    FOR usr_eventosdb.AUDITORIA_EVENTOS;

-- Vistas de servico
CREATE OR REPLACE PUBLIC SYNONYM V_PROGRAMACAO_EVENTOS
    FOR usr_eventosdb.V_PROGRAMACAO_EVENTOS;
CREATE OR REPLACE PUBLIC SYNONYM V_HORARIOS_BIBLIOTECAS
    FOR usr_eventosdb.V_HORARIOS_BIBLIOTECAS;
CREATE OR REPLACE PUBLIC SYNONYM V_BIBLIOTECAS_ACTIVAS
    FOR usr_eventosdb.V_BIBLIOTECAS_ACTIVAS;
CREATE OR REPLACE PUBLIC SYNONYM V_EVENTO_GLOBAL
    FOR usr_eventosdb.V_EVENTO_GLOBAL;

-- Vistas de fragmento originais
CREATE OR REPLACE PUBLIC SYNONYM FRAG_EVENTO_SUL
    FOR usr_eventosdb.FRAG_EVENTO_SUL;
CREATE OR REPLACE PUBLIC SYNONYM FRAG_EVENTO_CENTRO
    FOR usr_eventosdb.FRAG_EVENTO_CENTRO;
CREATE OR REPLACE PUBLIC SYNONYM FRAG_EVENTO_NORTE
    FOR usr_eventosdb.FRAG_EVENTO_NORTE;

-- Vistas de fragmentacao horizontal (Tarefa A1)
CREATE OR REPLACE PUBLIC SYNONYM VW_FRAG_EVENTO_FUTURO
    FOR usr_eventosdb.VW_FRAG_EVENTO_FUTURO;
CREATE OR REPLACE PUBLIC SYNONYM VW_FRAG_EVENTO_PASSADO
    FOR usr_eventosdb.VW_FRAG_EVENTO_PASSADO;

-- Vistas de fragmentacao derivada (Tarefa A2)
CREATE OR REPLACE PUBLIC SYNONYM VW_FRAG_PARTICIPACAO_FUTURO
    FOR usr_eventosdb.VW_FRAG_PARTICIPACAO_FUTURO;
CREATE OR REPLACE PUBLIC SYNONYM VW_FRAG_PARTICIPACAO_PASSADO
    FOR usr_eventosdb.VW_FRAG_PARTICIPACAO_PASSADO;

-- Vistas acedidas via dblink pelo NacionalDB (dashboard, bibliotecas, eventos)
CREATE OR REPLACE PUBLIC SYNONYM VW_EVENTOS_PROXIMOS          FOR usr_eventosdb.VW_EVENTOS_PROXIMOS;
CREATE OR REPLACE PUBLIC SYNONYM VW_EVENTOS_COMPLETOS         FOR usr_eventosdb.VW_EVENTOS_COMPLETOS;
CREATE OR REPLACE PUBLIC SYNONYM VW_BIBLIOTECAS_OPERACIONAIS  FOR usr_eventosdb.VW_BIBLIOTECAS_OPERACIONAIS;
CREATE OR REPLACE PUBLIC SYNONYM VW_HORARIOS_BIBLIOTECA_SEMANA FOR usr_eventosdb.VW_HORARIOS_BIBLIOTECA_SEMANA;
CREATE OR REPLACE PUBLIC SYNONYM VW_PARTICIPACOES_EVENTOS     FOR usr_eventosdb.VW_PARTICIPACOES_EVENTOS;
CREATE OR REPLACE PUBLIC SYNONYM INSERE_PARTICIPACAO_EVENTO   FOR usr_eventosdb.INSERE_PARTICIPACAO_EVENTO;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_EVENTO                   FOR usr_eventosdb.SEQ_EVENTO;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_AVALIACAO                FOR usr_eventosdb.SEQ_AVALIACAO;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_HORARIO_EVENTO           FOR usr_eventosdb.SEQ_HORARIO_EVENTO;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_AUDITORIA_EVT            FOR usr_eventosdb.SEQ_AUDITORIA_EVT;

-- Leitores e materiais — acedidos via dblink por queries cross-node (dashboard, bibliotecas)
CREATE OR REPLACE PUBLIC SYNONYM LEITOR
    FOR usr_NACIONALDB.leitor@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM MATERIAL_BIBLIOGRAFICO
    FOR usr_materiaisdb.MATERIAL_BIBLIOGRAFICO@link_materiaisdb;

-- Tabelas do NacionalDB acessiveis de qualquer no
CREATE OR REPLACE PUBLIC SYNONYM DOACAO             FOR usr_NACIONALDB.DOACAO@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM ITEM_DOACAO        FOR usr_NACIONALDB.ITEM_DOACAO@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM DOADOR             FOR usr_NACIONALDB.DOADOR@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM CERTIFICADO_DOACAO FOR usr_NACIONALDB.CERTIFICADO_DOACAO@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_DOACAO         FOR usr_NACIONALDB.SEQ_DOACAO@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_ITEMDOADO      FOR usr_NACIONALDB.SEQ_ITEMDOADO@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_DOADOR         FOR usr_NACIONALDB.SEQ_DOADOR@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_CERTIFICADO    FOR usr_NACIONALDB.SEQ_CERTIFICADO@link_nacionaldb;
-- Permissoes — leitura via dblink (escrita exclusiva do NacionalDB)
CREATE OR REPLACE PUBLIC SYNONYM PERMISSAO_CARGO    FOR usr_NACIONALDB.PERMISSAO_CARGO@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_PERMISSAO      FOR usr_NACIONALDB.SEQ_PERMISSAO@link_nacionaldb;

-- Autenticacao usa snapshots locais — funciona mesmo com NacionalDB offline
CREATE OR REPLACE PUBLIC SYNONYM FUNCIONARIO
    FOR usr_eventosdb.repl_funcionarios;
CREATE OR REPLACE PUBLIC SYNONYM FUNCAO_FUNCIONARIO
    FOR usr_eventosdb.repl_funcao_funcionario;

-- Snapshots locais (acesso directo pelo app_eventosdb sem prefixo de schema)
CREATE OR REPLACE PUBLIC SYNONYM snap_leitor             FOR usr_eventosdb.snap_leitor;
CREATE OR REPLACE PUBLIC SYNONYM repl_funcionarios       FOR usr_eventosdb.repl_funcionarios;
CREATE OR REPLACE PUBLIC SYNONYM repl_funcao_funcionario FOR usr_eventosdb.repl_funcao_funcionario;

-- ============================================================
-- Auditoria local (vista criada em EventosDB_AuditView.sql)
-- ============================================================
CREATE OR REPLACE PUBLIC SYNONYM VW_AUDITORIA FOR usr_eventosdb.VW_AUDITORIA;

-- ============================================================
-- Snapshots do NacionalDB (dashboard) — via link_nacionaldb
-- ============================================================
CREATE OR REPLACE PUBLIC SYNONYM snap_emp_activos           FOR usr_NACIONALDB.snap_emp_activos@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM snap_material_basico       FOR usr_NACIONALDB.snap_material_basico@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM snap_eventos               FOR usr_NACIONALDB.snap_eventos@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM snap_transferencias        FOR usr_NACIONALDB.snap_transferencias@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM vw_metricas_sistema        FOR usr_NACIONALDB.vw_metricas_sistema@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM vw_metricas_por_biblioteca FOR usr_NACIONALDB.vw_metricas_por_biblioteca@link_nacionaldb;

-- ============================================================
-- Objectos do NacionalDB acedidos por leitores / auditoria
-- ============================================================
CREATE OR REPLACE PUBLIC SYNONYM vw_leitores_completos  FOR usr_NACIONALDB.vw_leitores_completos@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM professor              FOR usr_NACIONALDB.professor@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM professor_disciplina   FOR usr_NACIONALDB.professor_disciplina@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM adulto                 FOR usr_NACIONALDB.adulto@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM crianca                FOR usr_NACIONALDB.crianca@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM adulto_interesse       FOR usr_NACIONALDB.adulto_interesse@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM vw_doacoes_detalhadas    FOR usr_NACIONALDB.vw_doacoes_detalhadas@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM VW_CERTIFICADOS_EMITIDOS FOR usr_NACIONALDB.vw_certificados_emitidos@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM FUNCIONARIO_HABILIDADE   FOR usr_NACIONALDB.funcionario_habilidade@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM HORARIO_FUNCIONARIO      FOR usr_NACIONALDB.horario_funcionario@link_nacionaldb;

-- ============================================================
-- EmprestimosDB — via PUBLIC link (sobrepõe sinónimos privados
-- @EMPRESTIMOSDB que só o SYS consegue usar)
-- ============================================================
CREATE OR REPLACE PUBLIC SYNONYM EMPRESTIMO               FOR usr_emprestimosdb.EMPRESTIMO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM VW_EMPRESTIMOS_ATIVOS    FOR usr_emprestimosdb.VW_EMPRESTIMOS_ATIVOS@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM VW_HISTORICO_EMPRESTIMOS FOR usr_emprestimosdb.VW_HISTORICO_EMPRESTIMOS@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM SUSPENSAO                FOR usr_emprestimosdb.SUSPENSAO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM PROCESSAR_DEVOLUCAO      FOR usr_emprestimosdb.PROCESSAR_DEVOLUCAO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_EMPRESTIMO           FOR usr_emprestimosdb.SEQ_EMPRESTIMO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM PROGRAMA_ALFABETIZACAO   FOR usr_emprestimosdb.PROGRAMA_ALFABETIZACAO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM PARTICIPACAO_PROGRAMA    FOR usr_emprestimosdb.PARTICIPACAO_PROGRAMA@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM NIVEL_PROGRESSAO         FOR usr_emprestimosdb.NIVEL_PROGRESSAO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM PROGRAMA_MATERIAL        FOR usr_emprestimosdb.PROGRAMA_MATERIAL@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM PROGRAMA_FUNCIONARIO     FOR usr_emprestimosdb.PROGRAMA_FUNCIONARIO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_NIVEL                FOR usr_emprestimosdb.SEQ_NIVEL@link_emprestimosdb;

-- ============================================================
-- MateriaisDB — via PUBLIC link (sobrepõe sinónimos privados
-- @MATERIAISDB que só o SYS consegue usar)
-- ============================================================
CREATE OR REPLACE PUBLIC SYNONYM CATEGORIA                    FOR usr_materiaisdb.CATEGORIA@link_materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM EBOOK                        FOR usr_materiaisdb.EBOOK@link_materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM LIVRO_FISICO                 FOR usr_materiaisdb.LIVRO_FISICO@link_materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM PERIODICO                    FOR usr_materiaisdb.PERIODICO@link_materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_TRANSFERENCIA            FOR usr_materiaisdb.SEQ_TRANSFERENCIA@link_materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM TRANSFERENCIA                FOR usr_materiaisdb.TRANSFERENCIA@link_materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM VW_MATERIAIS_COMPLETOS       FOR usr_materiaisdb.VW_MATERIAIS_COMPLETOS@link_materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM VW_TRANSFERENCIAS_DETALHADAS FOR usr_materiaisdb.VW_TRANSFERENCIAS_DETALHADAS@link_materiaisdb;

-- ============================================================
-- FUNCIONARIO/FUNCAO_FUNCIONARIO apontam para tabela real no NacionalDB
-- (necessario para INSERT/UPDATE de funcionarios de qualquer no)
-- NOTA: auth passa a requerer NacionalDB online
-- ============================================================
CREATE OR REPLACE PUBLIC SYNONYM FUNCIONARIO
    FOR usr_NACIONALDB.FUNCIONARIO@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM FUNCAO_FUNCIONARIO
    FOR usr_NACIONALDB.FUNCAO_FUNCIONARIO@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_FUNCIONARIO
    FOR usr_NACIONALDB.SEQ_FUNCIONARIO@link_nacionaldb;

-- reemitir_certificado: procedure no NacionalDB, acessivel de qualquer no
CREATE OR REPLACE PUBLIC SYNONYM reemitir_certificado
    FOR usr_NACIONALDB.reemitir_certificado@link_nacionaldb;
