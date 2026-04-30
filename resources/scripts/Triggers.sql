--- # AUTO INCREMENTS
-- 1. BIBLIOTECA
CREATE OR REPLACE TRIGGER trg_biblioteca_id
BEFORE INSERT ON BIBLIOTECA FOR EACH ROW
BEGIN
    IF :NEW.id_biblioteca IS NULL THEN
        SELECT SEQ_BIBLIOTECA.NEXTVAL INTO :NEW.id_biblioteca FROM DUAL;
    END IF;
END;
/

-- 2. CATEGORIA
CREATE OR REPLACE TRIGGER trg_categoria_id
BEFORE INSERT ON CATEGORIA FOR EACH ROW
BEGIN
    IF :NEW.id_categoria IS NULL THEN
        SELECT SEQ_CATEGORIA.NEXTVAL INTO :NEW.id_categoria FROM DUAL;
    END IF;
END;
/

-- 3. CERTIFICADO_DOACAO
CREATE OR REPLACE TRIGGER trg_certificado_id
BEFORE INSERT ON CERTIFICADO_DOACAO FOR EACH ROW
BEGIN
    IF :NEW.id_certificado IS NULL THEN
        SELECT SEQ_CERTIFICADO.NEXTVAL INTO :NEW.id_certificado FROM DUAL;
    END IF;
END;
/

-- 4. DOACAO
CREATE OR REPLACE TRIGGER trg_doacao_id
BEFORE INSERT ON DOACAO FOR EACH ROW
BEGIN
    IF :NEW.id_doacao IS NULL THEN
        SELECT SEQ_DOACAO.NEXTVAL INTO :NEW.id_doacao FROM DUAL;
    END IF;
END;
/

-- 5. DOADOR
CREATE OR REPLACE TRIGGER trg_doador_id
BEFORE INSERT ON DOADOR FOR EACH ROW
BEGIN
    IF :NEW.id_doador IS NULL THEN
        SELECT SEQ_DOADOR.NEXTVAL INTO :NEW.id_doador FROM DUAL;
    END IF;
END;
/

-- 6. EMPRESTIMO
CREATE OR REPLACE TRIGGER trg_emprestimo_id
BEFORE INSERT ON EMPRESTIMO FOR EACH ROW
BEGIN
    IF :NEW.id_emprestimo IS NULL THEN
        SELECT SEQ_EMPRESTIMO.NEXTVAL INTO :NEW.id_emprestimo FROM DUAL;
    END IF;
END;
/

-- 7. EVENTO
CREATE OR REPLACE TRIGGER trg_evento_id
BEFORE INSERT ON EVENTO FOR EACH ROW
BEGIN
    IF :NEW.id_evento IS NULL THEN
        SELECT SEQ_EVENTO.NEXTVAL INTO :NEW.id_evento FROM DUAL;
    END IF;
END;
/

-- 8. EVENTO_RECURSO
CREATE OR REPLACE TRIGGER trg_recurso_id
BEFORE INSERT ON EVENTO_RECURSO FOR EACH ROW
BEGIN
    IF :NEW.id_recurso IS NULL THEN
        SELECT SEQ_RECURSO.NEXTVAL INTO :NEW.id_recurso FROM DUAL;
    END IF;
END;
/

-- 9. FUNCAO_FUNCIONARIO
CREATE OR REPLACE TRIGGER trg_funcao_id
BEFORE INSERT ON FUNCAO_FUNCIONARIO FOR EACH ROW
BEGIN
    IF :NEW.id_funcao IS NULL THEN
        SELECT SEQ_FUNCAO.NEXTVAL INTO :NEW.id_funcao FROM DUAL;
    END IF;
END;
/

-- 10. FUNCIONARIO
CREATE OR REPLACE TRIGGER trg_funcionario_id
BEFORE INSERT ON FUNCIONARIO FOR EACH ROW
BEGIN
    IF :NEW.id_funcionario IS NULL THEN
        SELECT SEQ_FUNCIONARIO.NEXTVAL INTO :NEW.id_funcionario FROM DUAL;
    END IF;
END;
/

-- 11. HORARIO_EV_BIB
CREATE OR REPLACE TRIGGER trg_horario_id
BEFORE INSERT ON HORARIO_EV_BIB FOR EACH ROW
BEGIN
    IF :NEW.id_horario IS NULL THEN
        SELECT SEQ_HORARIO.NEXTVAL INTO :NEW.id_horario FROM DUAL;
    END IF;
END;
/

-- 12. ITEM_DOACAO
CREATE OR REPLACE TRIGGER trg_itemdoado_id
BEFORE INSERT ON ITEM_DOACAO FOR EACH ROW
BEGIN
    IF :NEW.id_itemDoado IS NULL THEN
        SELECT SEQ_ITEMDOADO.NEXTVAL INTO :NEW.id_itemDoado FROM DUAL;
    END IF;
END;
/

-- 13. MATERIAL_BIBLIOGRAFICO
CREATE OR REPLACE TRIGGER trg_material_id
BEFORE INSERT ON MATERIAL_BIBLIOGRAFICO FOR EACH ROW
BEGIN
    IF :NEW.id_material IS NULL THEN
        SELECT SEQ_MATERIAL.NEXTVAL INTO :NEW.id_material FROM DUAL;
    END IF;
END;
/

-- 14. TRANSFERENCIA
CREATE OR REPLACE TRIGGER trg_transferencia_id
BEFORE INSERT ON TRANSFERENCIA FOR EACH ROW
BEGIN
    IF :NEW.id_transferencia IS NULL THEN
        SELECT SEQ_TRANSFERENCIA.NEXTVAL INTO :NEW.id_transferencia FROM DUAL;
    END IF;
END;
/

--- # REGRAS DE NOGOCIO

-- Trigger para impedir que se apague o doador anonimo
CREATE OR REPLACE TRIGGER protege_anonimo
BEFORE DELETE ON DOADOR
FOR EACH ROW
BEGIN
    IF :OLD.id_doador = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'O doador Anonimo (ID 0) nao pode ser eliminado');
    END IF;
END;
/

--- # Formatacoes
-- Triggers para formatar contacto automaticamente:
CREATE OR REPLACE TRIGGER fmt_contacto_leitor
BEFORE INSERT OR UPDATE ON LEITOR
FOR EACH ROW
BEGIN
    :NEW.contacto := normalizar_telefone(:NEW.contacto);
END;
/

CREATE OR REPLACE TRIGGER fmt_contacto_funcionario
BEFORE INSERT OR UPDATE ON FUNCIONARIO
FOR EACH ROW
BEGIN
    :NEW.contacto := normalizar_telefone(:NEW.contacto);
END;
/

CREATE OR REPLACE TRIGGER fmt_contacto_doador
BEFORE INSERT OR UPDATE ON DOADOR
FOR EACH ROW
BEGIN
    :NEW.contacto := normalizar_telefone(:NEW.contacto);
END;
/

--- #Validacoes
CREATE OR REPLACE TRIGGER valida_horario_evento
BEFORE INSERT OR UPDATE ON HORARIO_EV_BIB
FOR EACH ROW
DECLARE
  v_id_bib NUMBER;
  v_hr_abre VARCHAR2(5);
  v_hr_fecha VARCHAR2(5);
BEGIN
  IF :NEW.id_evento IS NOT NULL THEN
    SELECT id_biblioteca INTO v_id_bib
    FROM EVENTO WHERE id_evento = :NEW.id_evento;
    
    BEGIN
      SELECT hora_abertura, hora_fecho INTO v_hr_abre, v_hr_fecha
      FROM HORARIO_EV_BIB
      WHERE id_biblioteca = v_id_bib 
        AND dia_semana = :NEW.dia_semana
        AND id_evento IS NULL
        AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20300, 'Biblioteca sem horario cadastrado');
    END;
    
    IF :NEW.hora_abertura < v_hr_abre OR :NEW.hora_fecho > v_hr_fecha THEN
      RAISE_APPLICATION_ERROR(-20301, 'Evento fora do horario de funcionamento');
    END IF;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER impede_exclusao_coordenador
BEFORE DELETE ON FUNCIONARIO
FOR EACH ROW
DECLARE
  v_count NUMBER;
BEGIN
  -- Consulta BIBLIOTECA (tabela diferente - OK)
  SELECT COUNT(*) INTO v_count
  FROM BIBLIOTECA WHERE id_responsavel = :OLD.id_funcionario;
  
  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20302, 'Coordenador nao pode ser removido');
  END IF;
  
  -- Consulta TRANSFERENCIA (tabela diferente - OK)
  SELECT COUNT(*) INTO v_count
  FROM TRANSFERENCIA
  WHERE (id_funcionario_solicitante = :OLD.id_funcionario 
         OR id_funcionario_aprovador = :OLD.id_funcionario)
    AND estado_transferencia != 'Concluida';
  
  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20303, 'Funcionario com transferencias ativas');
  END IF;
END;
/

-- TRIGGER: gera_certificado_automatico
-- OBJETIVO: Emitir certificado automático para doações ≥ 1000 MT
CREATE OR REPLACE TRIGGER gera_certificado_automatico
AFTER INSERT ON DOACAO
FOR EACH ROW
DECLARE
    v_valor_total NUMBER := 0;
    v_tipo_doador  VARCHAR2(50);
    v_seq          NUMBER;
    v_numero_cert  VARCHAR2(30);
BEGIN
    -- 1. Calcular o valor total estimado da doação (somando os itens associados)
    SELECT NVL(SUM(valor_estimado * quantidade), 0)
      INTO v_valor_total
      FROM ITEM_DOACAO
     WHERE id_doacao = :NEW.id_doacao;

    -- 2. Buscar o tipo do doador
    SELECT tipo_doador
      INTO v_tipo_doador
      FROM DOADOR
     WHERE id_doador = :NEW.id_doador;

    -- 3. Verificar se atende às condições para emissão automática
    IF v_valor_total >= 1000 AND v_tipo_doador = 'Individual' THEN

        -- 4. Gerar número de sequência
        SELECT seq_certificado.NEXTVAL INTO v_seq FROM dual;

        -- 5. Montar número do certificado
        v_numero_cert := 'CERT-' || TO_CHAR(SYSDATE, 'YYYY') || '-' || LPAD(v_seq, 4, '0');

        -- 6. Inserir o certificado automaticamente
        INSERT INTO CERTIFICADO_DOACAO (
            id_certificado,
            id_doacao,
            num_certificado,
            tipo_certificado,
            data_emissao,
            observacoes
        ) VALUES (
            seq_certificado.NEXTVAL,
            :NEW.id_doacao,
            v_numero_cert,
            'Original',
            SYSDATE,
            'Certificado gerado automaticamente (RN08)'
        );
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL; -- caso o doador não exista, não faz nada
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao gerar certificado automatico: ' || SQLERRM);
END;
/

-- TRIGGER: valida_item_doacao
-- OBJETIVO: Garantir consistência dos dados de ITEM_DOACAO
CREATE OR REPLACE TRIGGER valida_item_doacao
BEFORE INSERT ON ITEM_DOACAO
FOR EACH ROW
DECLARE
    v_existe_bib NUMBER;
BEGIN
    -- 1. Quantidade deve ser maior que zero
    IF :NEW.quantidade <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'A quantidade deve ser maior que zero.');
    END IF;

    -- 2. Valor estimado deve ser não negativo
    IF :NEW.valor_estimado < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'O valor estimado nao pode ser negativo.');
    END IF;

    -- 3. Biblioteca associada deve existir (se informada)
    IF :NEW.id_biblioteca IS NOT NULL THEN
        SELECT COUNT(*) INTO v_existe_bib
          FROM BIBLIOTECA
         WHERE id_biblioteca = :NEW.id_biblioteca;

        IF v_existe_bib = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'A biblioteca associada nao existe.');
        END IF;
    END IF;

    -- 4. Justificação obrigatória se quantidade > 1
    IF :NEW.quantidade > 1 AND (:NEW.observacoes IS NULL OR LENGTH(TRIM(:NEW.observacoes)) = 0) THEN
        RAISE_APPLICATION_ERROR(-20004, 'Informe observacoes justificando a quantidade (' ||
                                        :NEW.quantidade || '). Ex: "5 livros identicos".');
    END IF;
END;
/


-- TRIGGER: trg_protege_material_trans
-- OBJETIVO: Impedir empréstimo de material em transferência
CREATE OR REPLACE TRIGGER trg_protege_material_trans
BEFORE INSERT OR UPDATE OF id_material ON EMPRESTIMO
FOR EACH ROW
DECLARE
    v_em_transferencia NUMBER;
BEGIN
    -- Verifica se material est� em processo de transfer�ncia
    SELECT COUNT(*)
    INTO v_em_transferencia
    FROM TRANSFERENCIA
    WHERE id_material = :NEW.id_material
    AND estado_transferencia IN ('Pendente', 'Aprovada');
    
    IF v_em_transferencia > 0 THEN
        RAISE_APPLICATION_ERROR(-20101, 
            'Material em processo de transferencia. Emprestimo nao permitido.');
    END IF;
END;
/

-- TRIGGER: trg_valida_transferencia
-- OBJETIVO: Garantir coerencia nas transferencias
CREATE OR REPLACE TRIGGER trg_valida_transferencia
BEFORE INSERT OR UPDATE ON TRANSFERENCIA
FOR EACH ROW
DECLARE
    v_biblioteca_material NUMBER;
    v_biblioteca_solicitante NUMBER;
    v_biblioteca_aprovador NUMBER;
BEGIN
    -- Regra 1: Origem diferente de Destino
    IF :NEW.id_biblioteca_origem = :NEW.id_biblioteca_destino THEN
        RAISE_APPLICATION_ERROR(-20102, 
            'Transferencia invalida - Biblioteca origem deve ser diferente da destino');
    END IF;
    
    -- Regra 2: Material deve estar na biblioteca origem
    SELECT id_biblioteca 
    INTO v_biblioteca_material
    FROM MATERIAL_BIBLIOGRAFICO
    WHERE id_material = :NEW.id_material;
    
    IF v_biblioteca_material != :NEW.id_biblioteca_origem THEN
        RAISE_APPLICATION_ERROR(-20102, 
            'Transferencia invalida - Material nao esta na biblioteca de origem');
    END IF;
    
    -- Regra 3: Funcionario solicitante deve trabalhar na biblioteca origem
    SELECT id_biblioteca 
    INTO v_biblioteca_solicitante
    FROM FUNCIONARIO
    WHERE id_funcionario = :NEW.id_funcionario_solicitante;
    
    IF v_biblioteca_solicitante != :NEW.id_biblioteca_origem THEN
        RAISE_APPLICATION_ERROR(-20102, 
            'Transferencia invilida - Funcionario solicitante nao trabalha na biblioteca de origem');
    END IF;
    
    -- Regra 4: Funcionario aprovador (se definido) deve trabalhar na biblioteca destino
    IF :NEW.id_funcionario_aprovador IS NOT NULL THEN
        SELECT id_biblioteca 
        INTO v_biblioteca_aprovador
        FROM FUNCIONARIO
        WHERE id_funcionario = :NEW.id_funcionario_aprovador;
        
        IF v_biblioteca_aprovador != :NEW.id_biblioteca_destino THEN
            RAISE_APPLICATION_ERROR(-20102, 
                'Transferencia invalida - Funcionorio aprovador nao trabalha na biblioteca de destino');
        END IF;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_aplicar_multa
BEFORE UPDATE OF data_devolucao ON EMPRESTIMO
FOR EACH ROW
DECLARE
    v_multa NUMBER;
BEGIN
    IF :NEW.data_devolucao IS NOT NULL THEN
        v_multa := calcular_multa(:OLD.prazo_devolucao, :NEW.data_devolucao);
        :NEW.multa_valor := v_multa;
        :NEW.multa_paga := CASE WHEN v_multa = 0 THEN 'S' ELSE 'N' END;
        :NEW.data_pagamento_multa := CASE WHEN v_multa = 0 THEN SYSDATE ELSE NULL END;
        :NEW.OBSERVACOES_DEVOLUCAO := NVL(:NEW.OBSERVACOES_DEVOLUCAO, 'Multa aplicada automaticamente');
    END IF;
END;
/
--Sempre que a data de devolução é atualizada, a multa é recalculada automaticamente.
-- Criar a tabela de log (execute apenas uma vez)
-- Criar sequence
-- Apaga o trigger com erro

-- OBJETIVO: Garantir que o leitor não ultrapasse o limite de empréstimos

-- Garante que o leitor não ultrapasse o limite de empréstimos permitidos para sua categoria.

CREATE OR REPLACE TRIGGER valida_limite_emprestimos
BEFORE INSERT ON emprestimo
FOR EACH ROW
DECLARE
    v_tipo_leitor   VARCHAR2(15);
    v_qtd_ativos    NUMBER := 0;
    v_limite        NUMBER := 0;
BEGIN
    -- Obter o tipo de leitor a partir da view vw_leitores_completos
    SELECT tipo_leitor
      INTO v_tipo_leitor
      FROM vw_leitores_completos
     WHERE num_cartao = :NEW.num_cartao;

    -- Contar quantos empréstimos ativos o leitor possui
    SELECT COUNT(*)
      INTO v_qtd_ativos
      FROM emprestimo
     WHERE num_cartao = :NEW.num_cartao
       AND data_devolucao IS NULL;

    -- Definir o limite conforme categoria
    CASE UPPER(v_tipo_leitor)
        WHEN 'ADULTO' THEN v_limite := 3;
        WHEN 'CRIANCA' THEN v_limite := 2;
        WHEN 'PROFESSOR' THEN v_limite := 5;
        ELSE
            v_limite := 3; -- padrão de segurança
    END CASE;

    -- Validar o limite antes de inserir
    IF v_qtd_ativos >= v_limite THEN
        RAISE_APPLICATION_ERROR(-20201, 'Limite de emprestimos atingido');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER valida_emprestimo_categoria
BEFORE INSERT ON emprestimo
FOR EACH ROW
DECLARE
    v_tipo_leitor   VARCHAR2(15);
    v_faixa_etaria  VARCHAR2(30);
BEGIN
    -- Obter o tipo de leitor (ADULTO / CRIANCA / PROFESSOR)
    SELECT tipo_leitor
      INTO v_tipo_leitor
      FROM vw_leitores_completos
     WHERE num_cartao = :NEW.num_cartao;

    -- Obter a faixa etária do material a ser emprestado
    SELECT c.faixa_etaria
      INTO v_faixa_etaria
      FROM material_bibliografico m
      JOIN categoria c ON m.id_categoria = c.id_categoria
     WHERE m.id_material = :NEW.id_material;

    -- Verificar restrição de faixa etária para crianças
    IF UPPER(v_tipo_leitor) = 'CRIANCA' THEN
        IF UPPER(v_faixa_etaria) NOT IN ('INFANTIL', 'TODAS AS IDADES') THEN
            RAISE_APPLICATION_ERROR(-20202, 'Material inadequado para faixa etaria');
        END IF;
    END IF;
END;
/
-- Garante que leitores do tipo CRIANCA não possam pegar emprestado materiais inadequados para sua faixa etária.

CREATE OR REPLACE TRIGGER calcula_multa_atraso
BEFORE UPDATE ON emprestimo
FOR EACH ROW
WHEN (NEW.data_devolucao IS NOT NULL AND OLD.data_devolucao IS NULL)
DECLARE
    v_dias_atraso    NUMBER := 0;
    v_tipo_leitor    VARCHAR2(15);
    v_taxa_diaria    NUMBER := 0;
    v_infracoes_prof NUMBER := 0;
BEGIN
    -- Calcular dias de atraso
    v_dias_atraso := :NEW.data_devolucao - :OLD.prazo_devolucao;

    -- Se não houver atraso, multa = 0
    IF v_dias_atraso <= 0 THEN
        :NEW.multa_valor := 0;
        RETURN;
    END IF;

    -- Identificar categoria do leitor
    SELECT tipo_leitor
      INTO v_tipo_leitor
      FROM vw_leitores_completos
     WHERE num_cartao = :OLD.num_cartao;

    -- Definir taxa conforme categoria
    CASE UPPER(v_tipo_leitor)
        WHEN 'ADULTO' THEN
            v_taxa_diaria := 15;
        WHEN 'CRIANCA' THEN
            v_taxa_diaria := 5;
        WHEN 'PROFESSOR' THEN
            -- Verificar histórico de infrações do professor
            SELECT COUNT(*)
              INTO v_infracoes_prof
              FROM emprestimo
             WHERE num_cartao = :OLD.num_cartao
               AND data_devolucao IS NOT NULL
               AND data_devolucao > prazo_devolucao;

            IF v_infracoes_prof = 0 THEN
                -- Primeira infração → advertência
                v_taxa_diaria := 0;
                :NEW.OBSERVACOES_DEVOLUCAO := NVL(:NEW.OBSERVACOES_DEVOLUCAO, '') || 'Advertencia: 1 infracao sem multa.';
            ELSE
                -- Segunda infração em diante
                v_taxa_diaria := 10;
            END IF;
        ELSE
            v_taxa_diaria := 10; -- padrão de segurança
    END CASE;

    -- Calcular valor da multa
    :NEW.multa_valor := v_dias_atraso * v_taxa_diaria;

    -- Consequências automáticas
    IF v_dias_atraso > 30 THEN
        :NEW.MULTA_PAGA := 'S';  -- campo hipotético para indicar bloqueio do leitor
    END IF;

    IF v_dias_atraso > 60 THEN
        UPDATE material_bibliografico
           SET estado_material_conservacao = 'Indisponivel'
         WHERE id_material = :OLD.id_material;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_verificar_publico_alvo
BEFORE INSERT ON participacao_evento
FOR EACH ROW
DECLARE
    v_nivel_escolar leitor.nivel_escolar%TYPE;
    v_publico_alvo evento.publico_alvo%TYPE;
BEGIN
    SELECT nivel_escolar
    INTO v_nivel_escolar
    FROM leitor
    WHERE num_cartao = :NEW.num_cartao;

    SELECT publico_alvo
    INTO v_publico_alvo
    FROM evento
    WHERE id_evento = :NEW.id_evento;

    IF v_nivel_escolar = 'Sem Escolaridade' 
       AND v_publico_alvo NOT IN ('Todas as Idades', 'Infantil') THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Leitor sem escolaridade so pode participar em eventos Infantil ou Todas as Idades');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Leitor ou evento nao encontrado');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Erro ao verificar compatibilidade do publico alvo');
END;
/
-- Garante que leitores sem escolaridade só possam participar de eventos destinados a "Todos".
-- Além disso, ajusta automaticamente o público-alvo do evento com base no nível escolar do leitor.


-- Protege o ultimo material da biblioteca de ser transferido
CREATE OR REPLACE TRIGGER protege_ultimo_exemplar_insert
BEFORE INSERT ON TRANSFERENCIA
FOR EACH ROW
DECLARE
  v_total_exemplares_disponiveis NUMBER;
  v_isbn VARCHAR2(20);
  v_titulo VARCHAR2(200);
BEGIN
  -- Se o estado inicial não for 'Pendente', não há necessidade de verificar agora.
  -- Isto permite, por exemplo, inserir registos históricos já concluídos sem ativar a trigger.
  IF :NEW.estado_transferencia <> 'Pendente' THEN
    RETURN;
  END IF;

  -- 1. Busca ISBN e título do material a ser transferido
  SELECT ISBN, titulo INTO v_isbn, v_titulo
  FROM MATERIAL_BIBLIOGRAFICO
  WHERE id_material = :NEW.id_material;
  
  -- 2. Conta quantos exemplares ESTÃO DISPONÍVEIS (não emprestados, não em outra transferência)
  IF v_isbn IS NOT NULL THEN
    -- Contagem por ISBN (mais precisa)
    SELECT COUNT(m.id_material) INTO v_total_exemplares_disponiveis
    FROM MATERIAL_BIBLIOGRAFICO m
    WHERE m.ISBN = v_isbn
      AND m.id_biblioteca = :NEW.id_biblioteca_origem
      AND m.id_material NOT IN (SELECT id_material FROM EMPRESTIMO WHERE data_devolucao IS NULL)
      AND m.id_material NOT IN (SELECT id_material FROM TRANSFERENCIA WHERE estado_transferencia IN ('Pendente', 'Aprovada') AND id_transferencia <> :NEW.id_transferencia);
  ELSE
    -- Contagem por título normalizado (fallback)
    SELECT COUNT(m.id_material) INTO v_total_exemplares_disponiveis
    FROM MATERIAL_BIBLIOGRAFICO m
    WHERE normaliza_titulo(m.titulo) = normaliza_titulo(v_titulo)
      AND m.id_biblioteca = :NEW.id_biblioteca_origem
      AND m.id_material NOT IN (SELECT id_material FROM EMPRESTIMO WHERE data_devolucao IS NULL)
      AND m.id_material NOT IN (SELECT id_material FROM TRANSFERENCIA WHERE estado_transferencia IN ('Pendente', 'Aprovada') AND id_transferencia <> :NEW.id_transferencia);
  END IF;
  
  -- 3. Validação: se o total de exemplares disponíveis for 1 ou menos, bloqueia
  IF v_total_exemplares_disponiveis <= 1 THEN
    RAISE_APPLICATION_ERROR(-20015, 
      'Pedido de transferencia bloqueado: Este e o ultimo exemplar disponivel de "' || v_titulo || '" na biblioteca de origem.');
  END IF;
END;
/

CREATE OR REPLACE TRIGGER protege_ultimo_exemplar_update
BEFORE UPDATE ON TRANSFERENCIA
FOR EACH ROW
DECLARE
  v_total_exemplares_disponiveis NUMBER;
  v_isbn VARCHAR2(20);
  v_titulo VARCHAR2(200);
BEGIN
  -- A trigger só deve ser ativada ao tentar MUDAR o estado para 'Aprovada'
  IF :NEW.estado_transferencia = 'Aprovada' AND :OLD.estado_transferencia <> 'Aprovada' THEN
  
    -- 1. Busca ISBN e título do material a ser transferido
    SELECT ISBN, titulo INTO v_isbn, v_titulo
    FROM MATERIAL_BIBLIOGRAFICO
    WHERE id_material = :NEW.id_material;
    
    -- 2. Conta quantos exemplares ESTÃO DISPONÍVEIS (não emprestados, não em outra transferência pendente/aprovada)
    -- A lógica é idêntica à da trigger de INSERT
    IF v_isbn IS NOT NULL THEN
      -- Contagem por ISBN
      SELECT COUNT(m.id_material) INTO v_total_exemplares_disponiveis
      FROM MATERIAL_BIBLIOGRAFICO m
      WHERE m.ISBN = v_isbn
        AND m.id_biblioteca = :NEW.id_biblioteca_origem
        AND m.id_material NOT IN (SELECT id_material FROM EMPRESTIMO WHERE data_devolucao IS NULL)
        AND m.id_material NOT IN (
          SELECT id_material FROM TRANSFERENCIA 
          WHERE estado_transferencia IN ('Pendente', 'Aprovada')
            -- Exclui a própria transferência que estamos a tentar aprovar da contagem de bloqueios
            AND id_transferencia <> :NEW.id_transferencia 
        );
    ELSE
      -- Contagem por título
      SELECT COUNT(m.id_material) INTO v_total_exemplares_disponiveis
      FROM MATERIAL_BIBLIOGRAFICO m
      WHERE normaliza_titulo(m.titulo) = normaliza_titulo(v_titulo)
        AND m.id_biblioteca = :NEW.id_biblioteca_origem
        AND m.id_material NOT IN (SELECT id_material FROM EMPRESTIMO WHERE data_devolucao IS NULL)
        AND m.id_material NOT IN (
          SELECT id_material FROM TRANSFERENCIA 
          WHERE estado_transferencia IN ('Pendente', 'Aprovada')
            AND id_transferencia <> :NEW.id_transferencia
        );
    END IF;
    
    -- 3. Validação final: se o total de exemplares disponíveis for 1 ou menos, bloqueia a APROVAÇÃO
    IF v_total_exemplares_disponiveis <= 1 THEN
      RAISE_APPLICATION_ERROR(-20016, 
        'Aprovacao de transferencia bloqueada: Tornou-se o ultimo exemplar disponivel de "' || v_titulo || '" na biblioteca de origem.');
    END IF;
      
  END IF; -- Fim da condição de mudança de estado
END;
/