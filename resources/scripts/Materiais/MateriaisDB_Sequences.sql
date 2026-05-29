-- ============================================================
-- MateriaisDB_Sequences.sql — Sequencias do no MateriaisDB
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Create.sql
-- ============================================================

CREATE SEQUENCE SEQ_AUDITORIA_MAT
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- SEQ_TRANSFERENCIA: auto-incremento do id_transferencia em TRANSFERENCIA
-- Usada pelo trigger trg_transferencia_id
CREATE SEQUENCE SEQ_TRANSFERENCIA
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

