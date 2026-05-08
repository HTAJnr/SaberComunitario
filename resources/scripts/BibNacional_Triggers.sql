-- ============================================================
-- SECÇÃO 1: AUTO-INCREMENTOS
-- ============================================================

-- 1. FUNCAO_FUNCIONARIO
CREATE OR REPLACE TRIGGER trg_funcao_id
BEFORE INSERT ON FUNCAO_FUNCIONARIO FOR EACH ROW
BEGIN
    IF :NEW.id_funcao IS NULL THEN
        SELECT SEQ_FUNCAO.NEXTVAL INTO :NEW.id_funcao FROM DUAL;
    END IF;
END;
/

-- 2. FUNCIONARIO — gera FUC + ano + sequencial 4 dígitos
CREATE OR REPLACE TRIGGER trg_cod_funcionario
BEFORE INSERT ON FUNCIONARIO FOR EACH ROW
DECLARE
    v_seq NUMBER;
BEGIN
    IF :NEW.cod_funcionario IS NULL THEN
        SELECT SEQ_FUNCIONARIO.NEXTVAL INTO v_seq FROM DUAL;
        :NEW.cod_funcionario := 'FUC' || TO_CHAR(SYSDATE, 'YYYY') || LPAD(v_seq, 4, '0');
    END IF;
END;
/

-- 3. HORARIO_FUNCIONARIO
CREATE OR REPLACE TRIGGER trg_horario_func_id
BEFORE INSERT ON HORARIO_FUNCIONARIO FOR EACH ROW
BEGIN
    IF :NEW.id_horario_func IS NULL THEN
        SELECT SEQ_HORARIO_FUNC.NEXTVAL INTO :NEW.id_horario_func FROM DUAL;
    END IF;
END;
/

-- 4. DOADOR — id_doador = 0 é reservado (inserido explicitamente para Anónimo)
CREATE OR REPLACE TRIGGER trg_doador_id
BEFORE INSERT ON DOADOR FOR EACH ROW
BEGIN
    IF :NEW.id_doador IS NULL THEN
        SELECT SEQ_DOADOR.NEXTVAL INTO :NEW.id_doador FROM DUAL;
    END IF;
END;
/

-- 5. DOACAO
CREATE OR REPLACE TRIGGER trg_doacao_id
BEFORE INSERT ON DOACAO FOR EACH ROW
BEGIN
    IF :NEW.id_doacao IS NULL THEN
        SELECT SEQ_DOACAO.NEXTVAL INTO :NEW.id_doacao FROM DUAL;
    END IF;
END;
/

-- 6. ITEM_DOACAO
CREATE OR REPLACE TRIGGER trg_itemdoado_id
BEFORE INSERT ON ITEM_DOACAO FOR EACH ROW
BEGIN
    IF :NEW.id_itemDoado IS NULL THEN
        SELECT SEQ_ITEMDOADO.NEXTVAL INTO :NEW.id_itemDoado FROM DUAL;
    END IF;
END;
/

-- 7. CERTIFICADO_DOACAO
CREATE OR REPLACE TRIGGER trg_certificado_id
BEFORE INSERT ON CERTIFICADO_DOACAO FOR EACH ROW
BEGIN
    IF :NEW.id_certificado IS NULL THEN
        SELECT SEQ_CERTIFICADO.NEXTVAL INTO :NEW.id_certificado FROM DUAL;
    END IF;
END;
/

-- 8. PROGRAMA_ALFABETIZACAO — gera PROBIB + XXX (extraído de cod_biblioteca) + ano + sequencial 4 dígitos
--    Exemplo: cod_biblioteca = 'BIBMPC0001' → SUBSTR(..., 4, 3) = 'MPC' → 'PROBIBMPC20250001'
CREATE OR REPLACE TRIGGER trg_cod_programa
BEFORE INSERT ON PROGRAMA_ALFABETIZACAO FOR EACH ROW
DECLARE
    v_seq       NUMBER;
    v_provincia VARCHAR2(3);
BEGIN
    IF :NEW.cod_programa IS NULL THEN
        v_provincia := SUBSTR(:NEW.cod_biblioteca, 4, 3);
        SELECT SEQ_PROGRAMA.NEXTVAL INTO v_seq FROM DUAL;
        :NEW.cod_programa := 'PROBIB' || v_provincia || TO_CHAR(SYSDATE, 'YYYY') || LPAD(v_seq, 4, '0');
    END IF;
END;
/

-- 9. NIVEL_PROGRESSAO
CREATE OR REPLACE TRIGGER trg_nivel_id
BEFORE INSERT ON NIVEL_PROGRESSAO FOR EACH ROW
BEGIN
    IF :NEW.id_nivel IS NULL THEN
        SELECT SEQ_NIVEL.NEXTVAL INTO :NEW.id_nivel FROM DUAL;
    END IF;
END;
/

-- ============================================================
-- SECÇÃO 2: INTEGRIDADE DE DADOS
-- ============================================================

-- TRIGGER: protege_anonimo
-- Impede eliminação do doador anónimo (RN10)
CREATE OR REPLACE TRIGGER protege_anonimo
BEFORE DELETE ON DOADOR
FOR EACH ROW
BEGIN
    IF :OLD.id_doador = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'O doador Anonimo (ID 0) nao pode ser eliminado');
    END IF;
END;
/

-- TRIGGER: gera_certificado_automatico
-- Emite certificado automático para doações Individual >= 1000 MT (RN08).
-- Dispara após cada ITEM_DOACAO inserido; verifica total acumulado e se já existe certificado.
CREATE OR REPLACE TRIGGER gera_certificado_automatico
AFTER INSERT ON ITEM_DOACAO
FOR EACH ROW
DECLARE
    v_valor_total NUMBER := 0;
    v_tipo_doador VARCHAR2(20);
    v_ja_existe   NUMBER;
    v_seq         NUMBER;
    v_numero_cert VARCHAR2(30);
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
