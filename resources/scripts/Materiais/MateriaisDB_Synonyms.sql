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

-- EmprestimosDB (Yannis) — usada pelo trigger RN06
CREATE OR REPLACE PUBLIC SYNONYM emprestimo_activo
    FOR USR_EMPRESTIMOSDB.VW_EMPRESTIMOS_ACTIVOS@link_emprestimosdb;

-- EventosBibliotecasDB (Gerson)
CREATE OR REPLACE PUBLIC SYNONYM biblioteca_remota
    FOR USR_EVENTOSDB.biblioteca@link_eventosdb;

-- BibliotecaNacionalDB (Helder)
CREATE OR REPLACE PUBLIC SYNONYM leitor_remoto
    FOR USR_NACIONALDB.leitor@link_nacionaldb;

-- Vista publica de leitores do BibliotecaNacionalDB
CREATE OR REPLACE PUBLIC SYNONYM leitor_publico
    FOR USR_NACIONALDB.vw_leitor_publico@link_nacionaldb;


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
CREATE OR REPLACE PUBLIC SYNONYM VW_AUDITORIA
    FOR usr_materiaisdb.VW_AUDITORIA;

