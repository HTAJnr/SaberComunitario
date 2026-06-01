-- ============================================================
-- EmprestimosProg_Triggers.sql
-- ============================================================

-- trg_valida_emprestimo
-- Activa BEFORE INSERT em EMPRESTIMO
-- Verifica: status do leitor, limite de emprestimos, funcionario,
--           faixa etaria para criancas
-- Acesso remoto via EXECUTE IMMEDIATE (evita ORA-04052 em compilacao)
-- Blocos remotos com EXCEPTION WHEN OTHERS THEN NULL:
--   se no remoto offline, validacao remota e ignorada (fail-open)
--   validacoes locais (limite, funcionario) funcionam sempre
CREATE OR REPLACE TRIGGER trg_valida_emprestimo
BEFORE INSERT ON EMPRESTIMO
FOR EACH ROW
DECLARE
    v_status  VARCHAR2(12);
    v_count   NUMBER;
    v_func    NUMBER;
    v_crianca NUMBER;
    v_faixa   VARCHAR2(30);
    v_sql     VARCHAR2(500);
    v_erro    NUMBER := 0;
    v_msg     VARCHAR2(300);
BEGIN
    -- 1. Status do leitor
    BEGIN
        v_sql := 'SELECT status_leitor FROM leitor WHERE num_cartao = :1';
        EXECUTE IMMEDIATE v_sql INTO v_status USING :NEW.num_cartao;
        IF v_status != 'Activo' THEN
            v_erro := -20001;
            v_msg  := 'Leitor nao pode emprestar. Status: ' || v_status;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;

    IF v_erro != 0 THEN
        prc_registar_auditoria('CRIAR_EMPRESTIMO',:NEW.num_cartao,:NEW.cod_material,
            NULL,'FALHA',v_msg,'BibliotecaNacionalDB',NULL);
        RAISE_APPLICATION_ERROR(v_erro, v_msg);
    END IF;

    -- 2. Limite de 1 emprestimo activo (local)
    SELECT COUNT(*) INTO v_count FROM EMPRESTIMO
    WHERE num_cartao = :NEW.num_cartao AND data_devolucao IS NULL;

    IF v_count >= 1 THEN
        prc_registar_auditoria('CRIAR_EMPRESTIMO',:NEW.num_cartao,:NEW.cod_material,
            NULL,'FALHA','Leitor ja tem emprestimo activo','Local',NULL);
        RAISE_APPLICATION_ERROR(-20002, 'Leitor ja tem um emprestimo activo.');
    END IF;

    -- 3. Funcionario reconhecido (local)
    -- EXECUTE IMMEDIATE evita ORA-01775 em compilacao quando REPL_FUNCIONARIOS
    -- ainda nao existe (primeira instalacao com @nacionaldb offline).
    BEGIN
        EXECUTE IMMEDIATE
            'SELECT COUNT(*) FROM usr_emprestimosdb.repl_funcionarios WHERE cod_funcionario = :1'
            INTO v_func USING :NEW.cod_funcionario;
    EXCEPTION
        WHEN OTHERS THEN v_func := 1; -- fail-open: assume valido se MV indisponivel
    END;

    IF v_func = 0 THEN
        prc_registar_auditoria('CRIAR_EMPRESTIMO',:NEW.num_cartao,:NEW.cod_material,
            NULL,'FALHA','Funcionario nao reconhecido: '||:NEW.cod_funcionario,'Local',NULL);
        RAISE_APPLICATION_ERROR(-20004, 'Funcionario nao reconhecido neste no.');
    END IF;

    -- 4. Faixa etaria para criancas
    BEGIN
        v_sql := 'SELECT COUNT(*) FROM crianca WHERE num_cartao = :1';
        EXECUTE IMMEDIATE v_sql INTO v_crianca USING :NEW.num_cartao;
    EXCEPTION
        WHEN OTHERS THEN v_crianca := 0;
    END;

    IF v_crianca > 0 THEN
        BEGIN
            v_sql := 'SELECT c.faixa_etaria
                      FROM material_bibliografico m
                      JOIN categoria c ON m.cod_categoria = c.id_categoria
                      WHERE m.cod_material = :1';
            EXECUTE IMMEDIATE v_sql INTO v_faixa USING :NEW.cod_material;
        EXCEPTION
            WHEN OTHERS THEN v_faixa := 'Todas as Idades';
        END;

        IF v_faixa NOT IN ('Infantil','Todas as Idades') THEN
            prc_registar_auditoria('CRIAR_EMPRESTIMO',:NEW.num_cartao,:NEW.cod_material,
                NULL,'FALHA','Material inadequado para crianca. Faixa: '||v_faixa,
                'BibliotecaNacionalDB, MateriaisDB',NULL);
            RAISE_APPLICATION_ERROR(-20003,
                'Material nao permitido para criancas. Faixa: ' || v_faixa);
        END IF;
    END IF;
END;
/
-- trg_aplica_suspensao
-- Activa AFTER UPDATE OF data_devolucao em EMPRESTIMO
-- So activa quando data_devolucao passa de NULL para um valor
-- Fix mutating table: COUNT de atrasos feito via PRAGMA AUTONOMOUS_TRANSACTION
-- Update de material feito via procedure do Yasin (atualizar_estado_material)
CREATE OR REPLACE TRIGGER trg_aplica_suspensao
AFTER UPDATE OF data_devolucao ON EMPRESTIMO
FOR EACH ROW
WHEN (NEW.data_devolucao IS NOT NULL AND OLD.data_devolucao IS NULL)
DECLARE
    v_dias_atraso    NUMBER;
    v_dias_suspensao NUMBER;
    v_total_atrasos  NUMBER;
    v_sql            VARCHAR2(500);
BEGIN
    v_dias_atraso := TRUNC(:NEW.data_devolucao) - TRUNC(:NEW.prazo_devolucao);

    IF v_dias_atraso <= 0 THEN
        prc_registar_auditoria('PROCESSAR_DEVOLUCAO', :NEW.num_cartao,
            :NEW.cod_material, :NEW.id_emprestimo,
            'SUCESSO', NULL, 'Local', 'Sem atraso');
        RETURN;
    END IF;

    -- Bloqueio se atraso > 60 dias
    IF v_dias_atraso > 60 THEN
        BEGIN
            v_sql := 'UPDATE leitor SET status_leitor = ''Bloqueado''
                      WHERE num_cartao = :1';
            EXECUTE IMMEDIATE v_sql USING :NEW.num_cartao;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;

        -- Marcar material como perdido via procedure do Yasin
        BEGIN
            v_sql := 'BEGIN atualizar_estado_material@materiaisdb(:1, ''Indisponivel''); END;';
            EXECUTE IMMEDIATE v_sql USING :NEW.cod_material;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;

        prc_registar_auditoria('PROCESSAR_DEVOLUCAO', :NEW.num_cartao,
            :NEW.cod_material, :NEW.id_emprestimo, 'SUCESSO', NULL,
            'BibliotecaNacionalDB, MateriaisDB',
            'Leitor bloqueado. Atraso: ' || v_dias_atraso || ' dias');
        RETURN;
    END IF;

    -- Calcular dias de suspensao pela tabela da RN03
    IF    v_dias_atraso BETWEEN 1  AND 7  THEN v_dias_suspensao := 7;
    ELSIF v_dias_atraso BETWEEN 8  AND 15 THEN v_dias_suspensao := 15;
    ELSIF v_dias_atraso BETWEEN 16 AND 30 THEN v_dias_suspensao := 30;
    ELSE                                       v_dias_suspensao := 60;
    END IF;

    -- Registar suspensao (local)
    INSERT INTO SUSPENSAO (id_suspensao, num_cartao, id_emprestimo,
                           data_inicio, data_fim, dias_suspensao, estado_suspensao)
    VALUES (SEQ_SUSPENSAO.NEXTVAL, :NEW.num_cartao, :NEW.id_emprestimo,
            SYSDATE, SYSDATE + v_dias_suspensao, v_dias_suspensao, 'Activa');

    -- Actualizar status do leitor (BibliotecaNacionalDB)
    BEGIN
        v_sql := 'UPDATE leitor SET status_leitor = ''Suspenso''
                  WHERE num_cartao = :1 AND status_leitor = ''Activo''';
        EXECUTE IMMEDIATE v_sql USING :NEW.num_cartao;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    -- Contar total de atrasos via dblink (evita mutating table na tabela local)
    BEGIN
        v_sql := 'SELECT COUNT(*) FROM emprestimo@emprestimosdb
                  WHERE num_cartao = :1
                    AND data_devolucao IS NOT NULL
                    AND data_devolucao > prazo_devolucao';
        EXECUTE IMMEDIATE v_sql INTO v_total_atrasos USING :NEW.num_cartao;
    EXCEPTION
        WHEN OTHERS THEN v_total_atrasos := 1;
    END;

    -- Actualizar historico_pontualidade (BibliotecaNacionalDB)
    BEGIN
        IF v_total_atrasos >= 3 THEN
            v_sql := 'UPDATE leitor SET historico_pontualidade = ''Mau''
                      WHERE num_cartao = :1';
            EXECUTE IMMEDIATE v_sql USING :NEW.num_cartao;
        ELSIF v_total_atrasos BETWEEN 1 AND 2 THEN
            v_sql := 'UPDATE leitor SET historico_pontualidade = ''Irregular''
                      WHERE num_cartao = :1
                        AND historico_pontualidade = ''Pontual''';
            EXECUTE IMMEDIATE v_sql USING :NEW.num_cartao;
        END IF;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    prc_registar_auditoria('PROCESSAR_DEVOLUCAO', :NEW.num_cartao,
        :NEW.cod_material, :NEW.id_emprestimo, 'SUCESSO', NULL,
        'BibliotecaNacionalDB',
        'Suspenso ' || v_dias_suspensao || ' dias. Atraso: ' || v_dias_atraso || ' dias');
END;
/
