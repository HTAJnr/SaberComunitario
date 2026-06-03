-- ============================================================
-- EmprestimosDB_Synonyms.sql
-- ATENCAO: requer privilegio CREATE PUBLIC SYNONYM
-- Executar como SYSDBA antes deste script:
--   GRANT CREATE PUBLIC SYNONYM TO usr_emprestimosdb;
-- ============================================================

-- DROP de synonyms auto-referenciais que apontam @EMPRESTIMOSDB a partir
-- do próprio nó — criados por engano ao correr o script errado neste nó.
-- Os objectos locais são acedidos directamente via grant, não via dblink.
DROP PUBLIC SYNONYM vw_emprestimos_ativos;
DROP PUBLIC SYNONYM vw_historico_emprestimos;
DROP PUBLIC SYNONYM processar_devolucao;
DROP PUBLIC SYNONYM seq_emprestimo;
DROP PUBLIC SYNONYM seq_nivel;

-- SINONIMOS PUBLICOS � BibliotecaNacionalDB (Helder)
CREATE OR REPLACE PUBLIC SYNONYM leitor
    FOR leitor@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM adulto
    FOR adulto@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM adulto_interesse
    FOR adulto_interesse@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM professor
    FOR professor@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM professor_disciplina
    FOR professor_disciplina@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM crianca
    FOR crianca@nacionaldb;
-- Autenticacao usa snapshots locais — funciona mesmo com NacionalDB offline
CREATE OR REPLACE PUBLIC SYNONYM funcao_funcionario
    FOR usr_emprestimosdb.repl_funcao_funcionario;
CREATE OR REPLACE PUBLIC SYNONYM funcionario
    FOR usr_emprestimosdb.repl_funcionarios;
-- Necessario para queries que referenciam BIBLIOTECA (replica local de EventosDB)
CREATE OR REPLACE PUBLIC SYNONYM biblioteca
    FOR biblioteca_snap;

-- Tabelas do NacionalDB acessiveis de qualquer no
CREATE OR REPLACE PUBLIC SYNONYM DOACAO             FOR usr_NACIONALDB.DOACAO@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM ITEM_DOACAO        FOR usr_NACIONALDB.ITEM_DOACAO@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM DOADOR             FOR usr_NACIONALDB.DOADOR@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM CERTIFICADO_DOACAO FOR usr_NACIONALDB.CERTIFICADO_DOACAO@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_DOACAO         FOR usr_NACIONALDB.SEQ_DOACAO@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_ITEMDOADO      FOR usr_NACIONALDB.SEQ_ITEMDOADO@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_DOADOR         FOR usr_NACIONALDB.SEQ_DOADOR@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_CERTIFICADO    FOR usr_NACIONALDB.SEQ_CERTIFICADO@nacionaldb;
-- Permissoes — leitura via dblink (escrita exclusiva do NacionalDB)
CREATE OR REPLACE PUBLIC SYNONYM PERMISSAO_CARGO    FOR usr_NACIONALDB.PERMISSAO_CARGO@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_PERMISSAO      FOR usr_NACIONALDB.SEQ_PERMISSAO@nacionaldb;

-- SINONIMOS PUBLICOS - MateriaisDB (Yasin)
CREATE OR REPLACE PUBLIC SYNONYM material_bibliografico
    FOR material_bibliografico@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM livro_fisico
    FOR usr_materiaisdb.livro_fisico@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM ebook
    FOR usr_materiaisdb.ebook@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM periodico
    FOR usr_materiaisdb.periodico@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM categoria
    FOR categoria@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM transferencia
    FOR transferencia@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_transferencias_detalhadas
    FOR usr_materiaisdb.vw_transferencias_detalhadas@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_mat_disponivel
    FOR usr_materiaisdb.vw_mat_disponivel@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_mat_catalogo_publico
    FOR usr_materiaisdb.vw_mat_catalogo_publico@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM vw_materiais_completos
    FOR usr_materiaisdb.vw_materiais_completos@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_transferencia
    FOR usr_materiaisdb.seq_transferencia@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_material
    FOR usr_materiaisdb.seq_material@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM seq_categoria
    FOR usr_materiaisdb.seq_categoria@materiaisdb;

-- SINONIMOS PUBLICOS � Objectos locais (usr_emprestimosdb)
-- Vistas e objectos acedidos via dblink por outros nos (substituem os auto-referenciais)
CREATE OR REPLACE PUBLIC SYNONYM vw_emprestimos_ativos    FOR usr_emprestimosdb.vw_emprestimos_ativos;
CREATE OR REPLACE PUBLIC SYNONYM vw_historico_emprestimos FOR usr_emprestimosdb.vw_historico_emprestimos;
CREATE OR REPLACE PUBLIC SYNONYM processar_devolucao      FOR usr_emprestimosdb.processar_devolucao;
CREATE OR REPLACE PUBLIC SYNONYM seq_emprestimo           FOR usr_emprestimosdb.seq_emprestimo;
CREATE OR REPLACE PUBLIC SYNONYM seq_nivel                FOR usr_emprestimosdb.seq_nivel;

CREATE OR REPLACE PUBLIC SYNONYM emprestimo
    FOR usr_emprestimosdb.emprestimo;
CREATE OR REPLACE PUBLIC SYNONYM suspensao
    FOR usr_emprestimosdb.suspensao;
CREATE OR REPLACE PUBLIC SYNONYM repl_funcionarios
    FOR usr_emprestimosdb.repl_funcionarios;
CREATE OR REPLACE PUBLIC SYNONYM programa_alfabetizacao
    FOR usr_emprestimosdb.programa_alfabetizacao;
CREATE OR REPLACE PUBLIC SYNONYM nivel_progressao
    FOR usr_emprestimosdb.nivel_progressao;
CREATE OR REPLACE PUBLIC SYNONYM programa_material
    FOR usr_emprestimosdb.programa_material;
CREATE OR REPLACE PUBLIC SYNONYM programa_funcionario
    FOR usr_emprestimosdb.programa_funcionario;
CREATE OR REPLACE PUBLIC SYNONYM participacao_programa
    FOR usr_emprestimosdb.participacao_programa;
CREATE OR REPLACE PUBLIC SYNONYM vw_emprestimos_activos
    FOR usr_emprestimosdb.vw_emprestimos_activos;
CREATE OR REPLACE PUBLIC SYNONYM vw_suspensoes_activas
    FOR usr_emprestimosdb.vw_suspensoes_activas;
CREATE OR REPLACE PUBLIC SYNONYM frag_emp_activos_op
    FOR usr_emprestimosdb.frag_emp_activos_op;
CREATE OR REPLACE PUBLIC SYNONYM vw_auditoria
    FOR usr_emprestimosdb.vw_auditoria;
CREATE OR REPLACE PUBLIC SYNONYM vw_relatorio_programas
    FOR usr_emprestimosdb.vw_relatorio_programas;
CREATE OR REPLACE PUBLIC SYNONYM auditoria_emprestimos
    FOR usr_emprestimosdb.auditoria_emprestimos;
CREATE OR REPLACE PUBLIC SYNONYM seq_auditoria_emp
    FOR usr_emprestimosdb.seq_auditoria_emp;

-- Snapshots locais (acesso directo pelo app_emprestimosdb sem prefixo de schema)
CREATE OR REPLACE PUBLIC SYNONYM snap_leitor     FOR usr_emprestimosdb.snap_leitor;
CREATE OR REPLACE PUBLIC SYNONYM snap_material   FOR usr_emprestimosdb.snap_material;
CREATE OR REPLACE PUBLIC SYNONYM snap_adulto     FOR usr_emprestimosdb.snap_adulto;
CREATE OR REPLACE PUBLIC SYNONYM snap_crianca    FOR usr_emprestimosdb.snap_crianca;
CREATE OR REPLACE PUBLIC SYNONYM snap_professor  FOR usr_emprestimosdb.snap_professor;
CREATE OR REPLACE PUBLIC SYNONYM snap_categoria  FOR usr_emprestimosdb.snap_categoria;
CREATE OR REPLACE PUBLIC SYNONYM biblioteca_snap FOR usr_emprestimosdb.biblioteca_snap;

-- ============================================================
-- Snapshots do NacionalDB (dashboard) — via @nacionaldb
-- ============================================================
CREATE OR REPLACE PUBLIC SYNONYM snap_emp_activos           FOR usr_NACIONALDB.snap_emp_activos@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM snap_material_basico       FOR usr_NACIONALDB.snap_material_basico@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM snap_eventos               FOR usr_NACIONALDB.snap_eventos@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM snap_transferencias        FOR usr_NACIONALDB.snap_transferencias@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM vw_metricas_sistema        FOR usr_NACIONALDB.vw_metricas_sistema@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM vw_metricas_por_biblioteca FOR usr_NACIONALDB.vw_metricas_por_biblioteca@nacionaldb;

-- ============================================================
-- Objectos do NacionalDB acedidos por leitores / auditoria
-- ============================================================
CREATE OR REPLACE PUBLIC SYNONYM vw_leitores_completos FOR usr_NACIONALDB.vw_leitores_completos@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM vw_doacoes_detalhadas    FOR usr_NACIONALDB.vw_doacoes_detalhadas@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM VW_CERTIFICADOS_EMITIDOS FOR usr_NACIONALDB.vw_certificados_emitidos@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM FUNCIONARIO_HABILIDADE   FOR usr_NACIONALDB.funcionario_habilidade@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM HORARIO_FUNCIONARIO      FOR usr_NACIONALDB.horario_funcionario@nacionaldb;

-- ============================================================
-- EventosDB (Gerson) — backend completo (eventos, bibliotecas)
-- ============================================================
CREATE OR REPLACE PUBLIC SYNONYM EVENTO
    FOR USR_EVENTOSDB.EVENTO@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM HORARIO_EVENTO
    FOR USR_EVENTOSDB.HORARIO_EVENTO@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM PARTICIPACAO_EVENTO
    FOR USR_EVENTOSDB.PARTICIPACAO_EVENTO@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM AVALIACAO_EVENTO
    FOR USR_EVENTOSDB.AVALIACAO_EVENTO@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM EVENTO_RECURSO
    FOR USR_EVENTOSDB.EVENTO_RECURSO@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM HORARIO_BIBLIOTECA
    FOR USR_EVENTOSDB.HORARIO_BIBLIOTECA@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM BIBLIOTECA_RESPONSAVEL
    FOR USR_EVENTOSDB.BIBLIOTECA_RESPONSAVEL@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_EVENTO
    FOR USR_EVENTOSDB.SEQ_EVENTO@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_AVALIACAO
    FOR USR_EVENTOSDB.SEQ_AVALIACAO@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_HORARIO_EVENTO
    FOR USR_EVENTOSDB.SEQ_HORARIO_EVENTO@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM VW_EVENTOS_PROXIMOS
    FOR USR_EVENTOSDB.VW_EVENTOS_PROXIMOS@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM VW_EVENTOS_COMPLETOS
    FOR USR_EVENTOSDB.VW_EVENTOS_COMPLETOS@eventosdb;
CREATE OR REPLACE PUBLIC SYNONYM INSERE_PARTICIPACAO_EVENTO
    FOR USR_EVENTOSDB.INSERE_PARTICIPACAO_EVENTO@eventosdb;

-- ============================================================
-- FUNCIONARIO/FUNCAO_FUNCIONARIO apontam para tabela real no NacionalDB
-- (necessario para INSERT/UPDATE de funcionarios de qualquer no)
-- NOTA: auth passa a requerer NacionalDB online
-- ============================================================
CREATE OR REPLACE PUBLIC SYNONYM funcionario
    FOR usr_NACIONALDB.FUNCIONARIO@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM funcao_funcionario
    FOR usr_NACIONALDB.FUNCAO_FUNCIONARIO@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM SEQ_FUNCIONARIO
    FOR usr_NACIONALDB.SEQ_FUNCIONARIO@nacionaldb;

-- reemitir_certificado: procedure no NacionalDB, acessivel de qualquer no
CREATE OR REPLACE PUBLIC SYNONYM reemitir_certificado
    FOR usr_NACIONALDB.reemitir_certificado@nacionaldb;
