-- ============================================================
-- MateriaisDB_Procedures.sql — Procedures do no MateriaisDB
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Sequences.sql
-- ============================================================


-- ============================================================
-- PROCEDURE 1 — registar_auditoria_mat
-- Auditoria manual com PRAGMA AUTONOMOUS_TRANSACTION
-- Garante que o registo sobrevive ao ROLLBACK da transaccao
-- principal — critico para registar tentativas falhadas
-- ============================================================
CREATE OR REPLACE PROCEDURE registar_auditoria_mat (
    p_operacao          IN VARCHAR2,
    p_cod_material      IN VARCHAR2  DEFAULT NULL,
    p_id_transferencia  IN NUMBER    DEFAULT NULL,
    p_estado_anterior   IN VARCHAR2  DEFAULT NULL,
    p_estado_novo       IN VARCHAR2  DEFAULT NULL,
    p_resultado         IN VARCHAR2,
    p_motivo_falha      IN VARCHAR2  DEFAULT NULL,
    p_nos_afetados      IN VARCHAR2  DEFAULT NULL,
    p_observacoes       IN VARCHAR2  DEFAULT NULL
)
AS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO AUDITORIA_MATERIAIS (
        id_auditoria, data_operacao, operacao,
        cod_material, id_transferencia,
        estado_anterior, estado_novo,
        resultado, motivo_falha,
        nos_afetados, observacoes
    ) VALUES (
        SEQ_AUDITORIA_MAT.NEXTVAL, SYSDATE, p_operacao,
        p_cod_material, p_id_transferencia,
        p_estado_anterior, p_estado_novo,
        p_resultado, p_motivo_falha,
        p_nos_afetados, p_observacoes
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END registar_auditoria_mat;
/


-- ============================================================
-- PROCEDURE 2 — atualizar_estado_material (RN05)
-- Actualiza estado do material apos devolucao
-- Chamada remotamente pelo EmprestimosDB via database link
-- ============================================================
CREATE OR REPLACE PROCEDURE atualizar_estado_material (
    p_cod_material        IN VARCHAR2,
    p_estado_retorno      IN VARCHAR2
)
AS
    v_material_existe  NUMBER;
    v_estado_anterior  VARCHAR2(13);
    v_estado_novo      VARCHAR2(13);
BEGIN
    SELECT COUNT(*), MAX(estado_material_conservacao)
    INTO v_material_existe, v_estado_anterior
    FROM MATERIAL_BIBLIOGRAFICO
    WHERE cod_material = p_cod_material;

    IF v_material_existe = 0 THEN
        registar_auditoria_mat(
            p_operacao     => 'ATUALIZAR_ESTADO_MATERIAL',
            p_cod_material => p_cod_material,
            p_resultado    => 'FALHA',
            p_motivo_falha => 'Material ' || p_cod_material || ' nao encontrado',
            p_nos_afetados => 'MateriaisDB, EmprestimosDB'
        );
        RAISE_APPLICATION_ERROR(-20001,
            'Material ' || p_cod_material || ' nao encontrado no MateriaisDB.');
    END IF;

    IF p_estado_retorno = 'Destruido' THEN
        UPDATE MATERIAL_BIBLIOGRAFICO
        SET estado_material_conservacao = 'Indisponivel',
            motivo_indisponibilidade    = 'Material destruido na devolucao'
        WHERE cod_material = p_cod_material;
        v_estado_novo := 'Indisponivel';

    ELSIF p_estado_retorno = 'Perdido' THEN
        UPDATE MATERIAL_BIBLIOGRAFICO
        SET estado_material_conservacao = 'Indisponivel',
            motivo_indisponibilidade    = 'Material perdido pelo leitor'
        WHERE cod_material = p_cod_material;
        v_estado_novo := 'Indisponivel';

    ELSIF p_estado_retorno = 'Degradado' THEN
        UPDATE MATERIAL_BIBLIOGRAFICO
        SET estado_material_conservacao = 'Degradado'
        WHERE cod_material = p_cod_material;
        v_estado_novo := 'Degradado';

    ELSIF p_estado_retorno = 'Bom' THEN
        v_estado_novo := v_estado_anterior;
        NULL;

    ELSE
        registar_auditoria_mat(
            p_operacao     => 'ATUALIZAR_ESTADO_MATERIAL',
            p_cod_material => p_cod_material,
            p_resultado    => 'FALHA',
            p_motivo_falha => 'Estado de retorno invalido: ' || p_estado_retorno,
            p_nos_afetados => 'MateriaisDB, EmprestimosDB'
        );
        RAISE_APPLICATION_ERROR(-20002,
            'Estado de retorno invalido: ' || p_estado_retorno ||
            '. Valores validos: Bom, Degradado, Destruido, Perdido.');
    END IF;

    registar_auditoria_mat(
        p_operacao        => 'ATUALIZAR_ESTADO_MATERIAL',
        p_cod_material    => p_cod_material,
        p_estado_anterior => v_estado_anterior,
        p_estado_novo     => v_estado_novo,
        p_resultado       => 'SUCESSO',
        p_nos_afetados    => 'MateriaisDB, EmprestimosDB',
        p_observacoes     => 'Estado de retorno: ' || p_estado_retorno
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END atualizar_estado_material;
/


-- ============================================================
-- prc_refresh_snapshots
-- Forca REFRESH COMPLETE em todas as MVs locais deste no.
-- Chamada pelo backend via POST /api/manutencao/refresh-snapshots.
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_refresh_snapshots AS
    v_falhas NUMBER := 0;
BEGIN
    DBMS_MVIEW.REFRESH_ALL_MVIEWS(v_falhas);
    DBMS_OUTPUT.PUT_LINE('Refresh concluido. Falhas: ' || v_falhas);
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20300, 'Erro no refresh de snapshots: ' || SQLERRM);
END;
/
