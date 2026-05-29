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

-- ============================================================
-- TRIGGERS ADICIONADOS — ausentes no ficheiro original
-- ============================================================

-- TRIGGER: trg_transferencia_id
-- Auto-incremento do id_transferencia usando SEQ_TRANSFERENCIA
CREATE OR REPLACE TRIGGER trg_transferencia_id
BEFORE INSERT ON TRANSFERENCIA
FOR EACH ROW
BEGIN
    IF :NEW.id_transferencia IS NULL THEN
        SELECT SEQ_TRANSFERENCIA.NEXTVAL INTO :NEW.id_transferencia FROM DUAL;
    END IF;
END;
/

-- TRIGGER: trg_valida_transferencia
-- Valida consistencia: bibliotecas diferentes, material na origem,
-- funcionarios nas bibliotecas correctas
-- FUNCIONARIO e MATERIAL_BIBLIOGRAFICO acedidos via sinonimo (transparente)
CREATE OR REPLACE TRIGGER trg_valida_transferencia
BEFORE INSERT OR UPDATE ON TRANSFERENCIA
FOR EACH ROW
DECLARE
    v_biblioteca_material    VARCHAR2(10);
    v_biblioteca_solicitante VARCHAR2(10);
    v_biblioteca_aprovador   VARCHAR2(10);
BEGIN
    IF :NEW.cod_biblioteca_origem = :NEW.cod_biblioteca_destino THEN
        RAISE_APPLICATION_ERROR(-20102,
            'Transferencia invalida: biblioteca origem deve ser diferente da destino');
    END IF;

    SELECT cod_biblioteca INTO v_biblioteca_material
      FROM MATERIAL_BIBLIOGRAFICO
     WHERE cod_material = :NEW.cod_material;

    IF v_biblioteca_material != :NEW.cod_biblioteca_origem THEN
        RAISE_APPLICATION_ERROR(-20103,
            'Transferencia invalida: material nao esta na biblioteca de origem');
    END IF;

    SELECT cod_biblioteca INTO v_biblioteca_solicitante
      FROM FUNCIONARIO
     WHERE cod_funcionario = :NEW.cod_funcionario_solicitante;

    IF v_biblioteca_solicitante != :NEW.cod_biblioteca_origem THEN
        RAISE_APPLICATION_ERROR(-20104,
            'Transferencia invalida: funcionario solicitante nao trabalha na biblioteca de origem');
    END IF;

    IF :NEW.cod_funcionario_aprovador IS NOT NULL THEN
        SELECT cod_biblioteca INTO v_biblioteca_aprovador
          FROM FUNCIONARIO
         WHERE cod_funcionario = :NEW.cod_funcionario_aprovador;

        IF v_biblioteca_aprovador != :NEW.cod_biblioteca_destino THEN
            RAISE_APPLICATION_ERROR(-20105,
                'Transferencia invalida: funcionario aprovador nao trabalha na biblioteca de destino');
        END IF;
    END IF;
END;
/

-- TRIGGER: protege_ultimo_exemplar_insert
-- Bloqueia pedido de transferencia se for o unico exemplar disponivel na origem.
-- Usa emprestimo_activo (sinonimo para vw_emprestimos_activos@emprestimosdb)
CREATE OR REPLACE TRIGGER protege_ultimo_exemplar_insert
BEFORE INSERT ON TRANSFERENCIA
FOR EACH ROW
DECLARE
    v_disponiveis NUMBER;
    v_isbn        VARCHAR2(20);
    v_titulo      VARCHAR2(200);
BEGIN
    IF :NEW.estado_transferencia <> 'Pendente' THEN
        RETURN;
    END IF;

    SELECT ISBN, titulo INTO v_isbn, v_titulo
      FROM MATERIAL_BIBLIOGRAFICO
     WHERE cod_material = :NEW.cod_material;

    IF v_isbn IS NOT NULL THEN
        SELECT COUNT(m.cod_material) INTO v_disponiveis
          FROM MATERIAL_BIBLIOGRAFICO m
         WHERE m.ISBN = v_isbn
           AND m.cod_biblioteca = :NEW.cod_biblioteca_origem
           AND m.cod_material NOT IN (SELECT cod_material FROM emprestimo_activo)
           AND m.cod_material NOT IN (
               SELECT cod_material FROM TRANSFERENCIA
                WHERE estado_transferencia IN ('Pendente', 'Aprovada')
                  AND id_transferencia <> :NEW.id_transferencia);
    ELSE
        SELECT COUNT(m.cod_material) INTO v_disponiveis
          FROM MATERIAL_BIBLIOGRAFICO m
         WHERE normaliza_titulo(m.titulo) = normaliza_titulo(v_titulo)
           AND m.cod_biblioteca = :NEW.cod_biblioteca_origem
           AND m.cod_material NOT IN (SELECT cod_material FROM emprestimo_activo)
           AND m.cod_material NOT IN (
               SELECT cod_material FROM TRANSFERENCIA
                WHERE estado_transferencia IN ('Pendente', 'Aprovada')
                  AND id_transferencia <> :NEW.id_transferencia);
    END IF;

    IF v_disponiveis <= 1 THEN
        RAISE_APPLICATION_ERROR(-20015,
            'Transferencia bloqueada: ultimo exemplar disponivel de "' ||
            v_titulo || '" na biblioteca de origem.');
    END IF;
END;
/

-- TRIGGER: protege_ultimo_exemplar_update
-- Bloqueia aprovacao de transferencia se for o unico exemplar disponivel na origem.
CREATE OR REPLACE TRIGGER protege_ultimo_exemplar_update
BEFORE UPDATE ON TRANSFERENCIA
FOR EACH ROW
DECLARE
    v_disponiveis NUMBER;
    v_isbn        VARCHAR2(20);
    v_titulo      VARCHAR2(200);
BEGIN
    IF NOT (:NEW.estado_transferencia = 'Aprovada' AND :OLD.estado_transferencia <> 'Aprovada') THEN
        RETURN;
    END IF;

    SELECT ISBN, titulo INTO v_isbn, v_titulo
      FROM MATERIAL_BIBLIOGRAFICO
     WHERE cod_material = :NEW.cod_material;

    IF v_isbn IS NOT NULL THEN
        SELECT COUNT(m.cod_material) INTO v_disponiveis
          FROM MATERIAL_BIBLIOGRAFICO m
         WHERE m.ISBN = v_isbn
           AND m.cod_biblioteca = :NEW.cod_biblioteca_origem
           AND m.cod_material NOT IN (SELECT cod_material FROM emprestimo_activo)
           AND m.cod_material NOT IN (
               SELECT cod_material FROM TRANSFERENCIA
                WHERE estado_transferencia IN ('Pendente', 'Aprovada')
                  AND id_transferencia <> :NEW.id_transferencia);
    ELSE
        SELECT COUNT(m.cod_material) INTO v_disponiveis
          FROM MATERIAL_BIBLIOGRAFICO m
         WHERE normaliza_titulo(m.titulo) = normaliza_titulo(v_titulo)
           AND m.cod_biblioteca = :NEW.cod_biblioteca_origem
           AND m.cod_material NOT IN (SELECT cod_material FROM emprestimo_activo)
           AND m.cod_material NOT IN (
               SELECT cod_material FROM TRANSFERENCIA
                WHERE estado_transferencia IN ('Pendente', 'Aprovada')
                  AND id_transferencia <> :NEW.id_transferencia);
    END IF;

    IF v_disponiveis <= 1 THEN
        RAISE_APPLICATION_ERROR(-20016,
            'Aprovacao bloqueada: ultimo exemplar disponivel de "' ||
            v_titulo || '" na biblioteca de origem.');
    END IF;
END;
/

