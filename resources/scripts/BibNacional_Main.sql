-- ============================================================
-- BibNacional_Main.sql — Script de instalação completo
-- Executar como SYSDBA:
--   sqlplus sys/bd2.isctem as sysdba @/caminho/BibNacional_Main.sql
-- ============================================================

-- 1. Tablespaces
@TP/BibNacional_Tablespaces.sql

-- 2. Utilizadores
@TP/BibNacional_Users.sql

-- 3. Roles e permissões
@TP/BibNacional_Roles.sql

-- Passa para o schema owner — o resto corre como usr_NACIONALDB
CONNECT usr_NACIONALDB/HTAJnr#020403@XE

-- 4. Estruturas base (tabelas + constraints)
@TP/BibNacional_Create.sql

-- 5. Sequências
@TP/BibNacional_Sequences.sql

-- 6. Views
@TP/BibNacional_Views.sql

-- 7. Funções
@TP/BibNacional_Functions.sql

-- 8. Procedimentos
@TP/BibNacional_Procedures.sql

-- 9. Triggers
@TP/BibNacional_Triggers.sql

-- 10. Índices
@TP/BibNacional_Indexes.sql

-- 11. Dados iniciais
@TP/BibNacional_Intro.sql
