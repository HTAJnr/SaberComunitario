-- ============================================================
-- MateriaisDB_Grants.sql — GRANTs para todos os utilizadores
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Procedures.sql, MateriaisDB_Views.sql
-- ============================================================


-- ============================================================
-- GRANTS PARA APP_MATERIAISDB (utilizador de aplicacao local)
-- ============================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON CATEGORIA               TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON MATERIAL_BIBLIOGRAFICO  TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON LIVRO_FISICO            TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON EBOOK                   TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON PERIODICO               TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON TRANSFERENCIA           TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON AUDITORIA_MATERIAIS     TO app_materiaisdb;
GRANT SELECT  ON VW_MAT_DISPONIVEL        TO app_materiaisdb;
GRANT SELECT  ON VW_MAT_GLOBAL            TO app_materiaisdb;
GRANT SELECT  ON VW_MAT_CATALOGO_PUBLICO  TO app_materiaisdb;
GRANT SELECT  ON VW_AUDITORIA             TO app_materiaisdb;
GRANT EXECUTE ON atualizar_estado_material TO app_materiaisdb;
GRANT EXECUTE ON registar_auditoria_mat    TO app_materiaisdb;
GRANT SELECT  ON SEQ_AUDITORIA_MAT         TO app_materiaisdb;


-- ============================================================
-- GRANTS PARA VISITOR USERS (outros nos)
-- ============================================================

-- Para o Yannis (app_emprestimosdb)
-- RN05: verifica disponibilidade e actualiza estado via procedure
-- NAO tem UPDATE directo — deve usar atualizar_estado_material
GRANT SELECT  ON MATERIAL_BIBLIOGRAFICO    TO app_emprestimosdb;
GRANT SELECT  ON vw_mat_disponivel         TO app_emprestimosdb;
GRANT EXECUTE ON atualizar_estado_material TO app_emprestimosdb;

-- Para o Helder (app_nacionaldb)
-- Supervisao: visao global do catalogo + actualizacao para demo 2PC
GRANT SELECT ON MATERIAL_BIBLIOGRAFICO TO app_nacionaldb;
GRANT SELECT ON vw_mat_disponivel      TO app_nacionaldb;
GRANT UPDATE ON MATERIAL_BIBLIOGRAFICO TO app_nacionaldb;

-- Para o Gerson (app_eventosdb)
-- Planeamento de eventos: catalogo publico e disponibilidade
-- NAO tem acesso directo a MATERIAL_BIBLIOGRAFICO
GRANT SELECT ON vw_mat_catalogo_publico TO app_eventosdb;
GRANT SELECT ON vw_mat_disponivel       TO app_eventosdb;

