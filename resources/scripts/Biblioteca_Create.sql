-- Tabelas de associação e dependentes primeiro
DROP TABLE PARTICIPACAO_PROGRAMA CASCADE CONSTRAINTS;
DROP TABLE PROGRAMA_FUNCIONARIO CASCADE CONSTRAINTS;
DROP TABLE PROGRAMA_MATERIAL CASCADE CONSTRAINTS;
DROP TABLE NIVEL_PROGRESSAO CASCADE CONSTRAINTS;
DROP TABLE PROGRAMA_ALFABETIZACAO CASCADE CONSTRAINTS;
DROP TABLE AVALIACAO_EVENTO CASCADE CONSTRAINTS;
DROP TABLE PARTICIPACAO_EVENTO CASCADE CONSTRAINTS;
DROP TABLE EVENTO_RECURSO CASCADE CONSTRAINTS;
DROP TABLE HORARIO_EVENTO CASCADE CONSTRAINTS;
DROP TABLE EVENTO CASCADE CONSTRAINTS;
DROP TABLE SUSPENSAO CASCADE CONSTRAINTS;
DROP TABLE EMPRESTIMO CASCADE CONSTRAINTS;
DROP TABLE TRANSFERENCIA CASCADE CONSTRAINTS;
DROP TABLE CERTIFICADO_DOACAO CASCADE CONSTRAINTS;
DROP TABLE ITEM_DOACAO CASCADE CONSTRAINTS;
DROP TABLE DOACAO CASCADE CONSTRAINTS;
DROP TABLE DOADOR CASCADE CONSTRAINTS;
DROP TABLE ADULTO_INTERESSE CASCADE CONSTRAINTS;
DROP TABLE PROFESSOR_DISCIPLINA CASCADE CONSTRAINTS;
DROP TABLE PROFESSOR CASCADE CONSTRAINTS;
DROP TABLE CRIANCA CASCADE CONSTRAINTS;
DROP TABLE ADULTO CASCADE CONSTRAINTS;
DROP TABLE LEITOR CASCADE CONSTRAINTS;
DROP TABLE FUNCIONARIO_HABILIDADE CASCADE CONSTRAINTS;
DROP TABLE HORARIO_FUNCIONARIO CASCADE CONSTRAINTS;
DROP TABLE BIBLIOTECA_RESPONSAVEL CASCADE CONSTRAINTS;
DROP TABLE FUNCIONARIO CASCADE CONSTRAINTS;
DROP TABLE FUNCAO_FUNCIONARIO CASCADE CONSTRAINTS;
DROP TABLE HORARIO_BIBLIOTECA CASCADE CONSTRAINTS;
DROP TABLE LIVRO_FISICO CASCADE CONSTRAINTS;
DROP TABLE EBOOK CASCADE CONSTRAINTS;
DROP TABLE PERIODICO CASCADE CONSTRAINTS;
DROP TABLE MATERIAL_BIBLIOGRAFICO CASCADE CONSTRAINTS;
DROP TABLE CATEGORIA CASCADE CONSTRAINTS;
DROP TABLE BIBLIOTECA CASCADE CONSTRAINTS;

-- ============================================================
-- BIBLIOTECA
-- ============================================================
CREATE TABLE BIBLIOTECA (
    cod_biblioteca      VARCHAR2(10 BYTE)   NOT NULL,
    nome_biblioteca     VARCHAR2(100 BYTE)  NOT NULL,
    provincia           VARCHAR2(17 BYTE)   NOT NULL,
    endereco            VARCHAR2(200 BYTE)  NOT NULL,
    latitude            NUMBER(9,6),
    longitude           NUMBER(9,6),
    contacto_biblioteca VARCHAR2(50 BYTE)   NOT NULL,
    data_inauguracao    DATE,
    capacidade          NUMBER(5),
    infraestrutura      VARCHAR2(500 BYTE),
    servicos            VARCHAR2(500 BYTE)
);
ALTER TABLE BIBLIOTECA
    ADD CONSTRAINT BIBLIOTECA_PK PRIMARY KEY (cod_biblioteca);
ALTER TABLE BIBLIOTECA
    ADD CONSTRAINT uq_nome_biblioteca UNIQUE (nome_biblioteca);
ALTER TABLE BIBLIOTECA
    ADD CONSTRAINT chk_provincia CHECK (
        provincia IN ('Cabo Delgado','Gaza','Inhambane','Manica',
                      'Maputo Provincia','Maputo Cidade','Nampula','Niassa',
                      'Sofala','Tete','Zambezia')
    );

-- ============================================================
-- HORARIO_BIBLIOTECA
-- ============================================================
CREATE TABLE HORARIO_BIBLIOTECA (
    id_horario_bib  NUMBER              NOT NULL,
    cod_biblioteca  VARCHAR2(10 BYTE)   NOT NULL,
    dia_semana      VARCHAR2(13 BYTE)   NOT NULL,
    hora_abertura   VARCHAR2(5 BYTE)    NOT NULL,
    hora_fecho      VARCHAR2(5 BYTE)    NOT NULL
);
ALTER TABLE HORARIO_BIBLIOTECA
    ADD CONSTRAINT HORARIO_BIBLIOTECA_PK PRIMARY KEY (id_horario_bib);

-- ============================================================
-- FUNCAO_FUNCIONARIO
-- ============================================================
CREATE TABLE FUNCAO_FUNCIONARIO (
    id_funcao   NUMBER              NOT NULL,
    nome_funcao VARCHAR2(15 BYTE)   NOT NULL,
    nivel_acesso VARCHAR2(15 BYTE)  NOT NULL
);
ALTER TABLE FUNCAO_FUNCIONARIO
    ADD CONSTRAINT FUNCAO_FUNCIONARIO_PK PRIMARY KEY (id_funcao);
ALTER TABLE FUNCAO_FUNCIONARIO
    ADD CONSTRAINT chk_nome_funcao
    CHECK (nome_funcao IN ('Administrador','Coordenador','Bibliotecario','Assistente'));
ALTER TABLE FUNCAO_FUNCIONARIO
    ADD CONSTRAINT chk_nivel_acesso
    CHECK (nivel_acesso IN ('Administrador','Coordenador','Bibliotecario','Assistente'));

-- ============================================================
-- FUNCIONARIO
-- ============================================================
CREATE TABLE FUNCIONARIO (
    cod_funcionario  VARCHAR2(12 BYTE)  NOT NULL,
    nome_funcionario VARCHAR2(100 BYTE) NOT NULL,
    genero           VARCHAR2(9 BYTE)   NOT NULL,
    data_nasc        DATE,
    contacto         VARCHAR2(50 BYTE)  NOT NULL,
    endereco         VARCHAR2(200 BYTE),
    formacao         VARCHAR2(100 BYTE),
    experiencia      VARCHAR2(300 BYTE),
    data_contratacao DATE               NOT NULL,
    data_demissao    DATE,
    cod_biblioteca   VARCHAR2(10 BYTE)  NOT NULL,
    id_funcao        NUMBER             NOT NULL,
    email            VARCHAR2(100 BYTE) NOT NULL,
    senha            VARCHAR2(64 BYTE)  NOT NULL
);
ALTER TABLE FUNCIONARIO
    ADD CONSTRAINT FUNCIONARIO_PK PRIMARY KEY (cod_funcionario);
ALTER TABLE FUNCIONARIO
    ADD CONSTRAINT uq_email_func UNIQUE (email);
ALTER TABLE FUNCIONARIO
    ADD CONSTRAINT chk_genero_func
    CHECK (genero IN ('Masculino','Feminino'));

-- ============================================================
-- FUNCIONARIO_HABILIDADE
-- ============================================================
CREATE TABLE FUNCIONARIO_HABILIDADE (
    cod_funcionario VARCHAR2(12 BYTE)  NOT NULL,
    habilidade      VARCHAR2(50 BYTE)  NOT NULL
);
ALTER TABLE FUNCIONARIO_HABILIDADE
    ADD CONSTRAINT FUNCIONARIO_HABILIDADE_PK PRIMARY KEY (cod_funcionario, habilidade);

-- ============================================================
-- HORARIO_FUNCIONARIO
-- ============================================================
CREATE TABLE HORARIO_FUNCIONARIO (
    id_horario_func  NUMBER              NOT NULL,
    cod_funcionario  VARCHAR2(12 BYTE)   NOT NULL,
    dia_semana       VARCHAR2(13 BYTE)   NOT NULL,
    hora_entrada     VARCHAR2(5 BYTE)    NOT NULL,
    hora_saida       VARCHAR2(5 BYTE)    NOT NULL
);
ALTER TABLE HORARIO_FUNCIONARIO
    ADD CONSTRAINT HORARIO_FUNCIONARIO_PK PRIMARY KEY (id_horario_func);

-- ============================================================
-- BIBLIOTECA_RESPONSAVEL
-- ============================================================
CREATE TABLE BIBLIOTECA_RESPONSAVEL (
    cod_biblioteca  VARCHAR2(10 BYTE)  NOT NULL,
    cod_funcionario VARCHAR2(12 BYTE)  NOT NULL,
    data_inicio     DATE               NOT NULL,
    data_fim        DATE,
    papel           VARCHAR2(12 BYTE)  NOT NULL
);
ALTER TABLE BIBLIOTECA_RESPONSAVEL
    ADD CONSTRAINT BIBLIOTECA_RESPONSAVEL_PK PRIMARY KEY (cod_biblioteca, cod_funcionario);
ALTER TABLE BIBLIOTECA_RESPONSAVEL
    ADD CONSTRAINT chk_papel_responsavel
    CHECK (papel IN ('Principal','Substituto'));

-- ============================================================
-- CATEGORIA
-- ============================================================
CREATE TABLE CATEGORIA (
    id_categoria  NUMBER              NOT NULL,
    area_tematica VARCHAR2(50 BYTE)   NOT NULL,
    faixa_etaria  VARCHAR2(17 BYTE)   NOT NULL,
    nivel_leitura VARCHAR2(12 BYTE)   NOT NULL
);
ALTER TABLE CATEGORIA
    ADD CONSTRAINT CATEGORIA_PK PRIMARY KEY (id_categoria);
ALTER TABLE CATEGORIA
    ADD CONSTRAINT chk_faixa_etaria
    CHECK (faixa_etaria IN ('Infantil','Juvenil','Adulto','Todas as Idades'));
ALTER TABLE CATEGORIA
    ADD CONSTRAINT chk_nivel_leitura
    CHECK (nivel_leitura IN ('Basico','Intermedio','Avancado'));

-- ============================================================
-- MATERIAL_BIBLIOGRAFICO
-- ============================================================
CREATE TABLE MATERIAL_BIBLIOGRAFICO (
    cod_material                VARCHAR2(12 BYTE)  NOT NULL,
    titulo                      VARCHAR2(200 BYTE) NOT NULL,
    autor                       VARCHAR2(200 BYTE) NOT NULL,
    editora                     VARCHAR2(80 BYTE)  NOT NULL,
    ano_publicacao              NUMBER(4)          NOT NULL,
    ISBN                        VARCHAR2(17 BYTE),
    idioma                      VARCHAR2(30 BYTE)  NOT NULL,
    num_paginas                 NUMBER(5)          NOT NULL,
    estado_material_conservacao VARCHAR2(13 BYTE)  NOT NULL,
    motivo_indisponibilidade    VARCHAR2(100 BYTE),
    origem_material             VARCHAR2(12 BYTE)  NOT NULL,
    data_aquisicao              DATE,
    valor_aquisicao             NUMBER(10,2),
    localizacao_estante         VARCHAR2(50 BYTE),
    cod_categoria               NUMBER             NOT NULL,
    cod_biblioteca              VARCHAR2(10 BYTE)  NOT NULL,
    id_itemDoado                NUMBER
);
ALTER TABLE MATERIAL_BIBLIOGRAFICO
    ADD CONSTRAINT MATERIAL_BIBLIOGRAFICO_PK PRIMARY KEY (cod_material);
ALTER TABLE MATERIAL_BIBLIOGRAFICO
    ADD CONSTRAINT chk_origem_material
    CHECK (origem_material IN ('Comprado','Doado','Transferido'));
ALTER TABLE MATERIAL_BIBLIOGRAFICO
    ADD CONSTRAINT chk_estado_conservacao
    CHECK (estado_material_conservacao IN ('Bom','Degradado','Indisponivel'));
ALTER TABLE MATERIAL_BIBLIOGRAFICO
    ADD CONSTRAINT chk_doado_item
    CHECK (origem_material != 'Doado' OR id_itemDoado IS NOT NULL);
ALTER TABLE MATERIAL_BIBLIOGRAFICO
    ADD CONSTRAINT chk_motivo_indisponivel
    CHECK (estado_material_conservacao != 'Indisponivel' OR motivo_indisponibilidade IS NOT NULL);

-- ============================================================
-- LIVRO_FISICO
-- ============================================================
CREATE TABLE LIVRO_FISICO (
    cod_material VARCHAR2(12 BYTE) NOT NULL
);
ALTER TABLE LIVRO_FISICO
    ADD CONSTRAINT LIVRO_FISICO_PK PRIMARY KEY (cod_material);

-- ============================================================
-- EBOOK
-- ============================================================
CREATE TABLE EBOOK (
    cod_material    VARCHAR2(12 BYTE) NOT NULL,
    formato         VARCHAR2(4 BYTE)  NOT NULL,
    tamanho_arquivo NUMBER(8,2),
    url_acesso      VARCHAR2(300 BYTE)
);
ALTER TABLE EBOOK
    ADD CONSTRAINT EBOOK_PK PRIMARY KEY (cod_material);
ALTER TABLE EBOOK
    ADD CONSTRAINT chk_url_formato
    CHECK (formato NOT IN ('PDF','EPUB','MOBI') OR url_acesso IS NOT NULL);

-- ============================================================
-- PERIODICO
-- ============================================================
CREATE TABLE PERIODICO (
    cod_material    VARCHAR2(12 BYTE) NOT NULL,
    edicao          VARCHAR2(50 BYTE) NOT NULL,
    periodicidade   VARCHAR2(10 BYTE) NOT NULL,
    data_publicacao DATE              NOT NULL,
    ISSN            VARCHAR2(9 BYTE)
);
ALTER TABLE PERIODICO
    ADD CONSTRAINT PERIODICO_PK PRIMARY KEY (cod_material);
ALTER TABLE PERIODICO
    ADD CONSTRAINT chk_periodicidade
    CHECK (periodicidade IN ('Mensal','Trimestral','Anual'));

-- ============================================================
-- LEITOR
-- ============================================================
CREATE TABLE LEITOR (
    num_cartao               VARCHAR2(12 BYTE)  NOT NULL,
    nome_completo            VARCHAR2(100 BYTE) NOT NULL,
    data_nasc                DATE               NOT NULL,
    genero                   VARCHAR2(9 BYTE)   NOT NULL,
    nivel_escolar            VARCHAR2(20 BYTE)  NOT NULL,
    localizacao_leitor       VARCHAR2(200 BYTE) NOT NULL,
    contacto                 VARCHAR2(50 BYTE),
    foto_path                VARCHAR2(300 BYTE),
    distancia_biblioteca     NUMBER(6,2)        NOT NULL,
    historico_pontualidade   VARCHAR2(10 BYTE)  DEFAULT 'Pontual' NOT NULL,
    cod_biblioteca           VARCHAR2(10 BYTE)  NOT NULL,
    status_leitor            VARCHAR2(12 BYTE)  DEFAULT 'Activo' NOT NULL
);
ALTER TABLE LEITOR
    ADD CONSTRAINT LEITOR_PK PRIMARY KEY (num_cartao);
ALTER TABLE LEITOR
    ADD CONSTRAINT chk_status_leitor
    CHECK (status_leitor IN ('Activo','Suspenso','Bloqueado'));
ALTER TABLE LEITOR
    ADD CONSTRAINT chk_historico_pontualidade
    CHECK (historico_pontualidade IN ('Pontual','Irregular','Mau'));
ALTER TABLE LEITOR
    ADD CONSTRAINT chk_genero_leitor
    CHECK (genero IN ('Masculino','Feminino'));

-- ============================================================
-- ADULTO
-- ============================================================
CREATE TABLE ADULTO (
    num_cartao     VARCHAR2(12 BYTE) NOT NULL,
    profissao      VARCHAR2(50 BYTE),
    nivel_literacia VARCHAR2(15 BYTE) NOT NULL
);
ALTER TABLE ADULTO
    ADD CONSTRAINT ADULTO_PK PRIMARY KEY (num_cartao);
ALTER TABLE ADULTO
    ADD CONSTRAINT chk_nivel_literacia
    CHECK (nivel_literacia IN ('Basico','Funcional','Avancado'));

-- ============================================================
-- ADULTO_INTERESSE
-- ============================================================
CREATE TABLE ADULTO_INTERESSE (
    num_cartao VARCHAR2(12 BYTE) NOT NULL,
    interesse  VARCHAR2(50 BYTE) NOT NULL
);
ALTER TABLE ADULTO_INTERESSE
    ADD CONSTRAINT ADULTO_INTERESSE_PK PRIMARY KEY (num_cartao, interesse);

-- ============================================================
-- PROFESSOR
-- ============================================================
CREATE TABLE PROFESSOR (
    num_cartao        VARCHAR2(12 BYTE) NOT NULL,
    escola_instituto  VARCHAR2(100 BYTE),
    nivel_ensino      VARCHAR2(15 BYTE) NOT NULL,
    num_alunos        NUMBER(5)
);
ALTER TABLE PROFESSOR
    ADD CONSTRAINT PROFESSOR_PK PRIMARY KEY (num_cartao);
ALTER TABLE PROFESSOR
    ADD CONSTRAINT chk_nivel_ensino
    CHECK (nivel_ensino IN ('Primario','Secundario','Tecnico','Universitario'));

-- ============================================================
-- PROFESSOR_DISCIPLINA
-- ============================================================
CREATE TABLE PROFESSOR_DISCIPLINA (
    num_cartao VARCHAR2(12 BYTE) NOT NULL,
    disciplina VARCHAR2(50 BYTE) NOT NULL
);
ALTER TABLE PROFESSOR_DISCIPLINA
    ADD CONSTRAINT PROFESSOR_DISCIPLINA_PK PRIMARY KEY (num_cartao, disciplina);

-- ============================================================
-- CRIANCA
-- ============================================================
CREATE TABLE CRIANCA (
    num_cartao          VARCHAR2(12 BYTE)  NOT NULL,
    nome_responsavel    VARCHAR2(100 BYTE) NOT NULL,
    telefone_responsavel VARCHAR2(20 BYTE),
    escola_frequenta    VARCHAR2(100 BYTE),
    classe              VARCHAR2(10 BYTE)
);
ALTER TABLE CRIANCA
    ADD CONSTRAINT CRIANCA_PK PRIMARY KEY (num_cartao);

-- ============================================================
-- DOADOR
-- ============================================================
CREATE TABLE DOADOR (
    id_doador  NUMBER              NOT NULL,
    nome_doador VARCHAR2(100 BYTE) NOT NULL,
    tipo_doador VARCHAR2(13 BYTE)  NOT NULL,
    contacto   VARCHAR2(50 BYTE),
    endereco   VARCHAR2(200 BYTE),
    observacoes VARCHAR2(300 BYTE)
);
ALTER TABLE DOADOR
    ADD CONSTRAINT DOADOR_PK PRIMARY KEY (id_doador);
ALTER TABLE DOADOR
    ADD CONSTRAINT chk_tipo_doador
    CHECK (tipo_doador IN ('Individual','Institucional'));

-- ============================================================
-- DOACAO
-- ============================================================
CREATE TABLE DOACAO (
    id_doacao  NUMBER  NOT NULL,
    id_doador  NUMBER  NOT NULL,
    data_doacao DATE   NOT NULL
);
ALTER TABLE DOACAO
    ADD CONSTRAINT DOACAO_PK PRIMARY KEY (id_doacao);

-- ============================================================
-- ITEM_DOACAO
-- ============================================================
CREATE TABLE ITEM_DOACAO (
    id_itemDoado  NUMBER              NOT NULL,
    id_doacao     NUMBER              NOT NULL,
    cod_biblioteca VARCHAR2(10 BYTE)  NOT NULL,
    quantidade    NUMBER(4)           NOT NULL,
    valor_estimado NUMBER(10,2)       NOT NULL,
    observacoes   VARCHAR2(300 BYTE)
);
ALTER TABLE ITEM_DOACAO
    ADD CONSTRAINT ITEM_DOACAO_PK PRIMARY KEY (id_itemDoado);

-- ============================================================
-- CERTIFICADO_DOACAO
-- ============================================================
CREATE TABLE CERTIFICADO_DOACAO (
    id_certificado  NUMBER              NOT NULL,
    num_certificado VARCHAR2(20 BYTE)   NOT NULL,
    id_doacao       NUMBER              NOT NULL,
    original_numero VARCHAR2(20 BYTE),
    data_emissao    DATE                NOT NULL,
    tipo_certificado VARCHAR2(10 BYTE)  NOT NULL,
    observacoes     VARCHAR2(300 BYTE)
);
ALTER TABLE CERTIFICADO_DOACAO
    ADD CONSTRAINT CERTIFICADO_DOACAO_PK PRIMARY KEY (id_certificado);
ALTER TABLE CERTIFICADO_DOACAO
    ADD CONSTRAINT uq_num_certificado UNIQUE (num_certificado);
ALTER TABLE CERTIFICADO_DOACAO
    ADD CONSTRAINT chk_tipo_cert
    CHECK (tipo_certificado IN ('Original','Reemissao','Honorifico'));

-- ============================================================
-- EMPRESTIMO
-- ============================================================
CREATE TABLE EMPRESTIMO (
    id_emprestimo           NUMBER              NOT NULL,
    num_cartao              VARCHAR2(12 BYTE)   NOT NULL,
    cod_funcionario         VARCHAR2(12 BYTE)   NOT NULL,
    cod_material            VARCHAR2(12 BYTE)   NOT NULL,
    data_retirada           DATE                NOT NULL,
    prazo_devolucao         DATE                NOT NULL,
    data_devolucao          DATE,
    estado_material_saida   VARCHAR2(10 BYTE)   NOT NULL,
    estado_material_retorno VARCHAR2(10 BYTE),
    observacoes_devolucao   VARCHAR2(300 BYTE),
    multa_valor             NUMBER(8,2),
    multa_paga              CHAR(1 BYTE)        DEFAULT 'N' NOT NULL,
    data_pagamento_multa    DATE
);
ALTER TABLE EMPRESTIMO
    ADD CONSTRAINT EMPRESTIMO_PK PRIMARY KEY (id_emprestimo);
ALTER TABLE EMPRESTIMO
    ADD CONSTRAINT chk_estado_saida
    CHECK (estado_material_saida IN ('Bom','Degradado'));
ALTER TABLE EMPRESTIMO
    ADD CONSTRAINT chk_estado_retorno
    CHECK (estado_material_retorno IN ('Bom','Degradado','Destruido','Perdido'));
ALTER TABLE EMPRESTIMO
    ADD CONSTRAINT chk_data_devolucao
    CHECK (data_devolucao IS NULL OR data_devolucao >= data_retirada);

-- ============================================================
-- SUSPENSAO
-- ============================================================
CREATE TABLE SUSPENSAO (
    id_suspensao     NUMBER              NOT NULL,
    num_cartao       VARCHAR2(12 BYTE)   NOT NULL,
    id_emprestimo    NUMBER              NOT NULL,
    data_inicio      DATE                NOT NULL,
    data_fim         DATE                NOT NULL,
    dias_suspensao   NUMBER(3)           NOT NULL,
    estado_suspensao VARCHAR2(10 BYTE)   DEFAULT 'Activa' NOT NULL,
    observacoes      VARCHAR2(300 BYTE)
);
ALTER TABLE SUSPENSAO
    ADD CONSTRAINT SUSPENSAO_PK PRIMARY KEY (id_suspensao);
ALTER TABLE SUSPENSAO
    ADD CONSTRAINT chk_estado_suspensao
    CHECK (estado_suspensao IN ('Activa','Cumprida','Reduzida'));
ALTER TABLE SUSPENSAO
    ADD CONSTRAINT chk_dias_suspensao
    CHECK (dias_suspensao IN (7,15,30,60));
ALTER TABLE SUSPENSAO
    ADD CONSTRAINT chk_data_fim_suspensao
    CHECK (data_fim > data_inicio);

-- ============================================================
-- TRANSFERENCIA
-- ============================================================
CREATE TABLE TRANSFERENCIA (
    id_transferencia             NUMBER              NOT NULL,
    data_solicitacao             DATE                NOT NULL,
    data_aprovacao_destino       DATE,
    data_conclusao               DATE,
    motivo                       VARCHAR2(300 BYTE),
    estado_transferencia         VARCHAR2(10 BYTE)   NOT NULL,
    cod_material                 VARCHAR2(12 BYTE)   NOT NULL,
    cod_biblioteca_origem        VARCHAR2(10 BYTE)   NOT NULL,
    cod_biblioteca_destino       VARCHAR2(10 BYTE)   NOT NULL,
    cod_funcionario_solicitante  VARCHAR2(12 BYTE)   NOT NULL,
    cod_funcionario_aprovador    VARCHAR2(12 BYTE)
);
ALTER TABLE TRANSFERENCIA
    ADD CONSTRAINT TRANSFERENCIA_PK PRIMARY KEY (id_transferencia);
ALTER TABLE TRANSFERENCIA
    ADD CONSTRAINT chk_estado_transferencia
    CHECK (estado_transferencia IN ('Pendente','Aprovada','Rejeitada','Concluida'));
ALTER TABLE TRANSFERENCIA
    ADD CONSTRAINT chk_origem_destino
    CHECK (cod_biblioteca_origem <> cod_biblioteca_destino);
ALTER TABLE TRANSFERENCIA
    ADD CONSTRAINT chk_motivo_rejeitada
    CHECK (estado_transferencia != 'Rejeitada' OR motivo IS NOT NULL);

-- ============================================================
-- EVENTO
-- ============================================================
CREATE TABLE EVENTO (
    id_evento                    NUMBER              NOT NULL,
    cod_biblioteca               VARCHAR2(10 BYTE)   NOT NULL,
    cod_funcionario_responsavel  VARCHAR2(12 BYTE),
    titulo_evento                VARCHAR2(100 BYTE)  NOT NULL,
    descricao_evento             VARCHAR2(500 BYTE),
    local_evento                 VARCHAR2(200 BYTE),
    publico_alvo                 VARCHAR2(22 BYTE)   NOT NULL,
    data_evento                  DATE                NOT NULL,
    capacidade                   NUMBER(4),
    status_evento                VARCHAR2(10 BYTE)   DEFAULT 'Planeado' NOT NULL,
    recorrente                   CHAR(1 BYTE)        NOT NULL
);
ALTER TABLE EVENTO
    ADD CONSTRAINT EVENTO_PK PRIMARY KEY (id_evento);
ALTER TABLE EVENTO
    ADD CONSTRAINT chk_status_evento
    CHECK (status_evento IN ('Planeado','Realizado','Cancelado'));
ALTER TABLE EVENTO
    ADD CONSTRAINT chk_publico_alvo_evento
    CHECK (publico_alvo IN ('Iniciantes','Intermedios','Avancados','Todos'));

-- ============================================================
-- HORARIO_EVENTO
-- ============================================================
CREATE TABLE HORARIO_EVENTO (
    id_horario_ev   NUMBER              NOT NULL,
    id_evento       NUMBER              NOT NULL,
    dia_semana      VARCHAR2(13 BYTE)   NOT NULL,
    data_ocorrencia DATE                NOT NULL,
    hora_inicio     VARCHAR2(5 BYTE)    NOT NULL,
    hora_fim        VARCHAR2(5 BYTE)    NOT NULL
);
ALTER TABLE HORARIO_EVENTO
    ADD CONSTRAINT HORARIO_EVENTO_PK PRIMARY KEY (id_horario_ev);

-- ============================================================
-- EVENTO_RECURSO
-- ============================================================
CREATE TABLE EVENTO_RECURSO (
    id_recurso   NUMBER              NOT NULL,
    id_evento    NUMBER              NOT NULL,
    nome_recurso VARCHAR2(100 BYTE)  NOT NULL,
    quantidade   NUMBER(4)           NOT NULL
);
ALTER TABLE EVENTO_RECURSO
    ADD CONSTRAINT EVENTO_RECURSO_PK PRIMARY KEY (id_recurso);

-- ============================================================
-- PARTICIPACAO_EVENTO
-- ============================================================
CREATE TABLE PARTICIPACAO_EVENTO (
    num_cartao          VARCHAR2(12 BYTE) NOT NULL,
    id_evento           NUMBER            NOT NULL,
    data_inscricao      DATE              NOT NULL,
    presenca_confirmacao CHAR(1 BYTE)     DEFAULT 'N' NOT NULL
);
ALTER TABLE PARTICIPACAO_EVENTO
    ADD CONSTRAINT PARTICIPACAO_EVENTO_PK PRIMARY KEY (num_cartao, id_evento);

-- ============================================================
-- AVALIACAO_EVENTO
-- ============================================================
CREATE TABLE AVALIACAO_EVENTO (
    id_avaliacao   NUMBER              NOT NULL,
    id_evento      NUMBER              NOT NULL,
    num_cartao     VARCHAR2(12 BYTE)   NOT NULL,
    nota           NUMBER(2)           NOT NULL,
    comentario     VARCHAR2(300 BYTE),
    data_avaliacao DATE                NOT NULL
);
ALTER TABLE AVALIACAO_EVENTO
    ADD CONSTRAINT AVALIACAO_EVENTO_PK PRIMARY KEY (id_avaliacao);
ALTER TABLE AVALIACAO_EVENTO
    ADD CONSTRAINT chk_nota
    CHECK (nota BETWEEN 1 AND 5);

-- ============================================================
-- PROGRAMA_ALFABETIZACAO
-- ============================================================
CREATE TABLE PROGRAMA_ALFABETIZACAO (
    cod_programa        VARCHAR2(18 BYTE)  NOT NULL,
    cod_biblioteca      VARCHAR2(10 BYTE)  NOT NULL,
    nome_programa       VARCHAR2(100 BYTE) NOT NULL,
    descricao           VARCHAR2(500 BYTE),
    publico_alvo        VARCHAR2(22 BYTE)  NOT NULL,
    duracao_semanas     NUMBER(3),
    metodologia         VARCHAR2(300 BYTE),
    resultados_esperados VARCHAR2(300 BYTE),
    estado_programa     VARCHAR2(10 BYTE)  DEFAULT 'Activo' NOT NULL
);
ALTER TABLE PROGRAMA_ALFABETIZACAO
    ADD CONSTRAINT PROGRAMA_ALFABETIZACAO_PK PRIMARY KEY (cod_programa);
ALTER TABLE PROGRAMA_ALFABETIZACAO
    ADD CONSTRAINT chk_estado_programa
    CHECK (estado_programa IN ('Activo','Concluido','Suspenso'));
ALTER TABLE PROGRAMA_ALFABETIZACAO
    ADD CONSTRAINT chk_publico_alvo_prog
    CHECK (publico_alvo IN ('Iniciantes','Intermedios','Avancados','Todos'));

-- ============================================================
-- NIVEL_PROGRESSAO
-- ============================================================
CREATE TABLE NIVEL_PROGRESSAO (
    id_nivel     NUMBER              NOT NULL,
    cod_programa VARCHAR2(18 BYTE)   NOT NULL,
    nome_nivel   VARCHAR2(50 BYTE)   NOT NULL,
    descricao    VARCHAR2(300 BYTE),
    ordem        NUMBER(2)           NOT NULL
);
ALTER TABLE NIVEL_PROGRESSAO
    ADD CONSTRAINT NIVEL_PROGRESSAO_PK PRIMARY KEY (id_nivel);

-- ============================================================
-- PROGRAMA_MATERIAL (N:M)
-- ============================================================
CREATE TABLE PROGRAMA_MATERIAL (
    cod_programa VARCHAR2(18 BYTE) NOT NULL,
    cod_material VARCHAR2(12 BYTE) NOT NULL,
    observacoes  VARCHAR2(200 BYTE)
);
ALTER TABLE PROGRAMA_MATERIAL
    ADD CONSTRAINT PROGRAMA_MATERIAL_PK PRIMARY KEY (cod_programa, cod_material);

-- ============================================================
-- PROGRAMA_FUNCIONARIO (N:M)
-- ============================================================
CREATE TABLE PROGRAMA_FUNCIONARIO (
    cod_programa    VARCHAR2(18 BYTE) NOT NULL,
    cod_funcionario VARCHAR2(12 BYTE) NOT NULL,
    papel           VARCHAR2(20 BYTE) NOT NULL
);
ALTER TABLE PROGRAMA_FUNCIONARIO
    ADD CONSTRAINT PROGRAMA_FUNCIONARIO_PK PRIMARY KEY (cod_programa, cod_funcionario);
ALTER TABLE PROGRAMA_FUNCIONARIO
    ADD CONSTRAINT chk_papel_prog_func
    CHECK (papel IN ('Responsavel','Instrutor','Auxiliar'));

-- ============================================================
-- PARTICIPACAO_PROGRAMA
-- ============================================================
CREATE TABLE PARTICIPACAO_PROGRAMA (
    num_cartao         VARCHAR2(12 BYTE) NOT NULL,
    cod_programa       VARCHAR2(18 BYTE) NOT NULL,
    id_nivel_atual     NUMBER,
    data_inscricao     DATE              NOT NULL,
    data_conclusao     DATE,
    estado_participacao VARCHAR2(10 BYTE) DEFAULT 'Activo' NOT NULL
);
ALTER TABLE PARTICIPACAO_PROGRAMA
    ADD CONSTRAINT PARTICIPACAO_PROGRAMA_PK PRIMARY KEY (num_cartao, cod_programa);
ALTER TABLE PARTICIPACAO_PROGRAMA
    ADD CONSTRAINT chk_estado_participacao
    CHECK (estado_participacao IN ('Activo','Concluido','Desistiu'));

-- HORARIO_BIBLIOTECA
ALTER TABLE HORARIO_BIBLIOTECA ADD CONSTRAINT HB_BIBLIOTECA_FK
    FOREIGN KEY (cod_biblioteca) REFERENCES BIBLIOTECA (cod_biblioteca) ON DELETE CASCADE;

-- FUNCIONARIO
ALTER TABLE FUNCIONARIO ADD CONSTRAINT FUNC_BIBLIOTECA_FK
    FOREIGN KEY (cod_biblioteca) REFERENCES BIBLIOTECA (cod_biblioteca);
ALTER TABLE FUNCIONARIO ADD CONSTRAINT FUNC_FUNCAO_FK
    FOREIGN KEY (id_funcao) REFERENCES FUNCAO_FUNCIONARIO (id_funcao);

-- FUNCIONARIO_HABILIDADE
ALTER TABLE FUNCIONARIO_HABILIDADE ADD CONSTRAINT FH_FUNCIONARIO_FK
    FOREIGN KEY (cod_funcionario) REFERENCES FUNCIONARIO (cod_funcionario) ON DELETE CASCADE;

-- HORARIO_FUNCIONARIO
ALTER TABLE HORARIO_FUNCIONARIO ADD CONSTRAINT HFUNC_FUNCIONARIO_FK
    FOREIGN KEY (cod_funcionario) REFERENCES FUNCIONARIO (cod_funcionario) ON DELETE CASCADE;

-- BIBLIOTECA_RESPONSAVEL
ALTER TABLE BIBLIOTECA_RESPONSAVEL ADD CONSTRAINT BR_BIBLIOTECA_FK
    FOREIGN KEY (cod_biblioteca) REFERENCES BIBLIOTECA (cod_biblioteca) ON DELETE CASCADE;
ALTER TABLE BIBLIOTECA_RESPONSAVEL ADD CONSTRAINT BR_FUNCIONARIO_FK
    FOREIGN KEY (cod_funcionario) REFERENCES FUNCIONARIO (cod_funcionario);

-- MATERIAL_BIBLIOGRAFICO
ALTER TABLE MATERIAL_BIBLIOGRAFICO ADD CONSTRAINT MB_CATEGORIA_FK
    FOREIGN KEY (cod_categoria) REFERENCES CATEGORIA (id_categoria);
ALTER TABLE MATERIAL_BIBLIOGRAFICO ADD CONSTRAINT MB_BIBLIOTECA_FK
    FOREIGN KEY (cod_biblioteca) REFERENCES BIBLIOTECA (cod_biblioteca);
ALTER TABLE MATERIAL_BIBLIOGRAFICO ADD CONSTRAINT MB_ITEMDOADO_FK
    FOREIGN KEY (id_itemDoado) REFERENCES ITEM_DOACAO (id_itemDoado);

-- LIVRO_FISICO / EBOOK / PERIODICO
ALTER TABLE LIVRO_FISICO ADD CONSTRAINT LF_MATERIAL_FK
    FOREIGN KEY (cod_material) REFERENCES MATERIAL_BIBLIOGRAFICO (cod_material) ON DELETE CASCADE;
ALTER TABLE EBOOK ADD CONSTRAINT EB_MATERIAL_FK
    FOREIGN KEY (cod_material) REFERENCES MATERIAL_BIBLIOGRAFICO (cod_material) ON DELETE CASCADE;
ALTER TABLE PERIODICO ADD CONSTRAINT PER_MATERIAL_FK
    FOREIGN KEY (cod_material) REFERENCES MATERIAL_BIBLIOGRAFICO (cod_material) ON DELETE CASCADE;

-- LEITOR
ALTER TABLE LEITOR ADD CONSTRAINT LEITOR_BIBLIOTECA_FK
    FOREIGN KEY (cod_biblioteca) REFERENCES BIBLIOTECA (cod_biblioteca);

-- ADULTO / PROFESSOR / CRIANCA
ALTER TABLE ADULTO ADD CONSTRAINT ADULTO_LEITOR_FK
    FOREIGN KEY (num_cartao) REFERENCES LEITOR (num_cartao) ON DELETE CASCADE;
ALTER TABLE ADULTO_INTERESSE ADD CONSTRAINT AI_ADULTO_FK
    FOREIGN KEY (num_cartao) REFERENCES ADULTO (num_cartao) ON DELETE CASCADE;
ALTER TABLE PROFESSOR ADD CONSTRAINT PROF_ADULTO_FK
    FOREIGN KEY (num_cartao) REFERENCES ADULTO (num_cartao) ON DELETE CASCADE;
ALTER TABLE PROFESSOR_DISCIPLINA ADD CONSTRAINT PD_PROFESSOR_FK
    FOREIGN KEY (num_cartao) REFERENCES PROFESSOR (num_cartao) ON DELETE CASCADE;
ALTER TABLE CRIANCA ADD CONSTRAINT CRIANCA_LEITOR_FK
    FOREIGN KEY (num_cartao) REFERENCES LEITOR (num_cartao) ON DELETE CASCADE;

-- DOACAO / ITEM_DOACAO / CERTIFICADO_DOACAO
ALTER TABLE DOACAO ADD CONSTRAINT DOA_DOADOR_FK
    FOREIGN KEY (id_doador) REFERENCES DOADOR (id_doador);
ALTER TABLE ITEM_DOACAO ADD CONSTRAINT ITEM_DOACAO_FK
    FOREIGN KEY (id_doacao) REFERENCES DOACAO (id_doacao) ON DELETE CASCADE;
ALTER TABLE ITEM_DOACAO ADD CONSTRAINT ITEM_BIBLIOTECA_FK
    FOREIGN KEY (cod_biblioteca) REFERENCES BIBLIOTECA (cod_biblioteca);
ALTER TABLE CERTIFICADO_DOACAO ADD CONSTRAINT CERT_DOACAO_FK
    FOREIGN KEY (id_doacao) REFERENCES DOACAO (id_doacao) ON DELETE CASCADE;

-- EMPRESTIMO
ALTER TABLE EMPRESTIMO ADD CONSTRAINT EMP_LEITOR_FK
    FOREIGN KEY (num_cartao) REFERENCES LEITOR (num_cartao);
ALTER TABLE EMPRESTIMO ADD CONSTRAINT EMP_FUNCIONARIO_FK
    FOREIGN KEY (cod_funcionario) REFERENCES FUNCIONARIO (cod_funcionario);
ALTER TABLE EMPRESTIMO ADD CONSTRAINT EMP_MATERIAL_FK
    FOREIGN KEY (cod_material) REFERENCES MATERIAL_BIBLIOGRAFICO (cod_material);

-- SUSPENSAO
ALTER TABLE SUSPENSAO ADD CONSTRAINT SUSP_LEITOR_FK
    FOREIGN KEY (num_cartao) REFERENCES LEITOR (num_cartao);
ALTER TABLE SUSPENSAO ADD CONSTRAINT SUSP_EMPRESTIMO_FK
    FOREIGN KEY (id_emprestimo) REFERENCES EMPRESTIMO (id_emprestimo);

-- TRANSFERENCIA
ALTER TABLE TRANSFERENCIA ADD CONSTRAINT TRANS_MATERIAL_FK
    FOREIGN KEY (cod_material) REFERENCES MATERIAL_BIBLIOGRAFICO (cod_material);
ALTER TABLE TRANSFERENCIA ADD CONSTRAINT TRANS_ORIGEM_FK
    FOREIGN KEY (cod_biblioteca_origem) REFERENCES BIBLIOTECA (cod_biblioteca);
ALTER TABLE TRANSFERENCIA ADD CONSTRAINT TRANS_DESTINO_FK
    FOREIGN KEY (cod_biblioteca_destino) REFERENCES BIBLIOTECA (cod_biblioteca);
ALTER TABLE TRANSFERENCIA ADD CONSTRAINT TRANS_SOLIC_FK
    FOREIGN KEY (cod_funcionario_solicitante) REFERENCES FUNCIONARIO (cod_funcionario);
ALTER TABLE TRANSFERENCIA ADD CONSTRAINT TRANS_APROV_FK
    FOREIGN KEY (cod_funcionario_aprovador) REFERENCES FUNCIONARIO (cod_funcionario);

-- EVENTO
ALTER TABLE EVENTO ADD CONSTRAINT EV_BIBLIOTECA_FK
    FOREIGN KEY (cod_biblioteca) REFERENCES BIBLIOTECA (cod_biblioteca);
ALTER TABLE EVENTO ADD CONSTRAINT EV_FUNCIONARIO_FK
    FOREIGN KEY (cod_funcionario_responsavel) REFERENCES FUNCIONARIO (cod_funcionario);

-- HORARIO_EVENTO / EVENTO_RECURSO / PARTICIPACAO_EVENTO / AVALIACAO_EVENTO
ALTER TABLE HORARIO_EVENTO ADD CONSTRAINT HEV_EVENTO_FK
    FOREIGN KEY (id_evento) REFERENCES EVENTO (id_evento) ON DELETE CASCADE;
ALTER TABLE EVENTO_RECURSO ADD CONSTRAINT EREC_EVENTO_FK
    FOREIGN KEY (id_evento) REFERENCES EVENTO (id_evento) ON DELETE CASCADE;
ALTER TABLE PARTICIPACAO_EVENTO ADD CONSTRAINT PE_LEITOR_FK
    FOREIGN KEY (num_cartao) REFERENCES LEITOR (num_cartao) ON DELETE CASCADE;
ALTER TABLE PARTICIPACAO_EVENTO ADD CONSTRAINT PE_EVENTO_FK
    FOREIGN KEY (id_evento) REFERENCES EVENTO (id_evento) ON DELETE CASCADE;
ALTER TABLE AVALIACAO_EVENTO ADD CONSTRAINT AE_EVENTO_FK
    FOREIGN KEY (id_evento) REFERENCES EVENTO (id_evento) ON DELETE CASCADE;
ALTER TABLE AVALIACAO_EVENTO ADD CONSTRAINT AE_LEITOR_FK
    FOREIGN KEY (num_cartao) REFERENCES LEITOR (num_cartao);

-- PROGRAMA_ALFABETIZACAO e relacionadas
ALTER TABLE PROGRAMA_ALFABETIZACAO ADD CONSTRAINT PROG_BIBLIOTECA_FK
    FOREIGN KEY (cod_biblioteca) REFERENCES BIBLIOTECA (cod_biblioteca);
ALTER TABLE NIVEL_PROGRESSAO ADD CONSTRAINT NP_PROGRAMA_FK
    FOREIGN KEY (cod_programa) REFERENCES PROGRAMA_ALFABETIZACAO (cod_programa) ON DELETE CASCADE;
ALTER TABLE PROGRAMA_MATERIAL ADD CONSTRAINT PM_PROGRAMA_FK
    FOREIGN KEY (cod_programa) REFERENCES PROGRAMA_ALFABETIZACAO (cod_programa) ON DELETE CASCADE;
ALTER TABLE PROGRAMA_MATERIAL ADD CONSTRAINT PM_MATERIAL_FK
    FOREIGN KEY (cod_material) REFERENCES MATERIAL_BIBLIOGRAFICO (cod_material);
ALTER TABLE PROGRAMA_FUNCIONARIO ADD CONSTRAINT PF_PROGRAMA_FK
    FOREIGN KEY (cod_programa) REFERENCES PROGRAMA_ALFABETIZACAO (cod_programa) ON DELETE CASCADE;
ALTER TABLE PROGRAMA_FUNCIONARIO ADD CONSTRAINT PF_FUNCIONARIO_FK
    FOREIGN KEY (cod_funcionario) REFERENCES FUNCIONARIO (cod_funcionario);
ALTER TABLE PARTICIPACAO_PROGRAMA ADD CONSTRAINT PP_LEITOR_FK
    FOREIGN KEY (num_cartao) REFERENCES LEITOR (num_cartao) ON DELETE CASCADE;
ALTER TABLE PARTICIPACAO_PROGRAMA ADD CONSTRAINT PP_PROGRAMA_FK
    FOREIGN KEY (cod_programa) REFERENCES PROGRAMA_ALFABETIZACAO (cod_programa) ON DELETE CASCADE;
ALTER TABLE PARTICIPACAO_PROGRAMA ADD CONSTRAINT PP_NIVEL_FK
    FOREIGN KEY (id_nivel_atual) REFERENCES NIVEL_PROGRESSAO (id_nivel);

