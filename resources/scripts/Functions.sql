--- #Formatar contacto
CREATE OR REPLACE FUNCTION normalizar_telefone(p_input VARCHAR2) 
RETURN VARCHAR2 IS
    digitos VARCHAR2(50) := '';
    c VARCHAR2(1);
BEGIN
    IF p_input IS NULL OR p_input = 'Sem contacto' OR INSTR(p_input, '@') > 0 THEN
        RETURN p_input;
    END IF;
    
    -- Extrai dígitos manualmente
    FOR i IN 1..LENGTH(p_input) LOOP
        c := SUBSTR(p_input, i, 1);
        IF c BETWEEN '0' AND '9' THEN
            digitos := digitos || c;
        END IF;
    END LOOP;
    
    -- Formatação
    IF LENGTH(digitos) = 9 THEN
        RETURN '+258' || digitos;
    ELSIF LENGTH(digitos) = 12 AND SUBSTR(digitos, 1, 3) = '258' THEN
        RETURN '+' || digitos;
    ELSE
        RETURN p_input;
    END IF;
END;
/

-- Evento Disponivel
CREATE OR REPLACE FUNCTION biblioteca_disponivel_evento(
  p_id_biblioteca IN NUMBER,
  p_dia_semana IN VARCHAR2,
  p_hora_inicio IN VARCHAR2,
  p_hora_fim IN VARCHAR2
) RETURN NUMBER
IS
  v_hr_abre VARCHAR2(5);
  v_hr_fecha VARCHAR2(5);
BEGIN
  -- Verifica se existe horario cadastrado
  BEGIN
    SELECT hora_abertura, hora_fecho INTO v_hr_abre, v_hr_fecha
    FROM HORARIO_EV_BIB
    WHERE id_biblioteca = p_id_biblioteca
      AND dia_semana = p_dia_semana
      AND id_evento IS NULL;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 0; -- Nao tem horario cadastrado
  END;
  
  -- Verifica se horario solicitado esta dentro do funcionamento
  IF p_hora_inicio < v_hr_abre OR p_hora_fim > v_hr_fecha THEN
    RETURN 0; -- Fora do horario
  END IF;
  RETURN 1; -- Disponivel
END;
/

-- FUNCTION: total_doacoes_doador
-- OBJETIVO: Retorna o valor total doado por um doador em um ano específico (ou em todos os anos)
CREATE OR REPLACE FUNCTION total_doacoes_doador (
    p_id_doador IN NUMBER,
    p_ano       IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
    v_total NUMBER := 0;
BEGIN
    SELECT 
        COALESCE(SUM(id.valor_estimado * id.quantidade), 0)
    INTO 
        v_total
    FROM 
        DOACAO d
        JOIN ITEM_DOACAO id ON d.id_doacao = id.id_doacao
    WHERE 
        d.id_doador = p_id_doador
        AND (p_ano IS NULL OR EXTRACT(YEAR FROM d.data_doacao) = p_ano);

    RETURN v_total;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        -- Se algo correr mal, retorna 0 (evita quebra no relatório)
        RETURN 0;
END;
/

-- FUNCTION: func_disponivel_emprestimo
-- OBJETIVO: 
CREATE OR REPLACE FUNCTION func_disponivel_emprestimo(
    p_id_material IN NUMBER
) RETURN VARCHAR2
IS
    v_estado_conservacao VARCHAR2(13);
    v_transferencia_ativa NUMBER;
BEGIN
    -- Verificar estado de conserva��o
    SELECT estado_material_conservacao
    INTO v_estado_conservacao
    FROM MATERIAL_BIBLIOGRAFICO
    WHERE id_material = p_id_material;
    
    IF v_estado_conservacao = 'Indisponivel' THEN
        RETURN 'N';
    END IF;
    
    -- Verificar transfer�ncia ativa
    SELECT COUNT(*)
    INTO v_transferencia_ativa
    FROM TRANSFERENCIA
    WHERE id_material = p_id_material
    AND estado_transferencia IN ('Pendente', 'Aprovada');
    
    IF v_transferencia_ativa > 0 THEN
        RETURN 'N';
    END IF;
    
    RETURN 'S';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'N';
    WHEN OTHERS THEN
        RETURN 'N';
END;
/

CREATE OR REPLACE FUNCTION calcular_multa (
    p_prazo_devolucao DATE,
    p_data_devolucao  DATE
) RETURN NUMBER IS
    v_multa NUMBER := 0;
BEGIN
    IF p_data_devolucao > p_prazo_devolucao THEN
        v_multa := (p_data_devolucao - p_prazo_devolucao) * 25; -- 25 MT por dia
    END IF;
    RETURN ROUND(v_multa, 2);
END calcular_multa;
/
--Calcula automaticamente o valor da multa (25 MT/dia) se a devolução for atrasada.

CREATE OR REPLACE FUNCTION pode_emprestar(
    p_num_cartao IN VARCHAR2
) RETURN VARCHAR2 IS
    v_limite_categoria   NUMBER;
    v_emprestimos_ativos NUMBER;
    v_atrasos            NUMBER;
BEGIN
    -- Verifica se o leitor tem empréstimos atrasados há mais de 30 dias
    SELECT COUNT(*)
      INTO v_atrasos
      FROM emprestimo e
     WHERE e.num_cartao = p_num_cartao
       AND e.data_devolucao IS NULL
       AND e.prazo_devolucao < SYSDATE - 30;

    IF v_atrasos > 0 THEN
        RETURN 'SUSPENSO';
    END IF;

    -- Busca limite da categoria e número de empréstimos ativos
    SELECT vl.limite_emprestimo,
           vl.emprestimos_ativos
      INTO v_limite_categoria, v_emprestimos_ativos
      FROM vw_leitores_completos vl
     WHERE vl.num_cartao = p_num_cartao;

    -- Verifica se atingiu o limite
    IF v_emprestimos_ativos >= v_limite_categoria THEN
        RETURN 'LIMITE_ATINGIDO';
    END IF;

    -- Caso contrário → SIM
    RETURN 'SIM';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'SUSPENSO'; -- Caso o leitor não exista
    WHEN OTHERS THEN
        RETURN 'SUSPENSO'; -- Segurança
END;
/
--Verifica se o leitor pode realizar um novo empréstimo (limite e suspensões).

CREATE OR REPLACE FUNCTION get_leitor_info(
  p_num_cartao IN VARCHAR2,
  p_id_material IN NUMBER
) RETURN VARCHAR2
IS
  v_faixa_etaria VARCHAR2(17);
BEGIN
  SELECT c.faixa_etaria
  INTO v_faixa_etaria
  FROM leitor l
  JOIN emprestimo e ON e.num_cartao = l.num_cartao
  JOIN material_bibliografico m ON m.id_material = e.id_material
  JOIN categoria c ON c.id_categoria = m.id_categoria
  WHERE l.num_cartao = p_num_cartao
    AND m.id_material = p_id_material;

  RETURN v_faixa_etaria;
END;
/

--Retorna informações do leitor e a faixa etária do material solicitado.

CREATE OR REPLACE FUNCTION calcula_multa(p_id_emprestimo IN emprestimo.id_emprestimo%TYPE)
RETURN NUMBER
IS
    v_multa emprestimo.multa_valor%TYPE := 0;
    v_prazo emprestimo.prazo_devolucao%TYPE;
    v_data_dev emprestimo.data_devolucao%TYPE;
BEGIN
    -- Buscar dados do empréstimo
    SELECT prazo_devolucao, data_devolucao, NVL(multa_valor, 0)
      INTO v_prazo, v_data_dev, v_multa
      FROM emprestimo
     WHERE id_emprestimo = p_id_emprestimo;

    -- Caso o material tenha sido devolvido depois do prazo
    IF v_data_dev IS NOT NULL AND v_data_dev > v_prazo THEN
        -- Se já tiver multa registrada, retorna ela
        RETURN v_multa;
    ELSE
        -- Caso contrário, retorna 0
        RETURN 0;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0; -- id_emprestimo não existe
    WHEN OTHERS THEN
        RETURN 0; -- Qualquer outro erro retorna 0
END;
/
--Calcula a multa já registrada para um empréstimo específico, retornando 0 se não houver multa.

CREATE OR REPLACE FUNCTION emprestimo_ativo(p_id_emprestimo IN emprestimo.id_emprestimo%TYPE)
RETURN VARCHAR2
IS
    v_data_dev emprestimo.data_devolucao%TYPE;
    v_estado   VARCHAR2(10);
BEGIN
    SELECT data_devolucao, estado_material_retorno
      INTO v_data_dev, v_estado
      FROM emprestimo
     WHERE id_emprestimo = p_id_emprestimo;

    -- Se não devolveu ainda (data_devolucao é NULL), está ativo
    IF v_data_dev IS NULL THEN
        RETURN 'ATIVO';
    ELSE
        RETURN 'FINALIZADO';
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'INEXISTENTE';  -- Não existe esse id_emprestimo
END;
/
--`Verifica se um empréstimo está ativo (não devolvido) ou finalizado.
-- para executar a function usas: 
--SELECT emprestimo_ativo(id_emprestimo) FROM dual;`

CREATE OR REPLACE FUNCTION valor_estimado_emprestimo(p_id_emprestimo IN emprestimo.id_emprestimo%TYPE)
RETURN NUMBER
IS
    v_valor ITEM_DOACAO.VALOR_ESTIMADO%TYPE := 0;
BEGIN
    SELECT i.valor_estimado
      INTO v_valor
      FROM emprestimo e
      JOIN material_bibliografico m ON e.id_material = m.id_material
      JOIN item_doacao i ON m.id_itemdoado = i.id_itemdoado
     WHERE e.id_emprestimo = p_id_emprestimo;

    RETURN v_valor;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;  -- caso não exista relação ou id inválido
    WHEN OTHERS THEN
        RETURN 0;  -- qualquer outro erro retorna 0
END;
/
--Retorna o valor estimado do material associado a um empréstimo específico.
--Usar: SELECT valor_estimado_emprestimo(?) FROM dual;

CREATE OR REPLACE FUNCTION get_multa_valor(p_id_emprestimo IN emprestimo.id_emprestimo%TYPE)
RETURN NUMBER
IS
    v_multa emprestimo.multa_valor%TYPE := 0;
BEGIN
    SELECT NVL(multa_valor, 0)
      INTO v_multa
      FROM emprestimo
     WHERE id_emprestimo = p_id_emprestimo;

    RETURN v_multa;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;  -- caso não exista empréstimo com esse ID
    WHEN OTHERS THEN
        RETURN 0;  -- evita erro em caso de exceção inesperada
END;
/
--Retorna o valor da multa associada a um empréstimo específico, ou 0 se não houver multa.
--Usar: SELECT get_multa_valor(?) FROM dual;

CREATE OR REPLACE FUNCTION verificar_inscricao_evento (
    p_num_cartao  IN VARCHAR2,
    p_id_evento   IN NUMBER
) RETURN VARCHAR2
IS
    v_count NUMBER;
BEGIN
    -- Conta quantas vezes o leitor já está inscrito nesse evento
    SELECT COUNT(*)
    INTO v_count
    FROM PARTICIPACAO_EVENTO
    WHERE num_cartao = p_num_cartao
      AND id_evento = p_id_evento;

    IF v_count > 0 THEN
        RETURN 'Ja inscrito neste evento';
    ELSE
        RETURN 'Inscricao permitida';
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Inscricao permitida';
    WHEN OTHERS THEN
        RETURN 'Erro ao verificar inscricao: ' || SQLERRM;
END;
/
--Verifica se um leitor já está inscrito em um evento específico.
--Usar: SELECT verificar_inscricao_evento(?, ?) FROM dual;

CREATE OR REPLACE FUNCTION verificar_evento_passado (
    p_id_evento IN NUMBER
) RETURN VARCHAR2
IS
    v_data_evento DATE;
BEGIN
    -- Busca a data do evento
    SELECT data_evento
    INTO v_data_evento
    FROM evento
    WHERE id_evento = p_id_evento;

    -- Verifica se a data do evento já passou
    IF v_data_evento < SYSDATE THEN
        RETURN 'Evento ja realizado';
    ELSE
        RETURN 'Evento ainda nao realizado';
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Evento nao encontrado';
    WHEN OTHERS THEN
        RETURN 'Erro ao verificar evento: ' || SQLERRM;
END;
/
--Verifica se um evento já ocorreu com base na data atual.
--Usar: SELECT verificar_evento_passado(?) FROM dual;

CREATE OR REPLACE FUNCTION verificar_evento_passado (
    p_id_evento IN NUMBER
) RETURN VARCHAR2
IS
    v_data_evento DATE;
BEGIN
    SELECT data_evento
    INTO v_data_evento
    FROM evento
    WHERE id_evento = p_id_evento;

    IF v_data_evento < SYSDATE THEN
        RETURN 'Evento ja passou';
    ELSE
        RETURN 'Evento ainda nao passou';
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Evento nao encontrado';
    WHEN OTHERS THEN
        RETURN 'Erro ao verificar evento';
END;
/
--Verifica se um evento já ocorreu com base na data atual.
--Usar: SELECT verificar_evento_passado(?) FROM dual;

CREATE OR REPLACE FUNCTION obter_publico_alvo (
    p_nivel_escolar VARCHAR2
) RETURN VARCHAR2
IS
BEGIN
    IF p_nivel_escolar IN ('Primario', 'Secundario') THEN
        RETURN 'Iniciantes';
    ELSIF p_nivel_escolar = 'Tecnico' THEN
        RETURN 'Intermedios';
    ELSIF p_nivel_escolar = 'Superior' THEN
        RETURN 'Avancados';
    ELSIF p_nivel_escolar = 'Sem Escolaridade' THEN
        RETURN 'Todos';
    ELSE
        RETURN 'Todos';
    END IF;
END;
/
--Retorna o público-alvo adequado com base no nível escolar fornecido.
--Usar: SELECT obter_publico_alvo(?) FROM dual;

-- Normalizar titulos para transferencia
CREATE OR REPLACE FUNCTION normaliza_titulo(p_titulo IN VARCHAR2)
RETURN VARCHAR2
IS
  v_titulo_limpo VARCHAR2(4000);
BEGIN
  -- 1. Remove espaços extra e acentuação (usando TRANSLATE)
  v_titulo_limpo := TRANSLATE(TRIM(REGEXP_REPLACE(p_titulo, '\s+', ' ')),
    'áàâãéèêíìîóòôõúùûçÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇ',
    'aaaaeeiioooouuucAAAAEEIIOOOOUUUC'
  );
  
  -- 2. Converte tudo para uma única caixa (maiúscula ou minúscula, a consistência é o que importa)
  RETURN UPPER(v_titulo_limpo);
END;
/

