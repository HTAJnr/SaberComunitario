-- OBJETIVO: Rastreabilidade completa de doações e certificados
-- USADO EM: Relatórios de transparência, emissão de certificados
CREATE OR REPLACE VIEW vw_doacoes_detalhadas AS
SELECT
    d.id_doacao,
    d.data_doacao,
    r.nome_doador,
    r.tipo_doador,
    r.contacto AS doador_contacto,
    COUNT(DISTINCT i.id_itemDoado) AS total_itens,
    NVL(SUM(i.valor_estimado * i.quantidade), 0) AS valor_total_doacao,
    c.num_certificado AS certificado_numero,
    c.tipo_certificado,
    c.data_emissao AS data_emissao_certificado
FROM DOACAO d
JOIN DOADOR r ON d.id_doador = r.id_doador
LEFT JOIN ITEM_DOACAO i ON d.id_doacao = i.id_doacao
LEFT JOIN CERTIFICADO_DOACAO c ON d.id_doacao = c.id_doacao
GROUP BY
    d.id_doacao, d.data_doacao,
    r.nome_doador, r.tipo_doador, r.contacto,
    c.num_certificado, c.tipo_certificado, c.data_emissao;
/

-- OBJETIVO: Reconhecer principais benfeitores por valor total
-- USADO EM: Certificados honoríficos, relatórios anuais
CREATE OR REPLACE VIEW vw_doadores_ranking AS
SELECT
    r.id_doador,
    r.nome_doador,
    r.tipo_doador,
    COUNT(DISTINCT d.id_doacao)                        AS total_doacoes,
    NVL(SUM(i.valor_estimado * i.quantidade), 0)       AS valor_total_contribuido,
    MIN(d.data_doacao)                                 AS primeira_doacao,
    MAX(d.data_doacao)                                 AS ultima_doacao,
    COUNT(DISTINCT c.num_certificado)                  AS certificados_emitidos,
    ROW_NUMBER() OVER (
        ORDER BY NVL(SUM(i.valor_estimado * i.quantidade), 0) DESC
    ) AS ranking_geral
FROM DOADOR r
LEFT JOIN DOACAO d ON r.id_doador = d.id_doador
LEFT JOIN ITEM_DOACAO i ON d.id_doacao = i.id_doacao
LEFT JOIN CERTIFICADO_DOACAO c ON d.id_doacao = c.id_doacao
GROUP BY r.id_doador, r.nome_doador, r.tipo_doador;
/

-- OBJETIVO: Histórico de certificados para consulta e reemissão
-- USADO EM: Verificação, reemissões
CREATE OR REPLACE VIEW vw_certificados_emitidos AS
SELECT
    c.num_certificado,
    c.tipo_certificado,
    c.data_emissao,
    r.nome_doador,
    r.contacto AS doador_contacto,
    d.data_doacao,
    NVL(SUM(i.valor_estimado * i.quantidade), 0) AS valor_doacao,
    c.observacoes,
    c.original_numero
FROM CERTIFICADO_DOACAO c
JOIN DOACAO d ON c.id_doacao = d.id_doacao
JOIN DOADOR r ON d.id_doador = r.id_doador
LEFT JOIN ITEM_DOACAO i ON d.id_doacao = i.id_doacao
GROUP BY
    c.num_certificado, c.tipo_certificado, c.data_emissao,
    r.nome_doador, r.contacto, d.data_doacao, c.observacoes, c.original_numero;
/

-- OBJETIVO: Equipa operacional activa com nível de acesso
-- USADO EM: Gestão de acessos, autenticação, auditoria
CREATE OR REPLACE VIEW vw_funcionarios_ativos AS
SELECT
    f.cod_funcionario,
    f.nome_funcionario,
    f.genero,
    f.contacto,
    f.email,
    f.cod_biblioteca,
    f.data_contratacao,
    ff.nome_funcao,
    ff.nivel_acesso
FROM FUNCIONARIO f
JOIN FUNCAO_FUNCIONARIO ff ON f.id_funcao = ff.id_funcao
WHERE f.data_demissao IS NULL;
/

-- OBJETIVO: Mapear funcionários activos aos seus roles Oracle
-- USADO EM: Auditoria de acessos, gestão de permissões
CREATE OR REPLACE VIEW vw_acesso_funcionario AS
SELECT
    f.cod_funcionario,
    f.nome_funcionario,
    f.email,
    fn.nome_funcao,
    fn.nivel_acesso AS oracle_role,
    f.cod_biblioteca
FROM FUNCIONARIO f
JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
WHERE f.data_demissao IS NULL;
/

-- OBJETIVO: KPIs consolidados dos programas de alfabetização
-- USADO EM: Dashboard de coordenação, relatórios de impacto
CREATE OR REPLACE VIEW vw_programas_detalhados AS
SELECT
    p.cod_programa,
    p.cod_biblioteca,
    p.nome_programa,
    p.publico_alvo,
    p.duracao_semanas,
    p.estado_programa,
    COUNT(DISTINCT nl.id_nivel)          AS total_niveis,
    COUNT(DISTINCT pf.cod_funcionario)   AS total_funcionarios,
    COUNT(DISTINCT pp.num_cartao)        AS total_participantes_ativos
FROM PROGRAMA_ALFABETIZACAO p
LEFT JOIN NIVEL_PROGRESSAO nl   ON p.cod_programa = nl.cod_programa
LEFT JOIN PROGRAMA_FUNCIONARIO pf ON p.cod_programa = pf.cod_programa
LEFT JOIN PARTICIPACAO_PROGRAMA pp
    ON p.cod_programa = pp.cod_programa AND pp.estado_participacao = 'Activo'
GROUP BY
    p.cod_programa, p.cod_biblioteca, p.nome_programa,
    p.publico_alvo, p.duracao_semanas, p.estado_programa;
/

-- OBJETIVO: Grade horária semanal de cada funcionário
-- USADO EM: Gestão de escalas, verificação de disponibilidade
CREATE OR REPLACE VIEW vw_horarios_funcionario_semana AS
SELECT
    f.cod_funcionario,
    f.nome_funcionario,
    f.cod_biblioteca,
    h.dia_semana,
    h.hora_entrada,
    h.hora_saida
FROM FUNCIONARIO f
LEFT JOIN HORARIO_FUNCIONARIO h ON f.cod_funcionario = h.cod_funcionario
WHERE f.data_demissao IS NULL;
/
