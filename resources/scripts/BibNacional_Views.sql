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

-- ============================================================
-- SECÇÃO 2: LEITORES — VISTA UNIFICADA (local com join cross-node para BIBLIOTECA)
-- OBJETIVO: Dados completos de leitores com tipo e biblioteca
-- USADO EM: Gestão de leitores, filtros, backend
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
LEFT JOIN ADULTO a   ON l.num_cartao = a.num_cartao
LEFT JOIN PROFESSOR pr ON l.num_cartao = pr.num_cartao
LEFT JOIN CRIANCA cr  ON l.num_cartao = cr.num_cartao;
/

-- ============================================================
-- SECÇÃO 3: FRAGMENTAÇÃO VERTICAL DE LEITOR (Fase 1.3)
--
-- Critério de divisão: operacional vs. pessoal.
-- Fragmento público: o que outros nós precisam para verificações.
-- Fragmento privado: dados pessoais que ficam exclusivamente aqui.
--
-- As 3 regras (Guia BD2 Tema 8):
--   Completude   — cada atributo aparece em pelo menos um fragmento.
--   Reconstrução — JOIN pelo num_cartao reconstrói a tabela completa.
--   Disjuntividade — cada atributo num único fragmento, excepto num_cartao
--                    (chave primária, necessária em ambos para a Reconstrução).
-- ============================================================

-- Fragmento 1 — dados públicos (expostos a outros nós via database link)
CREATE OR REPLACE VIEW vw_leitor_publico AS
SELECT
    num_cartao,
    nome_completo,
    cod_biblioteca,
    status_leitor,
    historico_pontualidade,
    distancia_biblioteca
FROM LEITOR;
/

-- Fragmento 2 — dados privados (exclusivos deste nó)
CREATE OR REPLACE VIEW vw_leitor_privado AS
SELECT
    num_cartao,
    data_nasc,
    genero,
    nivel_escolar,
    localizacao_leitor,
    contacto,
    foto_path
FROM LEITOR;
/

-- ============================================================
-- SECÇÃO 4: VISTAS GLOBAIS — TRANSPARÊNCIA DE LOCALIZAÇÃO (Fase 2.5)
-- Agregam dados de múltiplos nós via database links.
-- O utilizador faz SELECT como se os dados estivessem todos num só lugar.
-- ============================================================

-- Vista global 1: leitores com estado de empréstimo actual
-- Nós consultados: local (LEITOR) + EmprestimosDB (EMPRESTIMO via @emprestimosdb)
CREATE OR REPLACE VIEW vw_global_leitores_emprestimos AS
SELECT
    l.num_cartao,
    l.nome_completo,
    l.cod_biblioteca,
    l.status_leitor,
    l.historico_pontualidade,
    e.id_emprestimo,
    e.cod_material,
    e.data_retirada,
    e.prazo_devolucao,
    CASE WHEN e.id_emprestimo IS NOT NULL THEN 'S' ELSE 'N' END AS tem_emprestimo_activo
FROM LEITOR l
LEFT JOIN emprestimo@emprestimosdb e
    ON l.num_cartao = e.num_cartao
   AND e.data_devolucao IS NULL;
/

-- Vista global 2: catálogo completo com disponibilidade e localização
-- Nós consultados: MateriaisDB (MATERIAL_BIBLIOGRAFICO via @materiaisdb)
--                + EventosBibliotecasDB (BIBLIOTECA via @eventosdb)
CREATE OR REPLACE VIEW vw_global_catalogo AS
SELECT
    m.cod_material,
    m.titulo,
    m.autor,
    m.editora,
    m.ano_publicacao,
    m.estado_material_conservacao,
    m.cod_biblioteca,
    b.nome_biblioteca,
    b.provincia,
    CASE
        WHEN m.estado_material_conservacao = 'Indisponivel' THEN 'N'
        ELSE 'S'
    END AS potencialmente_disponivel
FROM material_bibliografico@materiaisdb m
JOIN biblioteca@eventosdb b ON m.cod_biblioteca = b.cod_biblioteca;
/

-- Vista global 3: programação de eventos com participação
-- Nós consultados: EventosBibliotecasDB (EVENTO, PARTICIPACAO_EVENTO via @eventosdb)
CREATE OR REPLACE VIEW vw_global_eventos_participacao AS
SELECT
    e.id_evento,
    e.titulo_evento,
    e.data_evento,
    e.status_evento,
    e.publico_alvo,
    e.capacidade,
    e.cod_biblioteca,
    COUNT(pe.num_cartao) AS total_inscritos
FROM evento@eventosdb e
LEFT JOIN participacao_evento@eventosdb pe ON e.id_evento = pe.id_evento
GROUP BY
    e.id_evento, e.titulo_evento, e.data_evento, e.status_evento,
    e.publico_alvo, e.capacidade, e.cod_biblioteca;
/

-- ============================================================
-- SECÇÃO 1: VISTA FONTE DE REPLICAÇÃO
-- Expõe apenas os dados operacionalmente necessários noutros nós.
-- Dados pessoais (senha, endereco, data_nasc) ficam exclusivamente aqui.
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


-- ── FRAGMENTO 1: Activos — atributos operacionais ──────────
-- O que outros nós precisam para verificar: quem é, onde trabalha,
-- que função tem, que nível de acesso tem.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_func_activos_operacional AS
SELECT
    cod_funcionario,
    nome_funcionario,
    cod_biblioteca,
    id_funcao,
    nivel_acesso
FROM (
    SELECT
        f.cod_funcionario,
        f.nome_funcionario,
        f.cod_biblioteca,
        f.id_funcao,
        fn.nivel_acesso
    FROM FUNCIONARIO f
    JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
    WHERE f.data_demissao IS NULL        -- Horizontal: só activos
);
/
 
-- ── FRAGMENTO 2: Activos — atributos confidenciais ─────────
-- Dados pessoais e de segurança. Nunca saem deste nó.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_func_activos_confidencial AS
SELECT
    cod_funcionario,
    data_nasc,
    endereco,
    senha,
    formacao,
    experiencia
FROM FUNCIONARIO
WHERE data_demissao IS NULL;
/
 
-- ── FRAGMENTO 3: Inactivos — atributos operacionais ────────
-- Funcionários com data_demissao preenchida.
-- Mantidos para integridade referencial histórica (empréstimos, auditorias).
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_func_inactivos_operacional AS
SELECT
    cod_funcionario,
    nome_funcionario,
    cod_biblioteca,
    id_funcao,
    nivel_acesso
FROM (
    SELECT
        f.cod_funcionario,
        f.nome_funcionario,
        f.cod_biblioteca,
        f.id_funcao,
        fn.nivel_acesso
    FROM FUNCIONARIO f
    JOIN FUNCAO_FUNCIONARIO fn ON f.id_funcao = fn.id_funcao
    WHERE f.data_demissao IS NOT NULL    -- Horizontal: só inactivos
);
/
 
-- ── FRAGMENTO 4: Inactivos — atributos confidenciais ───────
CREATE OR REPLACE VIEW vw_func_inactivos_confidencial AS
SELECT
    cod_funcionario,
    data_nasc,
    endereco,
    senha,
    formacao,
    experiencia
FROM FUNCIONARIO
WHERE data_demissao IS NOT NULL;
/

-- ============================================================
-- GRANTS SOBRE VISTAS — executar após BibNacional_Views.sql
-- ============================================================
-- IMPORTANTE: roles Oracle não propagam através de database links.
-- Acesso cross-node via @bibliotecanacionaldb exige GRANT directo
-- ao utilizador de conexão (app_NACIONALDB).
-- Os outros nós (EmpréstimosProgramasDB, MateriaisDB, EventosBibliotecasDB)
-- criam database links que conectam como app_NACIONALDB a este nó.

GRANT SELECT ON usr_NACIONALDB.vw_leitor_publico TO app_NACIONALDB;

-- ============================================================
-- VW_AUDITORIA — interface padronizada de auditoria manual
-- Permite ao backend usar sempre a mesma query ("SELECT * FROM VW_AUDITORIA")
-- independentemente do nó onde está a correr.
-- Cada nó cria esta view no seu schema apontando para a sua própria
-- tabela de auditoria. O campo no_origem identifica o nó na interface.
-- ============================================================
CREATE OR REPLACE VIEW VW_AUDITORIA AS
SELECT
    id_auditoria,
    data_operacao,
    operacao,
    cod_funcionario,
    objeto_afetado,
    resultado,
    motivo_falha,
    nos_afetados,
    observacoes,
    'NACIONAL' AS no_origem
FROM AUDITORIA_OPERACOES;
/