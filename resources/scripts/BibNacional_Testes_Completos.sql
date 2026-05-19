-- ============================================================
-- BibNacional_Testes_Completos.sql
-- Documento de testes — BibliotecaNacionalDB (Hélder)
-- Cobre: Fase Comum + Fase 1 + Fase 2 + Tarefas Adicionais A1–A4
--
-- Executar como usr_NACIONALDB:
--   sqlplus usr_NACIONALDB/"HTAJnr#020403" @/root/TP/BibNacional_Testes_Completos.sql
--
-- Onde indicado, algumas queries requerem SYSDBA:
--   sqlplus sys/"bd2.isctem" as sysdba
-- ============================================================

PROMPT ============================================================
PROMPT SECÇÃO 0 — VERIFICAÇÃO DA INSTALAÇÃO BASE
PROMPT ============================================================

PROMPT --- 0.1 Tablespace e schema existem ---
SELECT TABLESPACE_NAME, STATUS FROM DBA_TABLESPACES WHERE TABLESPACE_NAME = 'TBS_NACIONALDB';
SELECT USERNAME, DEFAULT_TABLESPACE FROM DBA_USERS WHERE USERNAME IN ('USR_NACIONALDB','APP_NACIONALDB');

PROMPT --- 0.2 Visitor users criados ---
SELECT USERNAME, ACCOUNT_STATUS FROM DBA_USERS
 WHERE USERNAME IN ('APP_EMPRESTIMOSDB','APP_MATERIAISDB','APP_EVENTOSDB')
 ORDER BY USERNAME;

PROMPT --- 0.3 Roles criadas e atribuídas ---
SELECT GRANTEE, GRANTED_ROLE FROM DBA_ROLE_PRIVS
 WHERE GRANTEE IN ('APP_NACIONALDB','USR_NACIONALDB')
 ORDER BY GRANTEE;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 1 — DATABASE LINKS (Fase Comum)
PROMPT ============================================================

PROMPT --- 1.1 Links criados no schema ---
SELECT DB_LINK, USERNAME, HOST FROM USER_DB_LINKS ORDER BY DB_LINK;

PROMPT --- 1.2 Testar conectividade (requer nós online) ---
-- Descomentar quando os nós do Yannis/Yasin/Gerson estiverem online:
-- SELECT 'EMPRESTIMOSDB OK' AS link_status, SYSDATE FROM DUAL@emprestimosdb;
-- SELECT 'MATERIAISDB OK'   AS link_status, SYSDATE FROM DUAL@materiaisdb;
-- SELECT 'EVENTOSDB OK'     AS link_status, SYSDATE FROM DUAL@eventosdb;

PROMPT --- 1.3 ZeroTier links (remoto) ---
SELECT DB_LINK FROM USER_DB_LINKS WHERE DB_LINK LIKE 'Z%';


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 2 — SINÓNIMOS (Fase 2 — Transparência de Localização)
PROMPT ============================================================

PROMPT --- 2.1 Sinónimos criados ---
SELECT SYNONYM_NAME, TABLE_NAME, DB_LINK
  FROM USER_SYNONYMS
 ORDER BY SYNONYM_NAME;

PROMPT --- 2.2 Sinónimo BIBLIOTECA aponta para MV local ---
-- BIBLIOTECA deve apontar para biblioteca_snap (não directamente para @eventosdb)
SELECT SYNONYM_NAME, TABLE_NAME, DB_LINK
  FROM USER_SYNONYMS
 WHERE SYNONYM_NAME = 'BIBLIOTECA';


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 3 — SNAPSHOT / MATERIALIZED VIEW (Tarefa A1 — Tema 8.19)
PROMPT ============================================================

PROMPT --- 3.1 MV biblioteca_snap existe e tem dados ---
SELECT MVIEW_NAME, REFRESH_MODE, REFRESH_METHOD, BUILD_MODE, LAST_REFRESH_DATE
  FROM USER_MVIEWS
 ORDER BY MVIEW_NAME;

PROMPT --- 3.2 Contagem de registos na MV ---
SELECT COUNT(*) AS BIBLIOTECAS_NA_MV FROM biblioteca_snap;

PROMPT --- 3.3 Estrutura da MV (colunas) ---
SELECT COLUMN_NAME, DATA_TYPE, NULLABLE
  FROM USER_TAB_COLUMNS
 WHERE TABLE_NAME = 'BIBLIOTECA_SNAP'
 ORDER BY COLUMN_ID;

PROMPT --- 3.4 Conteúdo da MV ---
SELECT * FROM biblioteca_snap ORDER BY cod_biblioteca;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 4 — ESTRUTURA DAS TABELAS LOCAIS (Fase 1)
PROMPT ============================================================

PROMPT --- 4.1 Tabelas do schema ---
SELECT TABLE_NAME FROM USER_TABLES ORDER BY TABLE_NAME;

PROMPT --- 4.2 Constraints de integridade referencial ---
SELECT CONSTRAINT_NAME, TABLE_NAME, CONSTRAINT_TYPE, STATUS
  FROM USER_CONSTRAINTS
 WHERE CONSTRAINT_TYPE IN ('P','R','U','C')
 ORDER BY TABLE_NAME, CONSTRAINT_TYPE;

PROMPT --- 4.3 Sequências ---
SELECT SEQUENCE_NAME, MIN_VALUE, MAX_VALUE, INCREMENT_BY, LAST_NUMBER
  FROM USER_SEQUENCES
 ORDER BY SEQUENCE_NAME;

PROMPT --- 4.4 Dados de amostra — FUNCIONARIO ---
SELECT cod_funcionario, nome_funcionario, cod_biblioteca, data_demissao FROM FUNCIONARIO;

PROMPT --- 4.5 Dados de amostra — LEITOR ---
SELECT num_cartao, nome_completo, status_leitor, cod_biblioteca FROM LEITOR;

PROMPT --- 4.6 Dados de amostra — DOADOR e DOACAO ---
SELECT id_doador, nome_doador, tipo_doador FROM DOADOR;
SELECT id_doacao, id_doador, data_doacao FROM DOACAO;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 5 — FRAGMENTAÇÃO VERTICAL DE LEITOR (Fase 1 §1.3)
PROMPT ============================================================

PROMPT --- 5.1 Fragmento público (dados expostos a outros nós) ---
SELECT * FROM vw_leitor_publico ORDER BY num_cartao;

PROMPT --- 5.2 Fragmento privado (dados pessoais — exclusivos deste nó) ---
SELECT * FROM vw_leitor_privado ORDER BY num_cartao;

PROMPT --- 5.3 Validação — Reconstrução (JOIN deve igualar tabela base) ---
SELECT 'Linhas em LEITOR'       AS fonte, COUNT(*) AS total FROM LEITOR
UNION ALL
SELECT 'Linhas no JOIN pub+priv',
       COUNT(*) FROM (
           SELECT p.num_cartao FROM vw_leitor_publico p
           JOIN vw_leitor_privado r ON p.num_cartao = r.num_cartao
       );

PROMPT --- 5.4 Validação — Disjuntividade (num_cartao excluído — é a chave) ---
-- Na fragmentação vertical a chave primária (num_cartao) aparece em ambos —
-- isso é esperado e necessário para a Reconstrução. Todos os outros atributos
-- devem aparecer num único fragmento.
SELECT 'status_leitor em publico'  AS atributo, COUNT(*) FROM USER_TAB_COLUMNS
 WHERE TABLE_NAME='VW_LEITOR_PUBLICO' AND COLUMN_NAME='STATUS_LEITOR'
UNION ALL
SELECT 'status_leitor em privado', COUNT(*) FROM USER_TAB_COLUMNS
 WHERE TABLE_NAME='VW_LEITOR_PRIVADO' AND COLUMN_NAME='STATUS_LEITOR'
UNION ALL
SELECT 'contacto em publico', COUNT(*) FROM USER_TAB_COLUMNS
 WHERE TABLE_NAME='VW_LEITOR_PUBLICO' AND COLUMN_NAME='CONTACTO'
UNION ALL
SELECT 'contacto em privado', COUNT(*) FROM USER_TAB_COLUMNS
 WHERE TABLE_NAME='VW_LEITOR_PRIVADO' AND COLUMN_NAME='CONTACTO';


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 6 — FRAGMENTAÇÃO HORIZONTAL DE LEITOR (Tarefa A3 — Tema 8.10)
PROMPT ============================================================

PROMPT --- 6.1 Conteúdo de cada fragmento ---
SELECT 'Activos'    AS fragmento, COUNT(*) AS total FROM vw_frag_leitor_activos
UNION ALL
SELECT 'Suspensos',  COUNT(*) FROM vw_frag_leitor_suspensos
UNION ALL
SELECT 'Inactivos',  COUNT(*) FROM vw_frag_leitor_inactivos;

PROMPT --- 6.2 Validação — Completude (UNION ALL deve igualar tabela base) ---
SELECT 'Total em LEITOR'    AS fonte, COUNT(*) AS total FROM LEITOR
UNION ALL
SELECT 'Total nos fragmentos',
       (SELECT COUNT(*) FROM vw_frag_leitor_activos)
       + (SELECT COUNT(*) FROM vw_frag_leitor_suspensos)
       + (SELECT COUNT(*) FROM vw_frag_leitor_inactivos)
  FROM DUAL;

PROMPT --- 6.3 Validação — Disjuntividade (deve ser 0) ---
SELECT 'Activos nos suspensos'   AS cruzamento, COUNT(*) AS resultado
  FROM vw_frag_leitor_activos a
 WHERE a.num_cartao IN (SELECT num_cartao FROM vw_frag_leitor_suspensos)
UNION ALL
SELECT 'Activos nos inactivos', COUNT(*)
  FROM vw_frag_leitor_activos a
 WHERE a.num_cartao IN (SELECT num_cartao FROM vw_frag_leitor_inactivos)
UNION ALL
SELECT 'Suspensos nos inactivos', COUNT(*)
  FROM vw_frag_leitor_suspensos s
 WHERE s.num_cartao IN (SELECT num_cartao FROM vw_frag_leitor_inactivos);

PROMPT --- 6.4 Fragmento H1 — primeiros leitores activos ---
SELECT num_cartao, nome_completo, status_leitor FROM vw_frag_leitor_activos WHERE ROWNUM <= 5;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 7 — FRAGMENTAÇÃO MISTA DE FUNCIONARIO (Fase 2 §2.2)
PROMPT ============================================================

PROMPT --- 7.1 Vistas de fragmentação mista ---
SELECT VIEW_NAME FROM USER_VIEWS
 WHERE VIEW_NAME LIKE 'VW_FUNC%'
 ORDER BY VIEW_NAME;

PROMPT --- 7.2 Conteúdo de cada fragmento ---
SELECT 'Activos Operacional'     AS fragmento, COUNT(*) AS total FROM vw_func_activos_operacional
UNION ALL
SELECT 'Activos Confidencial',    COUNT(*) FROM vw_func_activos_confidencial
UNION ALL
SELECT 'Inactivos Operacional',   COUNT(*) FROM vw_func_inactivos_operacional
UNION ALL
SELECT 'Inactivos Confidencial',  COUNT(*) FROM vw_func_inactivos_confidencial;

PROMPT --- 7.3 Activos operacionais (dados expostos a outros nós) ---
SELECT cod_funcionario, nome_funcionario, cod_biblioteca, nivel_acesso
  FROM vw_func_activos_operacional;

PROMPT --- 7.4 Validação — soma activos + inactivos = total FUNCIONARIO ---
SELECT 'Total em FUNCIONARIO'     AS fonte, COUNT(*) AS total FROM FUNCIONARIO
UNION ALL
SELECT 'Activos + Inactivos',
       (SELECT COUNT(*) FROM vw_func_activos_operacional)
       + (SELECT COUNT(*) FROM vw_func_inactivos_operacional)
  FROM DUAL;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 8 — VISTAS GLOBAIS — TRANSPARÊNCIA DE LOCALIZAÇÃO (Fase 2 §2.5)
PROMPT ============================================================

PROMPT --- 8.1 Vistas globais existentes ---
SELECT VIEW_NAME FROM USER_VIEWS
 WHERE VIEW_NAME LIKE 'VW_GLOBAL%'
 ORDER BY VIEW_NAME;

-- Descomentar quando os nós estiverem online:
PROMPT --- 8.2 Vista global 1: leitores com empréstimos activos ---
-- SELECT * FROM vw_global_leitores_emprestimos WHERE ROWNUM <= 10;

PROMPT --- 8.3 Vista global 2: catálogo com disponibilidade ---
-- SELECT cod_material, titulo, nome_biblioteca, potencialmente_disponivel
--   FROM vw_global_catalogo WHERE ROWNUM <= 10;

PROMPT --- 8.4 Vista global 3: eventos e participação ---
-- SELECT id_evento, titulo_evento, data_evento, total_inscritos
--   FROM vw_global_eventos_participacao WHERE ROWNUM <= 10;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 9 — REPLICAÇÃO SÍNCRONA 2PC (Fase 2 §2.3)
PROMPT ============================================================

PROMPT --- 9.1 Procedimento prc_modificar_nivel_acesso existe ---
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME = 'PRC_MODIFICAR_NIVEL_ACESSO';

PROMPT --- 9.2 Procedimento prc_demo_2pc existe ---
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME = 'PRC_DEMO_2PC';

PROMPT --- 9.3 Verificar transacções 2PC pendentes (se houver) ---
-- (Requer SYSDBA ou SELECT em DBA_2PC_PENDING)
-- SELECT LOCAL_TRAN_ID, STATE, MIXED, ADVICE, TRAN_COMMENT
--   FROM DBA_2PC_PENDING;

PROMPT --- 9.4 Teste prc_demo_2pc (requer nós online) ---
-- Descomentar quando os nós estiverem acessíveis:
-- EXEC prc_demo_2pc;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 10 — REPLICAÇÃO ASSÍNCRONA (Fase 2 §2.4)
PROMPT ============================================================

PROMPT --- 10.1 Procedimento prc_sincronizar_funcionarios existe ---
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME = 'PRC_SINCRONIZAR_FUNCIONARIOS';

PROMPT --- 10.2 Vista de réplica (fonte de replicação) ---
SELECT * FROM vw_replica_funcionarios;

-- Descomentar quando nó do Yannis estiver online:
PROMPT --- 10.3 Executar sincronização ---
-- EXEC prc_sincronizar_funcionarios;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 11 — AUDITORIA MANUAL (Tabela AUDITORIA_OPERACOES)
PROMPT ============================================================

PROMPT --- 11.1 Estrutura da tabela de auditoria ---
SELECT COLUMN_NAME, DATA_TYPE, NULLABLE
  FROM USER_TAB_COLUMNS
 WHERE TABLE_NAME = 'AUDITORIA_OPERACOES'
 ORDER BY COLUMN_ID;

PROMPT --- 11.2 Registos de auditoria existentes ---
SELECT id_auditoria, data_operacao, operacao, cod_funcionario, objeto_afetado, resultado
  FROM AUDITORIA_OPERACOES
 ORDER BY data_operacao DESC;

PROMPT --- 11.3 Vista VW_AUDITORIA ---
SELECT * FROM VW_AUDITORIA ORDER BY data_operacao DESC;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 12 — AUDITORIA NATIVA ORACLE (Fase 2 §2.6)
PROMPT ============================================================

PROMPT --- 12.1 Políticas AUDIT activas para este schema ---
-- (Requer acesso a DBA_OBJ_AUDIT_OPTS ou SYSDBA)
-- SELECT OBJECT_NAME, ALT, AUD, COM, DEL, GRA, IND, INS, LOC, REN, SEL, UPD
--   FROM DBA_OBJ_AUDIT_OPTS
--  WHERE OWNER = 'USR_NACIONALDB'
--  ORDER BY OBJECT_NAME;

PROMPT --- 12.2 Registos na DBA_AUDIT_TRAIL (requer SYSDBA) ---
-- SELECT USERNAME, OBJ_NAME, ACTION_NAME, TIMESTAMP, RETURNCODE
--   FROM DBA_AUDIT_TRAIL
--  WHERE OWNER = 'USR_NACIONALDB'
--  ORDER BY TIMESTAMP DESC;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 13 — PROCEDURES E TRIGGERS
PROMPT ============================================================

PROMPT --- 13.1 Todos os objectos do schema ---
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_TYPE IN ('PROCEDURE','FUNCTION','TRIGGER','PACKAGE')
 ORDER BY OBJECT_TYPE, OBJECT_NAME;

PROMPT --- 13.2 Verificar que nenhum objecto está INVALID ---
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM USER_OBJECTS
 WHERE STATUS = 'INVALID'
 ORDER BY OBJECT_TYPE, OBJECT_NAME;

PROMPT --- 13.3 Teste registar_doacao_completa ---
-- Inserir um doador temporário para testar:
/*
DECLARE
    v_id_doacao NUMBER;
BEGIN
    registrar_doacao_completa(
        p_nome_doador    => 'Doador Teste',
        p_tipo_doador    => 'Individual',
        p_contacto       => '841234567',
        p_id_doacao      => v_id_doacao,
        p_data_doacao    => SYSDATE
    );
    DBMS_OUTPUT.PUT_LINE('Doação registada: id=' || v_id_doacao);
    ROLLBACK;
END;
/
*/

PROMPT --- 13.4 Trigger de certificado automático ---
SELECT TRIGGER_NAME, TRIGGERING_EVENT, STATUS
  FROM USER_TRIGGERS
 ORDER BY TRIGGER_NAME;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 14 — SAVEPOINTS (Fase 2 §2.5 — prc_apagar_leitor)
PROMPT ============================================================

PROMPT --- 14.1 Procedure prc_apagar_leitor existe ---
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME = 'PRC_APAGAR_LEITOR';

PROMPT --- 14.2 Fonte da procedure (verificar SAVEPOINTs) ---
SELECT TEXT FROM USER_SOURCE
 WHERE NAME = 'PRC_APAGAR_LEITOR'
 ORDER BY LINE;

PROMPT --- 14.3 PRAGMA AUTONOMOUS_TRANSACTION em prc_registar_auditoria ---
SELECT TEXT FROM USER_SOURCE
 WHERE NAME = 'PRC_REGISTAR_AUDITORIA'
   AND UPPER(TEXT) LIKE '%AUTONOMOUS%'
 ORDER BY LINE;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 15 — REGRAS DE NEGÓCIO (RN08 e RN10)
PROMPT ============================================================

PROMPT --- 15.1 Trigger ou procedure que implementa RN08 ---
-- RN08: limite de empréstimos simultâneos por leitor
-- (verificar trigger ou lógica no nó EmprestimosDB — cross-node)
SELECT OBJECT_NAME, OBJECT_TYPE FROM USER_OBJECTS
 WHERE UPPER(OBJECT_NAME) LIKE '%RN08%' OR UPPER(OBJECT_NAME) LIKE '%LIMITE%EMPR%';

PROMPT --- 15.2 RN10: validação de e-books para adultos ---
-- (verificar no nó MateriaisDB — este nó expõe vw_leitor_publico para isso)
SELECT SYNONYM_NAME FROM USER_SYNONYMS WHERE SYNONYM_NAME = 'LEITOR';


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 16 — VISITOR USERS E GRANTS CROSS-NODE
PROMPT ============================================================

PROMPT --- 16.1 Grants directos a visitor users ---
SELECT GRANTEE, TABLE_NAME, PRIVILEGE
  FROM USER_TAB_PRIVS_MADE
 WHERE GRANTEE IN ('APP_EMPRESTIMOSDB','APP_MATERIAISDB','APP_EVENTOSDB')
 ORDER BY GRANTEE, TABLE_NAME;

PROMPT --- 16.2 Verificar que roles não foram concedidas aos visitor users ---
-- (Roles não funcionam através de dblinks — grants directos são obrigatórios)
SELECT GRANTEE, GRANTED_ROLE FROM DBA_ROLE_PRIVS
 WHERE GRANTEE IN ('APP_EMPRESTIMOSDB','APP_MATERIAISDB','APP_EVENTOSDB');

PROMPT --- 16.3 Grants de execute a app_NACIONALDB (backend) ---
SELECT GRANTEE, TABLE_NAME AS OBJETO, PRIVILEGE
  FROM USER_TAB_PRIVS_MADE
 WHERE GRANTEE = 'APP_NACIONALDB'
 ORDER BY TABLE_NAME;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 17 — SET TRANSACTION READ ONLY (Tarefa A4 — Tema 9.11)
PROMPT ============================================================

PROMPT --- Executar bloco read-only ---
COMMIT;
SET TRANSACTION READ ONLY;

PROMPT --- SELECT 1: Leitores activos com empréstimos (snapshot cross-node) ---
-- SELECT l.num_cartao, l.nome_completo, l.status_leitor,
--        e.id_emprestimo, e.data_retirada
--   FROM LEITOR l
--   LEFT JOIN emprestimo@emprestimosdb e
--          ON e.num_cartao = l.num_cartao AND e.data_devolucao IS NULL
--  WHERE l.status_leitor = 'Activo';

PROMPT --- SELECT 2: Materiais disponíveis (snapshot cross-node) ---
-- SELECT cod_material, titulo, estado_material_conservacao
--   FROM material_bibliografico@materiaisdb
--  WHERE estado_material_conservacao != 'Indisponivel'
--  ORDER BY titulo;

PROMPT --- SELECT 3: Leitores por biblioteca (usa MV local) ---
SELECT b.cod_biblioteca, b.nome_biblioteca, COUNT(l.num_cartao) AS total_leitores
  FROM biblioteca_snap b
  LEFT JOIN LEITOR l ON l.cod_biblioteca = b.cod_biblioteca
 GROUP BY b.cod_biblioteca, b.nome_biblioteca
 ORDER BY b.cod_biblioteca;

COMMIT;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 18 — DEADLOCK (Tarefa A2 — Temas 9.16–9.19)
PROMPT ============================================================

PROMPT --- 18.1 Verificar dados para o cenário ---
SELECT id_doador, nome_doador FROM DOADOR WHERE ROWNUM <= 3;
SELECT id_doacao, id_doador   FROM DOACAO  WHERE ROWNUM <= 3;

PROMPT --- 18.2 Procedure de prevenção por ordem de bloqueio ---
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS FROM USER_OBJECTS
 WHERE OBJECT_NAME = 'PRC_ATUALIZAR_DOACAO_SEGURA';

PROMPT --- 18.3 Sessões activas (monitorização) ---
-- (Requer SELECT em V_$SESSION — executar como SYSDBA se necessário)
-- SELECT SID, SERIAL#, USERNAME, STATUS, PROGRAM
--   FROM V$SESSION WHERE USERNAME = 'USR_NACIONALDB';

PROMPT --- NOTA: O cenário completo de deadlock com ORA-00060 exige
PROMPT          duas sessões SQL*Plus simultâneas. Ver BibNacional_Deadlock_Demo.sql


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 19 — ÍNDICES
PROMPT ============================================================

PROMPT --- 19.1 Índices criados ---
SELECT INDEX_NAME, TABLE_NAME, UNIQUENESS, STATUS
  FROM USER_INDEXES
 ORDER BY TABLE_NAME, INDEX_NAME;


-- ============================================================
PROMPT ============================================================
PROMPT SECÇÃO 20 — RESUMO FINAL DE OBJECTOS
PROMPT ============================================================

PROMPT --- Contagem de objectos por tipo ---
SELECT OBJECT_TYPE, COUNT(*) AS TOTAL, SUM(CASE WHEN STATUS='VALID' THEN 1 ELSE 0 END) AS VALIDOS
  FROM USER_OBJECTS
 GROUP BY OBJECT_TYPE
 ORDER BY OBJECT_TYPE;

PROMPT --- Objectos inválidos (deve ser 0) ---
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM USER_OBJECTS
 WHERE STATUS != 'VALID'
 ORDER BY OBJECT_TYPE, OBJECT_NAME;

PROMPT ============================================================
PROMPT TESTES CONCLUÍDOS — BibliotecaNacionalDB
PROMPT ============================================================
