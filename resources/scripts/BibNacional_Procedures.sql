-- PROCEDURE: registrar_doacao_completa
-- Regista uma doação e os seus itens num único bloco transaccional.
-- O certificado automático é gerado pelo trigger gera_certificado_automatico.
CREATE OR REPLACE PROCEDURE registrar_doacao_completa (
    p_id_doador       IN  NUMBER,
    p_data            IN  DATE,
    p_itens           IN  SYS_REFCURSOR,
    p_id_doacao       OUT NUMBER,
    p_num_certificado OUT VARCHAR2
) AS
    v_cod_biblioteca VARCHAR2(10);
    v_qtd            NUMBER;
    v_valor          NUMBER;
    v_obs            VARCHAR2(300);
BEGIN
    INSERT INTO DOACAO (id_doador, data_doacao)
    VALUES (p_id_doador, NVL(p_data, SYSDATE))
    RETURNING id_doacao INTO p_id_doacao;

    LOOP
        FETCH p_itens INTO v_cod_biblioteca, v_qtd, v_valor, v_obs;
        EXIT WHEN p_itens%NOTFOUND;

        INSERT INTO ITEM_DOACAO (id_doacao, cod_biblioteca, quantidade, valor_estimado, observacoes)
        VALUES (p_id_doacao, v_cod_biblioteca, v_qtd, v_valor, v_obs);
    END LOOP;
    CLOSE p_itens;

    BEGIN
        SELECT num_certificado INTO p_num_certificado
          FROM CERTIFICADO_DOACAO
         WHERE id_doacao = p_id_doacao AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN p_num_certificado := NULL;
    END;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'Erro ao registrar doacao completa: ' || SQLERRM);
END;
/

-- PROCEDURE: reemitir_certificado
-- Reemite certificado de uma doação existente como tipo 'Reemissao'
CREATE OR REPLACE PROCEDURE reemitir_certificado (
    p_id_doacao   IN  NUMBER,
    p_motivo      IN  VARCHAR2,
    p_numero_novo OUT VARCHAR2
) AS
    v_numero_antigo VARCHAR2(20);
    v_seq           NUMBER;
    v_id_cert       NUMBER;
BEGIN
    SELECT num_certificado INTO v_numero_antigo
      FROM CERTIFICADO_DOACAO
     WHERE id_doacao = p_id_doacao AND tipo_certificado = 'Original' AND ROWNUM = 1;

    SELECT SEQ_CERTIFICADO.NEXTVAL INTO v_seq FROM DUAL;
    v_id_cert     := v_seq;
    p_numero_novo := 'CERT-' || TO_CHAR(SYSDATE, 'YYYY') || '-' || LPAD(v_seq, 4, '0');

    INSERT INTO CERTIFICADO_DOACAO (
        id_certificado, id_doacao, num_certificado,
        tipo_certificado, data_emissao, observacoes, original_numero
    ) VALUES (
        v_id_cert, p_id_doacao, p_numero_novo,
        'Reemissao', SYSDATE, p_motivo, v_numero_antigo
    );

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20020, 'A doacao informada nao possui certificado original.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20021, 'Erro ao reemitir certificado: ' || SQLERRM);
END;
/

-- PROCEDURE: proc_gerir_acesso_bd
-- Concede ou revoga role Oracle ao funcionário com base no nivel_acesso
CREATE OR REPLACE PROCEDURE proc_gerir_acesso_bd (
    p_cod_funcionario IN VARCHAR2,
    p_acao            IN VARCHAR2   -- 'GRANT' ou 'REVOKE'
) AS
    v_nivel VARCHAR2(30);
    v_email VARCHAR2(100);
BEGIN
    SELECT fn.nivel_acesso, f.email
      INTO v_nivel, v_email
      FROM FUNCIONARIO f
      JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
     WHERE f.cod_funcionario = p_cod_funcionario;

    IF p_acao = 'GRANT' THEN
        EXECUTE IMMEDIATE 'GRANT ROLE_' || v_nivel || ' TO "' || v_email || '"';
    ELSIF p_acao = 'REVOKE' THEN
        EXECUTE IMMEDIATE 'REVOKE ROLE_' || v_nivel || ' FROM "' || v_email || '"';
    ELSE
        RAISE_APPLICATION_ERROR(-20062, 'Acao invalida: ' || p_acao);
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20060, 'Funcionario nao encontrado: ' || p_cod_funcionario);
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20061, 'Erro ao gerir acesso BD: ' || SQLERRM);
END;
/
