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
CREATE OR REPLACE PUBLIC SYNONYM vw_doacoes_detalhadas  FOR usr_NACIONALDB.vw_doacoes_detalhadas@link_nacionaldb;
