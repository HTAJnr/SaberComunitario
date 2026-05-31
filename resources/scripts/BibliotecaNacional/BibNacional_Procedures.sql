-- ============================================================
-- BibNacional_Procedures.sql
--
-- PORQUÊ EXECUTE IMMEDIATE NAS QUERIES CROSS-NODE:
-- O Oracle PL/SQL valida objectos referenciados em tempo de compilação.
-- Quando uma procedure contém "SELECT ... FROM tabela@link", o Oracle
-- tenta resolver o objecto remoto no momento em que o código é compilado.
-- Se o nó remoto não está acessível nesse instante, a compilação falha
-- com ORA-04052. Com EXECUTE IMMEDIATE, a query é tratada como SQL
-- dinâmico e só é resolvida em runtime — quando o link já está activo.
--
-- As strings de EXECUTE IMMEDIATE referenciam sinónimos públicos
-- (ex: "emprestimo" em vez de "emprestimo@emprestimosdb").
-- O Oracle resolve o sinónimo em runtime via BibNacional_Synonyms.sql.
-- ============================================================


-- ============================================================
-- PROCEDURE: registrar_doacao_completa
-- Regista uma doação e os seus itens num único bloco transaccional.
-- O certificado automático é gerado pelo trigger gera_certificado_automatico.
-- ============================================================
CREATE OR REPLACE PROCEDURE registrar_doacao_completa (
    p_id_doador       IN  NUMBER,
    p_cod_biblioteca  IN  VARCHAR2,
    p_data            IN  DATE,
    p_itens           IN  SYS_REFCURSOR,
    p_id_doacao       OUT NUMBER,
    p_num_certificado OUT VARCHAR2
) AS
    v_nome_item  VARCHAR2(200);
    v_tipo_item  VARCHAR2(20);
    v_qtd        NUMBER;
    v_valor      NUMBER;
    v_obs        VARCHAR2(300);
BEGIN
    INSERT INTO DOACAO (id_doador, cod_biblioteca, data_doacao)
    VALUES (p_id_doador, p_cod_biblioteca, NVL(p_data, SYSDATE))
    RETURNING id_doacao INTO p_id_doacao;

    LOOP
        FETCH p_itens INTO v_nome_item, v_tipo_item, v_qtd, v_valor, v_obs;
        EXIT WHEN p_itens%NOTFOUND;

        INSERT INTO ITEM_DOACAO (id_doacao, nome_item, tipo_item, quantidade, valor_estimado, observacoes)
        VALUES (p_id_doacao, v_nome_item, v_tipo_item, v_qtd, v_valor, v_obs);
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


-- ============================================================
-- PROCEDURE: reemitir_certificado
-- ============================================================
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


-- ============================================================
-- PROCEDURE: proc_gerir_acesso_bd
-- ============================================================
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


-- ============================================================
-- PROCEDURE: prc_registar_auditoria
-- PRAGMA AUTONOMOUS_TRANSACTION — o INSERT persiste mesmo que a
-- transacção principal faça ROLLBACK.
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_registar_auditoria (
    p_cod_funcionario IN VARCHAR2,
    p_operacao        IN VARCHAR2,
    p_objeto_afetado  IN VARCHAR2,
    p_resultado       IN VARCHAR2,
    p_motivo_falha    IN VARCHAR2 DEFAULT NULL,
    p_nos_afetados    IN VARCHAR2 DEFAULT NULL,
    p_observacoes     IN VARCHAR2 DEFAULT NULL
) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_id NUMBER;
BEGIN
    SELECT SEQ_AUDITORIA.NEXTVAL INTO v_id FROM DUAL;

    INSERT INTO AUDITORIA_OPERACOES (
        id_auditoria,
        data_operacao,
        cod_funcionario,
        operacao,
        objeto_afetado,
        resultado,
        motivo_falha,
        nos_afetados,
        observacoes
    ) VALUES (
        v_id,
        SYSDATE,
        p_cod_funcionario,
        p_operacao,
        p_objeto_afetado,
        p_resultado,
        p_motivo_falha,
        p_nos_afetados,
        p_observacoes
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Aviso: falha ao registar auditoria: ' || SQLERRM);
END;
/


-- ============================================================
-- PROCEDURE 1: prc_apagar_leitor
-- Cross-node via sinónimos: emprestimo, participacao_evento,
-- avaliacao_evento, participacao_programa.
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_apagar_leitor (
    p_num_cartao      IN VARCHAR2,
    p_cod_funcionario IN VARCHAR2
) AS
    v_nivel       VARCHAR2(15);
    v_emprestimos NUMBER := 0;
BEGIN
    -- 1. Verificar nível de acesso local
    BEGIN
        SELECT fn.nivel_acesso
          INTO v_nivel
          FROM FUNCIONARIO f
          JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
         WHERE f.cod_funcionario = p_cod_funcionario
           AND f.data_demissao IS NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            prc_registar_auditoria(
                p_cod_funcionario => p_cod_funcionario,
                p_operacao        => 'APAGAR_LEITOR',
                p_objeto_afetado  => p_num_cartao,
                p_resultado       => 'FALHA',
                p_motivo_falha    => 'Funcionario nao encontrado ou inactivo'
            );
            RAISE_APPLICATION_ERROR(-20100, 'Funcionario nao encontrado ou inactivo.');
    END;

    IF v_nivel != 'Administrador' THEN
        prc_registar_auditoria(
            p_cod_funcionario => p_cod_funcionario,
            p_operacao        => 'APAGAR_LEITOR',
            p_objeto_afetado  => p_num_cartao,
            p_resultado       => 'FALHA',
            p_motivo_falha    => 'Nivel de acesso insuficiente: ' || v_nivel
        );
        RAISE_APPLICATION_ERROR(-20101, 'Acesso negado. Nivel Administrador necessario.');
    END IF;

    -- 2. Verificar empréstimos activos (sinónimo: emprestimo)
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM emprestimo
          WHERE num_cartao = :1 AND data_devolucao IS NULL'
        INTO v_emprestimos USING p_num_cartao;

    IF v_emprestimos > 0 THEN
        prc_registar_auditoria(
            p_cod_funcionario => p_cod_funcionario,
            p_operacao        => 'APAGAR_LEITOR',
            p_objeto_afetado  => p_num_cartao,
            p_resultado       => 'FALHA',
            p_motivo_falha    => 'Leitor tem ' || v_emprestimos || ' emprestimo(s) activo(s)',
            p_nos_afetados    => 'EmprestimosDB'
        );
        RAISE_APPLICATION_ERROR(-20102,
            'Leitor tem emprestimos activos. Devolucao obrigatoria antes de apagar.');
    END IF;

    SAVEPOINT sp_antes_limpeza_cross_node;

    -- 3a. Limpeza de participações em eventos (sinónimo: participacao_evento)
    BEGIN
        EXECUTE IMMEDIATE
            'DELETE FROM participacao_evento WHERE num_cartao = :1'
            USING p_num_cartao;
    EXCEPTION
        WHEN OTHERS THEN
            prc_registar_auditoria(
                p_cod_funcionario => p_cod_funcionario,
                p_operacao        => 'APAGAR_LEITOR',
                p_objeto_afetado  => p_num_cartao,
                p_resultado       => 'FALHA',
                p_motivo_falha    => 'Falha em participacao_evento: ' || SQLERRM,
                p_nos_afetados    => 'EventosBibliotecasDB'
            );
            ROLLBACK TO SAVEPOINT sp_antes_limpeza_cross_node;
            RAISE;
    END;

    SAVEPOINT sp_apos_eventos_participacao;

    -- 3b. Limpeza de avaliações de eventos (sinónimo: avaliacao_evento)
    BEGIN
        EXECUTE IMMEDIATE
            'DELETE FROM avaliacao_evento WHERE num_cartao = :1'
            USING p_num_cartao;
    EXCEPTION
        WHEN OTHERS THEN
            prc_registar_auditoria(
                p_cod_funcionario => p_cod_funcionario,
                p_operacao        => 'APAGAR_LEITOR',
                p_objeto_afetado  => p_num_cartao,
                p_resultado       => 'FALHA',
                p_motivo_falha    => 'Falha em avaliacao_evento: ' || SQLERRM,
                p_nos_afetados    => 'EventosBibliotecasDB'
            );
            ROLLBACK TO SAVEPOINT sp_apos_eventos_participacao;
            RAISE;
    END;

    SAVEPOINT sp_apos_eventos_avaliacoes;

    -- 3c. Limpeza de participações em programas (sinónimo: participacao_programa)
    BEGIN
        EXECUTE IMMEDIATE
            'DELETE FROM participacao_programa WHERE num_cartao = :1'
            USING p_num_cartao;
    EXCEPTION
        WHEN OTHERS THEN
            prc_registar_auditoria(
                p_cod_funcionario => p_cod_funcionario,
                p_operacao        => 'APAGAR_LEITOR',
                p_objeto_afetado  => p_num_cartao,
                p_resultado       => 'FALHA',
                p_motivo_falha    => 'Falha em participacao_programa: ' || SQLERRM,
                p_nos_afetados    => 'EmprestimosDB'
            );
            ROLLBACK TO SAVEPOINT sp_apos_eventos_avaliacoes;
            RAISE;
    END;

    -- 4. DELETE principal — LEITOR é local
    DELETE FROM LEITOR WHERE num_cartao = p_num_cartao;

    -- 5. Auditoria de sucesso + COMMIT
    prc_registar_auditoria(
        p_cod_funcionario => p_cod_funcionario,
        p_operacao        => 'APAGAR_LEITOR',
        p_objeto_afetado  => p_num_cartao,
        p_resultado       => 'SUCESSO',
        p_nos_afetados    => 'BibliotecaNacionalDB (local), EmprestimosDB, EventosBibliotecasDB'
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/


-- ============================================================
-- PROCEDURE 2: prc_remover_funcionario
-- Cross-node via sinónimos: emprestimo, programa_funcionario.
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_remover_funcionario (
    p_cod_funcionario_alvo IN VARCHAR2,
    p_cod_funcionario_op   IN VARCHAR2
) AS
    v_nivel        VARCHAR2(15);
    v_emprestimos  NUMBER := 0;
BEGIN
    -- 1. Verificar nível de acesso do operador
    BEGIN
        SELECT fn.nivel_acesso
          INTO v_nivel
          FROM FUNCIONARIO f
          JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
         WHERE f.cod_funcionario = p_cod_funcionario_op
           AND f.data_demissao IS NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            prc_registar_auditoria(
                p_cod_funcionario => p_cod_funcionario_op,
                p_operacao        => 'REMOVER_FUNCIONARIO',
                p_objeto_afetado  => p_cod_funcionario_alvo,
                p_resultado       => 'FALHA',
                p_motivo_falha    => 'Operador nao encontrado ou inactivo'
            );
            RAISE_APPLICATION_ERROR(-20110, 'Operador nao encontrado ou inactivo.');
    END;

    IF v_nivel != 'Administrador' THEN
        prc_registar_auditoria(
            p_cod_funcionario => p_cod_funcionario_op,
            p_operacao        => 'REMOVER_FUNCIONARIO',
            p_objeto_afetado  => p_cod_funcionario_alvo,
            p_resultado       => 'FALHA',
            p_motivo_falha    => 'Nivel de acesso insuficiente: ' || v_nivel
        );
        RAISE_APPLICATION_ERROR(-20111, 'Acesso negado. Nivel Administrador necessario.');
    END IF;

    -- 2. Verificar histórico de empréstimos (sinónimo: emprestimo)
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM emprestimo
          WHERE cod_funcionario = :1'
        INTO v_emprestimos USING p_cod_funcionario_alvo;

    IF v_emprestimos > 0 THEN
        -- Soft delete
        UPDATE FUNCIONARIO
           SET data_demissao = SYSDATE
         WHERE cod_funcionario = p_cod_funcionario_alvo;

        prc_registar_auditoria(
            p_cod_funcionario => p_cod_funcionario_op,
            p_operacao        => 'REMOVER_FUNCIONARIO',
            p_objeto_afetado  => p_cod_funcionario_alvo,
            p_resultado       => 'SUCESSO',
            p_nos_afetados    => 'BibliotecaNacionalDB (local)',
            p_observacoes     => 'Soft delete: data_demissao preenchida. '
                                 || v_emprestimos || ' emprestimo(s) no historico.'
        );
    ELSE
        -- DELETE físico
        DELETE FROM FUNCIONARIO_HABILIDADE WHERE cod_funcionario = p_cod_funcionario_alvo;
        DELETE FROM HORARIO_FUNCIONARIO    WHERE cod_funcionario = p_cod_funcionario_alvo;

        -- programa_funcionario pertence ao EmpréstimosDB (sinónimo: programa_funcionario)
        EXECUTE IMMEDIATE
            'DELETE FROM programa_funcionario WHERE cod_funcionario = :1'
            USING p_cod_funcionario_alvo;

        DELETE FROM FUNCIONARIO WHERE cod_funcionario = p_cod_funcionario_alvo;

        prc_registar_auditoria(
            p_cod_funcionario => p_cod_funcionario_op,
            p_operacao        => 'REMOVER_FUNCIONARIO',
            p_objeto_afetado  => p_cod_funcionario_alvo,
            p_resultado       => 'SUCESSO',
            p_nos_afetados    => 'BibliotecaNacionalDB (local)',
            p_observacoes     => 'DELETE fisico: sem historico de emprestimos.'
        );
    END IF;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/


-- ============================================================
-- PROCEDURE 3: prc_refresh_snapshots
-- BibliotecaNacionalDB nao tem snapshots locais — é a fonte dos dados.
-- Esta procedure existe apenas para manter a interface uniforme:
-- o backend chama prc_refresh_snapshots em qualquer nó e o Oracle
-- faz REFRESH COMPLETE nas MVs locais. No NacionalDB não há MVs.
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_refresh_snapshots AS
    v_falhas NUMBER := 0;
BEGIN
    -- NacionalDB é o nó fonte: não tem MVs locais para refrescar.
    -- DBMS_MVIEW.REFRESH_ALL_MVIEWS chamado com 0 falhas esperadas.
    DBMS_MVIEW.REFRESH_ALL_MVIEWS(v_falhas);
    DBMS_OUTPUT.PUT_LINE('Refresh concluido. Falhas: ' || v_falhas);
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20200, 'Erro no refresh de snapshots: ' || SQLERRM);
END;
/


-- ============================================================
-- PROCEDURE 4: prc_modificar_nivel_acesso
-- Cross-node via sinónimo: repl_funcionarios (EmpréstimosDB).
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_modificar_nivel_acesso (
    p_cod_funcionario_alvo IN VARCHAR2,
    p_novo_id_funcao       IN NUMBER,
    p_cod_funcionario_op   IN VARCHAR2
) AS
    v_nivel      VARCHAR2(15);
    v_novo_nivel VARCHAR2(15);
BEGIN
    -- 1. Verificar nível de acesso do operador
    BEGIN
        SELECT fn.nivel_acesso
          INTO v_nivel
          FROM FUNCIONARIO f
          JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
         WHERE f.cod_funcionario = p_cod_funcionario_op
           AND f.data_demissao IS NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            prc_registar_auditoria(
                p_cod_funcionario => p_cod_funcionario_op,
                p_operacao        => 'MODIFICAR_NIVEL_ACESSO',
                p_objeto_afetado  => p_cod_funcionario_alvo,
                p_resultado       => 'FALHA',
                p_motivo_falha    => 'Operador nao encontrado ou inactivo'
            );
            RAISE_APPLICATION_ERROR(-20120, 'Operador nao encontrado ou inactivo.');
    END;

    IF v_nivel != 'Administrador' THEN
        prc_registar_auditoria(
            p_cod_funcionario => p_cod_funcionario_op,
            p_operacao        => 'MODIFICAR_NIVEL_ACESSO',
            p_objeto_afetado  => p_cod_funcionario_alvo,
            p_resultado       => 'FALHA',
            p_motivo_falha    => 'Nivel de acesso insuficiente: ' || v_nivel
        );
        RAISE_APPLICATION_ERROR(-20121, 'Acesso negado. Nivel Administrador necessario.');
    END IF;

    -- 2. UPDATE local
    UPDATE FUNCIONARIO
       SET id_funcao = p_novo_id_funcao
     WHERE cod_funcionario = p_cod_funcionario_alvo;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20122,
            'Funcionario alvo nao encontrado: ' || p_cod_funcionario_alvo);
    END IF;

    SELECT nivel_acesso INTO v_novo_nivel
      FROM FUNCAO_FUNCIONARIO
     WHERE id_funcao = p_novo_id_funcao;

    -- 3. Sincronização imediata da réplica (sinónimo: repl_funcionarios)
    EXECUTE IMMEDIATE
        'UPDATE repl_funcionarios
            SET id_funcao    = :1,
                nivel_acesso = :2
          WHERE cod_funcionario = :3'
        USING p_novo_id_funcao, v_novo_nivel, p_cod_funcionario_alvo;

    -- 4. Auditoria
    prc_registar_auditoria(
        p_cod_funcionario => p_cod_funcionario_op,
        p_operacao        => 'MODIFICAR_NIVEL_ACESSO',
        p_objeto_afetado  => p_cod_funcionario_alvo,
        p_resultado       => 'SUCESSO',
        p_nos_afetados    => 'BibliotecaNacionalDB (local), EmprestimosDB (replica)',
        p_observacoes     => 'Novo nivel: ' || v_novo_nivel
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/


-- ============================================================
-- PROCEDURE 5: prc_demo_2pc
-- Cross-node via sinónimo: material_bibliografico (MateriaisDB).
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_demo_2pc (
    p_id_doador      IN  NUMBER,
    p_cod_biblioteca IN  VARCHAR2,
    p_valor          IN  NUMBER,
    p_cod_material   IN  VARCHAR2,
    p_novo_estado    IN  VARCHAR2,
    p_id_doacao      OUT NUMBER
) AS
BEGIN
    -- 1. INSERT local
    INSERT INTO DOACAO (id_doador, cod_biblioteca, data_doacao)
    VALUES (p_id_doador, p_cod_biblioteca, SYSDATE)
    RETURNING id_doacao INTO p_id_doacao;

    INSERT INTO ITEM_DOACAO (id_doacao, nome_item, tipo_item, quantidade, valor_estimado, observacoes)
    VALUES (p_id_doacao, 'Material ' || p_cod_material, 'Livro', 1, p_valor, 'Demo 2PC — transaccao distribuida');

    -- 2. UPDATE remoto (sinónimo: material_bibliografico → MateriaisDB)
    EXECUTE IMMEDIATE
        'UPDATE material_bibliografico
            SET estado_material_conservacao = :1
          WHERE cod_material = :2'
        USING p_novo_estado, p_cod_material;

    -- COMMIT — Oracle lança 2PC automaticamente
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('2PC concluido com sucesso.');
    DBMS_OUTPUT.PUT_LINE('  Doacao local id : ' || p_id_doacao);
    DBMS_OUTPUT.PUT_LINE('  Material ' || p_cod_material ||
                         ' -> ' || p_novo_estado || ' em material_bibliografico');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20300,
            'Falha na transaccao distribuida (2PC): ' || SQLERRM);
END;
/


-- ============================================================
-- PROCEDURE: prc_emitir_honorifico  (RN08)
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_emitir_honorifico (
    p_id_doacao       IN  NUMBER,
    p_cod_funcionario IN  VARCHAR2,
    p_justificativa   IN  VARCHAR2,
    p_num_certificado OUT VARCHAR2
) AS
    v_nivel  VARCHAR2(15);
    v_seq    NUMBER;
BEGIN
    BEGIN
        SELECT fn.nivel_acesso
          INTO v_nivel
          FROM FUNCIONARIO f
          JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
         WHERE f.cod_funcionario = p_cod_funcionario
           AND f.data_demissao IS NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20130, 'Funcionario nao encontrado ou inactivo.');
    END;

    IF v_nivel NOT IN ('Coordenador', 'Administrador') THEN
        RAISE_APPLICATION_ERROR(-20131,
            'Acesso negado. Nivel Coordenador ou Administrador necessario. Nivel actual: '
            || v_nivel);
    END IF;

    SELECT SEQ_CERTIFICADO.NEXTVAL INTO v_seq FROM DUAL;
    p_num_certificado := 'CERT-' || TO_CHAR(SYSDATE, 'YYYY') || '-' || LPAD(v_seq, 4, '0');

    INSERT INTO CERTIFICADO_DOACAO (
        id_certificado,
        id_doacao,
        num_certificado,
        tipo_certificado,
        data_emissao,
        observacoes
    ) VALUES (
        v_seq,
        p_id_doacao,
        p_num_certificado,
        'Honorifico',
        SYSDATE,
        p_justificativa
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END prc_emitir_honorifico;
/


-- ============================================================
-- PROCEDURE: prc_atualizar_doacao_segura
-- Demonstra prevenção de deadlock por ordem consistente de locks.
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_atualizar_doacao_segura(
    p_id_doador  IN DOADOR.id_doador%TYPE,
    p_id_doacao  IN DOACAO.id_doacao%TYPE
) AS
    v_dummy  NUMBER;
BEGIN
    SELECT id_doador INTO v_dummy
      FROM DOADOR
     WHERE id_doador = p_id_doador
       FOR UPDATE;

    UPDATE DOACAO
       SET data_doacao = SYSDATE
     WHERE id_doacao = p_id_doacao;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END prc_atualizar_doacao_segura;
/