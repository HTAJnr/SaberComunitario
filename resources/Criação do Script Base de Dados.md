---
created: 2025-10-08 22:00
tags: []
---
# Domínios e tamanhos Específicos

````sql
-- LEITOR  
num_cartao              VARCHAR2(12)   -- Fixo
nome_completo           VARCHAR2(100)  -- 2.5× nome médio
data_nasc               DATE
genero                  VARCHAR2(9)    -- Exato ('Masculino', 'Feminino')
nivel_escolar           VARCHAR2(20)   -- Exato ('Sem Escolaridade')
localizacao_leitor      VARCHAR2(200)  -- Endereço descritivo
contacto                VARCHAR2(20)   -- Tel internacional

-- ADULTO  
profissao               VARCHAR2(50)   -- "Agricultor", "Professor Secundário"

-- PROFESSOR  
escola_instituto        VARCHAR2(100)  -- Nome institucional
disciplina              VARCHAR2(50)   -- "Matemática", "História de Moçambique"
tipo_ensino             VARCHAR2(15)   -- Exato ('Universitário')

-- CRIANCA  
nome_responsavel        VARCHAR2(100)  -- Nome completo
telefone_responsavel    VARCHAR2(20)   -- Tel
escola_frequenta        VARCHAR2(100)  -- Nome escola

-- MATERIAL_BIBLIOGRAFICO  
id_material             NUMERIC         -- PK auto-increment
titulo                  VARCHAR2(200)  -- Título obra
autor                   VARCHAR2(100)  -- Nome autor
editora                 VARCHAR2(80)   -- Nome editora (empresas são +curtas)
ano_publicacao          NUMERIC(4)      -- YYYY
ISBN                    VARCHAR2(17)   -- Padrão
idioma                  VARCHAR2(30)   -- "Português", "Changana", "Emakhuwa"
num_paginas             NUMERIC(5)      -- Até 99999 páginas (Bíblia = ~1200)
estado_material_conservacao VARCHAR2(13) -- Exato ('Indisponível')
id_categoria            NUMERIC         -- FK
id_biblioteca           NUMERIC         -- FK
id_itemDoado            NUMERIC         -- FK       

-- LIVRO_FISICO  
localizacao_fisica      VARCHAR2(50)   -- Código prateleira

-- EBOOK  
formato                 VARCHAR2(4)    -- Exato ('EPUB')
tamanho_arquivo         NUMERIC(8,2)    -- MB (99999.99 MB = ~100GB)
url_acesso              VARCHAR2(300)  -- URL completo

-- PERIODICO  
edicao                  VARCHAR2(50)   -- "Nº 47/2025"
periodicidade           VARCHAR2(10)   -- Exato ('Trimestral')
data_publicacao         DATE
ISSN                    VARCHAR2(9)    -- Padrão

-- BIBLIOTECA  
id_biblioteca           NUMERIC
nome_biblioteca         VARCHAR2(100)  -- Nome institucional
localizacao             VARCHAR2(200)  -- Endereço
contacto_biblioteca     VARCHAR2(50)   -- Pode ter tel
id_responsavel          NUMERIC        -- FK

-- FUNCIONARIO  
id_funcionario          NUMERIC
nome_funcionario        VARCHAR2(100)
genero                  VARCHAR2(9)
contacto                VARCHAR2(20)
data_entrada            DATE
data_saida              DATE
id_funcao               NUMERIC 
id_biblioteca           NUMERIC 
email                   VARCHAR2(100)
senha                   VARCHAR2(64)

-- FUNCAO_FUNCIONARIO  
id_funcao               NUMERIC
nome_funcao             VARCHAR2(15)   -- Exato ('Coordenador')
nivel_acesso            VARCHAR2(15)   -- Exato ('Administrativo')

-- EMPRESTIMO  
id_emprestimo           NUMERIC
num_cartao              VARCHAR2(12)   -- FK
id_funcionario          NUMERIC
id_material             NUMERIC 
data_retirada           DATE
prazo_devolucao         DATE
data_devolucao          DATE
estado_material_saida   VARCHAR2(10)   -- Exato ('Degradado')
estado_material_retorno VARCHAR2(10)   -- Exato ('Perdido')
observacoes_devolucao   VARCHAR2(300)  -- Notas
multa_valor             NUMERIC(8,2)     -- MT (até 999999.99)
multa_paga              CHAR(1)       -- S/N Defalut N 
data_pagamento_multa    DATE 

-- CATEGORIA  
id_categoria            NUMERIC
area_tematica           VARCHAR2(50)   -- "Literatura", "Agricultura"
faixa_etaria            VARCHAR2(17)   -- Exato ('Todas as Idades')
nivel_leitura           VARCHAR2(12)   -- Exato ('Intermédio')

-- DOADOR  
id_doador               NUMERIC
nome_doador             VARCHAR2(100)  -- Nome/razão social
tipo_doador             VARCHAR2(13)   -- Exato ('Institucional')
contacto                VARCHAR2(50)
endereco                VARCHAR2(200)
observacoes             VARCHAR2(300)

-- DOACAO  
id_doacao               NUMERIC
id_doador               NUMERIC 
data_doacao             DATE

-- ITEM_DOACAO  
id_itemDoado            NUMERIC
id_doacao               NUMERIC 
id_biblioteca           NUMERIC 
observacoes             VARCHAR2(300)
valor_estimado          NUMERIC(10,2)   -- MT (até 99999999.99)
quantidade              NUMERIC(4)      -- Até 9999 itens por doação

-- EVENTO  
id_evento               NUMERIC
id_biblioteca           NUMERIC 
titulo_evento           VARCHAR2(100)
descricao_evento        VARCHAR2(500)
publico_alvo            VARCHAR2(22)   -- Exato ('Intermédios')
data_evento             DATE
recorrente              CHAR(1)        -- 'S'/'N'

-- EVENTO_RECURSO  
id_recurso              NUMERIC
id_evento               NUMERIC 
nome_recurso            VARCHAR2(100)  -- "Projetor LCD", "Cadeiras Plásticas"
quantidade              NUMERIC(4)

-- PARTICIPACAO_EVENTO  
id_participacao         NUMERIC
num_cartao              VARCHAR2(12) 
id_evento               NUMERIC
data_inscricao          DATE
presenca_confirmacao    CHAR(1)        -- 'S'/'N'

-- HORARIO_EV_BIB  
id_horario              NUMERIC
dia_semana              VARCHAR2(13)   -- Exato ('Segunda-feira')
hora_abertura           VARCHAR2(5)    -- "08:30"
hora_fecho              VARCHAR2(5)    -- "17:00"
id_evento               NUMERIC 
id_biblioteca           NUMERIC 

-- TRANSFERENCIA  
id_transferencia        NUMERIC
data_solicitacao        DATE
data_aprovacao_destino  DATE
data_conclusao          DATE
motivo                  VARCHAR2(300)
estado_transferencia    VARCHAR2(10)   -- Exato ('Concluída')
id_funcionario_solicitante NUMERIC  -- FK 
id_funcionario_aprovador   NUMERIC  -- FK
id_material             NUMERIC 
id_biblioteca_origem    NUMERIC 
id_biblioteca_destino   NUMERIC 

-- CERTIFICADO_DOACAO  
id_certificado          NUMERIC
numero_certificado      VARCHAR2(20)   -- "CERT-2025-000001
id_doacao               NUMERIC
original_numero         VARCHAR2(30)
data_emissao            DATE
tipo_certificado        VARCHAR2(10)   -- Exato ('Reemissão')
observacoes             VARCHAR2(300)
````


# Anatomia da Destruição Relacional

## Regra de Ouro

### CASCADE quando:

- **Dependência existencial:** filho não tem sentido sem pai
- **Composição:** filho é "parte de" pai (atributo multivalorado expandido)
- **Associação N:M:** registo associativo é pura conexão

### NO ACTION quando:

- **Histórico legal:** registos de transações (empréstimos, transferências)
- **Ativos patrimoniais:** materiais, bibliotecas (exigem relocação, não destruição)
- **Rastreabilidade:** certificados, doações (valor de auditoria)

## Matriz de Decisão do Projeto

| FK  | Tabela Filho        | Tabela Pai           | DELETE RULE | Razão                     |
| --- | ------------------- | -------------------- | ----------- | ------------------------- |
| ✓   | ADULTO              | LEITOR               | CASCADE     | Hierarquia                |
| ✓   | PROFESSOR           | ADULTO               | CASCADE     | Hierarquia                |
| ✓   | CRIANCA             | LEITOR               | CASCADE     | Hierarquia                |
| ✓   | LIVRO_FISICO        | MATERIAL             | CASCADE     | Hierarquia                |
| ✓   | EBOOK               | MATERIAL             | CASCADE     | Hierarquia                |
| ✓   | PERIODICO           | MATERIAL             | CASCADE     | Hierarquia                |
| ✓   | PARTICIPACAO_EVENTO | LEITOR               | CASCADE     | Associativa               |
| ✓   | PARTICIPACAO_EVENTO | EVENTO               | CASCADE     | Associativa               |
| ✓   | EVENTO_RECURSO      | EVENTO               | CASCADE     | Multivalor                |
| ✓   | ITEM_DOACAO         | DOACAO               | CASCADE     | Multivalor                |
| ✓   | HORARIO_EV_BIB      | BIBLIOTECA           | CASCADE     | Multivalor                |
| ✓   | HORARIO_EV_BIB      | EVENTO               | CASCADE     | Multivalor                |
| ✓   | CERTIFICADO_DOACAO  | DOACAO               | CASCADE     | Multivalor                |
| ⊗   | FUNCIONARIO         | BIBLIOTECA           | NO ACTION   | Ativo organizacional      |
| ⊗   | FUNCIONARIO         | FUNCAO_FUNCIONARIO   | NO ACTION   | Dados mestre              |
| ⊗   | MATERIAL            | BIBLIOTECA           | NO ACTION   | Ativo patrimonial         |
| ⊗   | MATERIAL            | CATEGORIA            | NO ACTION   | Dados mestre              |
| ⊗   | EMPRESTIMO          | LEITOR               | NO ACTION   | Histórico legal           |
| ⊗   | EMPRESTIMO          | FUNCIONARIO          | NO ACTION   | Auditoria                 |
| ⊗   | EMPRESTIMO          | MATERIAL             | NO ACTION   | Rastreabilidade           |
| ⊗   | TRANSFERENCIA       | MATERIAL             | NO ACTION   | Auditoria patrimonial     |
| ⊗   | TRANSFERENCIA       | BIBLIOTECA (origem)  | NO ACTION   | Histórico                 |
| ⊗   | TRANSFERENCIA       | BIBLIOTECA (destino) | NO ACTION   | Histórico                 |
| ⊗   | EVENTO              | BIBLIOTECA           | NO ACTION   | Histórico eventos         |
| ⊗   | DOACAO              | DOADOR               | NO ACTION   | Preserva histórico doador |
