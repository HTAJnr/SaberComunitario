-- ============================================================
-- BibNacional_Functions.sql
-- Apenas local — sem referências cross-node.
-- Nenhuma alteração necessária para sinónimos.
-- ============================================================

-- FUNCAO: total_doacoes_doador
-- Valor total doado por um doador, opcionalmente filtrado por ano
CREATE OR REPLACE FUNCTION total_doacoes_doador(
    p_id_doador IN NUMBER,
    p_ano       IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
    v_total NUMBER := 0;
BEGIN
    SELECT NVL(SUM(i.valor_estimado * i.quantidade), 0)
      INTO v_total
      FROM DOACAO d
      JOIN ITEM_DOACAO i ON d.id_doacao = i.id_doacao
     WHERE d.id_doador = p_id_doador
       AND (p_ano IS NULL OR EXTRACT(YEAR FROM d.data_doacao) = p_ano);

    RETURN v_total;
EXCEPTION
    WHEN OTHERS THEN RETURN 0;
END;
/