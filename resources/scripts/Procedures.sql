-- ============================================================
-- PROCEDURES.SQL — Sistema Saber Comunitario
-- Sessao 6: procedures limpas, sem logica de negocio duplicada
-- Logica de negocio (multas, limites, validacoes) → backend
-- BD responsavel por: integridade, auto-incremento, proteccao
-- ============================================================

-- PROCEDURE: registrar_doacao_completa
-- Regista uma doacao e os seus itens; certificado gerado pelo trigger gera_certificado_automatico
CREATE OR REPLACE PROCEDURE registrar_doacao_completa (
    p_id_doador         IN  NUMBER,
    p_data              IN  DATE,
    p_itens             IN  SYS_REFCURSOR,
    p_id_doacao         OUT NUMBER,
    p_num_certificado   OUT VARCHAR2
) AS
    v_cod_biblioteca  NUMBER;
    v_qtd            NUMBER;
    v_valor          NUMBER;
    v_obs            VARCHAR2(200);
BEGIN
    INSERT INTO DOACAO (id_doador, data_doacao)
    VALUES (p_id_doador, NVL(p_data, SYSDATE))
    RETURNING id_doacao INTO p_id_doacao;

    LOOP
        FETCH p_itens INTO v_cod_biblioteca, v_qtd, v_valor, v_obs;
        EXIT WHEN p_itens%NOTFOUND;

        INSERT INTO ITEM_DOACAO (
            id_doacao, cod_biblioteca, quantidade, valor_estimado, observacoes
        ) VALUES (
            p_id_doacao, v_cod_biblioteca, v_qtd, v_valor, v_obs
        );
    END LOOP;
    CLOSE p_itens;

    BEGIN
        SELECT num_certificado
          INTO p_num_certificado
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
-- Reemite certificado de uma doacao existente
CREATE OR REPLACE PROCEDURE reemitir_certificado (
    p_id_doacao     IN  NUMBER,
    p_motivo        IN  VARCHAR2,
    p_numero_novo   OUT VARCHAR2
) AS
    v_numero_antigo  VARCHAR2(30);
    v_seq            NUMBER;
BEGIN
    SELECT num_certificado
      INTO v_numero_antigo
      FROM CERTIFICADO_DOACAO
     WHERE id_doacao = p_id_doacao AND tipo_certificado = 'Original' AND ROWNUM = 1;

    SELECT seq_certificado.NEXTVAL INTO v_seq FROM dual;
    p_numero_novo := 'CERT-' || TO_CHAR(SYSDATE, 'YYYY') || '-' || LPAD(v_seq, 4, '0');

    INSERT INTO CERTIFICADO_DOACAO (
        id_certificado, id_doacao, num_certificado,
        tipo_certificado, data_emissao, observacoes, original_numero
    ) VALUES (
        seq_certificado.NEXTVAL, p_id_doacao, p_numero_novo,
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

-- PROCEDURE: inserir_leitor
-- Insere leitor + cod_biblioteca (obrigatorio); formatacao de contacto feita no backend
CREATE OR REPLACE PROCEDURE inserir_leitor (
    p_num_cartao         IN VARCHAR2,
    p_nome_completo      IN VARCHAR2,
    p_data_nasc          IN DATE,
    p_genero             IN VARCHAR2,
    p_nivel_escolar      IN VARCHAR2,
    p_localizacao_leitor IN VARCHAR2,
    p_contacto           IN VARCHAR2,
    p_cod_biblioteca      IN NUMBER
) AS
BEGIN
    INSERT INTO LEITOR (
        num_cartao, nome_completo, data_nasc, genero,
        nivel_escolar, localizacao_leitor, contacto, cod_biblioteca
    ) VALUES (
        p_num_cartao, p_nome_completo, p_data_nasc, p_genero,
        p_nivel_escolar, p_localizacao_leitor, p_contacto, p_cod_biblioteca
    );
END;
/

-- PROCEDURE: inserir_emprestimo
-- Insere emprestimo; verificacoes de disponibilidade e limites feitas no backend antes de chamar
CREATE OR REPLACE PROCEDURE inserir_emprestimo (
    p_num_cartao     IN VARCHAR2,
    p_cod_funcionario IN NUMBER,
    p_cod_material    IN NUMBER,
    p_dias_prazo     IN NUMBER,
    p_estado_saida   IN VARCHAR2
) AS
BEGIN
    INSERT INTO EMPRESTIMO (
        id_emprestimo, num_cartao, cod_funcionario, cod_material,
        data_retirada, prazo_devolucao, estado_material_saida, multa_paga
    ) VALUES (
        SEQ_EMPRESTIMO.NEXTVAL, p_num_cartao, p_cod_funcionario, p_cod_material,
        SYSDATE, SYSDATE + p_dias_prazo, p_estado_saida, 'N'
    );
END;
/

-- PROCEDURE: processar_devolucao
-- Regista devolucao com multa calculada pelo backend (p_multa_valor)
-- Actualiza estado do material se DEGRADADO ou PERDIDO
CREATE OR REPLACE PROCEDURE processar_devolucao (
    p_id_emprestimo           IN  EMPRESTIMO.id_emprestimo%TYPE,
    p_estado_material_retorno IN  VARCHAR2,
    p_observacoes             IN  VARCHAR2,
    p_multa_valor             IN  NUMBER,
    p_sucesso                 OUT VARCHAR2
) AS
    v_cod_material            EMPRESTIMO.cod_material%TYPE;
    v_data_devolucao_existente DATE;
BEGIN
    SELECT cod_material, data_devolucao
      INTO v_cod_material, v_data_devolucao_existente
      FROM EMPRESTIMO
     WHERE id_emprestimo = p_id_emprestimo;

    IF v_data_devolucao_existente IS NOT NULL THEN
        p_sucesso := 'Erro: Emprestimo ja devolvido anteriormente.';
        RETURN;
    END IF;

    UPDATE EMPRESTIMO
       SET data_devolucao         = SYSDATE,
           estado_material_retorno = p_estado_material_retorno,
           observacoes_devolucao  = p_observacoes,
           multa_valor            = p_multa_valor,
           multa_paga             = CASE WHEN p_multa_valor = 0 THEN 'S' ELSE 'N' END,
           data_pagamento_multa   = CASE WHEN p_multa_valor = 0 THEN SYSDATE ELSE NULL END
     WHERE id_emprestimo = p_id_emprestimo;

    IF UPPER(p_estado_material_retorno) = 'DEGRADADO' THEN
        UPDATE MATERIAL_BIBLIOGRAFICO
           SET estado_material_conservacao = 'Degradado'
         WHERE cod_material = v_cod_material;
    ELSIF UPPER(p_estado_material_retorno) = 'PERDIDO' THEN
        UPDATE MATERIAL_BIBLIOGRAFICO
           SET estado_material_conservacao = 'Indisponivel'
         WHERE cod_material = v_cod_material;
    END IF;

    p_sucesso := 'Sucesso: Devolucao processada com sucesso.';
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_sucesso := 'Erro: Emprestimo nao encontrado.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_sucesso := 'Erro inesperado: ' || SQLERRM;
END;
/

-- PROCEDURE: atualiza_multa
-- Actualiza o valor da multa para um emprestimo especifico
CREATE OR REPLACE PROCEDURE atualiza_multa (
    p_id_emprestimo IN EMPRESTIMO.id_emprestimo%TYPE,
    p_nova_multa    IN EMPRESTIMO.multa_valor%TYPE
) AS
BEGIN
    UPDATE EMPRESTIMO
       SET multa_valor = p_nova_multa
     WHERE id_emprestimo = p_id_emprestimo;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Emprestimo nao encontrado: ' || p_id_emprestimo);
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20031, 'Erro ao atualizar multa: ' || SQLERRM);
END;
/

-- PROCEDURE: insere_participacao_evento
-- Insere participacao em evento; verifica duplicado na BD (barreira de seguranca)
-- Validacoes de horario, publico-alvo e evento passado feitas no backend
CREATE OR REPLACE PROCEDURE insere_participacao_evento (
    p_num_cartao           IN PARTICIPACAO_EVENTO.num_cartao%TYPE,
    p_id_evento            IN PARTICIPACAO_EVENTO.id_evento%TYPE,
    p_presenca_confirmacao IN PARTICIPACAO_EVENTO.presenca_confirmacao%TYPE
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM PARTICIPACAO_EVENTO
     WHERE num_cartao = p_num_cartao AND id_evento = p_id_evento;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20600, 'Leitor ja inscrito neste evento');
    END IF;

    INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao, presenca_confirmacao)
    VALUES (p_num_cartao, p_id_evento, SYSDATE, p_presenca_confirmacao);

    COMMIT;
END;
/

-- PROCEDURE: suspender_leitor
-- Marca leitor como Suspenso; motivo registado via DBMS_OUTPUT para auditoria
CREATE OR REPLACE PROCEDURE suspender_leitor(
    p_num_cartao   IN VARCHAR2,
    p_id_emprestimo IN NUMBER,
    p_dias         IN NUMBER,   -- 7, 15, 30 ou 60
    p_observacoes  IN VARCHAR2 DEFAULT NULL
) AS
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe FROM LEITOR
    WHERE num_cartao = p_num_cartao;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20301, 'Leitor nao encontrado.');
    END IF;

    -- Não suspende Bloqueados (estado terminal)
    UPDATE LEITOR SET status_leitor = 'Suspenso'
    WHERE num_cartao = p_num_cartao AND status_leitor = 'Activo';

    INSERT INTO SUSPENSAO (num_cartao, id_emprestimo, data_inicio, data_fim,
                           dias_suspensao, estado_suspensao, observacoes)
    VALUES (p_num_cartao, p_id_emprestimo, SYSDATE, SYSDATE + p_dias,
            p_dias, 'Activa', p_observacoes);
END;
/

-- PROCEDURE: reativar_leitor
-- Reactiva leitor se nao tiver emprestimos em atraso (> 30 dias sem devolucao)
CREATE OR REPLACE PROCEDURE reativar_leitor(p_num_cartao IN VARCHAR2) AS
    v_suspensoes_activas NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_suspensoes_activas
    FROM SUSPENSAO
    WHERE num_cartao = p_num_cartao
      AND estado_suspensao = 'Activa'
      AND SYSDATE <= data_fim;

    IF v_suspensoes_activas > 0 THEN
        RAISE_APPLICATION_ERROR(-20302, 'Leitor tem suspensao activa. Aguardar data_fim ou reduzir via Coordenador.');
    END IF;

    -- Marcar suspensões vencidas como cumpridas
    UPDATE SUSPENSAO SET estado_suspensao = 'Cumprida'
    WHERE num_cartao = p_num_cartao
      AND estado_suspensao = 'Activa'
      AND SYSDATE > data_fim;

    UPDATE LEITOR SET status_leitor = 'Activo'
    WHERE num_cartao = p_num_cartao AND status_leitor = 'Suspenso';
END;
/

-- PROCEDURE: proc_gerir_acesso_bd
-- Gere acesso Oracle do funcionario via GRANT/REVOKE de role com base no nivel_acesso
CREATE OR REPLACE PROCEDURE proc_gerir_acesso_bd (
    p_cod_funcionario IN VARCHAR2,
    p_acao           IN VARCHAR2   -- 'GRANT' ou 'REVOKE'
) AS
    v_nivel  VARCHAR2(30);
    v_email  VARCHAR2(100);
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
