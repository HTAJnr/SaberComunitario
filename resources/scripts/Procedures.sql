-- PROCEDURE: registrar_doacao_completa
-- OBJETIVO: Registrar uma doação e seus itens, com emissão automática de certificado (RN08)
CREATE OR REPLACE PROCEDURE registrar_doacao_completa (
    p_id_doador         IN  NUMBER,
    p_data              IN  DATE,
    p_itens             IN  SYS_REFCURSOR,
    p_id_doacao         OUT NUMBER,
    p_num_certificado   OUT VARCHAR2
)
AS
    v_id_biblioteca    NUMBER;
    v_qtd              NUMBER;
    v_valor            NUMBER;
    v_obs              VARCHAR2(200);
BEGIN
    -- 1. Criar a doação (ID gerado pelo trigger) e obter o ID gerado
    INSERT INTO DOACAO (id_doador, data_doacao)
    VALUES (p_id_doador, NVL(p_data, SYSDATE))
    RETURNING id_doacao INTO p_id_doacao;

    -- 2. Inserir cada item
    LOOP
        FETCH p_itens INTO v_id_biblioteca, v_qtd, v_valor, v_obs;
        EXIT WHEN p_itens%NOTFOUND;

        -- CORREÇÃO: Removida a inserção manual do ID do item.
        -- O trigger 'trg_itemdoado_id' já usa a sequência 'SEQ_ITEMDOADO' para isso.
        INSERT INTO ITEM_DOACAO (
            id_doacao,
            id_biblioteca,
            quantidade,
            valor_estimado,
            observacoes
        ) VALUES (
            p_id_doacao,
            v_id_biblioteca,
            v_qtd,
            v_valor,
            v_obs
        );
    END LOOP;
    CLOSE p_itens;
    
    -- 3. Buscar número de certificado (se o trigger 'gera_certificado_automatico' tiver sido disparado)
    BEGIN
        SELECT num_certificado
          INTO p_num_certificado
          FROM CERTIFICADO_DOACAO
         WHERE id_doacao = p_id_doacao
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_num_certificado := NULL;
    END;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'Erro ao registrar doacao completa: ' || SQLERRM);
END;
/

-- PROCEDURE: reemitir_certificado
-- OBJETIVO: Reemitir certificado de uma doação existente
CREATE OR REPLACE PROCEDURE reemitir_certificado (
    p_id_doacao     IN  NUMBER,
    p_motivo        IN  VARCHAR2,
    p_numero_novo   OUT VARCHAR2
)
AS
    v_numero_antigo  VARCHAR2(30);
    v_seq            NUMBER;
BEGIN
    -- 1. Verificar se a doação tem certificado original
    SELECT num_certificado
      INTO v_numero_antigo
      FROM CERTIFICADO_DOACAO
     WHERE id_doacao = p_id_doacao
       AND tipo_certificado = 'Original'
       AND ROWNUM = 1;

    -- 2. Gerar novo número sequencial
    SELECT seq_certificado.NEXTVAL INTO v_seq FROM dual;

    p_numero_novo := 'CERT-' || TO_CHAR(SYSDATE, 'YYYY') || '-' || LPAD(v_seq, 4, '0');

    -- 3. Inserir novo certificado de reemissão
    INSERT INTO CERTIFICADO_DOACAO (
        id_certificado,
        id_doacao,
        num_certificado,
        tipo_certificado,
        data_emissao,
        observacoes,
        original_numero
    ) VALUES (
        seq_certificado.NEXTVAL,
        p_id_doacao,
        p_numero_novo,
        'Reemissao',
        SYSDATE,
        p_motivo,
        v_numero_antigo
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

-- PROCEDURE: cadastrar_biblioteca
-- OBJETIVO: Reemitir certificado de uma doação existente
CREATE OR REPLACE PROCEDURE cadastrar_biblioteca(
  p_nome IN VARCHAR2,
  p_localizacao IN VARCHAR2,
  p_contacto IN VARCHAR2,
  p_id_coordenador IN NUMBER
) AS
  v_id_biblioteca NUMBER;
BEGIN
  -- Gerar novo ID
  SELECT NVL(MAX(id_biblioteca), 0) + 1 INTO v_id_biblioteca
  FROM BIBLIOTECA;
  
  -- Inserir biblioteca
  INSERT INTO BIBLIOTECA (id_biblioteca, nome_biblioteca, localizacao, contacto_biblioteca, id_responsavel)
  VALUES (v_id_biblioteca, p_nome, p_localizacao, p_contacto, p_id_coordenador);
  COMMIT;
END;
/


CREATE OR REPLACE PROCEDURE inserir_leitor(
    p_num_cartao          IN VARCHAR2,
    p_nome_completo       IN VARCHAR2,
    p_data_nasc           IN DATE,
    p_genero              IN VARCHAR2,
    p_nivel_escolar       IN VARCHAR2,
    p_localizacao_leitor  IN VARCHAR2,
    p_contacto            IN VARCHAR2
)
IS
BEGIN
    INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar, localizacao_leitor, contacto)
    VALUES (p_num_cartao, p_nome_completo, p_data_nasc, p_genero, p_nivel_escolar, p_localizacao_leitor, p_contacto);
END inserir_leitor;
/

CREATE OR REPLACE PROCEDURE inserir_emprestimo (
    p_num_cartao            IN VARCHAR2,
    p_id_funcionario        IN NUMBER,
    p_id_material           IN NUMBER,
    p_dias_prazo            IN NUMBER,
    p_estado_saida          IN VARCHAR2
) AS
BEGIN
    INSERT INTO EMPRESTIMO (
        id_emprestimo,
        num_cartao,
        id_funcionario,
        id_material,
        data_retirada,
        prazo_devolucao,
        estado_material_saida,
        multa_paga
    ) VALUES (
        SEQ_EMPRESTIMO.NEXTVAL,
        p_num_cartao,
        p_id_funcionario,
        p_id_material,
        SYSDATE,
        SYSDATE + p_dias_prazo,
        p_estado_saida,
        'N'
    );

    DBMS_OUTPUT.PUT_LINE('Emprestimo inserido com sucesso para o leitor ' || p_num_cartao);
END inserir_emprestimo;
/
--inserir novo empréstimo
--EXEC inserir_emprestimo('L001', 5, 210, 10, 'Bom');

CREATE OR REPLACE PROCEDURE atualizar_devolucao (
    p_id_emprestimo IN NUMBER,
    p_estado_retorno IN VARCHAR2,
    p_observacoes IN VARCHAR2
) AS
    v_prazo DATE;
    v_data_retirada DATE;
    v_data_devolucao DATE := SYSDATE;
    v_multa NUMBER;
BEGIN
    SELECT prazo_devolucao, data_retirada INTO v_prazo, v_data_retirada
    FROM EMPRESTIMO
    WHERE id_emprestimo = p_id_emprestimo;

    v_multa := calcular_multa(v_prazo, v_data_devolucao);

    UPDATE EMPRESTIMO
    SET data_devolucao = v_data_devolucao,
        estado_material_retorno = p_estado_retorno,
        observacoes_devolucao = NVL(p_observacoes, 'Devolvido'),
        multa_valor = v_multa,
        multa_paga = CASE WHEN v_multa = 0 THEN 'S' ELSE 'N' END,
        data_pagamento_multa = CASE WHEN v_multa = 0 THEN SYSDATE ELSE NULL END
    WHERE id_emprestimo = p_id_emprestimo;

    DBMS_OUTPUT.PUT_LINE('Devolucao atualizada. Multa: ' || NVL(v_multa, 0) || ' MT');
END atualizar_devolucao;
/
--atualizar devolução e aplicar multa (usa a função acima)
--EXEC atualizar_devolucao(101, 'Bom', 'Devolvido dentro do prazo');

CREATE OR REPLACE PROCEDURE processar_devolucao (
    p_id_emprestimo          IN  EMPRESTIMO.id_emprestimo%TYPE,
    p_estado_material_retorno IN VARCHAR2,
    p_observacoes             IN VARCHAR2,
    p_sucesso                 OUT VARCHAR2,
    p_valor_multa             OUT NUMBER
) IS
    v_data_devolucao_atual    DATE := SYSDATE;
    v_valor_material    NUMBER := 0;
    v_valor_multa_final NUMBER := 0;
    v_atraso_dias       NUMBER := 0;
    v_id_material       EMPRESTIMO.id_material%TYPE;
    v_prazo_devolucao   DATE;
    v_data_devolucao_existente DATE;
BEGIN
    -- CORREÇÃO: Adicionado JOIN com ITEM_DOACAO para obter o 'valor_estimado'
    SELECT e.id_material, e.prazo_devolucao, e.data_devolucao, i.valor_estimado
      INTO v_id_material, v_prazo_devolucao, v_data_devolucao_existente, v_valor_material
      FROM EMPRESTIMO e
      JOIN MATERIAL_BIBLIOGRAFICO m ON e.id_material = m.id_material
      JOIN ITEM_DOACAO i ON m.id_itemDoado = i.id_itemDoado
     WHERE e.id_emprestimo = p_id_emprestimo;

    IF v_data_devolucao_existente IS NOT NULL THEN
        p_sucesso := 'Erro: Emprestimo ja devolvido anteriormente.';
        p_valor_multa := NULL;
        RETURN;
    END IF;

    -- CORREÇÃO: Trocado 'observacoes' por 'observacoes_devolucao'
    UPDATE EMPRESTIMO
       SET data_devolucao = v_data_devolucao_atual,
           estado_material_retorno = p_estado_material_retorno,
           observacoes_devolucao = p_observacoes
     WHERE id_emprestimo = p_id_emprestimo;

    -- CORREÇÃO: Trocado 'valor_multa' por 'multa_valor'
    SELECT NVL(multa_valor, 0)
      INTO v_valor_multa_final
      FROM EMPRESTIMO
     WHERE id_emprestimo = p_id_emprestimo;

    IF v_data_devolucao_atual > v_prazo_devolucao THEN
        v_atraso_dias := TRUNC(v_data_devolucao_atual - v_prazo_devolucao);
    END IF;

    -- CORREÇÃO: Trocado 'estado_conservacao' por 'estado_material_conservacao'
    IF UPPER(p_estado_material_retorno) = 'DEGRADADO' THEN
        v_valor_multa_final := v_valor_multa_final + (NVL(v_valor_material, 0) * 0.20);
        UPDATE MATERIAL_BIBLIOGRAFICO SET estado_material_conservacao = 'Degradado' WHERE id_material = v_id_material;

    ELSIF UPPER(p_estado_material_retorno) = 'PERDIDO' OR v_atraso_dias > 60 THEN
        v_valor_multa_final := v_valor_multa_final + (NVL(v_valor_material, 0) * 1.50) + 50;
        UPDATE MATERIAL_BIBLIOGRAFICO SET estado_material_conservacao = 'Indisponivel' WHERE id_material = v_id_material;
    END IF;

    -- CORREÇÃO: Trocado 'valor_multa' por 'multa_valor'
    UPDATE EMPRESTIMO
       SET multa_valor = v_valor_multa_final
     WHERE id_emprestimo = p_id_emprestimo;

    p_valor_multa := v_valor_multa_final;
    p_sucesso := 'Sucesso: Devolucao processada com sucesso.';
    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_sucesso := 'Erro: Emprestimo nao encontrado.';
        p_valor_multa := NULL;
    WHEN OTHERS THEN
        ROLLBACK;
        p_sucesso := 'Erro inesperado: ' || SQLERRM;
        p_valor_multa := NULL;
END;
/
--EXEC processar_devolucao(101, 'Degradado', 'Capa danificada', :sucesso, :valor_multa);

CREATE OR REPLACE PROCEDURE refresh_all_mviews IS
BEGIN
  FOR r IN (SELECT mview_name FROM user_mviews) LOOP
    DBMS_MVIEW.REFRESH(r.mview_name);
  END LOOP;
END;
/
--Atualiza todas as materialized views do usuário
--EXEC refresh_all_mviews;

CREATE OR REPLACE PROCEDURE atualiza_multa(
    p_id_emprestimo IN emprestimo.id_emprestimo%TYPE,
    p_nova_multa    IN emprestimo.multa_valor%TYPE
)
IS
BEGIN
    UPDATE emprestimo
       SET multa_valor = p_nova_multa
     WHERE id_emprestimo = p_id_emprestimo;

    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Nenhum emprestimo encontrado com o ID: ' || p_id_emprestimo);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Multa atualizada com sucesso para o emprestimo ID: ' || p_id_emprestimo);
    END IF;

    COMMIT;  -- Confirma a atualização
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;  -- Reverte caso ocorra erro
        DBMS_OUTPUT.PUT_LINE('Erro ao atualizar multa: ' || SQLERRM);
END;
/
--Atualiza o valor da multa para um empréstimo específico
--EXEC atualiza_multa(?, ?);

-- PROCEDURE: insere_participacao_evento
-- OBJETIVO: Inserir participação em evento, bloqueando duplicações
CREATE OR REPLACE PROCEDURE insere_participacao_evento (
    p_num_cartao           IN participacao_evento.num_cartao%TYPE,
    p_id_evento            IN participacao_evento.id_evento%TYPE,
    p_presenca_confirmacao IN participacao_evento.presenca_confirmacao%TYPE
)
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM participacao_evento
     WHERE num_cartao = p_num_cartao
       AND id_evento = p_id_evento;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20600, 'Leitor ja inscrito neste evento');
    END IF;

    INSERT INTO participacao_evento (
        num_cartao,
        id_evento,
        data_inscricao,
        presenca_confirmacao
    ) VALUES (
        p_num_cartao,
        p_id_evento,
        SYSDATE,
        p_presenca_confirmacao
    );

    COMMIT;
END;
/

-- Valida Formato do numero do cartão
CREATE OR REPLACE TRIGGER valida_formato_num_cartao
BEFORE INSERT OR UPDATE OF num_cartao ON LEITOR
FOR EACH ROW
DECLARE
    v_prefixo VARCHAR2(3);
    v_ano VARCHAR2(4);
    v_sequencia VARCHAR2(5);
BEGIN
    IF LENGTH(:NEW.num_cartao) != 12 THEN
        RAISE_APPLICATION_ERROR(-20500, 
            'Numero de cartao invalido: deve ter 12 caracteres (formato: XXX202XYYYYY)');
    END IF;

    v_prefixo := SUBSTR(:NEW.num_cartao, 1, 3);
    v_ano := SUBSTR(:NEW.num_cartao, 4, 4);
    v_sequencia := SUBSTR(:NEW.num_cartao, 8, 5);

    IF NOT REGEXP_LIKE(v_prefixo, '^[A-Z]{3}$') THEN
        RAISE_APPLICATION_ERROR(-20501, 'Prefixo invalido: 3 letras maiusculas');
    END IF;

    IF NOT REGEXP_LIKE(v_ano, '^202[3-9]$') THEN
        RAISE_APPLICATION_ERROR(-20502, 'Ano invalido: formato 202X (2023-2029)');
    END IF;

    IF NOT REGEXP_LIKE(v_sequencia, '^[0-9]{5}$') THEN
        RAISE_APPLICATION_ERROR(-20503, 'Sequencia invalida: 5 digitos');
    END IF;

    :NEW.num_cartao := UPPER(:NEW.num_cartao);
END;
/