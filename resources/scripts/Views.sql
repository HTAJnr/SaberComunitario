-- OBJETIVO: Rastreabilidade completa de doações
-- USADO EM: Relatórios de transparência, certificados
CREATE OR REPLACE VIEW vw_doacoes_detalhadas AS
WITH BibliotecasPorDoacao AS (
    SELECT
        d.id_doacao,
        RTRIM(
            XMLAGG(XMLELEMENT(E, b.nome_biblioteca || ',') ORDER BY b.nome_biblioteca)
            .EXTRACT('//text()').GETSTRINGVAL(),
        ',') AS bibliotecas_beneficiadas
    FROM
        DOACAO d
        JOIN ITEM_DOACAO i ON d.id_doacao = i.id_doacao
        JOIN BIBLIOTECA b ON i.cod_biblioteca = b.cod_biblioteca
    GROUP BY
        d.id_doacao
)
SELECT
    d.id_doacao,
    d.data_doacao,
    r.nome_doador AS doador_nome,
    r.tipo_doador AS doador_tipo,
    r.contacto    AS doador_contacto,
    COUNT(DISTINCT i.id_itemDoado) AS total_itens,
    COALESCE(SUM(i.valor_estimado * i.quantidade), 0) AS valor_total_doacao,
    bp.bibliotecas_beneficiadas,
    c.num_certificado AS certificado_numero,
    c.tipo_certificado   AS certificado_tipo,
    c.data_emissao       AS data_emissao_certificado
FROM
    DOACAO d
    JOIN DOADOR r ON d.id_doador = r.id_doador
    LEFT JOIN ITEM_DOACAO i ON d.id_doacao = i.id_doacao
    LEFT JOIN CERTIFICADO_DOACAO c ON d.id_doacao = c.id_doacao
    LEFT JOIN BibliotecasPorDoacao bp ON d.id_doacao = bp.id_doacao
GROUP BY
    d.id_doacao, d.data_doacao,
    r.nome_doador, r.tipo_doador, r.contacto,
    bp.bibliotecas_beneficiadas,
    c.num_certificado, c.tipo_certificado, c.data_emissao;
/


-- OBJETIVO: Reconhecer principais benfeitores
-- USADO EM: Certificados honoríficos, relatórios anuais
CREATE OR REPLACE VIEW vw_doadores_ranking AS
SELECT
    d.id_doador,
    r.nome_doador,
    r.tipo_doador,
    COUNT(DISTINCT d.id_doacao) AS total_doacoes,
    COALESCE(SUM(i.valor_estimado * i.quantidade), 0) AS valor_total_contribuido,
    MIN(d.data_doacao) AS primeira_doacao,
    MAX(d.data_doacao) AS ultima_doacao,
    COUNT(DISTINCT c.num_certificado) AS certificados_emitidos,
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(i.valor_estimado * i.quantidade), 0) DESC) AS ranking_geral
FROM
    DOADOR r
    LEFT JOIN DOACAO d ON r.id_doador = d.id_doador
    LEFT JOIN ITEM_DOACAO i ON d.id_doacao = i.id_doacao
    LEFT JOIN CERTIFICADO_DOACAO c ON d.id_doacao = c.id_doacao
GROUP BY
    d.id_doador, r.nome_doador, r.tipo_doador;
/

-- OBJETIVO: KPIs do sistema em tempo real
-- USADO EM: Dashboard administrativo
CREATE OR REPLACE VIEW vw_metricas_sistema AS
SELECT
    (SELECT COUNT(*) FROM BIBLIOTECA WHERE cod_biblioteca IS NOT NULL) AS total_bibliotecas_ativas,
    (SELECT COUNT(*) FROM LEITOR) AS total_leitores_cadastrados,
    (SELECT COUNT(*) FROM MATERIAL_BIBLIOGRAFICO) AS total_materiais_acervo,
    (SELECT COUNT(*) FROM EMPRESTIMO WHERE data_devolucao IS NULL) AS total_emprestimos_ativos,
    ROUND(
        (SELECT COUNT(*) FROM EMPRESTIMO e
         WHERE e.data_devolucao IS NOT NULL
           AND e.data_devolucao <= e.prazo_devolucao) /
        NULLIF((SELECT COUNT(*) FROM EMPRESTIMO WHERE data_devolucao IS NOT NULL), 0) * 100,
    2) AS taxa_devolucao_no_prazo,
    (SELECT COALESCE(SUM(multa_valor), 0) FROM EMPRESTIMO WHERE multa_paga = 'N') AS valor_multas_pendentes,
    (SELECT COALESCE(SUM(i.valor_estimado * i.quantidade), 0)
        FROM DOACAO d
        JOIN ITEM_DOACAO i ON d.id_doacao = i.id_doacao
        WHERE EXTRACT(MONTH FROM d.data_doacao) = EXTRACT(MONTH FROM SYSDATE)
          AND EXTRACT(YEAR FROM d.data_doacao) = EXTRACT(YEAR FROM SYSDATE)
    ) AS total_doacoes_mes_atual,
    (SELECT COUNT(*) FROM EVENTO WHERE data_evento BETWEEN SYSDATE AND SYSDATE + 30) AS eventos_proximos_30_dias,
    (SELECT COUNT(*) FROM LEITOR WHERE status_leitor = 'Suspenso') AS leitores_suspensos
FROM dual;
/

-- OBJETIVO: Histórico de certificados para reemissão
-- USADO EM: Verificação, reemissões
CREATE OR REPLACE VIEW vw_certificados_emitidos AS
SELECT
    c.num_certificado,
    c.tipo_certificado,
    c.data_emissao,
    r.nome_doador AS doador_nome,
    r.contacto AS doador_contacto,
    d.data_doacao,
    COALESCE(SUM(i.valor_estimado * i.quantidade), 0) AS valor_doacao,
    c.observacoes,
    CASE
        WHEN c.tipo_certificado = 'Reemissao' THEN
            (SELECT c2.num_certificado
             FROM CERTIFICADO_DOACAO c2
             WHERE c2.id_doacao = c.id_doacao
               AND c2.tipo_certificado = 'Original'
               AND ROWNUM = 1)
        ELSE NULL
    END AS original_numero
FROM
    CERTIFICADO_DOACAO c
    JOIN DOACAO d ON c.id_doacao = d.id_doacao
    JOIN DOADOR r ON d.id_doador = r.id_doador
    LEFT JOIN ITEM_DOACAO i ON d.id_doacao = i.id_doacao
GROUP BY
    c.num_certificado, c.tipo_certificado, c.data_emissao,
    r.nome_doador, r.contacto, d.data_doacao, c.observacoes, c.id_doacao;
/

-- OBJETIVO: Grade horária semanal de cada biblioteca
-- USADO EM: Validação de eventos, informação ao público
CREATE OR REPLACE VIEW vw_horarios_biblioteca_semana AS
SELECT
    b.cod_biblioteca,
    b.nome_biblioteca,
    h.dia_semana,
    h.hora_abertura,
    h.hora_fecho
FROM biblioteca b
LEFT JOIN HORARIO_BIBLIOTECA h
    ON b.cod_biblioteca = h.cod_biblioteca;
/

-- OBJETIVO: Equipa operacional com permissões
-- USADO EM: Gestão de acessos, auditoria
CREATE OR REPLACE VIEW vw_funcionarios_ativos AS
SELECT
    f.cod_funcionario,
    f.nome_funcionario,
    ff.nome_funcao,
    b.nome_biblioteca
FROM funcionario f
JOIN funcao_funcionario ff
    ON f.id_funcao = ff.id_funcao
LEFT JOIN biblioteca b
    ON f.cod_biblioteca = b.cod_biblioteca
WHERE f.data_demissao IS NULL;
/

-- OBJETIVO: Agenda de eventos futuros
-- USADO EM: Homepage, inscrições
CREATE OR REPLACE VIEW vw_eventos_proximos AS
SELECT
    e.id_evento,
    e.titulo_evento,
    e.descricao_evento,
    e.data_evento,
    b.nome_biblioteca AS biblioteca_nome
FROM evento e
JOIN biblioteca b
    ON e.cod_biblioteca = b.cod_biblioteca
WHERE e.data_evento >= SYSDATE;
/

-- OBJETIVO: Dados consolidados de cada unidade
-- USADO EM: Dashboard, seleção de biblioteca
CREATE OR REPLACE VIEW vw_bibliotecas_operacionais AS
SELECT
    b.cod_biblioteca,
    b.nome_biblioteca,
    b.provincia,
    b.endereco,
    f.nome_funcionario AS coordenador_nome,
    f.contacto AS coordenador_contacto
FROM biblioteca b
LEFT JOIN BIBLIOTECA_RESPONSAVEL br
    ON b.cod_biblioteca = br.cod_biblioteca AND br.papel = 'Principal' AND br.data_fim IS NULL
LEFT JOIN FUNCIONARIO f ON br.cod_funcionario = f.cod_funcionario;
/

-- OBJETIVO: Unificar hierarquia de materiais com dados de contexto
-- USADO EM: Consultas de disponibilidade, relatórios de acervo
CREATE OR REPLACE VIEW vw_materiais_completos AS
SELECT
    m.cod_material,
    CASE
        WHEN lf.cod_material IS NOT NULL THEN 'LIVRO_FISICO'
        WHEN e.cod_material IS NOT NULL THEN 'EBOOK'
        WHEN p.cod_material IS NOT NULL THEN 'PERIODICO'
    END AS tipo_material,
    m.titulo,
    m.autor,
    m.editora,
    m.ano_publicacao,
    m.ISBN,
    m.idioma,
    m.num_paginas,
    m.estado_material_conservacao AS estado_conservacao,
    c.area_tematica AS categoria_area_tematica,
    c.faixa_etaria AS categoria_faixa_etaria,
    c.nivel_leitura AS categoria_nivel_leitura,
    b.nome_biblioteca AS biblioteca_nome,
    b.endereco AS biblioteca_localizacao,
    b.cod_biblioteca,
    CASE
        WHEN m.estado_material_conservacao = 'Indisponivel' THEN 'N'
        WHEN EXISTS (
            SELECT 1 FROM EMPRESTIMO emp
            WHERE emp.cod_material = m.cod_material
            AND emp.data_devolucao IS NULL
        ) THEN 'N'
        WHEN EXISTS (
            SELECT 1 FROM TRANSFERENCIA t
            WHERE t.cod_material = m.cod_material
            AND t.estado_transferencia IN ('Pendente', 'Aprovada')
        ) THEN 'N'
        ELSE 'S'
    END AS disponivel_emprestimo,
    m.localizacao_estante,
    e.formato AS ebook_formato,
    e.tamanho_arquivo AS ebook_tamanho,
    e.url_acesso AS ebook_url,
    p.edicao AS periodico_edicao,
    p.periodicidade AS periodico_periodicidade,
    p.data_publicacao AS periodico_data_publicacao,
    p.ISSN AS periodico_issn
FROM MATERIAL_BIBLIOGRAFICO m
INNER JOIN CATEGORIA c ON m.cod_categoria = c.id_categoria
INNER JOIN BIBLIOTECA b ON m.cod_biblioteca = b.cod_biblioteca
LEFT JOIN LIVRO_FISICO lf ON m.cod_material = lf.cod_material
LEFT JOIN EBOOK e ON m.cod_material = e.cod_material
LEFT JOIN PERIODICO p ON m.cod_material = p.cod_material;
/

-- OBJETIVO: Rastrear movimentação de materiais com atores envolvidos
-- USADO EM: Dashboard de coordenadores, auditoria
CREATE OR REPLACE VIEW vw_transferencias_detalhadas AS
SELECT
    t.id_transferencia,
    t.estado_transferencia,
    t.motivo,
    t.data_solicitacao,
    t.data_aprovacao_destino AS data_aprovacao,
    t.data_conclusao,
    CASE
        WHEN t.estado_transferencia IN ('Pendente', 'Aprovada')
        THEN TRUNC(SYSDATE - t.data_solicitacao)
        ELSE NULL
    END AS dias_pendente,
    m.titulo AS material_titulo,
    m.cod_material AS material_codigo,
    m.estado_material_conservacao AS material_estado,
    bo.nome_biblioteca AS biblioteca_origem_nome,
    bo.endereco AS biblioteca_origem_localizacao,
    bd.nome_biblioteca AS biblioteca_destino_nome,
    bd.endereco AS biblioteca_destino_localizacao,
    fs.nome_funcionario AS funcionario_solicitante_nome,
    fs.contacto AS contacto,
    fa.nome_funcionario AS funcionario_aprovador_nome,
    fa.contacto AS funcionario_aprovador_contacto
FROM TRANSFERENCIA t
INNER JOIN MATERIAL_BIBLIOGRAFICO m ON t.cod_material = m.cod_material
INNER JOIN BIBLIOTECA bo ON t.cod_biblioteca_origem = bo.cod_biblioteca
INNER JOIN BIBLIOTECA bd ON t.cod_biblioteca_destino = bd.cod_biblioteca
INNER JOIN FUNCIONARIO fs ON t.cod_funcionario_solicitante = fs.cod_funcionario
LEFT JOIN FUNCIONARIO fa ON t.cod_funcionario_aprovador = fa.cod_funcionario
WHERE t.data_solicitacao >= ADD_MONTHS(SYSDATE, -24);
/

-- OBJETIVO: Estatísticas do acervo por classificação
-- USADO EM: Relatórios gerenciais, gráficos
CREATE OR REPLACE VIEW vw_materiais_por_categoria AS
SELECT
    c.area_tematica,
    c.faixa_etaria,
    c.nivel_leitura,
    COUNT(m.cod_material) AS total_materiais,
    SUM(CASE
        WHEN m.estado_material_conservacao != 'Indisponivel'
        AND NOT EXISTS (
            SELECT 1 FROM EMPRESTIMO e
            WHERE e.cod_material = m.cod_material
            AND e.data_devolucao IS NULL
        )
        AND NOT EXISTS (
            SELECT 1 FROM TRANSFERENCIA t
            WHERE t.cod_material = m.cod_material
            AND t.estado_transferencia IN ('Pendente', 'Aprovada')
        )
        THEN 1 ELSE 0
    END) AS total_disponiveis,
    SUM(CASE
        WHEN EXISTS (
            SELECT 1 FROM EMPRESTIMO e
            WHERE e.cod_material = m.cod_material
            AND e.data_devolucao IS NULL
        )
        THEN 1 ELSE 0
    END) AS total_emprestados,
    SUM(CASE
        WHEN m.estado_material_conservacao = 'Indisponivel'
        THEN 1 ELSE 0
    END) AS total_indisponiveis,
    ROUND(
        (SUM(CASE
            WHEN EXISTS (
                SELECT 1 FROM EMPRESTIMO e
                WHERE e.cod_material = m.cod_material
                AND e.data_devolucao IS NULL
            )
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(m.cod_material), 0)) * 100,
        2
    ) AS taxa_circulacao
FROM CATEGORIA c
LEFT JOIN MATERIAL_BIBLIOGRAFICO m ON m.cod_categoria = c.id_categoria
GROUP BY c.area_tematica, c.faixa_etaria, c.nivel_leitura
ORDER BY c.area_tematica, c.faixa_etaria;
/

-- OBJETIVO: Unificar informações de todos os tipos de leitores
--           Expõe status_leitor (mantido por trigger), empréstimos activos e biblioteca
-- USADO EM: Gestão de leitores, filtro por biblioteca no backend
CREATE OR REPLACE VIEW vw_leitores_completos AS
SELECT
    l.num_cartao,
    l.nome_completo,
    l.data_nasc,
    l.genero,
    l.nivel_escolar,
    l.localizacao_leitor,
    l.contacto,
    l.foto_path,
    l.distancia_biblioteca,
    l.historico_pontualidade,
    l.cod_biblioteca,
    b.nome_biblioteca,
    l.status_leitor,
    CASE
        WHEN pr.num_cartao IS NOT NULL THEN 'Professor'
        WHEN a.num_cartao IS NOT NULL  THEN 'Adulto'
        WHEN cr.num_cartao IS NOT NULL THEN 'Crianca'
    END AS tipo_leitor,
    a.profissao,
    a.nivel_literacia,
    pr.escola_instituto,
    pr.nivel_ensino,
    pr.num_alunos,
    cr.nome_responsavel,
    cr.escola_frequenta,
    cr.classe
FROM LEITOR l
JOIN BIBLIOTECA b ON l.cod_biblioteca = b.cod_biblioteca
LEFT JOIN ADULTO a  ON l.num_cartao = a.num_cartao
LEFT JOIN PROFESSOR pr ON l.num_cartao = pr.num_cartao
LEFT JOIN CRIANCA cr ON l.num_cartao = cr.num_cartao;
/

-- OBJETIVO: Empréstimos em curso com dados do leitor, material e biblioteca
-- USADO EM: Dashboard de bibliotecário, devoluções, alertas de atraso
CREATE OR REPLACE VIEW vw_emprestimos_ativos AS
SELECT
    e.id_emprestimo,
    e.num_cartao,
    l.nome_completo AS nome_leitor,
    l.cod_biblioteca,
    b.nome_biblioteca AS biblioteca_nome,
    e.cod_material,
    mb.titulo AS material_titulo,
    e.data_retirada,
    e.prazo_devolucao,
    TRUNC(SYSDATE) - TRUNC(e.prazo_devolucao) AS dias_atraso,
    CASE
        WHEN TRUNC(SYSDATE) > TRUNC(e.prazo_devolucao) THEN
            CASE
                WHEN pr.num_cartao IS NOT NULL THEN
                    CASE WHEN (SELECT COUNT(*) FROM EMPRESTIMO e2
                               WHERE e2.num_cartao = e.num_cartao
                                 AND e2.data_devolucao > e2.prazo_devolucao) = 0
                         THEN 0
                         ELSE (TRUNC(SYSDATE) - TRUNC(e.prazo_devolucao)) * 10
                    END
                WHEN cr.num_cartao IS NOT NULL THEN
                    (TRUNC(SYSDATE) - TRUNC(e.prazo_devolucao)) * 5
                ELSE
                    (TRUNC(SYSDATE) - TRUNC(e.prazo_devolucao)) * 15
            END
        ELSE 0
    END AS multa_estimada
FROM EMPRESTIMO e
JOIN LEITOR l ON e.num_cartao = l.num_cartao
JOIN MATERIAL_BIBLIOGRAFICO mb ON e.cod_material = mb.cod_material
JOIN BIBLIOTECA b ON l.cod_biblioteca = b.cod_biblioteca
LEFT JOIN PROFESSOR pr ON e.num_cartao = pr.num_cartao
LEFT JOIN CRIANCA cr   ON e.num_cartao = cr.num_cartao
WHERE e.data_devolucao IS NULL;
/

-- OBJETIVO: Histórico completo de empréstimos com tipo de leitor e biblioteca do leitor
-- USADO EM: Relatórios, auditoria, filtro por biblioteca no backend
CREATE OR REPLACE VIEW vw_historico_emprestimos AS
SELECT
    e.id_emprestimo,
    l.num_cartao,
    l.nome_completo AS nome_leitor,
    l.cod_biblioteca,
    CASE
        WHEN p.num_cartao IS NOT NULL THEN 'PROFESSOR'
        WHEN a.num_cartao IS NOT NULL THEN 'ADULTO'
        WHEN cr.num_cartao IS NOT NULL THEN 'CRIANCA'
        ELSE 'DESCONHECIDO'
    END AS tipo_leitor,
    m.titulo AS material_titulo,
    c.area_tematica AS categoria_area,
    e.data_retirada,
    e.data_devolucao,
    ROUND(e.data_devolucao - e.data_retirada) AS dias_uso,
    e.prazo_devolucao,
    CASE
        WHEN e.data_devolucao IS NULL THEN NULL
        WHEN e.data_devolucao <= e.prazo_devolucao THEN 'TRUE'
        ELSE 'FALSE'
    END AS devolvido_no_prazo,
    e.estado_material_saida,
    e.estado_material_retorno,
    CASE
        WHEN e.estado_material_retorno IS NULL THEN NULL
        WHEN e.estado_material_retorno <> e.estado_material_saida THEN 'TRUE'
        ELSE 'FALSE'
    END AS material_danificado,
    e.multa_valor,
    CASE
        WHEN e.multa_paga = 'S' THEN 'TRUE'
        ELSE 'FALSE'
    END AS multa_paga,
    CASE WHEN e.data_devolucao IS NOT NULL AND e.data_devolucao > e.prazo_devolucao
         THEN ROUND(e.data_devolucao - e.prazo_devolucao)
         ELSE 0
    END AS dias_atraso,
    b.nome_biblioteca AS biblioteca_nome,
    f.nome_funcionario AS funcionario_nome
FROM emprestimo e
JOIN leitor l ON e.num_cartao = l.num_cartao
JOIN funcionario f ON e.cod_funcionario = f.cod_funcionario
JOIN biblioteca b ON f.cod_biblioteca = b.cod_biblioteca
JOIN material_bibliografico m ON e.cod_material = m.cod_material
JOIN categoria c ON m.cod_categoria = c.id_categoria
LEFT JOIN professor p ON l.num_cartao = p.num_cartao
LEFT JOIN adulto a ON l.num_cartao = a.num_cartao
LEFT JOIN crianca cr ON l.num_cartao = cr.num_cartao;
/

-- OBJETIVO: Engajamento dos leitores em eventos
-- USADO EM: Relatórios de eventos, perfil do leitor
CREATE OR REPLACE VIEW vw_participacoes_eventos AS
SELECT
    e.id_evento,
    e.titulo_evento,
    e.data_evento,
    b.nome_biblioteca AS biblioteca_nome,
    l.num_cartao,
    l.nome_completo AS nome_leitor,
    CASE
        WHEN l.nivel_escolar LIKE '%Professor%' THEN 'PROFESSOR'
        WHEN l.nivel_escolar LIKE '%Adulto%' THEN 'ADULTO'
        WHEN l.nivel_escolar LIKE '%Crianca%' THEN 'CRIANCA'
        ELSE 'LEITOR'
    END AS tipo_leitor,
    p.data_inscricao,
    p.presenca_confirmacao AS presenca_confirmada,
    e.publico_alvo,
    e.recorrente
FROM participacao_evento p
JOIN evento e
    ON p.id_evento = e.id_evento
LEFT JOIN biblioteca b
    ON e.cod_biblioteca = b.cod_biblioteca
JOIN leitor l
    ON p.num_cartao = l.num_cartao;
/

-- OBJETIVO: Métricas específicas de uma biblioteca (inclui total de leitores registados)
-- USADO EM: Dashboard de bibliotecário (visão local)
CREATE OR REPLACE VIEW vw_metricas_por_biblioteca AS
SELECT
    b.cod_biblioteca,
    b.nome_biblioteca,
    b.provincia,
    b.endereco,
    (SELECT COUNT(*)
     FROM LEITOR l
     WHERE l.cod_biblioteca = b.cod_biblioteca) AS total_leitores,
    (SELECT COUNT(*)
     FROM MATERIAL_BIBLIOGRAFICO m
     WHERE m.cod_biblioteca = b.cod_biblioteca) AS total_materiais,
    (SELECT COUNT(*)
     FROM MATERIAL_BIBLIOGRAFICO m
     WHERE m.cod_biblioteca = b.cod_biblioteca
     AND m.estado_material_conservacao != 'Indisponivel'
     AND NOT EXISTS (
         SELECT 1 FROM EMPRESTIMO e
         WHERE e.cod_material = m.cod_material
         AND e.data_devolucao IS NULL
     )) AS materiais_disponiveis,
    (SELECT COUNT(*)
     FROM EMPRESTIMO e
     JOIN MATERIAL_BIBLIOGRAFICO m ON e.cod_material = m.cod_material
     WHERE m.cod_biblioteca = b.cod_biblioteca
     AND e.data_devolucao IS NULL) AS emprestimos_ativos,
    (SELECT COUNT(*)
     FROM EMPRESTIMO e
     JOIN FUNCIONARIO f ON e.cod_funcionario = f.cod_funcionario
     WHERE f.cod_biblioteca = b.cod_biblioteca
     AND TRUNC(e.data_retirada) = TRUNC(SYSDATE)) AS emprestimos_hoje,
    (SELECT COUNT(*)
     FROM EMPRESTIMO e
     JOIN FUNCIONARIO f ON e.cod_funcionario = f.cod_funcionario
     WHERE f.cod_biblioteca = b.cod_biblioteca
     AND TRUNC(e.data_devolucao) = TRUNC(SYSDATE)) AS devolucoes_hoje,
    (SELECT COUNT(*)
     FROM EMPRESTIMO e
     JOIN MATERIAL_BIBLIOGRAFICO m ON e.cod_material = m.cod_material
     WHERE m.cod_biblioteca = b.cod_biblioteca
     AND e.data_devolucao IS NULL
     AND SYSDATE > e.prazo_devolucao + 7) AS emprestimos_muito_atrasados,
    (SELECT COUNT(*)
     FROM EVENTO ev
     WHERE ev.cod_biblioteca = b.cod_biblioteca
     AND ev.data_evento BETWEEN SYSDATE AND SYSDATE + 30) AS eventos_proximos,
    (SELECT titulo_evento
     FROM EVENTO ev
     WHERE ev.cod_biblioteca = b.cod_biblioteca
     AND TRUNC(ev.data_evento) = TRUNC(SYSDATE)
     AND ROWNUM = 1) AS evento_hoje,
    (SELECT COALESCE(SUM(e.multa_valor), 0)
     FROM EMPRESTIMO e
     JOIN FUNCIONARIO f ON e.cod_funcionario = f.cod_funcionario
     WHERE f.cod_biblioteca = b.cod_biblioteca
     AND e.multa_paga = 'N') AS multas_pendentes
FROM BIBLIOTECA b;
/

-- OBJETIVO: Mapear funcionários aos seus roles Oracle
-- USADO EM: Auditoria de acessos
CREATE OR REPLACE VIEW vw_acesso_funcionario AS
SELECT
    f.cod_funcionario,
    f.nome_funcionario,
    f.email,
    fn.nome_funcao,
    fn.nivel_acesso   AS oracle_role,
    b.nome_biblioteca
FROM FUNCIONARIO f
JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
JOIN BIBLIOTECA b ON f.cod_biblioteca = b.cod_biblioteca
WHERE f.data_demissao IS NULL;
/

CREATE OR REPLACE VIEW vw_eventos_completos AS
SELECT
    e.id_evento,
    e.titulo_evento,
    e.descricao_evento,
    e.local_evento,
    e.publico_alvo,
    e.data_evento,
    e.capacidade,
    e.status_evento,
    e.recorrente,
    b.cod_biblioteca,
    b.nome_biblioteca,
    f.cod_funcionario,
    f.nome_funcionario AS nome_responsavel,
    COUNT(pe.num_cartao) AS total_inscritos,
    ROUND(AVG(av.nota), 1) AS media_avaliacao
FROM EVENTO e
JOIN BIBLIOTECA b ON e.cod_biblioteca = b.cod_biblioteca
LEFT JOIN FUNCIONARIO f ON e.cod_funcionario_responsavel = f.cod_funcionario
LEFT JOIN PARTICIPACAO_EVENTO pe ON e.id_evento = pe.id_evento
LEFT JOIN AVALIACAO_EVENTO av ON e.id_evento = av.id_evento
GROUP BY
    e.id_evento, e.titulo_evento, e.descricao_evento, e.local_evento,
    e.publico_alvo, e.data_evento, e.capacidade, e.status_evento, e.recorrente,
    b.cod_biblioteca, b.nome_biblioteca, f.cod_funcionario, f.nome_funcionario;
/

