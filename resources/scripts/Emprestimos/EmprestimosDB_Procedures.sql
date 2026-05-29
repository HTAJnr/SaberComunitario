-- ============================================================
-- EmprestimosProg_Procedures.sql
-- Executar como: usr_emprestimosdb
-- ============================================================
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
-- Identificada por (num_cartao, cod_programa) — PK composta.
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