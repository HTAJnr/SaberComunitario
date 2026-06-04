-- ============================================================
-- MateriaisDB_Synonyms.sql — Sinonimos publicos
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Database_Links.sql
-- ============================================================


-- ============================================================
-- SINONIMOS PUBLICOS REMOTOS
-- Transparencia de localizacao para objectos em outros nos
-- ============================================================

-- EmprestimosDB (Yannis) — backend completo (emprestimos, programas, suspensoes)
CREATE OR REPLACE PUBLIC SYNONYM emprestimo_activo
    FOR USR_EMPRESTIMOSDB.VW_EMPRESTIMOS_ACTIVOS@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM EMPRESTIMO
    FOR USR_EMPRESTIMOSDB.EMPRESTIMO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM SUSPENSAO
    FOR USR_EMPRESTIMOSDB.SUSPENSAO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM VW_EMPRESTIMOS_ATIVOS
    FOR USR_EMPRESTIMOSDB.VW_EMPRESTIMOS_ATIVOS@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM VW_EMPRESTIMOS_ACTIVOS
    FOR USR_EMPRESTIMOSDB.VW_EMPRESTIMOS_ACTIVOS@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM VW_HISTORICO_EMPRESTIMOS
    FOR USR_EMPRESTIMOSDB.VW_HISTORICO_EMPRESTIMOS@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM VW_SUSPENSOES_ACTIVAS
    FOR USR_EMPRESTIMOSDB.VW_SUSPENSOES_ACTIVAS@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM PROCESSAR_DEVOLUCAO
    FOR USR_EMPRESTIMOSDB.PROCESSAR_DEVOLUCAO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_EMPRESTIMO
    FOR USR_EMPRESTIMOSDB.SEQ_EMPRESTIMO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM PROGRAMA_ALFABETIZACAO
    FOR USR_EMPRESTIMOSDB.PROGRAMA_ALFABETIZACAO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM PARTICIPACAO_PROGRAMA
    FOR USR_EMPRESTIMOSDB.PARTICIPACAO_PROGRAMA@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM NIVEL_PROGRESSAO
    FOR USR_EMPRESTIMOSDB.NIVEL_PROGRESSAO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM PROGRAMA_MATERIAL
    FOR USR_EMPRESTIMOSDB.PROGRAMA_MATERIAL@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM PROGRAMA_FUNCIONARIO
    FOR USR_EMPRESTIMOSDB.PROGRAMA_FUNCIONARIO@link_emprestimosdb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_NIVEL
    FOR USR_EMPRESTIMOSDB.SEQ_NIVEL@link_emprestimosdb;

-- EventosBibliotecasDB (Gerson) — backend completo (eventos, bibliotecas)
CREATE OR REPLACE PUBLIC SYNONYM biblioteca_remota
    FOR USR_EVENTOSDB.biblioteca@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM EVENTO
    FOR USR_EVENTOSDB.EVENTO@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM HORARIO_EVENTO
    FOR USR_EVENTOSDB.HORARIO_EVENTO@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM PARTICIPACAO_EVENTO
    FOR USR_EVENTOSDB.PARTICIPACAO_EVENTO@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM AVALIACAO_EVENTO
    FOR USR_EVENTOSDB.AVALIACAO_EVENTO@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM EVENTO_RECURSO
    FOR USR_EVENTOSDB.EVENTO_RECURSO@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM HORARIO_BIBLIOTECA
    FOR USR_EVENTOSDB.HORARIO_BIBLIOTECA@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM BIBLIOTECA_RESPONSAVEL
    FOR USR_EVENTOSDB.BIBLIOTECA_RESPONSAVEL@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_EVENTO
    FOR USR_EVENTOSDB.SEQ_EVENTO@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_AVALIACAO
    FOR USR_EVENTOSDB.SEQ_AVALIACAO@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_HORARIO_EVENTO
    FOR USR_EVENTOSDB.SEQ_HORARIO_EVENTO@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM VW_EVENTOS_PROXIMOS
    FOR USR_EVENTOSDB.VW_EVENTOS_PROXIMOS@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM VW_EVENTOS_COMPLETOS
    FOR USR_EVENTOSDB.VW_EVENTOS_COMPLETOS@link_eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM INSERE_PARTICIPACAO_EVENTO
    FOR USR_EVENTOSDB.INSERE_PARTICIPACAO_EVENTO@link_eventosdb;

-- BibliotecaNacionalDB (Helder)
CREATE OR REPLACE PUBLIC SYNONYM leitor_remoto
    FOR USR_NACIONALDB.leitor@link_nacionaldb;

-- Vista publica de leitores do BibliotecaNacionalDB
CREATE OR REPLACE PUBLIC SYNONYM leitor_publico
    FOR USR_NACIONALDB.vw_leitor_publico@link_nacionaldb;

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

-- Subtipos de leitor do NacionalDB (acedidos via dblink)
CREATE OR REPLACE PUBLIC SYNONYM leitor              FOR usr_NACIONALDB.leitor@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM adulto              FOR usr_NACIONALDB.adulto@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM adulto_interesse    FOR usr_NACIONALDB.adulto_interesse@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM professor           FOR usr_NACIONALDB.professor@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM professor_disciplina FOR usr_NACIONALDB.professor_disciplina@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM crianca             FOR usr_NACIONALDB.crianca@link_nacionaldb;

-- Autenticacao usa snapshots locais — funciona mesmo com NacionalDB offline
CREATE OR REPLACE PUBLIC SYNONYM funcionario
    FOR usr_materiaisdb.repl_funcionarios;
CREATE OR REPLACE PUBLIC SYNONYM funcao_funcionario
    FOR usr_materiaisdb.repl_funcao_funcionario;
-- Necessario para queries que referenciam BIBLIOTECA (replica local de EventosDB)
CREATE OR REPLACE PUBLIC SYNONYM biblioteca
    FOR biblioteca_snap;


-- ============================================================
-- SINONIMOS PUBLICOS LOCAIS
-- Permite acesso sem prefixo usr_materiaisdb.
-- ============================================================
CREATE OR REPLACE PUBLIC SYNONYM CATEGORIA
    FOR usr_materiaisdb.CATEGORIA;
CREATE OR REPLACE PUBLIC SYNONYM MATERIAL_BIBLIOGRAFICO
    FOR usr_materiaisdb.MATERIAL_BIBLIOGRAFICO;
CREATE OR REPLACE PUBLIC SYNONYM LIVRO_FISICO
    FOR usr_materiaisdb.LIVRO_FISICO;
CREATE OR REPLACE PUBLIC SYNONYM EBOOK
    FOR usr_materiaisdb.EBOOK;
CREATE OR REPLACE PUBLIC SYNONYM PERIODICO
    FOR usr_materiaisdb.PERIODICO;
CREATE OR REPLACE PUBLIC SYNONYM TRANSFERENCIA
    FOR usr_materiaisdb.TRANSFERENCIA;
CREATE OR REPLACE PUBLIC SYNONYM AUDITORIA_MATERIAIS
    FOR usr_materiaisdb.AUDITORIA_MATERIAIS;
CREATE OR REPLACE PUBLIC SYNONYM VW_MAT_DISPONIVEL
    FOR usr_materiaisdb.VW_MAT_DISPONIVEL;
CREATE OR REPLACE PUBLIC SYNONYM VW_MAT_GLOBAL
    FOR usr_materiaisdb.VW_MAT_GLOBAL;
CREATE OR REPLACE PUBLIC SYNONYM VW_MATERIAIS_COMPLETOS
    FOR usr_materiaisdb.VW_MATERIAIS_COMPLETOS;
CREATE OR REPLACE PUBLIC SYNONYM VW_TRANSFERENCIAS_DETALHADAS
    FOR usr_materiaisdb.VW_TRANSFERENCIAS_DETALHADAS;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_TRANSFERENCIA
    FOR usr_materiaisdb.SEQ_TRANSFERENCIA;
CREATE OR REPLACE PUBLIC SYNONYM VW_MAT_CATALOGO_PUBLICO
    FOR usr_materiaisdb.VW_MAT_CATALOGO_PUBLICO;
CREATE OR REPLACE PUBLIC SYNONYM VW_AUDITORIA
    FOR usr_materiaisdb.VW_AUDITORIA;
CREATE OR REPLACE PUBLIC SYNONYM REPL_FUNCIONARIOS
    FOR usr_materiaisdb.REPL_FUNCIONARIOS;
CREATE OR REPLACE PUBLIC SYNONYM REPL_FUNCAO_FUNCIONARIO
    FOR usr_materiaisdb.REPL_FUNCAO_FUNCIONARIO;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_AUDITORIA_MAT
    FOR usr_materiaisdb.SEQ_AUDITORIA_MAT;
CREATE OR REPLACE PUBLIC SYNONYM ATUALIZAR_ESTADO_MATERIAL
    FOR usr_materiaisdb.ATUALIZAR_ESTADO_MATERIAL;
CREATE OR REPLACE PUBLIC SYNONYM REGISTAR_AUDITORIA_MAT
    FOR usr_materiaisdb.REGISTAR_AUDITORIA_MAT;

-- Snapshots locais (acesso directo pelo app_materiaisdb sem prefixo de schema)
CREATE OR REPLACE PUBLIC SYNONYM snap_leitor_publico FOR usr_materiaisdb.snap_leitor_publico;
CREATE OR REPLACE PUBLIC SYNONYM biblioteca_snap     FOR usr_materiaisdb.biblioteca_snap;

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
CREATE OR REPLACE PUBLIC SYNONYM vw_leitores_completos FOR usr_NACIONALDB.vw_leitores_completos@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM vw_doacoes_detalhadas    FOR usr_NACIONALDB.vw_doacoes_detalhadas@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM VW_CERTIFICADOS_EMITIDOS FOR usr_NACIONALDB.vw_certificados_emitidos@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM FUNCIONARIO_HABILIDADE   FOR usr_NACIONALDB.funcionario_habilidade@link_nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM HORARIO_FUNCIONARIO      FOR usr_NACIONALDB.horario_funcionario@link_nacionaldb;

-- funcionario/funcao_funcionario apontam para snapshots locais (definidos acima).
-- Escritas em FUNCIONARIO vão directamente ao NacionalDB via getConnectionNacional()
-- na camada de aplicação — não é necessário dblink aqui.

-- reemitir_certificado: procedure no NacionalDB, acessivel de qualquer no
CREATE OR REPLACE PUBLIC SYNONYM reemitir_certificado
    FOR usr_NACIONALDB.reemitir_certificado@link_nacionaldb;
