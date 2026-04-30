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
        JOIN BIBLIOTECA b ON i.id_biblioteca = b.id_biblioteca
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
    (SELECT COUNT(*) FROM BIBLIOTECA WHERE id_biblioteca IS NOT NULL) AS total_bibliotecas_ativas,
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
    (SELECT COUNT(*) FROM LEITOR WHERE num_cartao IN 
        (SELECT DISTINCT num_cartao FROM EMPRESTIMO WHERE multa_paga = 'N' AND multa_valor > 0)
    ) AS leitores_suspensos
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

-- OBJETIVO: Grade horária semanal de cada biblioteca
-- USADO EM: Validação de eventos, informação ao público
CREATE OR REPLACE VIEW vw_horarios_biblioteca_semana AS
SELECT
    b.id_biblioteca,
    b.nome_biblioteca,
    h.dia_semana,
    h.hora_abertura,
    h.hora_fecho
FROM biblioteca b
LEFT JOIN horario_ev_bib h
    ON b.id_biblioteca = h.id_biblioteca
WHERE h.id_evento IS NULL;
/

-- OBJETIVO: Equipa operacional com permissões
-- USADO EM: Gestão de acessos, auditoria
CREATE OR REPLACE VIEW vw_funcionarios_ativos AS
SELECT
    f.id_funcionario,
    f.nome_funcionario,
    ff.nome_funcao,
    b.nome_biblioteca
FROM funcionario f
JOIN funcao_funcionario ff
    ON f.id_funcao = ff.id_funcao
LEFT JOIN biblioteca b
    ON f.id_biblioteca = b.id_biblioteca
WHERE f.data_saida IS NULL;
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
    ON e.id_biblioteca = b.id_biblioteca
WHERE e.data_evento >= SYSDATE;
/

-- OBJETIVO: Dados consolidados de cada unidade
-- USADO EM: Dashboard, seleção de biblioteca
CREATE OR REPLACE VIEW vw_bibliotecas_operacionais AS
SELECT
    b.id_biblioteca,
    b.nome_biblioteca,
    b.localizacao,
    f.nome_funcionario AS coordenador_nome,
    f.contacto AS coordenador_contacto
FROM biblioteca b
LEFT JOIN funcionario f
    ON b.id_responsavel = f.id_funcionario;
/


-- OBJETIVO: Unificar hierarquia de materiais com dados de contexto
-- USADO EM: Consultas de disponibilidade, relatórios de acervo
CREATE OR REPLACE VIEW vw_materiais_completos AS
SELECT 
    m.id_material,
    CASE 
        WHEN lf.id_material IS NOT NULL THEN 'LIVRO_FISICO'
        WHEN e.id_material IS NOT NULL THEN 'EBOOK'
        WHEN p.id_material IS NOT NULL THEN 'PERIODICO'
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
    b.localizacao AS biblioteca_localizacao,
    b.id_biblioteca,
    -- C�lculo de disponibilidade
    CASE
        WHEN m.estado_material_conservacao = 'Indisponivel' THEN 'N'
        WHEN EXISTS (
            SELECT 1 FROM EMPRESTIMO emp 
            WHERE emp.id_material = m.id_material 
            AND emp.data_devolucao IS NULL
        ) THEN 'N'
        WHEN EXISTS (
            SELECT 1 FROM TRANSFERENCIA t 
            WHERE t.id_material = m.id_material 
            AND t.estado_transferencia IN ('Pendente', 'Aprovada')
        ) THEN 'N'
        ELSE 'S'
    END AS disponivel_emprestimo,
    -- Campos espec�ficos LIVRO_FISICO
    lf.localizacao_fisica,
    -- Campos espec�ficos EBOOK
    e.formato AS ebook_formato,
    e.tamanho_arquivo AS ebook_tamanho,
    e.url_acesso AS ebook_url,
    -- Campos espec�ficos PERIODICO
    p.edicao AS periodico_edicao,
    p.periodicidade AS periodico_periodicidade,
    p.data_publicacao AS periodico_data_publicacao,
    p.ISSN AS periodico_issn
FROM MATERIAL_BIBLIOGRAFICO m
INNER JOIN CATEGORIA c ON m.id_categoria = c.id_categoria
INNER JOIN BIBLIOTECA b ON m.id_biblioteca = b.id_biblioteca
LEFT JOIN LIVRO_FISICO lf ON m.id_material = lf.id_material
LEFT JOIN EBOOK e ON m.id_material = e.id_material
LEFT JOIN PERIODICO p ON m.id_material = p.id_material;
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
    -- C�lculo de dias pendentes
    CASE 
        WHEN t.estado_transferencia IN ('Pendente', 'Aprovada') 
        THEN TRUNC(SYSDATE - t.data_solicitacao)
        ELSE NULL
    END AS dias_pendente,
    -- Dados do Material
    m.titulo AS material_titulo,
    m.id_material AS material_codigo,
    m.estado_material_conservacao AS material_estado,
    -- Bibliotecas
    bo.nome_biblioteca AS biblioteca_origem_nome,
    bo.localizacao AS biblioteca_origem_localizacao,
    bd.nome_biblioteca AS biblioteca_destino_nome,
    bd.localizacao AS biblioteca_destino_localizacao,
    -- Funcion�rios
    fs.nome_funcionario AS funcionario_solicitante_nome,
    fs.contacto AS contacto,
    fa.nome_funcionario AS funcionario_aprovador_nome,
    fa.contacto AS funcionario_aprovador_contacto
FROM TRANSFERENCIA t
INNER JOIN MATERIAL_BIBLIOGRAFICO m ON t.id_material = m.id_material
INNER JOIN BIBLIOTECA bo ON t.id_biblioteca_origem = bo.id_biblioteca
INNER JOIN BIBLIOTECA bd ON t.id_biblioteca_destino = bd.id_biblioteca
INNER JOIN FUNCIONARIO fs ON t.id_funcionario_solicitante = fs.id_funcionario
LEFT JOIN FUNCIONARIO fa ON t.id_funcionario_aprovador = fa.id_funcionario
WHERE t.data_solicitacao >= ADD_MONTHS(SYSDATE, -24);
/

-- OBJETIVO: Estatísticas do acervo por classificação
-- USADO EM: Relatórios gerenciais, gráficos
CREATE OR REPLACE VIEW vw_materiais_por_categoria AS
SELECT 
    c.area_tematica,
    c.faixa_etaria,
    c.nivel_leitura,
    COUNT(m.id_material) AS total_materiais,
    -- Total dispon�veis
    SUM(CASE 
        WHEN m.estado_material_conservacao != 'Indisponivel'
        AND NOT EXISTS (
            SELECT 1 FROM EMPRESTIMO e 
            WHERE e.id_material = m.id_material 
            AND e.data_devolucao IS NULL
        )
        AND NOT EXISTS (
            SELECT 1 FROM TRANSFERENCIA t 
            WHERE t.id_material = m.id_material 
            AND t.estado_transferencia IN ('Pendente', 'Aprovada')
        )
        THEN 1 ELSE 0 
    END) AS total_disponiveis,
    -- Total emprestados
    SUM(CASE 
        WHEN EXISTS (
            SELECT 1 FROM EMPRESTIMO e 
            WHERE e.id_material = m.id_material 
            AND e.data_devolucao IS NULL
        )
        THEN 1 ELSE 0 
    END) AS total_emprestados,
    -- Total indispon�veis
    SUM(CASE 
        WHEN m.estado_material_conservacao = 'Indisponivel'
        THEN 1 ELSE 0 
    END) AS total_indisponiveis,
    -- Taxa de circula��o
    ROUND(
        (SUM(CASE 
            WHEN EXISTS (
                SELECT 1 FROM EMPRESTIMO e 
                WHERE e.id_material = m.id_material 
                AND e.data_devolucao IS NULL
            )
            THEN 1 ELSE 0 
        END) / NULLIF(COUNT(m.id_material), 0)) * 100, 
        2
    ) AS taxa_circulacao
FROM CATEGORIA c
LEFT JOIN MATERIAL_BIBLIOGRAFICO m ON c.id_categoria = m.id_categoria
GROUP BY c.area_tematica, c.faixa_etaria, c.nivel_leitura
ORDER BY c.area_tematica, c.faixa_etaria;
/

CREATE OR REPLACE VIEW leitores_participantes_eventos AS
SELECT L.num_cartao,
       L.nome_completo,
       P.id_evento,
       P.data_inscricao,
       P.presenca_confirmacao
FROM LEITOR L
JOIN PARTICIPACAO_EVENTO P
  ON L.num_cartao = P.num_cartao;
/

CREATE OR REPLACE VIEW criancas_responsaveis AS
SELECT L.nome_completo AS nome_crianca,
       C.nome_responsavel,
       C.telefone_responsavel,
       C.escola_frequenta
FROM LEITOR L
JOIN CRIANCA C
  ON L.num_cartao = C.num_cartao;
/
--visualizar leitor que estiveram no evento

CREATE OR REPLACE VIEW vw_relatorio_emprestimos AS
SELECT
    e.id_emprestimo,
    l.num_cartao,
    l.nome_completo,
    l.nivel_escolar,
    CASE
        WHEN p.num_cartao IS NOT NULL THEN 'PROFESSOR'
        WHEN c.num_cartao IS NOT NULL THEN 'CRIANCA'
        WHEN a.num_cartao IS NOT NULL THEN 'ADULTO'
        ELSE 'OUTRO'
    END AS tipo_leitor,
    e.id_material,
    m.titulo,  -- adiciona o título do material
    e.data_retirada,
    e.prazo_devolucao,
    e.data_devolucao,
    e.estado_material_saida,
    e.estado_material_retorno,
    NVL(e.multa_valor, 0) AS multa_valor,
    e.multa_paga,
    CASE
        WHEN e.data_devolucao IS NULL AND SYSDATE > e.prazo_devolucao THEN 'ATRASADO'
        WHEN e.data_devolucao > e.prazo_devolucao THEN 'DEVOLVIDO COM ATRASO'
        WHEN e.data_devolucao IS NULL THEN 'EM CURSO'
        ELSE 'FINALIZADO'
    END AS status_emprestimo,
    -- adiciona coluna calculada de dias de atraso
    CASE
        WHEN e.data_devolucao IS NULL AND SYSDATE > e.prazo_devolucao THEN TRUNC(SYSDATE - e.prazo_devolucao)
        WHEN e.data_devolucao > e.prazo_devolucao THEN TRUNC(e.data_devolucao - e.prazo_devolucao)
        ELSE 0
    END AS dias_atraso
FROM EMPRESTIMO e
JOIN LEITOR l ON e.num_cartao = l.num_cartao
LEFT JOIN PROFESSOR p ON l.num_cartao = p.num_cartao
LEFT JOIN CRIANCA c ON l.num_cartao = c.num_cartao
LEFT JOIN ADULTO a ON l.num_cartao = a.num_cartao
JOIN MATERIAL_BIBLIOGRAFICO m ON e.id_material = m.id_material;

--relatório de empréstimos detalhado com tipo de leitor e status
--SELECT * FROM vw_relatorio_emprestimos WHERE status_emprestimo = 'ATRASADO';

---
-- OBJETIVO: Unificar informações de todos os tipos de leitores
--           Calcula idade, empréstimos ativos e status de empréstimo
CREATE OR REPLACE VIEW vw_leitores_completos AS
SELECT
    l.num_cartao,
    l.nome_completo,
    l.data_nasc,
    TRUNC(MONTHS_BETWEEN(SYSDATE, l.data_nasc)/12) AS idade_calculada,
    CASE 
        WHEN p.num_cartao IS NOT NULL THEN 'PROFESSOR'
        WHEN a.num_cartao IS NOT NULL THEN 'ADULTO'
        WHEN c.num_cartao IS NOT NULL THEN 'CRIANCA'
        ELSE 'DESCONHECIDO'
    END AS tipo_leitor,
    CASE 
        WHEN p.num_cartao IS NOT NULL THEN 5
        WHEN a.num_cartao IS NOT NULL THEN 3
        WHEN c.num_cartao IS NOT NULL THEN 2
        ELSE 0
    END AS limite_emprestimo,
    l.genero,
    l.nivel_escolar,
    l.localizacao_leitor AS localizacao,
    l.contacto,
    a.profissao,
    p.escola_instituto,
    p.disciplina,
    p.tipo_ensino,
    c.nome_responsavel,
    c.telefone_responsavel,
    (SELECT COUNT(*) FROM EMPRESTIMO e 
        WHERE e.num_cartao = l.num_cartao
        AND e.data_devolucao IS NULL) AS emprestimos_ativos,
    CASE
        WHEN EXISTS (SELECT 1 FROM EMPRESTIMO e
                     WHERE e.num_cartao = l.num_cartao
                       AND e.prazo_devolucao < SYSDATE - 30
                       AND e.data_devolucao IS NULL) THEN 'SUSPENSO'
        WHEN (SELECT COUNT(*) FROM EMPRESTIMO e
                WHERE e.num_cartao = l.num_cartao
                  AND e.data_devolucao IS NULL) >=
             CASE 
                WHEN p.num_cartao IS NOT NULL THEN 5
                WHEN a.num_cartao IS NOT NULL THEN 3
                WHEN c.num_cartao IS NOT NULL THEN 2
                ELSE 0
             END
        THEN 'NO_LIMITE'
        ELSE 'OK'
    END AS status_emprestimo
FROM LEITOR l
LEFT JOIN CRIANCA c   ON l.num_cartao = c.num_cartao
LEFT JOIN ADULTO a    ON l.num_cartao = a.num_cartao
LEFT JOIN PROFESSOR p ON l.num_cartao = p.num_cartao;
/

-- Visualizar leitores completos com status de empréstimo
-- SELECT * FROM vw_leitores_completos;
CREATE OR REPLACE VIEW vw_emprestimos_ativos AS
SELECT
    e.id_emprestimo,
    e.num_cartao,
    l.nome_completo AS nome_leitor,
    CASE 
        WHEN p.num_cartao IS NOT NULL THEN 'PROFESSOR'
        WHEN a.num_cartao IS NOT NULL THEN 'ADULTO'
        WHEN c.num_cartao IS NOT NULL THEN 'CRIANCA'
        ELSE 'DESCONHECIDO'
    END AS tipo_leitor,
    m.titulo AS material_titulo,
    m.id_material AS material_codigo,
    b.nome_biblioteca AS biblioteca_nome,
    e.data_retirada,
    e.prazo_devolucao,
    TRUNC(SYSDATE - e.data_retirada) AS dias_emprestado,
    CASE 
        WHEN SYSDATE > e.prazo_devolucao THEN TRUNC(SYSDATE - e.prazo_devolucao)
        ELSE 0
    END AS dias_atraso,
    CASE 
        WHEN SYSDATE > e.prazo_devolucao THEN
            CASE 
                WHEN p.num_cartao IS NOT NULL THEN TRUNC(SYSDATE - e.prazo_devolucao) * 5
                WHEN a.num_cartao IS NOT NULL THEN TRUNC(SYSDATE - e.prazo_devolucao) * 3
                WHEN c.num_cartao IS NOT NULL THEN TRUNC(SYSDATE - e.prazo_devolucao) * 2
                ELSE 0
            END
        ELSE 0
    END AS multa_estimada,
    e.estado_material_saida
FROM emprestimo e
JOIN leitor l ON e.num_cartao = l.num_cartao
JOIN material_bibliografico m ON e.id_material = m.id_material
JOIN biblioteca b ON m.id_biblioteca = b.id_biblioteca
LEFT JOIN professor p ON l.num_cartao = p.num_cartao
LEFT JOIN adulto a ON l.num_cartao = a.num_cartao
LEFT JOIN crianca c ON l.num_cartao = c.num_cartao
WHERE e.data_devolucao IS NULL;
/

-- Visualizar empréstimos ativos
-- SELECT * FROM vw_emprestimos_ativos;

CREATE OR REPLACE VIEW vw_historico_emprestimos AS
SELECT
    e.id_emprestimo,
    l.num_cartao,
    l.nome_completo AS nome_leitor,
    CASE
        WHEN l.nivel_escolar LIKE '%Professor%' THEN 'PROFESSOR'
        WHEN l.nivel_escolar LIKE '%Adult%' THEN 'ADULTO'
        ELSE 'ESTUDANTE'
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
JOIN funcionario f ON e.id_funcionario = f.id_funcionario
JOIN biblioteca b ON f.id_biblioteca = b.id_biblioteca
JOIN material_bibliografico m ON e.id_material = m.id_material
JOIN categoria c ON m.id_categoria = c.id_categoria;
/
-- Visualizar histórico de empréstimos
-- SELECT * FROM vw_historico_emprestimos;

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
    ON e.id_biblioteca = b.id_biblioteca
JOIN leitor l
    ON p.num_cartao = l.num_cartao;
/
-- Visualizar participações em eventos
-- SELECT * FROM vw_participacoes_eventos;

-- OBJETIVO: Métricas específicas de uma biblioteca
-- USADO EM: Dashboard de bibliotecário (visão local)
CREATE OR REPLACE VIEW vw_metricas_por_biblioteca AS
SELECT
    b.id_biblioteca,
    b.nome_biblioteca,
    b.localizacao,
    -- Total de materiais nesta biblioteca
    (SELECT COUNT(*) 
     FROM MATERIAL_BIBLIOGRAFICO m 
     WHERE m.id_biblioteca = b.id_biblioteca) AS total_materiais,
    -- Materiais disponíveis
    (SELECT COUNT(*) 
     FROM MATERIAL_BIBLIOGRAFICO m 
     WHERE m.id_biblioteca = b.id_biblioteca
     AND m.estado_material_conservacao != 'Indisponivel'
     AND NOT EXISTS (
         SELECT 1 FROM EMPRESTIMO e 
         WHERE e.id_material = m.id_material 
         AND e.data_devolucao IS NULL
     )) AS materiais_disponiveis,
    -- Empréstimos ativos desta biblioteca
    (SELECT COUNT(*) 
     FROM EMPRESTIMO e
     JOIN MATERIAL_BIBLIOGRAFICO m ON e.id_material = m.id_material
     WHERE m.id_biblioteca = b.id_biblioteca
     AND e.data_devolucao IS NULL) AS emprestimos_ativos,
    -- Empréstimos de HOJE
    (SELECT COUNT(*) 
     FROM EMPRESTIMO e
     JOIN FUNCIONARIO f ON e.id_funcionario = f.id_funcionario
     WHERE f.id_biblioteca = b.id_biblioteca
     AND TRUNC(e.data_retirada) = TRUNC(SYSDATE)) AS emprestimos_hoje,
    -- Devoluções de HOJE
    (SELECT COUNT(*) 
     FROM EMPRESTIMO e
     JOIN FUNCIONARIO f ON e.id_funcionario = f.id_funcionario
     WHERE f.id_biblioteca = b.id_biblioteca
     AND TRUNC(e.data_devolucao) = TRUNC(SYSDATE)) AS devolucoes_hoje,
    -- Empréstimos atrasados (mais de 7 dias)
    (SELECT COUNT(*) 
     FROM EMPRESTIMO e
     JOIN MATERIAL_BIBLIOGRAFICO m ON e.id_material = m.id_material
     WHERE m.id_biblioteca = b.id_biblioteca
     AND e.data_devolucao IS NULL
     AND SYSDATE > e.prazo_devolucao + 7) AS emprestimos_muito_atrasados,
    -- Eventos próximos (30 dias)
    (SELECT COUNT(*) 
     FROM EVENTO ev 
     WHERE ev.id_biblioteca = b.id_biblioteca
     AND ev.data_evento BETWEEN SYSDATE AND SYSDATE + 30) AS eventos_proximos,
    -- Evento de HOJE
    (SELECT titulo_evento 
     FROM EVENTO ev 
     WHERE ev.id_biblioteca = b.id_biblioteca
     AND TRUNC(ev.data_evento) = TRUNC(SYSDATE)
     AND ROWNUM = 1) AS evento_hoje,
    -- Multas pendentes nesta biblioteca
    (SELECT COALESCE(SUM(e.multa_valor), 0) 
     FROM EMPRESTIMO e
     JOIN FUNCIONARIO f ON e.id_funcionario = f.id_funcionario
     WHERE f.id_biblioteca = b.id_biblioteca
     AND e.multa_paga = 'N') AS multas_pendentes
FROM BIBLIOTECA b;
/