-- ============================================================
-- Functions.sql
-- Sessao 3 — apenas funcoes de integridade usadas por triggers/views
-- Logica de negocio (multas, limites, validacoes) vai para backend
-- ============================================================

-- DROP para re-execucao limpa (ignorar ORA-04043 se nao existir)
DROP FUNCTION normalizar_telefone;
DROP FUNCTION biblioteca_disponivel_evento;
DROP FUNCTION func_disponivel_emprestimo;
DROP FUNCTION calcular_multa;
DROP FUNCTION calcula_multa;
DROP FUNCTION get_multa_valor;
DROP FUNCTION emprestimo_ativo;
DROP FUNCTION pode_emprestar;
DROP FUNCTION get_leitor_info;
DROP FUNCTION valor_estimado_emprestimo;
DROP FUNCTION verificar_inscricao_evento;
DROP FUNCTION verificar_evento_passado;
DROP FUNCTION obter_publico_alvo;
DROP FUNCTION normaliza_titulo;
DROP FUNCTION total_doacoes_doador;

-- ============================================================
-- FUNCAO 1: normaliza_titulo
-- Usada por trg_valida_transferencia para comparar titulos
-- ============================================================
CREATE OR REPLACE FUNCTION normaliza_titulo(p_titulo IN VARCHAR2)
RETURN VARCHAR2
IS
    v_titulo_limpo VARCHAR2(4000);
BEGIN
    v_titulo_limpo := TRANSLATE(TRIM(REGEXP_REPLACE(p_titulo, '\s+', ' ')),
        'aàâãeèéêiìíîoòóôõuùúûcÀÁÂÃÈÉÊÌÍÎÒÓÔÕÙÚÛÇ',
        'aaaaeeeeiiiioooooouuucAAAAEEEIIIOOOOOUUUC'
    );
    RETURN UPPER(v_titulo_limpo);
END;
/

-- ============================================================
-- FUNCAO 2: total_doacoes_doador
-- Usada por vw_doadores_ranking
-- ============================================================
CREATE OR REPLACE FUNCTION total_doacoes_doador(
    p_id_doador IN NUMBER,
    p_ano       IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
    v_total NUMBER := 0;
BEGIN
    SELECT NVL(SUM(id.valor_estimado * id.quantidade), 0)
    INTO v_total
    FROM DOACAO d
    JOIN ITEM_DOACAO id ON d.id_doacao = id.id_doacao
    WHERE d.id_doador = p_id_doador
      AND (p_ano IS NULL OR EXTRACT(YEAR FROM d.data_doacao) = p_ano);

    RETURN v_total;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/
