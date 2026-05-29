-- ============================================================
-- MateriaisDB_Triggers.sql — Triggers do no MateriaisDB
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Synonyms.sql, MateriaisDB_Procedures.sql
-- ============================================================


-- ============================================================
-- TRIGGER 1 — trg_transferencia_insert (RN06)
-- Proteccao no INSERT de TRANSFERENCIA
-- ============================================================
CREATE OR REPLACE TRIGGER trg_transferencia_insert
BEFORE INSERT ON TRANSFERENCIA
FOR EACH ROW
DECLARE
    v_emp_activo    NUMBER := 0;
    v_trans_activa  NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_trans_activa
    FROM TRANSFERENCIA
    WHERE cod_material = :NEW.cod_material
    AND estado_transferencia IN ('Pendente', 'Aprovada');

    IF v_trans_activa > 0 THEN
        registar_auditoria_mat(
            p_operacao         => 'CRIAR_TRANSFERENCIA',
            p_cod_material     => :NEW.cod_material,
            p_id_transferencia => :NEW.id_transferencia,
            p_resultado        => 'FALHA',
            p_motivo_falha     => 'Material ja tem transferencia activa',
            p_nos_afetados     => 'MateriaisDB'
        );
        RAISE_APPLICATION_ERROR(-20010,
            'Material ' || :NEW.cod_material ||
            ' ja tem uma transferencia activa (Pendente ou Aprovada).');
    END IF;

    BEGIN
        EXECUTE IMMEDIATE
            'SELECT COUNT(*) FROM emprestimo_activo
             WHERE cod_material = :1'
        INTO v_emp_activo
        USING :NEW.cod_material;
    EXCEPTION
        WHEN OTHERS THEN
            registar_auditoria_mat(
                p_operacao         => 'CRIAR_TRANSFERENCIA',
                p_cod_material     => :NEW.cod_material,
                p_id_transferencia => :NEW.id_transferencia,
                p_resultado        => 'FALHA',
                p_motivo_falha     => 'EmprestimosDB indisponivel',
                p_nos_afetados     => 'MateriaisDB, EmprestimosDB'
            );
            RAISE_APPLICATION_ERROR(-20011,
                'Nao foi possivel verificar emprestimos activos. ' ||
                'EmprestimosDB indisponivel. Transferencia bloqueada.');
    END;

    IF v_emp_activo > 0 THEN
        registar_auditoria_mat(
            p_operacao         => 'CRIAR_TRANSFERENCIA',
            p_cod_material     => :NEW.cod_material,
            p_id_transferencia => :NEW.id_transferencia,
            p_resultado        => 'FALHA',
            p_motivo_falha     => 'Material tem emprestimo activo no EmprestimosDB',
            p_nos_afetados     => 'MateriaisDB, EmprestimosDB'
        );
        RAISE_APPLICATION_ERROR(-20012,
            'Material ' || :NEW.cod_material ||
            ' tem emprestimo activo. Nao e possivel transferir.');
    END IF;
END trg_transferencia_insert;
/


-- ============================================================
-- TRIGGER 2 — trg_transferencia_fluxo (RN06)
-- Validacao do fluxo de estados de TRANSFERENCIA
-- ============================================================
CREATE OR REPLACE TRIGGER trg_transferencia_fluxo
BEFORE UPDATE ON TRANSFERENCIA
FOR EACH ROW
BEGIN
    IF :OLD.estado_transferencia IN ('Concluida', 'Rejeitada') THEN
        registar_auditoria_mat(
            p_operacao         => 'ATUALIZAR_TRANSFERENCIA',
            p_cod_material     => :OLD.cod_material,
            p_id_transferencia => :OLD.id_transferencia,
            p_estado_anterior  => :OLD.estado_transferencia,
            p_estado_novo      => :NEW.estado_transferencia,
            p_resultado        => 'FALHA',
            p_motivo_falha     => 'Transferencia ja esta ' || :OLD.estado_transferencia,
            p_nos_afetados     => 'MateriaisDB'
        );
        RAISE_APPLICATION_ERROR(-20013,
            'Transferencia ' || :OLD.id_transferencia ||
            ' ja esta ' || :OLD.estado_transferencia ||
            '. Nao e possivel alterar o estado.');
    END IF;

    IF NOT (
        (:OLD.estado_transferencia = 'Pendente'  AND :NEW.estado_transferencia = 'Aprovada')   OR
        (:OLD.estado_transferencia = 'Pendente'  AND :NEW.estado_transferencia = 'Rejeitada')  OR
        (:OLD.estado_transferencia = 'Aprovada'  AND :NEW.estado_transferencia = 'Concluida')  OR
        (:OLD.estado_transferencia = 'Aprovada'  AND :NEW.estado_transferencia = 'Rejeitada')
    ) THEN
        registar_auditoria_mat(
            p_operacao         => 'ATUALIZAR_TRANSFERENCIA',
            p_cod_material     => :OLD.cod_material,
            p_id_transferencia => :OLD.id_transferencia,
            p_estado_anterior  => :OLD.estado_transferencia,
            p_estado_novo      => :NEW.estado_transferencia,
            p_resultado        => 'FALHA',
            p_motivo_falha     => 'Fluxo invalido: ' || :OLD.estado_transferencia ||
                                  ' -> ' || :NEW.estado_transferencia,
            p_nos_afetados     => 'MateriaisDB'
        );
        RAISE_APPLICATION_ERROR(-20014,
            'Fluxo invalido: ' || :OLD.estado_transferencia ||
            ' -> ' || :NEW.estado_transferencia ||
            '. Caminhos validos: Pendente->Aprovada, Pendente->Rejeitada, ' ||
            'Aprovada->Concluida, Aprovada->Rejeitada.');
    END IF;

    IF :NEW.estado_transferencia = 'Concluida' THEN
        UPDATE MATERIAL_BIBLIOGRAFICO
        SET cod_biblioteca = :OLD.cod_biblioteca_destino
        WHERE cod_material = :OLD.cod_material;

        registar_auditoria_mat(
            p_operacao         => 'CONCLUIR_TRANSFERENCIA',
            p_cod_material     => :OLD.cod_material,
            p_id_transferencia => :OLD.id_transferencia,
            p_estado_anterior  => :OLD.estado_transferencia,
            p_estado_novo      => :NEW.estado_transferencia,
            p_resultado        => 'SUCESSO',
            p_nos_afetados     => 'MateriaisDB',
            p_observacoes      => 'Material movido para ' || :OLD.cod_biblioteca_destino
        );
    END IF;
END trg_transferencia_fluxo;
/

