-- ============================================================
-- EmprestimosProgramas_Functions.sql
-- ============================================================
CREATE OR REPLACE FUNCTION fn_calcular_prazo(
    p_num_cartao    IN VARCHAR2,
    p_data_retirada IN DATE
) RETURN DATE IS
    v_distancia NUMBER;
    v_historico VARCHAR2(10);
    v_professor NUMBER;
    v_dias      NUMBER := 14;
    v_sql       VARCHAR2(500);
BEGIN
    v_sql := 'SELECT distancia_biblioteca, historico_pontualidade
              FROM leitor@nacionaldb WHERE num_cartao = :1';
    EXECUTE IMMEDIATE v_sql INTO v_distancia, v_historico
        USING p_num_cartao;

    v_sql := 'SELECT COUNT(*) FROM professor@nacionaldb
              WHERE num_cartao = :1';
    EXECUTE IMMEDIATE v_sql INTO v_professor USING p_num_cartao;

    IF v_distancia > 20 THEN v_dias := v_dias + 7; END IF;
    IF v_professor  > 0 THEN v_dias := v_dias + 7; END IF;
    IF v_historico  = 'Mau' THEN v_dias := v_dias - 7; END IF;
    IF v_dias < 7 THEN v_dias := 7; END IF;

    RETURN p_data_retirada + v_dias;
END;
/