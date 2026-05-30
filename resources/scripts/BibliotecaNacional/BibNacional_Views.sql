-- ============================================================
-- BibNacional_Views.sql
--
-- ARQUITECTURA DE REFERÊNCIAS CROSS-NODE:
--
-- Views globais (vw_global_*): usam @link EXPLÍCITO.
-- Motivo: views são compiladas estaticamente — o Oracle resolve
-- os objectos em tempo de criação (DDL). Sinónimos públicos com
-- o mesmo nome que tabelas remotas criam ORA-01775 (loop) porque
-- o nó remoto também tem um sinónimo com esse nome. @link explícito
-- quebra o loop e identifica inequivocamente o nó de destino.
-- ============================================================

-- ============================================================
-- SECÇÃO 1: DOAÇÕES E CERTIFICADOS (100% local)
-- ============================================================

-- OBJETIVO: Rastreabilidade completa de doações e certificados
CREATE OR REPLACE VIEW vw_doacoes_detalhadas AS
WITH BibliotecasPorDoacao AS (
    SELECT
        d.id_doacao,
        RTRIM(
            XMLAGG(XMLELEMENT(E, b.nome_biblioteca || ',') ORDER BY b.nome_biblioteca)
            .EXTRACT('//text()').GETSTRINGVAL(),
        ',') AS bibliotecas_beneficiadas
    FROM DOACAO d
    JOIN ITEM_DOACAO i ON d.id_doacao = i.id_doacao
    JOIN BIBLIOTECA b ON i.cod_biblioteca = b.cod_biblioteca
    GROUP BY d.id_doacao
)
SELECT
    d.id_doacao,
    d.data_doacao,
    r.nome_doador,
    r.tipo_doador,
    r.contacto    AS doador_contacto,
    COUNT(DISTINCT i.id_itemDoado) AS total_itens,
    NVL(SUM(i.valor_estimado * i.quantidade), 0) AS valor_total_doacao,
    bp.bibliotecas_beneficiadas,
    c.num_certificado AS certificado_numero,
    c.tipo_certificado AS certificado_tipo,
    c.data_emissao    AS data_emissao_certificado
FROM DOACAO d
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

-- OBJETIVO: Reconhecer principais benfeitores por valor total
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

-- ============================================================
-- SECÇÃO 2: FUNCIONÁRIOS (100% local)
-- ============================================================

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
    ff.nivel_acesso,
    b.nome_biblioteca
FROM FUNCIONARIO f
JOIN FUNCAO_FUNCIONARIO ff ON f.id_funcao = ff.id_funcao
LEFT JOIN BIBLIOTECA b ON f.cod_biblioteca = b.cod_biblioteca
WHERE f.data_demissao IS NULL;
/

CREATE OR REPLACE VIEW vw_acesso_funcionario AS
SELECT
    f.cod_funcionario,
    f.nome_funcionario,
    f.email,
    fn.nome_funcao,
    fn.nivel_acesso AS oracle_role,
    f.cod_biblioteca,
    b.nome_biblioteca
FROM FUNCIONARIO f
JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
LEFT JOIN BIBLIOTECA b ON f.cod_biblioteca = b.cod_biblioteca
WHERE f.data_demissao IS NULL;
/

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

-- ============================================================
-- SECÇÃO 3: LEITORES — FRAGMENTAÇÃO VERTICAL (100% local)
-- ============================================================

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
        WHEN a.num_cartao  IS NOT NULL THEN 'Adulto'
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
LEFT JOIN ADULTO a    ON l.num_cartao = a.num_cartao
LEFT JOIN PROFESSOR pr ON l.num_cartao = pr.num_cartao
LEFT JOIN CRIANCA cr   ON l.num_cartao = cr.num_cartao;
/

CREATE OR REPLACE VIEW vw_leitor_publico AS
SELECT num_cartao, nome_completo, cod_biblioteca,
       status_leitor, historico_pontualidade, distancia_biblioteca
FROM LEITOR;
/ 

CREATE OR REPLACE VIEW vw_leitor_privado AS
SELECT num_cartao, data_nasc, genero, nivel_escolar,
       localizacao_leitor, contacto, foto_path
FROM LEITOR;
/

-- ============================================================
-- SECÇÃO 4: FRAGMENTAÇÃO HORIZONTAL DE LEITOR (100% local)
-- ============================================================

CREATE OR REPLACE VIEW vw_frag_leitor_activos AS
SELECT * FROM LEITOR WHERE STATUS_LEITOR = 'Activo';
/

CREATE OR REPLACE VIEW vw_frag_leitor_suspensos AS
SELECT * FROM LEITOR WHERE STATUS_LEITOR = 'Suspenso';
/

CREATE OR REPLACE VIEW vw_frag_leitor_inactivos AS
SELECT * FROM LEITOR WHERE STATUS_LEITOR NOT IN ('Activo', 'Suspenso');
/


-- ============================================================
-- SECÇÃO 5: REPLICAÇÃO DE FUNCIONÁRIOS (100% local)
-- ============================================================

CREATE OR REPLACE VIEW vw_replica_funcionarios AS
SELECT
    f.cod_funcionario,
    f.nome_funcionario,
    f.cod_biblioteca,
    f.id_funcao,
    fn.nivel_acesso,
    fn.nome_funcao
FROM FUNCIONARIO f
JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
WHERE f.data_demissao IS NULL;
/

CREATE OR REPLACE VIEW vw_func_activos_operacional AS
SELECT cod_funcionario, nome_funcionario, cod_biblioteca, id_funcao, nivel_acesso
FROM (
    SELECT f.cod_funcionario, f.nome_funcionario, f.cod_biblioteca,
           f.id_funcao, fn.nivel_acesso
    FROM FUNCIONARIO f
    JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
    WHERE f.data_demissao IS NULL
);
/

CREATE OR REPLACE VIEW vw_func_activos_confidencial AS
SELECT cod_funcionario, data_nasc, endereco, senha, formacao, experiencia
FROM FUNCIONARIO
WHERE data_demissao IS NULL;
/

CREATE OR REPLACE VIEW vw_func_inactivos_operacional AS
SELECT cod_funcionario, nome_funcionario, cod_biblioteca, id_funcao, nivel_acesso
FROM (
    SELECT f.cod_funcionario, f.nome_funcionario, f.cod_biblioteca,
           f.id_funcao, fn.nivel_acesso
    FROM FUNCIONARIO f
    JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
    WHERE f.data_demissao IS NOT NULL
);
/

CREATE OR REPLACE VIEW vw_func_inactivos_confidencial AS
SELECT cod_funcionario, data_nasc, endereco, senha, formacao, experiencia
FROM FUNCIONARIO
WHERE data_demissao IS NOT NULL;
/

-- ============================================================
-- SECÇÃO 6: VISTAS GLOBAIS CROSS-NODE
--
-- Usam @link EXPLÍCITO — não podem usar sinónimos públicos.
-- Motivo: ORA-01775 (looping chain) quando sinónimo local tem o
-- mesmo nome que a tabela remota — o nó remoto resolve o sinónimo
-- de volta para si próprio criando um loop infinito.
--

-- ============================================================

CREATE OR REPLACE VIEW vw_global_leitores_emprestimos AS
SELECT
    l.num_cartao, l.nome_completo, l.cod_biblioteca, l.status_leitor,
    l.historico_pontualidade,
    e.id_emprestimo, e.cod_material, e.data_retirada, e.prazo_devolucao,
    CASE WHEN e.id_emprestimo IS NOT NULL THEN 'S' ELSE 'N' END AS tem_emprestimo_activo
FROM LEITOR l
LEFT JOIN emprestimo@emprestimosdb e
    ON l.num_cartao = e.num_cartao AND e.data_devolucao IS NULL;
/

-- Yasin nao tem que me dar acesso a essa? Nao 
CREATE OR REPLACE VIEW vw_global_catalogo AS
SELECT
    m.cod_material, m.titulo, m.autor, m.editora, m.ano_publicacao,
    m.estado_material_conservacao, m.cod_biblioteca,
    b.nome_biblioteca, b.provincia,
    CASE WHEN m.estado_material_conservacao = 'Indisponivel' THEN 'N' ELSE 'S' END
        AS potencialmente_disponivel
FROM material_bibliografico@materiaisdb m
JOIN biblioteca@eventosdb b ON m.cod_biblioteca = b.cod_biblioteca;
/

CREATE OR REPLACE VIEW vw_global_eventos_participacao AS
SELECT
    e.id_evento, e.titulo_evento, e.data_evento, e.status_evento,
    e.publico_alvo, e.capacidade,
    COUNT(pe.num_cartao) AS total_inscritos
FROM evento@eventosdb e
LEFT JOIN participacao_evento@eventosdb pe ON e.id_evento = pe.id_evento
GROUP BY e.id_evento, e.titulo_evento, e.data_evento,
         e.status_evento, e.publico_alvo, e.capacidade;
/

-- ── VW_AUDITORIA (sempre local) ─────────────────────────────
CREATE OR REPLACE VIEW VW_AUDITORIA AS
SELECT
    id_auditoria, data_operacao, operacao, cod_funcionario,
    objeto_afetado, resultado, motivo_falha, nos_afetados, observacoes,
    'NACIONAL' AS no_origem
FROM AUDITORIA_OPERACOES;
/

-- ============================================================
-- SECÇÃO 7: MÉTRICAS DO SISTEMA (DASHBOARD ADMIN)
-- Usa snapshots locais em vez de links live — resiliente a nós offline.
-- snap_material_basico → MaterialsDB
-- snap_emp_activos     → EmprestimosDB
-- snap_eventos         → EventosDB
-- LEITOR, DOACAO, ITEM_DOACAO são locais; BIBLIOTECA usa biblioteca_snap.
-- ============================================================

CREATE OR REPLACE VIEW vw_metricas_sistema AS
SELECT
    (SELECT COUNT(*) FROM BIBLIOTECA WHERE cod_biblioteca IS NOT NULL)     AS total_bibliotecas_ativas,
    (SELECT COUNT(*) FROM LEITOR)                                           AS total_leitores_cadastrados,
    (SELECT COUNT(*) FROM snap_material_basico)                             AS total_materiais_acervo,
    (SELECT COUNT(*) FROM snap_emp_activos)                                 AS total_emprestimos_ativos,
    0                                                                       AS taxa_devolucao_no_prazo,
    (SELECT NVL(SUM(multa_valor), 0)
       FROM snap_emp_activos WHERE multa_paga = 'N')                        AS valor_multas_pendentes,
    (SELECT NVL(SUM(i.valor_estimado * i.quantidade), 0)
       FROM DOACAO d
       JOIN ITEM_DOACAO i ON d.id_doacao = i.id_doacao
      WHERE EXTRACT(MONTH FROM d.data_doacao) = EXTRACT(MONTH FROM SYSDATE)
        AND EXTRACT(YEAR  FROM d.data_doacao) = EXTRACT(YEAR  FROM SYSDATE)
    )                                                                       AS total_doacoes_mes_atual,
    (SELECT COUNT(*) FROM snap_eventos
      WHERE data_evento BETWEEN SYSDATE AND SYSDATE + 30)                  AS eventos_proximos_30_dias,
    (SELECT COUNT(*) FROM LEITOR WHERE status_leitor = 'Suspenso')          AS leitores_suspensos
FROM dual;
/

-- ============================================================
-- SECÇÃO 8: MÉTRICAS POR BIBLIOTECA (DASHBOARD BIBLIOTECÁRIO)
-- Usa snapshots locais — resiliente a MATERIAISDB, EMPRESTIMOSDB
-- e EVENTOSDB offline. LEITOR e FUNCIONARIO são locais.
-- NOTA: devolucoes_hoje = 0 (snap_emp_activos só tem activos).
-- NOTA: emprestimos_hoje aproximado pelo material da biblioteca,
--       não pelo funcionário (funcionário está sempre local).
-- ============================================================

CREATE OR REPLACE VIEW vw_metricas_por_biblioteca AS
SELECT
    b.cod_biblioteca,
    b.nome_biblioteca,
    b.provincia,
    b.endereco,
    (SELECT COUNT(*)
       FROM LEITOR l
      WHERE l.cod_biblioteca = b.cod_biblioteca)                            AS total_leitores,
    (SELECT COUNT(*)
       FROM snap_material_basico smb
      WHERE smb.cod_biblioteca = b.cod_biblioteca)                          AS total_materiais,
    (SELECT COUNT(*)
       FROM snap_material_basico smb
      WHERE smb.cod_biblioteca = b.cod_biblioteca
        AND smb.estado_material_conservacao != 'Indisponivel'
        AND NOT EXISTS (
            SELECT 1 FROM snap_emp_activos sea
             WHERE sea.cod_material = smb.cod_material
        ))                                                                  AS materiais_disponiveis,
    (SELECT COUNT(*)
       FROM snap_emp_activos sea, snap_material_basico smb
      WHERE sea.cod_material = smb.cod_material
        AND smb.cod_biblioteca = b.cod_biblioteca)                          AS emprestimos_ativos,
    (SELECT COUNT(*)
       FROM snap_emp_activos sea, snap_material_basico smb
      WHERE sea.cod_material = smb.cod_material
        AND smb.cod_biblioteca = b.cod_biblioteca
        AND TRUNC(sea.data_retirada) = TRUNC(SYSDATE))                     AS emprestimos_hoje,
    0                                                                       AS devolucoes_hoje,
    (SELECT COUNT(*)
       FROM snap_emp_activos sea, snap_material_basico smb
      WHERE sea.cod_material = smb.cod_material
        AND smb.cod_biblioteca = b.cod_biblioteca
        AND SYSDATE > sea.prazo_devolucao + 7)                             AS emprestimos_muito_atrasados,
    (SELECT COUNT(*)
       FROM snap_eventos sev
      WHERE sev.cod_biblioteca = b.cod_biblioteca
        AND sev.data_evento BETWEEN SYSDATE AND SYSDATE + 30)              AS eventos_proximos,
    (SELECT titulo_evento
       FROM snap_eventos sev
      WHERE sev.cod_biblioteca = b.cod_biblioteca
        AND TRUNC(sev.data_evento) = TRUNC(SYSDATE)
        AND ROWNUM = 1)                                                     AS evento_hoje,
    (SELECT NVL(SUM(sea.multa_valor), 0)
       FROM snap_emp_activos sea, snap_material_basico smb
      WHERE sea.cod_material = smb.cod_material
        AND smb.cod_biblioteca = b.cod_biblioteca
        AND sea.multa_paga = 'N')                                           AS multas_pendentes
FROM BIBLIOTECA b;
/