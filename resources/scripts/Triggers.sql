-- ============================================================
-- SECÇÃO 1: AUTO-INCREMENTOS
-- ============================================================

-- 1. CATEGORIA
CREATE OR REPLACE TRIGGER trg_categoria_id
BEFORE INSERT ON CATEGORIA FOR EACH ROW
BEGIN
    IF :NEW.id_categoria IS NULL THEN
        SELECT SEQ_CATEGORIA.NEXTVAL INTO :NEW.id_categoria FROM DUAL;
    END IF;
END;
/

-- 2. CERTIFICADO_DOACAO
CREATE OR REPLACE TRIGGER trg_certificado_id
BEFORE INSERT ON CERTIFICADO_DOACAO FOR EACH ROW
BEGIN
    IF :NEW.id_certificado IS NULL THEN
        SELECT SEQ_CERTIFICADO.NEXTVAL INTO :NEW.id_certificado FROM DUAL;
    END IF;
END;
/

-- 3. DOACAO
CREATE OR REPLACE TRIGGER trg_doacao_id
BEFORE INSERT ON DOACAO FOR EACH ROW
BEGIN
    IF :NEW.id_doacao IS NULL THEN
        SELECT SEQ_DOACAO.NEXTVAL INTO :NEW.id_doacao FROM DUAL;
    END IF;
END;
/

-- 4. DOADOR
CREATE OR REPLACE TRIGGER trg_doador_id
BEFORE INSERT ON DOADOR FOR EACH ROW
BEGIN
    IF :NEW.id_doador IS NULL THEN
        SELECT SEQ_DOADOR.NEXTVAL INTO :NEW.id_doador FROM DUAL;
    END IF;
END;
/

-- 5. EMPRESTIMO
CREATE OR REPLACE TRIGGER trg_emprestimo_id
BEFORE INSERT ON EMPRESTIMO FOR EACH ROW
BEGIN
    IF :NEW.id_emprestimo IS NULL THEN
        SELECT SEQ_EMPRESTIMO.NEXTVAL INTO :NEW.id_emprestimo FROM DUAL;
    END IF;
END;
/

-- 6. EVENTO
CREATE OR REPLACE TRIGGER trg_evento_id
BEFORE INSERT ON EVENTO FOR EACH ROW
BEGIN
    IF :NEW.id_evento IS NULL THEN
        SELECT SEQ_EVENTO.NEXTVAL INTO :NEW.id_evento FROM DUAL;
    END IF;
END;
/

-- 7. EVENTO_RECURSO
CREATE OR REPLACE TRIGGER trg_recurso_id
BEFORE INSERT ON EVENTO_RECURSO FOR EACH ROW
BEGIN
    IF :NEW.id_recurso IS NULL THEN
        SELECT SEQ_RECURSO.NEXTVAL INTO :NEW.id_recurso FROM DUAL;
    END IF;
END;
/

-- 8. FUNCAO_FUNCIONARIO
CREATE OR REPLACE TRIGGER trg_funcao_id
BEFORE INSERT ON FUNCAO_FUNCIONARIO FOR EACH ROW
BEGIN
    IF :NEW.id_funcao IS NULL THEN
        SELECT SEQ_FUNCAO.NEXTVAL INTO :NEW.id_funcao FROM DUAL;
    END IF;
END;
/

-- 10. ITEM_DOACAO
CREATE OR REPLACE TRIGGER trg_itemdoado_id
BEFORE INSERT ON ITEM_DOACAO FOR EACH ROW
BEGIN
    IF :NEW.id_itemDoado IS NULL THEN
        SELECT SEQ_ITEMDOADO.NEXTVAL INTO :NEW.id_itemDoado FROM DUAL;
    END IF;
END;
/

-- 11. TRANSFERENCIA
CREATE OR REPLACE TRIGGER trg_transferencia_id
BEFORE INSERT ON TRANSFERENCIA FOR EACH ROW
BEGIN
    IF :NEW.id_transferencia IS NULL THEN
        SELECT SEQ_TRANSFERENCIA.NEXTVAL INTO :NEW.id_transferencia FROM DUAL;
    END IF;
END;
/

-- 12. NIVEL_PROGRESSAO
CREATE OR REPLACE TRIGGER trg_nivel_id
BEFORE INSERT ON NIVEL_PROGRESSAO FOR EACH ROW
BEGIN
    IF :NEW.id_nivel IS NULL THEN
        SELECT SEQ_NIVEL.NEXTVAL INTO :NEW.id_nivel FROM DUAL;
    END IF;
END;
/

-- 13. HORARIO_BIBLIOTECA
CREATE OR REPLACE TRIGGER trg_horario_bib_id
BEFORE INSERT ON HORARIO_BIBLIOTECA FOR EACH ROW
BEGIN
    IF :NEW.id_horario_bib IS NULL THEN
        SELECT SEQ_HORARIO_BIB.NEXTVAL INTO :NEW.id_horario_bib FROM DUAL;
    END IF;
END;
/

-- 14. HORARIO_FUNCIONARIO
CREATE OR REPLACE TRIGGER trg_horario_func_id
BEFORE INSERT ON HORARIO_FUNCIONARIO FOR EACH ROW
BEGIN
    IF :NEW.id_horario_func IS NULL THEN
        SELECT SEQ_HORARIO_FUNC.NEXTVAL INTO :NEW.id_horario_func FROM DUAL;
    END IF;
END;
/

-- 15. HORARIO_EVENTO
CREATE OR REPLACE TRIGGER trg_horario_ev_id
BEFORE INSERT ON HORARIO_EVENTO FOR EACH ROW
BEGIN
    IF :NEW.id_horario_ev IS NULL THEN
        SELECT SEQ_HORARIO_EV.NEXTVAL INTO :NEW.id_horario_ev FROM DUAL;
    END IF;
END;
/

-- 17. SUSPENSAO
CREATE OR REPLACE TRIGGER trg_suspensao_id
BEFORE INSERT ON SUSPENSAO FOR EACH ROW
BEGIN
    IF :NEW.id_suspensao IS NULL THEN
        SELECT SEQ_SUSPENSAO.NEXTVAL INTO :NEW.id_suspensao FROM DUAL;
    END IF;
END;
/

-- 18. AVALIACAO_EVENTO
CREATE OR REPLACE TRIGGER trg_avaliacao_id
BEFORE INSERT ON AVALIACAO_EVENTO FOR EACH ROW
BEGIN
    IF :NEW.id_avaliacao IS NULL THEN
        SELECT SEQ_AVALIACAO.NEXTVAL INTO :NEW.id_avaliacao FROM DUAL;
    END IF;
END;
/

-- ============================================================
-- SECÇÃO 2: INTEGRIDADE DE DADOS
-- ============================================================

-- TRIGGER: protege_anonimo
-- Impede eliminação do doador anónimo (RN10) — integridade referencial
CREATE OR REPLACE TRIGGER protege_anonimo
BEFORE DELETE ON DOADOR
FOR EACH ROW
BEGIN
    IF :OLD.id_doador = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'O doador Anonimo (ID 0) nao pode ser eliminado');
    END IF;
END;
/

-- TRIGGER: impede_exclusao_coordenador
-- Impede remoção de coordenador responsável por biblioteca ou com transferências activas
CREATE OR REPLACE TRIGGER impede_exclusao_coordenador
BEFORE DELETE ON FUNCIONARIO
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM BIBLIOTECA_RESPONSAVEL
    WHERE cod_funcionario = :OLD.cod_funcionario AND data_fim IS NULL;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20302, 'Coordenador nao pode ser removido enquanto for responsavel de biblioteca');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM TRANSFERENCIA
    WHERE (cod_funcionario_solicitante = :OLD.cod_funcionario
           OR cod_funcionario_aprovador = :OLD.cod_funcionario)
      AND estado_transferencia NOT IN ('Concluida', 'Rejeitada');

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20303, 'Funcionario com transferencias activas nao pode ser removido');
    END IF;
END;
/

-- TRIGGER: gera_certificado_automatico
-- Emite certificado automático para doações >= 1000 MT de doador Individual.
-- Dispara após cada item inserido; verifica total acumulado e se certificado já existe
-- (o INSERT de ITEM_DOACAO vem depois do INSERT de DOACAO, por isso dispara aqui e não em DOACAO).
CREATE OR REPLACE TRIGGER gera_certificado_automatico
AFTER INSERT ON ITEM_DOACAO
FOR EACH ROW
DECLARE
    v_valor_total  NUMBER := 0;
    v_tipo_doador  VARCHAR2(20);
    v_ja_existe    NUMBER;
    v_seq          NUMBER;
    v_numero_cert  VARCHAR2(30);
BEGIN
    SELECT NVL(SUM(valor_estimado * quantidade), 0)
      INTO v_valor_total
      FROM ITEM_DOACAO
     WHERE id_doacao = :NEW.id_doacao;

    IF v_valor_total < 1000 THEN
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_ja_existe
      FROM CERTIFICADO_DOACAO
     WHERE id_doacao = :NEW.id_doacao;

    IF v_ja_existe > 0 THEN
        RETURN;
    END IF;

    SELECT d.tipo_doador
      INTO v_tipo_doador
      FROM DOACAO doc
      JOIN DOADOR d ON doc.id_doador = d.id_doador
     WHERE doc.id_doacao = :NEW.id_doacao;

    IF v_tipo_doador = 'Individual' THEN
        SELECT SEQ_CERTIFICADO.NEXTVAL INTO v_seq FROM DUAL;
        v_numero_cert := 'CERT-' || TO_CHAR(SYSDATE, 'YYYY') || '-' || LPAD(v_seq, 4, '0');

        INSERT INTO CERTIFICADO_DOACAO (
            id_certificado, id_doacao, num_certificado,
            tipo_certificado, data_emissao, observacoes
        ) VALUES (
            v_seq, :NEW.id_doacao, v_numero_cert,
            'Original', SYSDATE, 'Certificado gerado automaticamente (RN08)'
        );
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN NULL;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao gerar certificado automatico: ' || SQLERRM);
END;
/

-- TRIGGER: trg_protege_material_trans
-- Impede empréstimo de material em transferência pendente ou aprovada — bypass sem trigger
CREATE OR REPLACE TRIGGER trg_protege_material_trans
BEFORE INSERT OR UPDATE OF cod_material ON EMPRESTIMO
FOR EACH ROW
DECLARE
    v_em_transferencia NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_em_transferencia
      FROM TRANSFERENCIA
     WHERE cod_material = :NEW.cod_material
       AND estado_transferencia IN ('Pendente', 'Aprovada');

    IF v_em_transferencia > 0 THEN
        RAISE_APPLICATION_ERROR(-20101,
            'Material em processo de transferencia. Emprestimo nao permitido.');
    END IF;
END;
/

-- TRIGGER: trg_valida_transferencia
-- Valida consistência da transferência: material na origem, funcionários nas bibliotecas correctas
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

    SELECT cod_biblioteca
      INTO v_biblioteca_material
      FROM MATERIAL_BIBLIOGRAFICO
     WHERE cod_material = :NEW.cod_material;

    IF v_biblioteca_material != :NEW.cod_biblioteca_origem THEN
        RAISE_APPLICATION_ERROR(-20103,
            'Transferencia invalida: material nao esta na biblioteca de origem');
    END IF;

    SELECT cod_biblioteca
      INTO v_biblioteca_solicitante
      FROM FUNCIONARIO
     WHERE cod_funcionario = :NEW.cod_funcionario_solicitante;

    IF v_biblioteca_solicitante != :NEW.cod_biblioteca_origem THEN
        RAISE_APPLICATION_ERROR(-20104,
            'Transferencia invalida: funcionario solicitante nao trabalha na biblioteca de origem');
    END IF;

    IF :NEW.cod_funcionario_aprovador IS NOT NULL THEN
        SELECT cod_biblioteca
          INTO v_biblioteca_aprovador
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
-- Bloqueia pedido de transferência se for o único exemplar disponível na origem
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
           AND m.cod_material NOT IN (SELECT cod_material FROM EMPRESTIMO WHERE data_devolucao IS NULL)
           AND m.cod_material NOT IN (
               SELECT cod_material FROM TRANSFERENCIA
                WHERE estado_transferencia IN ('Pendente', 'Aprovada')
                  AND id_transferencia <> :NEW.id_transferencia);
    ELSE
        SELECT COUNT(m.cod_material) INTO v_disponiveis
          FROM MATERIAL_BIBLIOGRAFICO m
         WHERE normaliza_titulo(m.titulo) = normaliza_titulo(v_titulo)
           AND m.cod_biblioteca = :NEW.cod_biblioteca_origem
           AND m.cod_material NOT IN (SELECT cod_material FROM EMPRESTIMO WHERE data_devolucao IS NULL)
           AND m.cod_material NOT IN (
               SELECT cod_material FROM TRANSFERENCIA
                WHERE estado_transferencia IN ('Pendente', 'Aprovada')
                  AND id_transferencia <> :NEW.id_transferencia);
    END IF;

    IF v_disponiveis <= 1 THEN
        RAISE_APPLICATION_ERROR(-20015,
            'Transferencia bloqueada: ultimo exemplar disponivel de "' || v_titulo || '" na biblioteca de origem.');
    END IF;
END;
/

-- TRIGGER: protege_ultimo_exemplar_update
-- Bloqueia aprovação de transferência se for o único exemplar disponível na origem
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
           AND m.cod_material NOT IN (SELECT cod_material FROM EMPRESTIMO WHERE data_devolucao IS NULL)
           AND m.cod_material NOT IN (
               SELECT cod_material FROM TRANSFERENCIA
                WHERE estado_transferencia IN ('Pendente', 'Aprovada')
                  AND id_transferencia <> :NEW.id_transferencia);
    ELSE
        SELECT COUNT(m.cod_material) INTO v_disponiveis
          FROM MATERIAL_BIBLIOGRAFICO m
         WHERE normaliza_titulo(m.titulo) = normaliza_titulo(v_titulo)
           AND m.cod_biblioteca = :NEW.cod_biblioteca_origem
           AND m.cod_material NOT IN (SELECT cod_material FROM EMPRESTIMO WHERE data_devolucao IS NULL)
           AND m.cod_material NOT IN (
               SELECT cod_material FROM TRANSFERENCIA
                WHERE estado_transferencia IN ('Pendente', 'Aprovada')
                  AND id_transferencia <> :NEW.id_transferencia);
    END IF;

    IF v_disponiveis <= 1 THEN
        RAISE_APPLICATION_ERROR(-20016,
            'Aprovacao bloqueada: ultimo exemplar disponivel de "' || v_titulo || '" na biblioteca de origem.');
    END IF;
END;
/

-- TRIGGER: trg_aplica_suspensao
-- Ao devolver (UPDATE com `data_devolucao`): criar registo em `SUSPENSAO` 
-- se há atraso (RN03.2), actualizar `historico_pontualidade` (RN03.2), actualizar `status_leitor`.
-- Verificação de leitor bloqueado: se atraso > 60 dias, activar RN03.3.
CREATE OR REPLACE TRIGGER trg_aplica_suspensao
AFTER UPDATE OF data_devolucao ON EMPRESTIMO
FOR EACH ROW
WHEN (NEW.data_devolucao IS NOT NULL AND OLD.data_devolucao IS NULL)
DECLARE
    v_dias_atraso    NUMBER;
    v_dias_suspensao NUMBER;
    v_total_atrasos  NUMBER;
    v_tipo_leitor    VARCHAR2(10);
    v_infracoes_prof NUMBER := 0;
BEGIN
    -- Calcular atraso
    v_dias_atraso := TRUNC(:NEW.data_devolucao) - TRUNC(:NEW.prazo_devolucao);

    IF v_dias_atraso <= 0 THEN
        RETURN; -- Devolvido a tempo — nada a fazer
    END IF;

    -- Bloqueio > 60 dias (RN03.3) — já devolvido mas com penalização máxima
    IF v_dias_atraso > 60 THEN
        UPDATE LEITOR SET status_leitor = 'Bloqueado'
        WHERE num_cartao = :NEW.num_cartao;
        RETURN;
    END IF;

    -- Calcular dias de suspensão (RN03.2)
    IF    v_dias_atraso BETWEEN 1  AND 7  THEN v_dias_suspensao := 7;
    ELSIF v_dias_atraso BETWEEN 8  AND 15 THEN v_dias_suspensao := 15;
    ELSIF v_dias_atraso BETWEEN 16 AND 30 THEN v_dias_suspensao := 30;
    ELSE                                       v_dias_suspensao := 60;
    END IF;

    -- Verificar se é Professor na 1ª infracção (RN03.1 — isento de multa mas não de suspensão)
    -- A multa é calculada no backend; aqui só registamos a suspensão

    -- Registar suspensão
    INSERT INTO SUSPENSAO (num_cartao, id_emprestimo, data_inicio, data_fim,
                           dias_suspensao, estado_suspensao)
    VALUES (:NEW.num_cartao, :NEW.id_emprestimo, SYSDATE,
            SYSDATE + v_dias_suspensao, v_dias_suspensao, 'Activa');

    -- Actualizar status do leitor
    UPDATE LEITOR SET status_leitor = 'Suspenso'
    WHERE num_cartao = :NEW.num_cartao AND status_leitor = 'Activo';

    -- Actualizar historico_pontualidade (RN03.2)
    SELECT COUNT(*) INTO v_total_atrasos
    FROM EMPRESTIMO
    WHERE num_cartao = :NEW.num_cartao
      AND data_devolucao > prazo_devolucao
      AND data_devolucao IS NOT NULL;

    IF v_total_atrasos >= 3 THEN
        UPDATE LEITOR SET historico_pontualidade = 'Mau'
        WHERE num_cartao = :NEW.num_cartao;
    ELSIF v_total_atrasos BETWEEN 1 AND 2 THEN
        UPDATE LEITOR SET historico_pontualidade = 'Irregular'
        WHERE num_cartao = :NEW.num_cartao
          AND historico_pontualidade = 'Pontual';
    END IF;
END;
/

-- Job diário para levantar suspensões cumpridas
-- (ou verificar via query no backend: estado_suspensao = 'Activa' AND SYSDATE > data_fim)
-- Trigger separado para levantar Suspenso → Activo quando suspensão termina
CREATE OR REPLACE TRIGGER trg_levanta_suspensao
-- Este trigger é chamado pelo job diário ou manualmente
-- Implementado como procedure (ver secção 6)
-- O trigger aqui é minimalista: só protege estado Bloqueado de ser revertido
BEFORE UPDATE OF status_leitor ON LEITOR
FOR EACH ROW
BEGIN
    IF :OLD.status_leitor = 'Bloqueado' AND :NEW.status_leitor != 'Bloqueado' THEN
        RAISE_APPLICATION_ERROR(-20200, 'Leitor bloqueado nao pode ser reactivado por trigger. Requer intervencao de Administrador.');
    END IF;
END;
/