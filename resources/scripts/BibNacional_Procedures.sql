-- ============================================================
-- BibNacional_Procedures.sql
-- Versão corrigida: referências cross-node via EXECUTE IMMEDIATE
--
-- PORQUÊ EXECUTE IMMEDIATE NAS QUERIES CROSS-NODE:
-- O Oracle PL/SQL valida objectos referenciados em tempo de compilação.
-- Quando uma procedure contém "SELECT ... FROM tabela@link", o Oracle
-- tenta resolver o objecto remoto no momento em que o código é compilado.
-- Se o nó remoto não está acessível nesse instante (ex: outros nós do
-- grupo ainda não estão ligados), a compilação falha com ORA-04052.
-- Com EXECUTE IMMEDIATE, a query é tratada como SQL dinâmico e só é
-- resolvida em tempo de execução — quando o link já está activo.
-- Resultado: a procedure compila sempre; o erro só ocorre se o nó
-- remoto estiver down no momento da chamada, que é o comportamento correcto.
-- ============================================================


-- ============================================================
-- PROCEDURE: registrar_doacao_completa
-- Regista uma doação e os seus itens num único bloco transaccional.
-- O certificado automático é gerado pelo trigger gera_certificado_automatico.
-- ============================================================
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

    -- Verifica se o trigger gera_certificado_automatico emitiu certificado
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
-- Reemite certificado de uma doação existente como tipo 'Reemissao'.
-- Guarda referência ao número original em original_numero.
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
-- Concede ou revoga role Oracle ao funcionário com base no nivel_acesso.
-- Usa DDL dinâmico porque GRANT/REVOKE não são permitidos em PL/SQL estático.
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
-- Regista uma operação na tabela AUDITORIA_OPERACOES.
--
-- PRAGMA AUTONOMOUS_TRANSACTION: garante que o INSERT na tabela de
-- auditoria é confirmado (COMMIT) independentemente do que aconteça
-- na transacção principal. Se a transacção principal fizer ROLLBACK
-- (ex: operação falhou), o registo de auditoria NÃO é revertido —
-- fica na tabela como prova da tentativa. Sem este pragma, o log
-- desapareceria junto com o ROLLBACK da operação principal, tornando
-- a auditoria inútil para rastrear falhas e tentativas.
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

    COMMIT; -- AUTONOMOUS: confirma só este INSERT, não afecta a transacção principal
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- Não propaga o erro — a auditoria nunca deve bloquear a operação principal
        DBMS_OUTPUT.PUT_LINE('Aviso: falha ao registar auditoria: ' || SQLERRM);
END;
/


-- ============================================================
-- PROCEDURE 1: prc_apagar_leitor
-- Só Administrador pode apagar. Limpa dependências cross-node
-- manualmente antes do DELETE (CASCADEs não funcionam entre nós).
-- É uma transacção distribuída — demonstra 2PC automaticamente.
--
-- EXECUTE IMMEDIATE nas queries cross-node: ver nota no topo do ficheiro.
-- ── VERSÃO MODIFICADA DE prc_apagar_leitor COM SAVEPOINTs ──

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
 
    -- 2. Verificar empréstimos activos
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM emprestimo@emprestimosdb
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
 
    -- ── SAVEPOINT antes das operações cross-node ────────────
    -- Se qualquer DELETE remoto falhar, fazemos ROLLBACK TO aqui,
    -- registamos o erro com detalhe, e relançamos.
    -- O ROLLBACK TO garante que nada foi alterado antes de RAISE.
    -- (Em 2PC, o ROLLBACK final será total — o SAVEPOINT serve
    --  para o bloco de logging estruturado por etapa.)
    SAVEPOINT sp_antes_limpeza_cross_node;
 
    -- 3a. Limpeza no EventosBibliotecasDB
    BEGIN
        EXECUTE IMMEDIATE
            'DELETE FROM participacao_evento@eventosdb WHERE num_cartao = :1'
            USING p_num_cartao;
    EXCEPTION
        WHEN OTHERS THEN
            prc_registar_auditoria(
                p_cod_funcionario => p_cod_funcionario,
                p_operacao        => 'APAGAR_LEITOR',
                p_objeto_afetado  => p_num_cartao,
                p_resultado       => 'FALHA',
                p_motivo_falha    => 'Falha em participacao_evento@eventosdb: ' || SQLERRM,
                p_nos_afetados    => 'EventosBibliotecasDB'
            );
            ROLLBACK TO SAVEPOINT sp_antes_limpeza_cross_node;
            RAISE;
    END;
 
    SAVEPOINT sp_apos_eventos_participacao;
 
    -- 3b. Limpeza de avaliações no EventosBibliotecasDB
    BEGIN
        EXECUTE IMMEDIATE
            'DELETE FROM avaliacao_evento@eventosdb WHERE num_cartao = :1'
            USING p_num_cartao;
    EXCEPTION
        WHEN OTHERS THEN
            prc_registar_auditoria(
                p_cod_funcionario => p_cod_funcionario,
                p_operacao        => 'APAGAR_LEITOR',
                p_objeto_afetado  => p_num_cartao,
                p_resultado       => 'FALHA',
                p_motivo_falha    => 'Falha em avaliacao_evento@eventosdb: ' || SQLERRM,
                p_nos_afetados    => 'EventosBibliotecasDB'
            );
            ROLLBACK TO SAVEPOINT sp_apos_eventos_participacao;
            RAISE;
    END;
 
    SAVEPOINT sp_apos_eventos_avaliacoes;
 
    -- 3c. Limpeza no EmpréstimosProgramasDB
    BEGIN
        EXECUTE IMMEDIATE
            'DELETE FROM participacao_programa@emprestimosdb WHERE num_cartao = :1'
            USING p_num_cartao;
    EXCEPTION
        WHEN OTHERS THEN
            prc_registar_auditoria(
                p_cod_funcionario => p_cod_funcionario,
                p_operacao        => 'APAGAR_LEITOR',
                p_objeto_afetado  => p_num_cartao,
                p_resultado       => 'FALHA',
                p_motivo_falha    => 'Falha em participacao_programa@emprestimosdb: ' || SQLERRM,
                p_nos_afetados    => 'EmprestimosDB'
            );
            ROLLBACK TO SAVEPOINT sp_apos_eventos_avaliacoes;
            RAISE;
    END;
 
    -- 4. DELETE principal — LEITOR é local neste nó (v3)
    DELETE FROM LEITOR WHERE num_cartao = p_num_cartao;
 
    -- 5. Auditoria de sucesso + COMMIT
    prc_registar_auditoria(
        p_cod_funcionario => p_cod_funcionario,
        p_operacao        => 'APAGAR_LEITOR',
        p_objeto_afetado  => p_num_cartao,
        p_resultado       => 'SUCESSO',
        p_nos_afetados    => 'BibliotecaNacionalDB (local), EmprestimosDB, EventosBibliotecasDB'
    );
 
    COMMIT; -- Oracle usa 2PC automaticamente (toca múltiplos nós)
 
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/


-- ============================================================
-- PROCEDURE 2: prc_remover_funcionario
-- Só Administrador pode remover.
-- Se tiver histórico de empréstimos → data_demissao (soft delete).
-- Se não tiver → DELETE físico.
--
-- EXECUTE IMMEDIATE nas queries cross-node: ver nota no topo do ficheiro.
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
    -- EXECUTE IMMEDIATE: resolve @emprestimosdb em runtime (ver nota no topo).
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM emprestimo@emprestimosdb
          WHERE cod_funcionario = :1'
        INTO v_emprestimos USING p_cod_funcionario_alvo;

    IF v_emprestimos > 0 THEN
        -- Tem histórico — soft delete (preserva integridade referencial cross-node)
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
        -- Sem histórico — DELETE físico seguro
        DELETE FROM FUNCIONARIO_HABILIDADE WHERE cod_funcionario = p_cod_funcionario_alvo;
        DELETE FROM HORARIO_FUNCIONARIO    WHERE cod_funcionario = p_cod_funcionario_alvo;

        -- PROGRAMA_FUNCIONARIO pertence ao EmpréstimosProgramasDB (nó do Yannis)
        EXECUTE IMMEDIATE
            'DELETE FROM programa_funcionario@emprestimosdb WHERE cod_funcionario = :1'
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
-- PROCEDURE 3: prc_sincronizar_funcionarios
-- Replica o estado actual dos funcionários activos para a tabela
-- repl_funcionarios no EmpréstimosDB (sincronização periódica completa).
-- Estratégia: DELETE + INSERT — garante consistência total da réplica.
--
-- EXECUTE IMMEDIATE em ambas as operações cross-node: ver nota no topo.
-- O Oracle tenta resolver objectos remotos em tempo de compilação mesmo
-- em INSERTs estáticos — EXECUTE IMMEDIATE força resolução em runtime.
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_sincronizar_funcionarios AS
    v_linhas NUMBER := 0;
BEGIN
    -- Limpa a réplica anterior no nó remoto
    EXECUTE IMMEDIATE 'DELETE FROM repl_funcionarios@emprestimosdb';

    -- Insere o estado actual de todos os funcionários activos.
    -- INSERT via EXECUTE IMMEDIATE com cursor explícito — evita ORA-04052
    -- na compilação quando o nó remoto não está acessível.
    FOR r IN (
        SELECT cod_funcionario, nome_funcionario, cod_biblioteca,
               id_funcao, nivel_acesso, nome_funcao
          FROM vw_replica_funcionarios
    ) LOOP
        EXECUTE IMMEDIATE
            'INSERT INTO repl_funcionarios@emprestimosdb
             (cod_funcionario, nome_funcionario, cod_biblioteca,
              id_funcao, nivel_acesso, nome_funcao)
             VALUES (:1, :2, :3, :4, :5, :6)'
            USING r.cod_funcionario, r.nome_funcionario, r.cod_biblioteca,
                  r.id_funcao, r.nivel_acesso, r.nome_funcao;

        v_linhas := v_linhas + 1;
    END LOOP;

    COMMIT; -- Oracle usa 2PC automaticamente (local + EmprestimosDB)

    DBMS_OUTPUT.PUT_LINE('Sincronizacao concluida: ' || v_linhas || ' funcionario(s) replicado(s).');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20200, 'Erro na sincronizacao de funcionarios: ' || SQLERRM);
END;
/


-- ============================================================
-- PROCEDURE 4: prc_modificar_nivel_acesso
-- Só Administrador pode modificar.
-- Após UPDATE local, sincroniza imediatamente a réplica no EmpréstimosDB.
-- Não espera pelo ciclo periódico — mudança de acesso é crítica para segurança.
--
-- EXECUTE IMMEDIATE no UPDATE cross-node: ver nota no topo do ficheiro.
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_modificar_nivel_acesso (
    p_cod_funcionario_alvo IN VARCHAR2,   -- funcionário a modificar
    p_novo_id_funcao       IN NUMBER,     -- novo id_funcao
    p_cod_funcionario_op   IN VARCHAR2    -- quem pede a operação
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

    -- Obter o novo nível para auditoria e sincronização
    SELECT nivel_acesso INTO v_novo_nivel
      FROM FUNCAO_FUNCIONARIO
     WHERE id_funcao = p_novo_id_funcao;

    -- 3. Sincronização imediata da réplica no EmpréstimosDB
    -- EXECUTE IMMEDIATE: resolve @emprestimosdb em runtime (ver nota no topo).
    -- UPDATE cirúrgico — só o registo alterado, sem replicar tudo.
    EXECUTE IMMEDIATE
        'UPDATE repl_funcionarios@emprestimosdb
            SET id_funcao    = :1,
                nivel_acesso = :2
          WHERE cod_funcionario = :3'
        USING p_novo_id_funcao, v_novo_nivel, p_cod_funcionario_alvo;

    -- 4. Auditoria de sucesso
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


-- ============================================================
-- PROCEDURE 5: prc_demo_2pc  (§2.6 — demonstração de Two-Phase Commit)
-- Numa única transacção: insere uma doação localmente (BibliotecaNacionalDB)
-- e actualiza o estado de conservação de um material no MateriaisDB remoto.
--
-- O Oracle detecta que a transacção toca dois nós distintos e lança o
-- protocolo 2PC automaticamente no COMMIT:
--   Fase 1 PREPARE — cada nó confirma que está pronto para persistir
--   Fase 2 COMMIT  — coordenador confirma globalmente; ambos escrevem
--
-- Se um nó falhar entre as duas fases, o Oracle regista em DBA_2PC_PENDING
-- e pode recuperar manualmente com COMMIT FORCE / ROLLBACK FORCE.
--
-- EXECUTE IMMEDIATE no UPDATE cross-node: ver nota no topo do ficheiro.
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_demo_2pc (
    p_id_doador      IN  NUMBER,    -- doador (0 = anónimo)
    p_cod_biblioteca IN  VARCHAR2,  -- biblioteca que recebe o item de doação
    p_valor          IN  NUMBER,    -- valor estimado do item (MT)
    p_cod_material   IN  VARCHAR2,  -- código do material a actualizar em @materiaisdb
    p_novo_estado    IN  VARCHAR2,  -- novo estado_material_conservacao
    p_id_doacao      OUT NUMBER     -- id da doação gerada (confirmação)
) AS
BEGIN
    -- 1. INSERT local: nova doação (BibliotecaNacionalDB)
    -- A partir daqui a transacção está aberta localmente.
    INSERT INTO DOACAO (id_doador, data_doacao)
    VALUES (p_id_doador, SYSDATE)
    RETURNING id_doacao INTO p_id_doacao;

    INSERT INTO ITEM_DOACAO (id_doacao, cod_biblioteca, quantidade, valor_estimado, observacoes)
    VALUES (p_id_doacao, p_cod_biblioteca, 1, p_valor, 'Demo 2PC — transaccao distribuida');

    -- 2. UPDATE remoto: estado de conservação no MateriaisDB
    -- EXECUTE IMMEDIATE: resolve @materiaisdb em runtime (ver nota no topo).
    -- A partir deste ponto a transacção é distribuída — toca dois nós.
    -- O Oracle coordena 2PC automaticamente no COMMIT abaixo.
    EXECUTE IMMEDIATE
        'UPDATE material_bibliografico@materiaisdb
            SET estado_material_conservacao = :1
          WHERE cod_material = :2'
        USING p_novo_estado, p_cod_material;

    -- COMMIT — Oracle lança 2PC:
    --   Fase 1 PREPARE: pede confirmação a BibliotecaNacionalDB e MateriaisDB
    --   Fase 2 COMMIT:  ambos confirmam → escrita permanente nos dois nós
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('2PC concluido com sucesso.');
    DBMS_OUTPUT.PUT_LINE('  Doacao local id : ' || p_id_doacao);
    DBMS_OUTPUT.PUT_LINE('  Material ' || p_cod_material ||
                         ' -> ' || p_novo_estado || ' em @materiaisdb');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20300,
            'Falha na transaccao distribuida (2PC): ' || SQLERRM);
END;
/


-- ============================================================
-- PROCEDURE: prc_emitir_honorifico  (RN08)
-- Só Coordenador ou Administrador pode emitir certificado honorífico.
-- Emissão manual — não é automática como os certificados Individual >= 1000 MT.
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
            'Acesso negado. Nivel Coordenador ou Administrador necessario. Nivel actual: '
            || v_nivel);
    END IF;

    -- 2. Gerar número sequencial e inserir certificado honorífico
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
-- Bloqueia DOADOR (pai) antes de DOACAO (filho) — sempre nesta ordem.
-- Se todas as transacções seguirem a mesma ordem, o ciclo nunca se forma.
-- Tarefa A2 — Guia BD2 Temas 9.16–9.19
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