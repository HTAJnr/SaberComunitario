-- ============================================================
-- TRIGGERS - EventosBibliotecasDB (v4)
-- Executar como usr_eventosdb
-- Nota: Sequencias criadas em EventosDB_Sequences.sql
-- ============================================================

-- ============================================================
-- TRIGGER RN07: Validacao do horario de evento
-- ============================================================
CREATE OR REPLACE TRIGGER trg_valida_horario_evento
BEFORE INSERT ON HORARIO_EVENTO
FOR EACH ROW
DECLARE
    v_cod_biblioteca EVENTO.cod_biblioteca%TYPE;
    v_dia_semana     VARCHAR2(20);
    v_hora_abertura  VARCHAR2(5);
    v_hora_fecho     VARCHAR2(5);
    v_count          NUMBER;
    v_motivo         VARCHAR2(300);
BEGIN
    -- 1. Obter a biblioteca do evento
    SELECT cod_biblioteca INTO v_cod_biblioteca
    FROM EVENTO WHERE id_evento = :NEW.id_evento;

    -- 2. Determinar dia da semana
    v_dia_semana := TRIM(TO_CHAR(:NEW.data_ocorrencia, 'DAY',
        'NLS_DATE_LANGUAGE=PORTUGUESE'));

    v_dia_semana := CASE v_dia_semana
        WHEN 'SEGUNDA-FEIRA' THEN 'Segunda-feira'
        WHEN 'TERCA-FEIRA'   THEN 'Terca-feira'
        WHEN 'QUARTA-FEIRA'  THEN 'Quarta-feira'
        WHEN 'QUINTA-FEIRA'  THEN 'Quinta-feira'
        WHEN 'SEXTA-FEIRA'   THEN 'Sexta-feira'
        WHEN 'SABADO'        THEN 'Sabado'
        WHEN 'DOMINGO'       THEN 'Domingo'
        ELSE v_dia_semana
    END;

    -- 3. Verificar se existe horario para esse dia
    SELECT COUNT(*) INTO v_count
    FROM HORARIO_BIBLIOTECA
    WHERE cod_biblioteca = v_cod_biblioteca
    AND dia_semana = v_dia_semana;

    IF v_count = 0 THEN
        v_motivo := 'Biblioteca nao tem horario para ' || v_dia_semana;
        INSERT INTO AUDITORIA_EVENTOS VALUES (
            SEQ_AUDITORIA_EVT.NEXTVAL, SYSDATE,
            'INSERIR_HORARIO_EV', :NEW.id_evento,
            v_cod_biblioteca, NULL,
            'FALHA', v_motivo, NULL, NULL);
        RAISE_APPLICATION_ERROR(-20001,
            'Erro RN07: ' || v_motivo || '.');
    END IF;

    -- 4. Obter horario da biblioteca
    SELECT hora_abertura, hora_fecho
    INTO v_hora_abertura, v_hora_fecho
    FROM HORARIO_BIBLIOTECA
    WHERE cod_biblioteca = v_cod_biblioteca
    AND dia_semana = v_dia_semana;

    -- 5. Validar hora de inicio
    IF :NEW.hora_inicio < v_hora_abertura THEN
        v_motivo := 'Hora de inicio (' || :NEW.hora_inicio ||
            ') anterior a abertura (' || v_hora_abertura || ')';
        INSERT INTO AUDITORIA_EVENTOS VALUES (
            SEQ_AUDITORIA_EVT.NEXTVAL, SYSDATE,
            'INSERIR_HORARIO_EV', :NEW.id_evento,
            v_cod_biblioteca, NULL,
            'FALHA', v_motivo, NULL, NULL);
        RAISE_APPLICATION_ERROR(-20002, 'Erro RN07: ' || v_motivo || '.');
    END IF;

    -- 6. Validar hora de fim
    IF :NEW.hora_fim > v_hora_fecho THEN
        v_motivo := 'Hora de fim (' || :NEW.hora_fim ||
            ') apos fecho (' || v_hora_fecho || ')';
        INSERT INTO AUDITORIA_EVENTOS VALUES (
            SEQ_AUDITORIA_EVT.NEXTVAL, SYSDATE,
            'INSERIR_HORARIO_EV', :NEW.id_evento,
            v_cod_biblioteca, NULL,
            'FALHA', v_motivo, NULL, NULL);
        RAISE_APPLICATION_ERROR(-20003, 'Erro RN07: ' || v_motivo || '.');
    END IF;

    -- 7. Registar sucesso na auditoria
    INSERT INTO AUDITORIA_EVENTOS VALUES (
        SEQ_AUDITORIA_EVT.NEXTVAL, SYSDATE,
        'INSERIR_HORARIO_EV', :NEW.id_evento,
        v_cod_biblioteca, NULL,
        'SUCESSO', NULL, NULL, NULL);
END;
/

-- ============================================================
-- TRIGGER: Proteccao de DELETE em EVENTO
-- ============================================================
CREATE OR REPLACE TRIGGER trg_protege_delete_evento
BEFORE DELETE ON EVENTO
FOR EACH ROW
BEGIN
    IF :OLD.status_evento != 'Cancelado' THEN
        INSERT INTO AUDITORIA_EVENTOS VALUES (
            SEQ_AUDITORIA_EVT.NEXTVAL, SYSDATE,
            'APAGAR_EVENTO', :OLD.id_evento,
            :OLD.cod_biblioteca, NULL,
            'FALHA',
            'Tentativa de apagar evento com status ' || :OLD.status_evento,
            NULL, NULL);
        RAISE_APPLICATION_ERROR(-20010,
            'Operacao negada: so e possivel apagar eventos com status ' ||
            'Cancelado. Status actual: ' || :OLD.status_evento || '.');
    END IF;

    -- Registar DELETE autorizado
    INSERT INTO AUDITORIA_EVENTOS VALUES (
        SEQ_AUDITORIA_EVT.NEXTVAL, SYSDATE,
        'APAGAR_EVENTO', :OLD.id_evento,
        :OLD.cod_biblioteca, NULL,
        'SUCESSO', NULL, NULL, NULL);
END;
/

-- ============================================================
-- TRIGGERS DE AUTO-INCREMENTO — ausentes no ficheiro original
-- ============================================================

-- AVALIACAO_EVENTO: SEQ_AVALIACAO.NEXTVAL
-- Nota: o backend tambem usa SEQ_AVALIACAO.NEXTVAL directamente no INSERT;
-- este trigger e' uma barreira de seguranca para insercoes directas na BD
CREATE OR REPLACE TRIGGER trg_avaliacao_id
BEFORE INSERT ON AVALIACAO_EVENTO
FOR EACH ROW
BEGIN
    IF :NEW.id_avaliacao IS NULL THEN
        SELECT SEQ_AVALIACAO.NEXTVAL INTO :NEW.id_avaliacao FROM DUAL;
    END IF;
END;
/

-- EVENTO_RECURSO: SEQ_RECURSO.NEXTVAL
CREATE OR REPLACE TRIGGER trg_recurso_id
BEFORE INSERT ON EVENTO_RECURSO
FOR EACH ROW
BEGIN
    IF :NEW.id_recurso IS NULL THEN
        SELECT SEQ_RECURSO.NEXTVAL INTO :NEW.id_recurso FROM DUAL;
    END IF;
END;
/

