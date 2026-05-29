-- ============================================================
-- EmprestimosProg_Views.sql
-- Executar como: usr_emprestimosdb
-- Nota: os 4 fragmentos de EMPRESTIMO estao em Fragmentacao.sql
-- ============================================================

-- vw_emprestimos_activos
-- Lista todos os emprestimos ainda nao devolvidos (data_devolucao IS NULL).
-- Consultada pelo MateriaisDB para verificar se um material tem emprestimo
-- activo antes de autorizar uma transferencia (RN06).
-- Consultada pelo BibliotecaNacionalDB para as suas vistas globais de leitores.
CREATE OR REPLACE VIEW vw_emprestimos_activos AS
SELECT id_emprestimo,
       num_cartao,
       cod_material,
       data_retirada,
       prazo_devolucao,
       TRUNC(SYSDATE) - TRUNC(prazo_devolucao) AS dias_atraso
FROM EMPRESTIMO
WHERE data_devolucao IS NULL;

-- vw_suspensoes_activas
-- Lista todas as suspensoes em vigor (estado_suspensao = Activa).
-- Consultada pelo BibliotecaNacionalDB para verificar o estado de
-- um leitor antes de operacoes que exijam que ele esteja sem restricoes.
CREATE OR REPLACE VIEW vw_suspensoes_activas AS
SELECT id_suspensao,
       num_cartao,
       id_emprestimo,
       data_inicio,
       data_fim,
       dias_suspensao,
       estado_suspensao
FROM SUSPENSAO
WHERE estado_suspensao = 'Activa';


-- ============================================================
-- FRAGMENTACAO MISTA (horizontal + vertical) de EMPRESTIMO
-- ============================================================

DROP VIEW frag_emp_activos_op;
DROP VIEW frag_emp_activos_det;
DROP VIEW frag_emp_historico_op;
DROP VIEW frag_emp_historico_det;

-- Fragmento 1: Activos Operacional
-- Parte horizontal: so emprestimos activos (data_devolucao IS NULL)
-- Parte vertical: atributos operacionais consultados por outros nos
CREATE OR REPLACE VIEW frag_emp_activos_op AS
SELECT id_emprestimo, num_cartao, cod_material,
       data_retirada, prazo_devolucao
FROM EMPRESTIMO
WHERE data_devolucao IS NULL;

-- Fragmento 2: Activos Detalhe
-- Parte horizontal: so emprestimos activos
-- Parte vertical: atributos de detalhe operacional (uso interno)
CREATE OR REPLACE VIEW frag_emp_activos_det AS
SELECT id_emprestimo, cod_funcionario,
       estado_material_saida, observacoes_devolucao
FROM EMPRESTIMO
WHERE data_devolucao IS NULL;

-- Fragmento 3: Historico Operacional
-- Parte horizontal: so emprestimos devolvidos
-- Parte vertical: atributos operacionais para relatorios
CREATE OR REPLACE VIEW frag_emp_historico_op AS
SELECT id_emprestimo, num_cartao, cod_material,
       data_retirada, prazo_devolucao, data_devolucao
FROM EMPRESTIMO
WHERE data_devolucao IS NOT NULL;

-- Fragmento 4: Historico Detalhe
-- Parte horizontal: so emprestimos devolvidos
-- Parte vertical: atributos financeiros e de estado do material
CREATE OR REPLACE VIEW frag_emp_historico_det AS
SELECT id_emprestimo, estado_material_retorno,
       multa_valor, multa_paga, data_pagamento_multa,
       observacoes_devolucao
FROM EMPRESTIMO
WHERE data_devolucao IS NOT NULL;
