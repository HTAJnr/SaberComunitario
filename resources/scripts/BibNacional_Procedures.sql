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

-- PROCEDURE DE REGISTO DE AUDITORIA
-- PRAGMA AUTONOMOUS_TRANSACTION garante que o INSERT na tabela de
-- auditoria é confirmado (COMMIT) independentemente do que aconteça
-- na transacção principal. Se a transacção principal fizer ROLLBACK
-- (ex: operação falhou), o registo de auditoria NÃO é revertido —
-- fica na tabela como prova da tentativa. Sem este pragma, o log
-- desapareceria junto com o ROLLBACK da operação principal, o que
-- tornaria a auditoria inútil para rastrear falhas e tentativas.
 
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
 
    COMMIT; -- AUTONOMOUS: confirma só este INSERT, não afecta a transacção principal
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- Não propaga o erro — a auditoria nunca deve bloquear a operação principal
        DBMS_OUTPUT.PUT_LINE('Aviso: falha ao registar auditoria: ' || SQLERRM);
END;
/

-- PROCEDURE 1: prc_apagar_leitor
-- Só Administrador pode apagar. Limpa dependências cross-node
-- manualmente antes do DELETE (CASCADEs não funcionam entre nós).
-- É uma transacção distribuída — demonstra 2PC automaticamente.
-- ============================================================
 
CREATE OR REPLACE PROCEDURE prc_apagar_leitor (
    p_num_cartao      IN VARCHAR2,   -- leitor a apagar
    p_cod_funcionario IN VARCHAR2    -- quem pede a operação
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
 
    -- 2. Verificar empréstimos activos no EmpréstimosDB
    SELECT COUNT(*)
      INTO v_emprestimos
      FROM emprestimo@emprestimosdb
     WHERE num_cartao = p_num_cartao
       AND data_devolucao IS NULL;
 
    IF v_emprestimos > 0 THEN
        prc_registar_auditoria(
            p_cod_funcionario => p_cod_funcionario,
            p_operacao        => 'APAGAR_LEITOR',
            p_objeto_afetado  => p_num_cartao,
            p_resultado       => 'FALHA',
            p_motivo_falha    => 'Leitor tem ' || v_emprestimos || ' emprestimo(s) activo(s)',
            p_nos_afetados    => 'EmprestimosDB'
        );
        RAISE_APPLICATION_ERROR(-20102, 'Leitor tem emprestimos activos. Devolucao obrigatoria antes de apagar.');
    END IF;
 
    -- 3. Limpeza cross-node (CASCADEs não funcionam entre nós)
    -- EventosBibliotecasDB
    DELETE FROM participacao_evento@eventosdb  WHERE num_cartao = p_num_cartao;
    DELETE FROM avaliacao_evento@eventosdb     WHERE num_cartao = p_num_cartao;

    -- EmpréstimosProgramasDB (PARTICIPACAO_PROGRAMA pertence ao nó do Yannis)
    DELETE FROM participacao_programa@emprestimosdb WHERE num_cartao = p_num_cartao;

    -- 4. DELETE principal — LEITOR agora é LOCAL neste nó (v3)
    DELETE FROM LEITOR WHERE num_cartao = p_num_cartao;

    -- 5. Auditoria de sucesso + COMMIT (Oracle faz 2PC automaticamente)
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
        RAISE; -- propaga o erro original (já foi auditado acima)
END;
/

-- PROCEDURE 2: prc_remover_funcionario
-- Só Administrador pode remover.
-- Se tiver histórico de empréstimos → data_demissao (soft delete).
-- Se não tiver → DELETE físico.
-- ============================================================
 
CREATE OR REPLACE PROCEDURE prc_remover_funcionario (
    p_cod_funcionario_alvo IN VARCHAR2,   -- funcionário a remover
    p_cod_funcionario_op   IN VARCHAR2    -- quem pede a operação
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
 
    -- 2. Verificar histórico de empréstimos no EmpréstimosDB
    SELECT COUNT(*)
      INTO v_emprestimos
      FROM emprestimo@emprestimosdb
     WHERE cod_funcionario = p_cod_funcionario_alvo;
 
    IF v_emprestimos > 0 THEN
        -- Tem histórico — soft delete (preserva integridade referencial)
        UPDATE FUNCIONARIO
           SET data_demissao = SYSDATE
         WHERE cod_funcionario = p_cod_funcionario_alvo;
 
        prc_registar_auditoria(
            p_cod_funcionario => p_cod_funcionario_op,
            p_operacao        => 'REMOVER_FUNCIONARIO',
            p_objeto_afetado  => p_cod_funcionario_alvo,
            p_resultado       => 'SUCESSO',
            p_nos_afetados    => 'BibliotecaNacionalDB (local)',
            p_observacoes     => 'Soft delete: data_demissao preenchida. ' || v_emprestimos || ' emprestimo(s) no historico.'
        );
    ELSE
        -- Sem histórico — DELETE físico seguro
        DELETE FROM FUNCIONARIO_HABILIDADE WHERE cod_funcionario = p_cod_funcionario_alvo;
        DELETE FROM HORARIO_FUNCIONARIO    WHERE cod_funcionario = p_cod_funcionario_alvo;
        -- PROGRAMA_FUNCIONARIO pertence ao EmpréstimosProgramasDB (nó do Yannis)
        DELETE FROM programa_funcionario@emprestimosdb WHERE cod_funcionario = p_cod_funcionario_alvo;
        DELETE FROM FUNCIONARIO            WHERE cod_funcionario = p_cod_funcionario_alvo;
 
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

-- PROCEDURE 3: prc_modificar_nivel_acesso
-- Só Administrador pode modificar.
-- Após UPDATE local, sincroniza imediatamente a réplica no EmpréstimosDB.
-- ============================================================
 
CREATE OR REPLACE PROCEDURE prc_modificar_nivel_acesso (
    p_cod_funcionario_alvo IN VARCHAR2,   -- funcionário a modificar
    p_novo_id_funcao       IN NUMBER,     -- novo id_funcao
    p_cod_funcionario_op   IN VARCHAR2    -- quem pede a operação
) AS
    v_nivel          VARCHAR2(15);
    v_novo_nivel     VARCHAR2(15);
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
        RAISE_APPLICATION_ERROR(-20122, 'Funcionario alvo nao encontrado: ' || p_cod_funcionario_alvo);
    END IF;
 
    -- Obter o novo nível para o log
    SELECT nivel_acesso INTO v_novo_nivel
      FROM FUNCAO_FUNCIONARIO
     WHERE id_funcao = p_novo_id_funcao;
 
    -- 3. Sincronização imediata da réplica no EmpréstimosDB
    -- Não espera pelo ciclo periódico — mudança de acesso é crítica
    UPDATE repl_funcionarios@emprestimosdb
       SET id_funcao    = p_novo_id_funcao,
           nivel_acesso = v_novo_nivel
     WHERE cod_funcionario = p_cod_funcionario_alvo;
 
    -- 4. Auditoria
    prc_registar_auditoria(
        p_cod_funcionario => p_cod_funcionario_op,
        p_operacao        => 'MODIFICAR_NIVEL_ACESSO',
        p_objeto_afetado  => p_cod_funcionario_alvo,
        p_resultado       => 'SUCESSO',
        p_nos_afetados    => 'BibliotecaNacionalDB (local), EmprestimosDB (replica)',
        p_observacoes     => 'Novo nivel: ' || v_novo_nivel
    );
 
    COMMIT; -- Oracle usa 2PC automaticamente (local + EmprestimosDB)
 
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- PROCEDURE DE CERTIFICADO HONORÍFICO (RN08)
-- Só Coordenador ou Administrador pode emitir.
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
    -- 1. Verificar nível de acesso
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
            'Acesso negado. Nivel Coordenador ou Administrador necessario. Nivel actual: ' || v_nivel);
    END IF;
 
    -- 2. Gerar número e inserir certificado
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
END;
/

CREATE OR REPLACE PROCEDURE prc_sincronizar_funcionarios AS
    v_linhas NUMBER := 0;
BEGIN
    -- Limpa a réplica anterior
    DELETE FROM repl_funcionarios@emprestimosdb;
 
    -- Insere o estado actual
    INSERT INTO repl_funcionarios@emprestimosdb (
        cod_funcionario,
        nome_funcionario,
        cod_biblioteca,
        id_funcao,
        nivel_acesso,
        nome_funcao
    )
    SELECT
        cod_funcionario,
        nome_funcionario,
        cod_biblioteca,
        id_funcao,
        nivel_acesso,
        nome_funcao
    FROM vw_replica_funcionarios;
 
    v_linhas := SQL%ROWCOUNT;
 
    COMMIT;
 
    DBMS_OUTPUT.PUT_LINE('Sincronizacao concluida: ' || v_linhas || ' funcionario(s) replicado(s).');
 
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20200, 'Erro na sincronizacao de funcionarios: ' || SQLERRM);
END;
/