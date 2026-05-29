-- ============================================================
-- MateriaisDB_Indexes.sql — Indices do no MateriaisDB
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Create.sql
-- ============================================================

-- ------------------------------------------------------------
-- MATERIAL_BIBLIOGRAFICO
-- Pesquisas frequentes: titulo, biblioteca, estado, categoria
-- ------------------------------------------------------------
CREATE INDEX idx_mat_titulo
    ON MATERIAL_BIBLIOGRAFICO (titulo)                      TABLESPACE tbs_MATERIAISDB_idx;
CREATE INDEX idx_mat_biblioteca
    ON MATERIAL_BIBLIOGRAFICO (cod_biblioteca)              TABLESPACE tbs_MATERIAISDB_idx;
CREATE INDEX idx_mat_estado
    ON MATERIAL_BIBLIOGRAFICO (estado_material_conservacao) TABLESPACE tbs_MATERIAISDB_idx;
CREATE INDEX idx_mat_categoria
    ON MATERIAL_BIBLIOGRAFICO (cod_categoria)               TABLESPACE tbs_MATERIAISDB_idx;

-- ------------------------------------------------------------
-- TRANSFERENCIA
-- Pesquisas frequentes: material, estado, bibliotecas
-- ------------------------------------------------------------
CREATE INDEX it_mat  ON TRANSFERENCIA(cod_material)           TABLESPACE tbs_MATERIAISDB_idx;
CREATE INDEX it_est  ON TRANSFERENCIA(estado_transferencia)   TABLESPACE tbs_MATERIAISDB_idx;
CREATE INDEX it_orig ON TRANSFERENCIA(cod_biblioteca_origem)  TABLESPACE tbs_MATERIAISDB_idx;
CREATE INDEX it_dest ON TRANSFERENCIA(cod_biblioteca_destino) TABLESPACE tbs_MATERIAISDB_idx;

-- ------------------------------------------------------------
-- CATEGORIA
-- ------------------------------------------------------------
CREATE INDEX icat_area ON CATEGORIA(area_tematica) TABLESPACE tbs_MATERIAISDB_idx;

-- ------------------------------------------------------------
-- AUDITORIA_MATERIAIS
-- ------------------------------------------------------------
CREATE INDEX iaud_mat_material
    ON AUDITORIA_MATERIAIS (cod_material)     TABLESPACE tbs_MATERIAISDB_idx;
CREATE INDEX iaud_mat_transf
    ON AUDITORIA_MATERIAIS (id_transferencia) TABLESPACE tbs_MATERIAISDB_idx;
CREATE INDEX iaud_mat_data
    ON AUDITORIA_MATERIAIS (data_operacao)    TABLESPACE tbs_MATERIAISDB_idx;
CREATE INDEX iaud_mat_res
    ON AUDITORIA_MATERIAIS (resultado)        TABLESPACE tbs_MATERIAISDB_idx;
