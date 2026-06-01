-- ============================================================
-- EmprestimosProg_Procedures.sql
-- Executar como: usr_emprestimosdb
-- Pré-requisito: EmprestimosDB_Auditoria_Owner.sql (tabela + sequencia)
-- ============================================================

-- ------------------------------------------------------------
-- prc_registar_auditoria
-- Regista operacoes na tabela AUDITORIA_EMPRESTIMOS.
-- PRAGMA AUTONOMOUS_TRANSACTION: pode ser chamada dentro de triggers
-- sem interferir com a transaccao principal.
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_registar_auditoria(
    p_operacao      IN VARCHAR2,
    p_num_cartao    IN VARCHAR2    DEFAULT NULL,
    p_cod_material  IN VARCHAR2    DEFAULT NULL,
    p_id_emprestimo IN NUMBER      DEFAULT NULL,
    p_resultado     IN VARCHAR2,
    p_motivo_falha  IN VARCHAR2    DEFAULT NULL,
    p_nos_afetados  IN VARCHAR2    DEFAULT NULL,
    p_observacoes   IN VARCHAR2    DEFAULT NULL
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO AUDITORIA_EMPRESTIMOS (
        id_auditoria, data_operacao, operacao,
        num_cartao, cod_material, id_emprestimo,
        resultado, motivo_falha, nos_afetados, observacoes
    ) VALUES (
        SEQ_AUDITORIA_EMP.NEXTVAL, SYSDATE, p_operacao,
        p_num_cartao, p_cod_material, p_id_emprestimo,
        p_resultado, p_motivo_falha, p_nos_afetados, p_observacoes
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;
/

DROP PROCEDURE prc_inscrever_participante;
DROP PROCEDURE prc_atualizar_nivel;
DROP PROCEDURE prc_vincular_material;

-- ------------------------------------------------------------
-- prc_inscrever_participante
-- Inscreve um leitor num programa de alfabetizacao.
-- Valida existencia do leitor via @nacionaldb.
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_inscrever_participante(
    p_cod_programa IN VARCHAR2,
    p_num_cartao   IN VARCHAR2,
    p_sucesso      OUT VARCHAR2
) IS
    v_leitor_existe    NUMBER;
    v_ja_inscrito      NUMBER;
    v_sql              VARCHAR2(200);
BEGIN
    -- Verificar se leitor existe no BibliotecaNacionalDB
    v_sql := 'SELECT COUNT(*) FROM leitor@nacionaldb WHERE num_cartao = :1';
    EXECUTE IMMEDIATE v_sql INTO v_leitor_existe USING p_num_cartao;

    IF v_leitor_existe = 0 THEN
        p_sucesso := 'ERRO: Leitor ' || p_num_cartao || ' nao existe.';
        RETURN;
    END IF;

    -- Verificar se ja esta inscrito neste programa
    SELECT COUNT(*) INTO v_ja_inscrito
    FROM PARTICIPACAO_PROGRAMA
    WHERE num_cartao = p_num_cartao
      AND cod_programa = p_cod_programa;

    IF v_ja_inscrito > 0 THEN
        p_sucesso := 'ERRO: Leitor ' || p_num_cartao ||
                     ' ja inscrito no programa ' || p_cod_programa || '.';
        RETURN;
    END IF;

    INSERT INTO PARTICIPACAO_PROGRAMA (
        num_cartao, cod_programa, data_inscricao, estado_participacao
    ) VALUES (
        p_num_cartao, p_cod_programa, SYSDATE, 'Activo'
    );

    COMMIT;
    p_sucesso := 'OK: Leitor ' || p_num_cartao ||
                 ' inscrito no programa ' || p_cod_programa;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_sucesso := 'ERRO: ' || SQLERRM;
END;
/

-- ------------------------------------------------------------
-- prc_atualizar_nivel
-- Actualiza o nivel de progressao de uma participacao.
-- Identificada por (num_cartao, cod_programa) � PK composta.
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_atualizar_nivel(
    p_num_cartao   IN VARCHAR2,
    p_cod_programa IN VARCHAR2,
    p_id_nivel     IN NUMBER,
    p_sucesso      OUT VARCHAR2
) IS
BEGIN
    UPDATE PARTICIPACAO_PROGRAMA
    SET id_nivel_atual = p_id_nivel
    WHERE num_cartao   = p_num_cartao
      AND cod_programa = p_cod_programa;

    IF SQL%ROWCOUNT = 0 THEN
        p_sucesso := 'ERRO: Participacao de ' || p_num_cartao ||
                     ' no programa ' || p_cod_programa || ' nao encontrada.';
        RETURN;
    END IF;

    COMMIT;
    p_sucesso := 'OK: Nivel actualizado para ' || p_id_nivel || '.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_sucesso := 'ERRO: ' || SQLERRM;
END;
/

-- ------------------------------------------------------------
-- prc_vincular_material
-- Associa um material bibliografico a um programa.
-- Valida existencia e estado do material via @materiaisdb.
-- Estado valido: 'Bom' (unico estado que permite uso em programa)
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_vincular_material(
    p_cod_programa IN VARCHAR2,
    p_cod_material IN VARCHAR2,
    p_sucesso      OUT VARCHAR2
) IS
    v_existe NUMBER;
    v_estado VARCHAR2(20);
    v_sql    VARCHAR2(300);
BEGIN
    v_sql := 'SELECT COUNT(*), MAX(estado_material_conservacao)
              FROM material_bibliografico@materiaisdb
              WHERE cod_material = :1';
    EXECUTE IMMEDIATE v_sql INTO v_existe, v_estado USING p_cod_material;

    IF v_existe = 0 THEN
        p_sucesso := 'ERRO: Material ' || p_cod_material || ' nao existe.';
        RETURN;
    END IF;

    -- Estado valido para uso em programa: apenas 'Bom'
    -- 'Degradado' e 'Indisponivel' nao sao aceites (dicionario v3)
    IF v_estado != 'Bom' THEN
        p_sucesso := 'ERRO: Material em estado inadequado: ' || v_estado ||
                     '. Apenas materiais em estado ''Bom'' podem ser associados.';
        RETURN;
    END IF;

    INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material)
    VALUES (p_cod_programa, p_cod_material);

    COMMIT;
    p_sucesso := 'OK: Material ' || p_cod_material ||
                 ' associado ao programa ' || p_cod_programa;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_sucesso := 'ERRO: ' || SQLERRM;
END;
/

-- ============================================================
-- PROCEDURE ADICIONADA — ausente no ficheiro original
-- ============================================================

-- processar_devolucao
-- Regista a devolucao de um emprestimo: actualiza data_devolucao,
-- estado do material, multa e observacoes.
-- trg_aplica_suspensao (AFTER UPDATE DE data_devolucao) dispara no commit.
-- NOTA: COMMIT removido da procedure — feito pelo backend apos o call
-- para compatibilidade com chamadas via dblink (ORA-02064 se COMMIT interno).
-- Chamada pelo backend:
--   BEGIN processar_devolucao(:id_emp,:cond,:obs,:multa_val,:sucesso); END;
CREATE OR REPLACE PROCEDURE processar_devolucao(
    p_id_emprestimo           IN  NUMBER,
    p_estado_material_retorno IN  VARCHAR2,
    p_observacoes             IN  VARCHAR2,
    p_multa_valor             IN  NUMBER,
    p_sucesso                 OUT VARCHAR2
) IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM EMPRESTIMO
    WHERE id_emprestimo = p_id_emprestimo AND data_devolucao IS NULL;

    IF v_count = 0 THEN
        p_sucesso := 'Erro: Emprestimo ' || p_id_emprestimo ||
                     ' nao encontrado ou ja devolvido.';
        RETURN;
    END IF;

    UPDATE EMPRESTIMO
       SET data_devolucao          = SYSDATE,
           estado_material_retorno = p_estado_material_retorno,
           multa_valor             = NVL(p_multa_valor, 0),
           observacoes_devolucao   = p_observacoes
     WHERE id_emprestimo = p_id_emprestimo;

    p_sucesso := 'OK';
EXCEPTION
    WHEN OTHERS THEN
        p_sucesso := 'Erro: ' || SQLERRM;
END;
/
-- ============================================================
-- prc_refresh_snapshots
-- Forca REFRESH COMPLETE em todas as MVs locais deste no.
-- Chamada pelo backend via POST /api/manutencao/refresh-snapshots.
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_refresh_snapshots AS
    v_falhas NUMBER := 0;
BEGIN
    DBMS_MVIEW.REFRESH_ALL_MVIEWS(v_falhas);
    DBMS_OUTPUT.PUT_LINE('Refresh concluido. Falhas: ' || v_falhas);
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20300, 'Erro no refresh de snapshots: ' || SQLERRM);
END;
/
