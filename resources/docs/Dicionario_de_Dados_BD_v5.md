# Sistema de Gestão de Bibliotecas Comunitárias
**Versão 5.0**

> **v5 — Alterações face à v4:**
> - `BIBLIOTECA`: nova coluna `ESTADO VARCHAR2(10)` — controla activação/desactivação da biblioteca na rede
> - `DOACAO`: nova coluna `COD_BIBLIOTECA VARCHAR2(10)` — biblioteca beneficiada ao nível da doação (não do item)
> - `ITEM_DOACAO`: novas colunas `NOME_ITEM VARCHAR2(200)` e `TIPO_ITEM VARCHAR2(20)`; coluna `COD_BIBLIOTECA` removida (movida para `DOACAO`)
> - `PERMISSAO_CARGO`: nova tabela — matriz de permissões granulares por cargo (módulo × acção)
> - `FUNCAO_FUNCIONARIO`: campo `descricao` documentado (suporte para gestão de cargos via API)

---

## Convenção de Códigos (PKs com formato significativo)

Tabelas com a palavra "código" no enunciado usam VARCHAR2 como PK com formato fixo. O código é **gerado no backend no momento do registo** e enviado já formatado para a BD no INSERT — não é gerado por trigger nem sequência Oracle.

| Tabela                   | Campo PK          | Formato             | Exemplo             | Tamanho      |
| ------------------------ | ----------------- | ------------------- | ------------------- | ------------ |
| `MATERIAL_BIBLIOGRAFICO` | `cod_material`    | `MAT20XXYYYY`       | `MAT20250001`       | VARCHAR2(12) |
| `BIBLIOTECA`             | `cod_biblioteca`  | `BIBXXXYYYY`        | `BIBMPM0001`        | VARCHAR2(10) |
| `FUNCIONARIO`            | `cod_funcionario` | `FUC20XXYYYY`       | `FUC20250042`       | VARCHAR2(12) |
| `PROGRAMA_ALFABETIZACAO` | `cod_programa`    | `PROBIBXXX20XXYYYY` | `PROBIBMPC20250001` | VARCHAR2(18) |

> **XXX** = 3 letras da província moçambicana (ex: `MPC` Maputo Cidade, `MPP` Maputo Província, `GZA` Gaza, `INH` Inhambane, `SOF` Sofala, `MAN` Manica, `TET` Tete, `ZAM` Zambézia, `NMP` Nampula, `CBD` Cabo Delgado, `NAS` Niassa).
> **20XX** = ano 4 dígitos. **YYYY** = sequencial 4 dígitos com zero-padding.

**`num_cartao` do LEITOR** segue o mesmo princípio — gerado no backend:

| Segmento | Significado                                                                   | Exemplo                                |
| -------- | ----------------------------------------------------------------------------- | -------------------------------------- |
| `XXX`    | 3 primeiras letras do nome da biblioteca onde o leitor se regista             | `BEI` (Biblioteca Esperança Inhambane) |
| `202X`   | Ano de registo (4 dígitos)                                                    | `2025`                                 |
| `YYYY`   | Sequencial de 4 dígitos com zero-padding, reiniciado por ano e por biblioteca | `0001`                                 |

> Exemplo completo: `BEI20250001` — primeiro leitor registado em 2025 na Biblioteca Esperança de Inhambane. Tamanho fixo: VARCHAR2(12).

---

## Domínios e Tamanhos Específicos

### LEITOR
| Atributo                 | Tipo     | Tamanho | Notas                                                                     |
| ------------------------ | -------- | ------- | ------------------------------------------------------------------------- |
| `num_cartao`             | VARCHAR2 | 12      | PK. Formato: `XXX202XYYYYY` — ver Convenção de Códigos. Gerado no backend |
| `nome_completo`          | VARCHAR2 | 100     | —                                                                         |
| `data_nasc`              | DATE     | —       | —                                                                         |
| `genero`                 | VARCHAR2 | 9       | `'Masculino'`, `'Feminino'`                                               |
| `nivel_escolar`          | VARCHAR2 | 20      | Ex: `'Sem Escolaridade'`, `'Primário Completo'`                           |
| `localizacao_leitor`     | VARCHAR2 | 200     | Endereço descritivo                                                       |
| `contacto`               | VARCHAR2 | 50      | Sem UNIQUE — RN11 (contacto partilhado com responsável)                   |
| `foto_path`              | VARCHAR2 | 300     | Nullable. Caminho do ficheiro no servidor                                 |
| `distancia_biblioteca`   | NUMBER   | (6,2)   | km até à biblioteca — usado em RN02                                       |
| `historico_pontualidade` | VARCHAR2 | 10      | DEFAULT `'Pontual'`. `'Pontual'`, `'Irregular'`, `'Mau'`                  |
| `cod_biblioteca`         | VARCHAR2 | 10      | FK → BIBLIOTECA (NO ACTION)                                               |
| `status_leitor`          | VARCHAR2 | 12      | DEFAULT `'Activo'`. `'Activo'`, `'Suspenso'`, `'Bloqueado'`               |

> `status_leitor = 'Suspenso'` é mantido por trigger com base na tabela `SUSPENSAO`. Não existe `data_fim_suspensao` em LEITOR.

---

### ADULTO
| Atributo          | Tipo     | Tamanho | Notas                                   |
| ----------------- | -------- | ------- | --------------------------------------- |
| `num_cartao`      | VARCHAR2 | 12      | PK + FK → LEITOR (CASCADE)              |
| `profissao`       | VARCHAR2 | 50      | Ex: `'Agricultor'`, `'Enfermeiro'`      |
| `nivel_literacia` | VARCHAR2 | 15      | `'Basico'`, `'Funcional'`, `'Avancado'` |

> `interesses` é atributo multivalorado → tabela própria `ADULTO_INTERESSE`

### ADULTO_INTERESSE
| Atributo     | Tipo     | Tamanho | Notas                                   |
| ------------ | -------- | ------- | --------------------------------------- |
| `num_cartao` | VARCHAR2 | 12      | PK + FK → ADULTO (CASCADE)              |
| `interesse`  | VARCHAR2 | 50      | PK. Ex: `'Agricultura'`, `'Literatura'` |

---

### PROFESSOR
| Atributo           | Tipo     | Tamanho | Notas                                                        |
| ------------------ | -------- | ------- | ------------------------------------------------------------ |
| `num_cartao`       | VARCHAR2 | 12      | PK + FK → ADULTO (CASCADE)                                   |
| `escola_instituto` | VARCHAR2 | 100     | Nome institucional                                           |
| `nivel_ensino`     | VARCHAR2 | 15      | `'Primario'`, `'Secundario'`, `'Tecnico'`, `'Universitario'` |
| `num_alunos`       | NUMBER   | (5)     | Número de alunos                                             |

> `disciplinas` é atributo multivalorado → tabela própria `PROFESSOR_DISCIPLINA`

### PROFESSOR_DISCIPLINA
| Atributo     | Tipo     | Tamanho | Notas                                              |
| ------------ | -------- | ------- | -------------------------------------------------- |
| `num_cartao` | VARCHAR2 | 12      | PK + FK → PROFESSOR (CASCADE)                      |
| `disciplina` | VARCHAR2 | 50      | PK. Ex: `'Matemática'`, `'História de Moçambique'` |

---

### CRIANCA
| Atributo               | Tipo     | Tamanho | Notas                             |
| ---------------------- | -------- | ------- | --------------------------------- |
| `num_cartao`           | VARCHAR2 | 12      | PK + FK → LEITOR (CASCADE)        |
| `nome_responsavel`     | VARCHAR2 | 100     | Nome completo do responsável      |
| `telefone_responsavel` | VARCHAR2 | 20      | Contacto do responsável           |
| `escola_frequenta`     | VARCHAR2 | 100     | Nome da escola                    |
| `classe`               | VARCHAR2 | 10      | Ex: `'5ª Classe'`, `'12ª Classe'` |

> Responsável não é modelado como FK — pode não ser leitor registado. Sem bloqueios de DELETE.

---

### MATERIAL_BIBLIOGRAFICO
| Atributo                      | Tipo     | Tamanho | Notas                                                                                                           |
| ----------------------------- | -------- | ------- | --------------------------------------------------------------------------------------------------------------- |
| `cod_material`                | VARCHAR2 | 12      | PK. Formato: `MAT20XXYYYY`. Gerado por trigger + sequência                                                      |
| `titulo`                      | VARCHAR2 | 200     | —                                                                                                               |
| `autor`                       | VARCHAR2 | 200     | Campo único. Múltiplos autores separados por vírgula. Ex: `'Silva, J., Costa, M.'`                              |
| `editora`                     | VARCHAR2 | 80      | —                                                                                                               |
| `ano_publicacao`              | NUMBER   | (4)     | YYYY                                                                                                            |
| `ISBN`                        | VARCHAR2 | 17      | Nullable                                                                                                        |
| `idioma`                      | VARCHAR2 | 30      | Ex: `'Português'`, `'Changana'`, `'Emakhuwa'`                                                                   |
| `num_paginas`                 | NUMBER   | (5)     | Até 99.999 páginas                                                                                              |
| `estado_material_conservacao` | VARCHAR2 | 13      | `'Bom'`, `'Degradado'`, `'Indisponivel'`                                                                        |
| `motivo_indisponibilidade`    | VARCHAR2 | 100     | Nullable. Obrigatório quando `estado = 'Indisponivel'`. Ex: `'Perdido em empréstimo'`, `'Destruído'`, `'Extraviado'` |
| `origem_material`             | VARCHAR2 | 12      | `'Comprado'`, `'Doado'`, `'Transferido'`. Detalhe do doador/biblioteca via JOIN                                 |
| `data_aquisicao`              | DATE     | —       | Nullable. Se `'Doado'`: valor de `DOACAO.data_doacao` via backend                                               |
| `valor_aquisicao`             | NUMBER   | (10,2)  | Nullable. MT. Se `'Doado'`: valor de `ITEM_DOACAO.valor_estimado` via backend                                   |
| `localizacao_estante`         | VARCHAR2 | 50      | Nullable. Ex: `'A2-EST3-001'`. E-books digitais (PDF/EPUB/MOBI) ficam NULL                                      |
| `cod_categoria`               | NUMBER   | —       | FK → CATEGORIA (NO ACTION)                                                                                      |
| `cod_biblioteca`              | VARCHAR2 | 10      | FK → BIBLIOTECA (NO ACTION)                                                                                     |
| `id_itemDoado`                | NUMBER   | —       | Nullable. FK → ITEM_DOACAO (NO ACTION). Só preenchido se `origem_material = 'Doado'`                            |

> **`estado_material_conservacao`:** `'Indisponivel'` é o estado permanente após perda (RN03.3 / RN05). O valor `'Perdido'` existe apenas em `EMPRESTIMO.estado_material_retorno` — não aqui. `motivo_indisponibilidade` garante rastreabilidade futura.

### LIVRO_FISICO
| Atributo       | Tipo     | Tamanho | Notas                                      |
| -------------- | -------- | ------- | ------------------------------------------ |
| `cod_material` | VARCHAR2 | 12      | PK + FK → MATERIAL_BIBLIOGRAFICO (CASCADE) |

> `localizacao_estante` está em MATERIAL_BIBLIOGRAFICO — aplica-se também a e-books em suporte físico (CD/PEN).

### EBOOK
| Atributo          | Tipo     | Tamanho | Notas                                              |
| ----------------- | -------- | ------- | -------------------------------------------------- |
| `cod_material`    | VARCHAR2 | 12      | PK + FK → MATERIAL_BIBLIOGRAFICO (CASCADE)         |
| `formato`         | VARCHAR2 | 4       | `'PDF'`, `'EPUB'`, `'MOBI'`, `'CD'`, `'PEN'`       |
| `tamanho_arquivo` | NUMBER   | (8,2)   | Nullable — CD/PEN podem não ter tamanho digital    |
| `url_acesso`      | VARCHAR2 | 300     | Nullable — CD/PEN não têm URL                      |

> **CHECK (RN09):** `CHECK (formato NOT IN ('PDF','EPUB','MOBI') OR url_acesso IS NOT NULL)`

### PERIODICO
| Atributo          | Tipo     | Tamanho | Notas                                      |
| ----------------- | -------- | ------- | ------------------------------------------ |
| `cod_material`    | VARCHAR2 | 12      | PK + FK → MATERIAL_BIBLIOGRAFICO (CASCADE) |
| `edicao`          | VARCHAR2 | 50      | Ex: `'Nº 47/2025'`                         |
| `periodicidade`   | VARCHAR2 | 10      | `'Mensal'`, `'Trimestral'`, `'Anual'`      |
| `data_publicacao` | DATE     | —       | —                                          |
| `ISSN`            | VARCHAR2 | 9       | Nullable                                   |

---

### CATEGORIA
| Atributo        | Tipo     | Tamanho | Notas                                                      |
| --------------- | -------- | ------- | ---------------------------------------------------------- |
| `id_categoria`  | NUMBER   | —       | PK                                                         |
| `area_tematica` | VARCHAR2 | 50      | Ex: `'Literatura'`, `'Agricultura'`                        |
| `faixa_etaria`  | VARCHAR2 | 17      | `'Infantil'`, `'Juvenil'`, `'Adulto'`, `'Todas as Idades'` |
| `nivel_leitura` | VARCHAR2 | 12      | `'Basico'`, `'Intermedio'`, `'Avancado'`                   |

---

### BIBLIOTECA *(alterada em v5)*
| Atributo              | Tipo     | Tamanho | Notas                                                     |
| --------------------- | -------- | ------- | --------------------------------------------------------- |
| `cod_biblioteca`      | VARCHAR2 | 10      | PK. Formato: `BIBXXXYYYY`. Gerado por trigger + sequência |
| `nome_biblioteca`     | VARCHAR2 | 100     | UNIQUE                                                    |
| `endereco`            | VARCHAR2 | 200     | Endereço descritivo                                       |
| `latitude`            | NUMBER   | (9,6)   | Nullable. Ex: `-25.966115`                                |
| `longitude`           | NUMBER   | (9,6)   | Nullable. Ex: `32.573229`                                 |
| `contacto_biblioteca` | VARCHAR2 | 50      | —                                                         |
| `data_inauguracao`    | DATE     | —       | Nullable                                                  |
| `capacidade`          | NUMBER   | (5)     | Nullable. Número de lugares/pessoas                       |
| `infraestrutura`      | VARCHAR2 | 500     | Nullable. Descrição livre                                 |
| `servicos`            | VARCHAR2 | 500     | Nullable. Descrição livre                                 |
| `provincia`           | VARCHAR2 | 17      | `Maputo Provincia`                                        |
| `estado`              | VARCHAR2 | 10      | **[v5]** DEFAULT `'Activo'`. CHECK `IN ('Activo','Inactivo')`. Controla activação/desactivação da biblioteca na rede |

> Responsáveis: tabela `BIBLIOTECA_RESPONSAVEL`. Horário de funcionamento: tabela `HORARIO_BIBLIOTECA`.
> `provincia` serve para criação do código e controle. `estado` é gerido exclusivamente por Administradores (RN13).

### HORARIO_BIBLIOTECA
| Atributo         | Tipo     | Tamanho | Notas                                   |
| ---------------- | -------- | ------- | --------------------------------------- |
| `id_horario_bib` | NUMBER   | —       | PK                                      |
| `cod_biblioteca` | VARCHAR2 | 10      | FK → BIBLIOTECA (CASCADE)               |
| `dia_semana`     | VARCHAR2 | 13      | `'Segunda-feira'` … `'Domingo'`         |
| `hora_abertura`  | VARCHAR2 | 5       | Formato `'HH:MM'`. Ex: `'08:00'`        |
| `hora_fecho`     | VARCHAR2 | 5       | Formato `'HH:MM'`. Ex: `'17:00'`        |

> Usada por RN07: `hora_inicio >= hora_abertura AND hora_fim <= hora_fecho`.

### BIBLIOTECA_RESPONSAVEL
| Atributo          | Tipo     | Tamanho | Notas                                        |
| ----------------- | -------- | ------- | -------------------------------------------- |
| `cod_biblioteca`  | VARCHAR2 | 10      | PK + FK → BIBLIOTECA (CASCADE)               |
| `cod_funcionario` | VARCHAR2 | 12      | PK + FK → FUNCIONARIO (NO ACTION)            |
| `data_inicio`     | DATE     | —       | Data de início da responsabilidade           |
| `data_fim`        | DATE     | —       | Nullable — NULL = responsável actual         |
| `papel`           | VARCHAR2 | 12      | `'Principal'`, `'Substituto'`                |

> NO ACTION para FUNCIONARIO — responsável histórico não pode ser eliminado sem intervenção manual.

---

### FUNCIONARIO
| Atributo           | Tipo     | Tamanho | Notas                                                      |
| ------------------ | -------- | ------- | ---------------------------------------------------------- |
| `cod_funcionario`  | VARCHAR2 | 12      | PK. Formato: `FUC20XXYYYY`. Gerado por trigger + sequência |
| `nome_funcionario` | VARCHAR2 | 100     | —                                                          |
| `genero`           | VARCHAR2 | 9       | `'Masculino'`, `'Feminino'`                                |
| `data_nasc`        | DATE     | —       | Nullable                                                   |
| `contacto`         | VARCHAR2 | 50      | —                                                          |
| `endereco`         | VARCHAR2 | 200     | Nullable                                                   |
| `formacao`         | VARCHAR2 | 100     | Nullable. Ex: `'Licenciatura em Biblioteconomia'`          |
| `experiencia`      | VARCHAR2 | 300     | Nullable                                                   |
| `data_contratacao` | DATE     | —       | Data de início do vínculo laboral                          |
| `data_demissao`    | DATE     | —       | Nullable. Preenchido na saída do funcionário               |
| `cod_biblioteca`   | VARCHAR2 | 10      | FK → BIBLIOTECA (NO ACTION)                                |
| `id_funcao`        | NUMBER   | —       | FK → FUNCAO_FUNCIONARIO (NO ACTION)                        |
| `email`            | VARCHAR2 | 100     | UNIQUE                                                     |
| `senha`            | VARCHAR2 | 64      | Hash SHA-256                                               |

> `habilidades`: tabela `FUNCIONARIO_HABILIDADE`. Horário semanal: tabela `HORARIO_FUNCIONARIO`.

### FUNCIONARIO_HABILIDADE
| Atributo          | Tipo     | Tamanho | Notas                                       |
| ----------------- | -------- | ------- | ------------------------------------------- |
| `cod_funcionario` | VARCHAR2 | 12      | PK + FK → FUNCIONARIO (CASCADE)             |
| `habilidade`      | VARCHAR2 | 50      | PK. Ex: `'Catalogação'`, `'Língua Inglesa'` |

### HORARIO_FUNCIONARIO
| Atributo          | Tipo     | Tamanho | Notas                                                                                                       |
| ----------------- | -------- | ------- | ----------------------------------------------------------------------------------------------------------- |
| `id_horario_func` | NUMBER   | —       | PK                                                                                                          |
| `cod_funcionario` | VARCHAR2 | 12      | FK → FUNCIONARIO (CASCADE)                                                                                  |
| `dia_semana`      | VARCHAR2 | 13      | `'Segunda-feira'`, `'Terça-feira'`, `'Quarta-feira'`, `'Quinta-feira'`, `'Sexta-feira'`, `'Sábado'`, `'Domingo'` |
| `hora_entrada`    | VARCHAR2 | 5       | Formato `'HH:MM'`. Ex: `'07:30'`                                                                            |
| `hora_saida`      | VARCHAR2 | 5       | Formato `'HH:MM'`. Ex: `'16:00'`                                                                            |

> Cada linha = um turno num dia. Um funcionário tem uma linha por dia trabalhado.

### FUNCAO_FUNCIONARIO
| Atributo       | Tipo     | Tamanho | Notas                                                                 |
| -------------- | -------- | ------- | --------------------------------------------------------------------- |
| `id_funcao`    | NUMBER   | —       | PK                                                                    |
| `nome_funcao`  | VARCHAR2 | 15      | `'Administrador'`, `'Coordenador'`, `'Bibliotecario'`, `'Assistente'` |
| `nivel_acesso` | VARCHAR2 | 15      | `'Administrador'`, `'Coordenador'`, `'Bibliotecario'`, `'Assistente'` |
| `descricao`    | VARCHAR2 | 300     | Nullable. Descrição livre do cargo                                    |

> `PERMISSAO_CARGO` (nova em v5) permite definir a matriz de permissões por módulo/acção para cada `id_funcao`.

### PERMISSAO_CARGO *(nova em v5)*
| Atributo        | Tipo     | Tamanho | Notas                                                                                |
| --------------- | -------- | ------- | ------------------------------------------------------------------------------------ |
| `id_permissao`  | NUMBER   | —       | PK. Gerado por SEQ_PERMISSAO                                                         |
| `id_funcao`     | NUMBER   | —       | NOT NULL. FK → FUNCAO_FUNCIONARIO (NO ACTION)                                        |
| `modulo`        | VARCHAR2 | 50      | NOT NULL. Ex: `'leitores'`, `'emprestimos'`, `'materiais'`, `'eventos'`, `'doacoes'` |
| `accao`         | VARCHAR2 | 30      | NOT NULL. Ex: `'ver'`, `'criar'`, `'editar'`, `'eliminar'`, `'alterar_status'`       |
| `permitido`     | NUMBER   | (1)     | DEFAULT `1`. CHECK `IN (0,1)`. `1` = concedido, `0` = revogado                      |

**Constraints:**
- `pk_permissao_cargo` — PRIMARY KEY (`id_permissao`)
- `fk_perm_funcao` — FOREIGN KEY (`id_funcao`) REFERENCES FUNCAO_FUNCIONARIO (NO ACTION)
- `chk_permitido` — CHECK (`permitido IN (0,1)`)
- `uq_perm_cargo_modulo_accao` — UNIQUE (`id_funcao`, `modulo`, `accao`) — evita duplicados por par (módulo, acção)

**Sequência:** `SEQ_PERMISSAO START WITH 1 INCREMENT BY 1 NOCACHE`

> A tabela define a matriz completa de permissões. Para um cargo, a ausência de linha equivale a não ter permissão. `permitido = 0` é uma revogação explícita útil para auditar permissões negadas. O backend verifica `PERMISSAO_CARGO` em complemento ao `nivel_acesso` herdado de `FUNCAO_FUNCIONARIO`.

---

### EMPRESTIMO
| Atributo                  | Tipo     | Tamanho | Notas                                                        |
| ------------------------- | -------- | ------- | ------------------------------------------------------------ |
| `id_emprestimo`           | NUMBER   | —       | PK                                                           |
| `num_cartao`              | VARCHAR2 | 12      | FK → LEITOR (NO ACTION)                                      |
| `cod_funcionario`         | VARCHAR2 | 12      | FK → FUNCIONARIO (NO ACTION)                                 |
| `cod_material`            | VARCHAR2 | 12      | FK → MATERIAL_BIBLIOGRAFICO (NO ACTION)                      |
| `data_retirada`           | DATE     | —       | —                                                            |
| `prazo_devolucao`         | DATE     | —       | Calculado via RN02 e passado no INSERT                       |
| `data_devolucao`          | DATE     | —       | Nullable até devolução                                       |
| `estado_material_saida`   | VARCHAR2 | 10      | `'Bom'`, `'Degradado'`                                       |
| `estado_material_retorno` | VARCHAR2 | 10      | Nullable. `'Bom'`, `'Degradado'`, `'Destruido'`, `'Perdido'` |
| `observacoes_devolucao`   | VARCHAR2 | 300     | Nullable                                                     |
| `multa_valor`             | NUMBER   | (8,2)   | Nullable até devolução                                       |
| `multa_paga`              | CHAR     | 1       | DEFAULT `'N'`. `'S'`/`'N'`                                   |
| `data_pagamento_multa`    | DATE     | —       | Nullable                                                     |

### SUSPENSAO
| Atributo           | Tipo     | Tamanho | Notas                                                                                                |
| ------------------ | -------- | ------- | ---------------------------------------------------------------------------------------------------- |
| `id_suspensao`     | NUMBER   | —       | PK                                                                                                   |
| `num_cartao`       | VARCHAR2 | 12      | FK → LEITOR (NO ACTION)                                                                              |
| `id_emprestimo`    | NUMBER   | —       | FK → EMPRESTIMO (NO ACTION)                                                                          |
| `data_inicio`      | DATE     | —       | Data de início (= data da devolução com atraso)                                                      |
| `data_fim`         | DATE     | —       | `data_inicio + dias_suspensao` (RN03.2)                                                              |
| `dias_suspensao`   | NUMBER   | (3)     | Atribuídos conforme RN03.2: 7, 15, 30 ou 60                                                          |
| `estado_suspensao` | VARCHAR2 | 10      | DEFAULT `'Activa'`. `'Activa'`, `'Cumprida'`, `'Reduzida'`                                           |
| `observacoes`      | VARCHAR2 | 300     | Nullable. Obrigatório quando `estado = 'Reduzida'` — justificativa do Coordenador (RN03.2)           |

> Verificar suspensão activa: `SELECT * FROM SUSPENSAO WHERE num_cartao = :x AND estado_suspensao = 'Activa' AND SYSDATE <= data_fim`.

---

### DOADOR
| Atributo      | Tipo     | Tamanho | Notas                                                  |
| ------------- | -------- | ------- | ------------------------------------------------------ |
| `id_doador`   | NUMBER   | —       | PK. `id_doador = 0` reservado para `'Anonimo'` (RN10) |
| `nome_doador` | VARCHAR2 | 100     | —                                                      |
| `tipo_doador` | VARCHAR2 | 13      | `'Individual'`, `'Institucional'`                      |
| `contacto`    | VARCHAR2 | 50      | Nullable — doador anónimo tem NULL (RN10)              |
| `endereco`    | VARCHAR2 | 200     | Nullable                                               |
| `observacoes` | VARCHAR2 | 300     | Nullable                                               |

### DOACAO *(alterada em v5)*
| Atributo         | Tipo     | Tamanho | Notas                                                                                  |
| ---------------- | -------- | ------- | -------------------------------------------------------------------------------------- |
| `id_doacao`      | NUMBER   | —       | PK                                                                                     |
| `id_doador`      | NUMBER   | —       | FK → DOADOR (NO ACTION)                                                                |
| `data_doacao`    | DATE     | —       | —                                                                                      |
| `cod_biblioteca` | VARCHAR2 | 10      | **[v5]** NOT NULL. FK → BIBLIOTECA (NO ACTION). Biblioteca beneficiada pela doação toda |

> Uma doação destina-se a uma única biblioteca — os itens não vão para destinos diferentes. O campo `cod_biblioteca` foi movido de `ITEM_DOACAO` para `DOACAO` em v5.

### ITEM_DOACAO *(alterada em v5)*
| Atributo         | Tipo     | Tamanho | Notas                                                                              |
| ---------------- | -------- | ------- | ---------------------------------------------------------------------------------- |
| `id_itemDoado`   | NUMBER   | —       | PK                                                                                 |
| `id_doacao`      | NUMBER   | —       | FK → DOACAO (CASCADE)                                                              |
| `nome_item`      | VARCHAR2 | 200     | **[v5]** NOT NULL. Nome descritivo do item doado. Ex: `'Dom Casmurro'`, `'Tablet'` |
| `tipo_item`      | VARCHAR2 | 20      | **[v5]** NOT NULL. CHECK `IN ('Livro','Dinheiro','Recurso','Outro')`               |
| `quantidade`     | NUMBER   | (5)     | DEFAULT `1`. Até 99.999 unidades                                                   |
| `valor_estimado` | NUMBER   | (10,2)  | Nullable. MT                                                                       |
| `observacoes`    | VARCHAR2 | 300     | Nullable                                                                           |

> `cod_biblioteca` foi removido de `ITEM_DOACAO` em v5 — a biblioteca beneficiada é definida ao nível de `DOACAO`. `nome_item` e `tipo_item` são obrigatórios (RN_DOACAO).

---

### EVENTO
| Atributo                      | Tipo     | Tamanho | Notas                                                                      |
| ----------------------------- | -------- | ------- | -------------------------------------------------------------------------- |
| `id_evento`                   | NUMBER   | —       | PK                                                                         |
| `cod_biblioteca`              | VARCHAR2 | 10      | FK → BIBLIOTECA (NO ACTION)                                                |
| `cod_funcionario_responsavel` | VARCHAR2 | 12      | FK → FUNCIONARIO (NO ACTION)                                               |
| `titulo_evento`               | VARCHAR2 | 100     | —                                                                          |
| `descricao_evento`            | VARCHAR2 | 500     | Nullable                                                                   |
| `local_evento`                | VARCHAR2 | 200     | Local físico. Pode ser dentro ou fora da biblioteca                        |
| `publico_alvo`                | VARCHAR2 | 22      | `'Iniciantes'`, `'Intermedios'`, `'Avancados'`, `'Todos'`                  |
| `data_evento`                 | DATE     | —       | Data base. Ocorrências específicas em HORARIO_EVENTO                       |
| `capacidade`                  | NUMBER   | (4)     | Nullable                                                                   |
| `status_evento`               | VARCHAR2 | 10      | DEFAULT `'Planeado'`. `'Planeado'`, `'Realizado'`, `'Cancelado'`           |
| `recorrente`                  | CHAR     | 1       | `'S'`/`'N'`                                                                |

### AVALIACAO_EVENTO
| Atributo         | Tipo     | Tamanho | Notas                   |
| ---------------- | -------- | ------- | ----------------------- |
| `id_avaliacao`   | NUMBER   | —       | PK                      |
| `id_evento`      | NUMBER   | —       | FK → EVENTO (CASCADE)   |
| `num_cartao`     | VARCHAR2 | 12      | FK → LEITOR (NO ACTION) |
| `nota`           | NUMBER   | (2)     | 1–5                     |
| `comentario`     | VARCHAR2 | 300     | Nullable                |
| `data_avaliacao` | DATE     | —       | —                       |

### EVENTO_RECURSO
| Atributo       | Tipo     | Tamanho | Notas                              |
| -------------- | -------- | ------- | ---------------------------------- |
| `id_recurso`   | NUMBER   | —       | PK                                 |
| `id_evento`    | NUMBER   | —       | FK → EVENTO (CASCADE)              |
| `nome_recurso` | VARCHAR2 | 100     | Ex: `'Projetor LCD'`, `'Cadeiras'` |
| `quantidade`   | NUMBER   | (4)     | —                                  |

### PARTICIPACAO_EVENTO
| Atributo               | Tipo     | Tamanho | Notas                      |
| ---------------------- | -------- | ------- | -------------------------- |
| `num_cartao`           | VARCHAR2 | 12      | PK + FK → LEITOR (CASCADE) |
| `id_evento`            | NUMBER   | —       | PK + FK → EVENTO (CASCADE) |
| `data_inscricao`       | DATE     | —       | —                          |
| `presenca_confirmacao` | CHAR     | 1       | DEFAULT `'N'`. `'S'`/`'N'` |

### HORARIO_EVENTO
| Atributo          | Tipo     | Tamanho | Notas                                                                        |
| ----------------- | -------- | ------- | ---------------------------------------------------------------------------- |
| `id_horario_ev`   | NUMBER   | —       | PK                                                                           |
| `id_evento`       | NUMBER   | —       | FK → EVENTO (CASCADE)                                                        |
| `dia_semana`      | VARCHAR2 | 13      | `'Segunda-feira'` … `'Domingo'`                                              |
| `data_ocorrencia` | DATE     | —       | Data concreta — obrigatório para eventos recorrentes (RN07)                  |
| `hora_inicio`     | VARCHAR2 | 5       | Formato `'HH:MM'`. Validado contra `HORARIO_BIBLIOTECA.hora_abertura` (RN07) |
| `hora_fim`        | VARCHAR2 | 5       | Formato `'HH:MM'`. Validado contra `HORARIO_BIBLIOTECA.hora_fecho` (RN07)   |

> Biblioteca obtida via `EVENTO.cod_biblioteca`. Trigger `trg_valida_horario_evento` consulta `HORARIO_BIBLIOTECA`.

---

### TRANSFERENCIA
| Atributo                      | Tipo     | Tamanho | Notas                                                    |
| ----------------------------- | -------- | ------- | -------------------------------------------------------- |
| `id_transferencia`            | NUMBER   | —       | PK                                                       |
| `data_solicitacao`            | DATE     | —       | —                                                        |
| `data_aprovacao_destino`      | DATE     | —       | Nullable                                                 |
| `data_conclusao`              | DATE     | —       | Nullable                                                 |
| `motivo`                      | VARCHAR2 | 300     | Nullable. Obrigatório quando `estado = 'Rejeitada'`      |
| `estado_transferencia`        | VARCHAR2 | 10      | `'Pendente'`, `'Aprovada'`, `'Rejeitada'`, `'Concluida'` |
| `cod_material`                | VARCHAR2 | 12      | FK → MATERIAL_BIBLIOGRAFICO (NO ACTION)                  |
| `cod_biblioteca_origem`       | VARCHAR2 | 10      | FK → BIBLIOTECA (NO ACTION)                              |
| `cod_biblioteca_destino`      | VARCHAR2 | 10      | FK → BIBLIOTECA (NO ACTION)                              |
| `cod_funcionario_solicitante` | VARCHAR2 | 12      | FK → FUNCIONARIO (NO ACTION)                             |
| `cod_funcionario_aprovador`   | VARCHAR2 | 12      | Nullable. FK → FUNCIONARIO (NO ACTION)                   |

---

### CERTIFICADO_DOACAO
| Atributo           | Tipo     | Tamanho | Notas                                       |
| ------------------ | -------- | ------- | ------------------------------------------- |
| `id_certificado`   | NUMBER   | —       | PK                                          |
| `num_certificado`  | VARCHAR2 | 20      | UNIQUE. Formato: `CERT-2025-0001`           |
| `id_doacao`        | NUMBER   | —       | FK → DOACAO (CASCADE)                       |
| `original_numero`  | VARCHAR2 | 20      | Nullable — preenchido em reemissões         |
| `data_emissao`     | DATE     | —       | —                                           |
| `tipo_certificado` | VARCHAR2 | 10      | `'Original'`, `'Reemissao'`, `'Honorifico'` |
| `observacoes`      | VARCHAR2 | 300     | Nullable                                    |

---

### PROGRAMA_ALFABETIZACAO
| Atributo               | Tipo     | Tamanho | Notas                                                            |
| ---------------------- | -------- | ------- | ---------------------------------------------------------------- |
| `cod_programa`         | VARCHAR2 | 18      | PK. Formato: `PROBIBXXX20XXYYYY`. Gerado por trigger + sequência |
| `cod_biblioteca`       | VARCHAR2 | 10      | FK → BIBLIOTECA (NO ACTION)                                      |
| `nome_programa`        | VARCHAR2 | 100     | —                                                                |
| `descricao`            | VARCHAR2 | 500     | Nullable                                                         |
| `publico_alvo`         | VARCHAR2 | 22      | `'Iniciantes'`, `'Intermedios'`, `'Avancados'`, `'Todos'`        |
| `duracao_semanas`      | NUMBER   | (3)     | Ex: `12`                                                         |
| `metodologia`          | VARCHAR2 | 300     | Nullable                                                         |
| `resultados_esperados` | VARCHAR2 | 300     | Nullable                                                         |
| `estado_programa`      | VARCHAR2 | 10      | DEFAULT `'Activo'`. `'Activo'`, `'Concluido'`, `'Suspenso'`      |

### NIVEL_PROGRESSAO
| Atributo       | Tipo     | Tamanho | Notas                                 |
| -------------- | -------- | ------- | ------------------------------------- |
| `id_nivel`     | NUMBER   | —       | PK                                    |
| `cod_programa` | VARCHAR2 | 18      | FK → PROGRAMA_ALFABETIZACAO (CASCADE) |
| `nome_nivel`   | VARCHAR2 | 50      | Ex: `'Nível 1 — Iniciação'`           |
| `descricao`    | VARCHAR2 | 300     | Nullable                              |
| `ordem`        | NUMBER   | (2)     | Sequência do nível no programa        |

### PROGRAMA_MATERIAL *(N:M)*
| Atributo       | Tipo     | Tamanho | Notas                                        |
| -------------- | -------- | ------- | -------------------------------------------- |
| `cod_programa` | VARCHAR2 | 18      | PK + FK → PROGRAMA_ALFABETIZACAO (CASCADE)   |
| `cod_material` | VARCHAR2 | 12      | PK + FK → MATERIAL_BIBLIOGRAFICO (NO ACTION) |
| `observacoes`  | VARCHAR2 | 200     | Nullable                                     |

### PROGRAMA_FUNCIONARIO *(N:M)*
| Atributo          | Tipo     | Tamanho | Notas                                        |
| ----------------- | -------- | ------- | -------------------------------------------- |
| `cod_programa`    | VARCHAR2 | 18      | PK + FK → PROGRAMA_ALFABETIZACAO (CASCADE)   |
| `cod_funcionario` | VARCHAR2 | 12      | PK + FK → FUNCIONARIO (NO ACTION)            |
| `papel`           | VARCHAR2 | 20      | `'Responsavel'`, `'Instrutor'`, `'Auxiliar'` |

### PARTICIPACAO_PROGRAMA
| Atributo              | Tipo     | Tamanho | Notas                                              |
| --------------------- | -------- | ------- | -------------------------------------------------- |
| `num_cartao`          | VARCHAR2 | 12      | PK + FK → LEITOR (CASCADE)                         |
| `cod_programa`        | VARCHAR2 | 18      | PK + FK → PROGRAMA_ALFABETIZACAO (CASCADE)         |
| `id_nivel_atual`      | NUMBER   | —       | Nullable. FK → NIVEL_PROGRESSAO (NO ACTION)        |
| `data_inscricao`      | DATE     | —       | —                                                  |
| `data_conclusao`      | DATE     | —       | Nullable                                           |
| `estado_participacao` | VARCHAR2 | 10      | DEFAULT `'Activo'`. `'Activo'`, `'Concluido'`, `'Desistiu'` |

### AUDITORIA_OPERACOES
| Atributo          | Tipo     | Tamanho | Notas                                                                      |
| ----------------- | -------- | ------- | -------------------------------------------------------------------------- |
| `id_auditoria`    | NUMBER   | —       | PK. Gerado por SEQ_AUDITORIA                                               |
| `data_operacao`   | DATE     | —       | NOT NULL. DEFAULT SYSDATE. Momento exacto da operação                      |
| `cod_funcionario` | VARCHAR2 | 12      | NOT NULL. FK lógica → FUNCIONARIO. Quem executou a operação                |
| `operacao`        | VARCHAR2 | 50      | NOT NULL. Ex: `'APAGAR_LEITOR'`, `'REMOVER_FUNCIONARIO'`, `'MODIFICAR_NIVEL_ACESSO'` |
| `objeto_afetado`  | VARCHAR2 | 100     | NOT NULL. Identificador do registo alvo (ex: `num_cartao`, `cod_funcionario`) |
| `resultado`       | VARCHAR2 | 10      | NOT NULL. CHECK (`'SUCESSO'`, `'FALHA'`)                                   |
| `motivo_falha`    | VARCHAR2 | 300     | Nullable. Preenchido apenas em caso de FALHA                               |
| `nos_afetados`    | VARCHAR2 | 200     | Nullable. Ex: `'EmprestimosDB, EventosBibliotecasDB'`                      |
| `observacoes`     | VARCHAR2 | 300     | Nullable. Contexto adicional da operação                                   |

**Constraints:**
- `AUDITORIA_PK` — PRIMARY KEY (`id_auditoria`)
- `chk_resultado_audit` — CHECK (`resultado` IN (`'SUCESSO'`, `'FALHA'`))

**Índices** *(tablespace tbs_NACIONALDB_idx):*
- `iaud_func` — `cod_funcionario`
- `iaud_data` — `data_operacao`

> Usa `PRAGMA AUTONOMOUS_TRANSACTION` na procedure de inserção — o registo é confirmado independentemente do resultado da transacção principal. Sem isto, um ROLLBACK da operação principal apagaria também o log, tornando a auditoria inútil para rastrear falhas. O middleware `backend/middleware/auditoria.js` chama este INSERT em todas as operações críticas.

---

### AUDITORIA_EMPRESTIMOS *(nó EmpréstimosProgramasDB — Yannis)*
| Atributo        | Tipo     | Tamanho | Notas                                                                                                          |
| --------------- | -------- | ------- | -------------------------------------------------------------------------------------------------------------- |
| `id_auditoria`  | NUMBER   | —       | PK. Gerado por SEQ_AUDITORIA_EMP                                                                               |
| `data_operacao` | DATE     | —       | NOT NULL. DEFAULT SYSDATE. Momento exacto da operação                                                          |
| `operacao`      | VARCHAR2 | 50      | NOT NULL. Ex: `'CRIAR_EMPRESTIMO'`, `'DEVOLUCAO'`, `'SUSPENSAO'`, `'BLOQUEIO'`                                 |
| `num_cartao`    | VARCHAR2 | 12      | Nullable. Leitor envolvido na operação                                                                         |
| `cod_material`  | VARCHAR2 | 12      | Nullable. Material envolvido na operação                                                                       |
| `id_emprestimo` | NUMBER   | —       | Nullable. Empréstimo envolvido na operação                                                                     |
| `resultado`     | VARCHAR2 | 10      | NOT NULL. CHECK (`'SUCESSO'`, `'FALHA'`)                                                                       |
| `motivo_falha`  | VARCHAR2 | 300     | Nullable. Preenchido apenas em caso de FALHA                                                                   |
| `nos_afetados`  | VARCHAR2 | 200     | Nullable. Ex: `'BibliotecaNacionalDB, MateriaisDB'`                                                            |
| `observacoes`   | VARCHAR2 | 300     | Nullable. Contexto adicional da operação                                                                       |

**Constraints:**
- `AUDITORIA_EMP_PK` — PRIMARY KEY (`id_auditoria`)
- `chk_resultado_emp` — CHECK (`resultado` IN (`'SUCESSO'`, `'FALHA'`))

**Índices** *(tablespace tbs_EMPRESTIMOSDB_idx):*
- `iaud_emp_cartao` — `num_cartao`
- `iaud_emp_data` — `data_operacao`
- `iaud_emp_res` — `resultado`

> Usa `PRAGMA AUTONOMOUS_TRANSACTION`. Chamada pelos triggers RN01 (rejeições de empréstimo) e RN03 (suspensões, bloqueios e devoluções). Campos `num_cartao`, `cod_material` e `id_emprestimo` são nullable porque algumas operações não envolvem todos estes objectos.

---

### AUDITORIA_MATERIAIS *(nó MateriaisDB — Yasin)*
| Atributo           | Tipo     | Tamanho | Notas                                                                                                     |
| ------------------ | -------- | ------- | --------------------------------------------------------------------------------------------------------- |
| `id_auditoria`     | NUMBER   | —       | PK. Gerado por SEQ_AUDITORIA_MAT                                                                          |
| `data_operacao`    | DATE     | —       | NOT NULL. DEFAULT SYSDATE. Momento exacto da operação                                                     |
| `operacao`         | VARCHAR2 | 50      | NOT NULL. Ex: `'ATUALIZAR_ESTADO'`, `'CRIAR_TRANSFERENCIA'`, `'MUDAR_ESTADO_TRANSF'`, `'CRIAR_MATERIAL'`  |
| `cod_material`     | VARCHAR2 | 12      | Nullable. Material envolvido na operação                                                                  |
| `id_transferencia` | NUMBER   | —       | Nullable. Transferência envolvida na operação                                                             |
| `estado_anterior`  | VARCHAR2 | 13      | Nullable. Estado do material ou transferência antes da operação                                           |
| `estado_novo`      | VARCHAR2 | 13      | Nullable. Estado após a operação                                                                          |
| `resultado`        | VARCHAR2 | 10      | NOT NULL. CHECK (`'SUCESSO'`, `'FALHA'`)                                                                  |
| `motivo_falha`     | VARCHAR2 | 300     | Nullable. Preenchido apenas em caso de FALHA                                                              |
| `nos_afetados`     | VARCHAR2 | 200     | Nullable. Ex: `'EmprestimosDB'` (consultado para verificar empréstimos activos na RN06)                   |
| `observacoes`      | VARCHAR2 | 300     | Nullable. Contexto adicional da operação                                                                  |

**Constraints:**
- `AUDITORIA_MAT_PK` — PRIMARY KEY (`id_auditoria`)
- `chk_resultado_mat` — CHECK (`resultado` IN (`'SUCESSO'`, `'FALHA'`))

**Índices** *(tablespace tbs_MATERIAISDB_idx):*
- `iaud_mat_material` — `cod_material`
- `iaud_mat_transf` — `id_transferencia`
- `iaud_mat_data` — `data_operacao`
- `iaud_mat_res` — `resultado`

---

### AUDITORIA_EVENTOS *(nó EventosBibliotecasDB — Gerson)*
| Atributo         | Tipo     | Tamanho | Notas                                                                                                               |
| ---------------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------- |
| `id_auditoria`   | NUMBER   | —       | PK. Gerado por SEQ_AUDITORIA_EVT                                                                                    |
| `data_operacao`  | DATE     | —       | NOT NULL. DEFAULT SYSDATE. Momento exacto da operação                                                               |
| `operacao`       | VARCHAR2 | 50      | NOT NULL. Ex: `'CRIAR_EVENTO'`, `'APAGAR_EVENTO'`, `'INSERIR_HORARIO_EV'`, `'INSCRICAO_EVENTO'`, `'AVALIACAO_EVENTO'` |
| `id_evento`      | NUMBER   | —       | Nullable. Evento envolvido na operação                                                                              |
| `cod_biblioteca` | VARCHAR2 | 10      | Nullable. Biblioteca envolvida na operação                                                                          |
| `num_cartao`     | VARCHAR2 | 12      | Nullable. Leitor envolvido (inscrições, avaliações, e DELETEs remotos via `prc_apagar_leitor` do BibliotecaNacionalDB) |
| `resultado`      | VARCHAR2 | 10      | NOT NULL. CHECK (`'SUCESSO'`, `'FALHA'`)                                                                            |
| `motivo_falha`   | VARCHAR2 | 300     | Nullable. Preenchido apenas em caso de FALHA                                                                        |
| `nos_afetados`   | VARCHAR2 | 200     | Nullable. Ex: `'BibliotecaNacionalDB'`                                                                              |
| `observacoes`    | VARCHAR2 | 300     | Nullable. Contexto adicional da operação                                                                            |

**Constraints:**
- `AUDITORIA_EVT_PK` — PRIMARY KEY (`id_auditoria`)
- `chk_resultado_evt` — CHECK (`resultado` IN (`'SUCESSO'`, `'FALHA'`))

**Índices** *(tablespace tbs_EVENTOSDB_idx):*
- `iaud_evt_evento` — `id_evento`
- `iaud_evt_bib` — `cod_biblioteca`
- `iaud_evt_data` — `data_operacao`
- `iaud_evt_res` — `resultado`

---

## Anatomia da Destruição Relacional

### Regra de Ouro

**CASCADE quando:**
- Dependência existencial: filho não tem sentido sem pai
- Composição: filho é "parte de" pai (atributo multivalorado expandido)
- Associação N:M sem valor histórico próprio

**NO ACTION quando:**
- Histórico legal: transações (empréstimos, transferências, suspensões)
- Activos patrimoniais: materiais, bibliotecas (exigem relocação, não destruição)
- Rastreabilidade: certificados, doações, responsáveis (valor de auditoria)

### Matriz de Decisão Completa

| FK  | Tabela Filho           | Tabela Pai                | DELETE RULE | Razão                     |
| --- | ---------------------- | ------------------------- | ----------- | ------------------------- |
| ✓   | ADULTO                 | LEITOR                    | CASCADE     | Hierarquia                |
| ✓   | ADULTO_INTERESSE       | ADULTO                    | CASCADE     | Multivalor                |
| ✓   | PROFESSOR              | ADULTO                    | CASCADE     | Hierarquia                |
| ✓   | PROFESSOR_DISCIPLINA   | PROFESSOR                 | CASCADE     | Multivalor                |
| ✓   | CRIANCA                | LEITOR                    | CASCADE     | Hierarquia                |
| ✓   | LIVRO_FISICO           | MATERIAL_BIBLIOGRAFICO    | CASCADE     | Hierarquia                |
| ✓   | EBOOK                  | MATERIAL_BIBLIOGRAFICO    | CASCADE     | Hierarquia                |
| ✓   | PERIODICO              | MATERIAL_BIBLIOGRAFICO    | CASCADE     | Hierarquia                |
| ✓   | PARTICIPACAO_EVENTO    | LEITOR                    | CASCADE     | Associativa               |
| ✓   | PARTICIPACAO_EVENTO    | EVENTO                    | CASCADE     | Associativa               |
| ✓   | AVALIACAO_EVENTO       | EVENTO                    | CASCADE     | Multivalor                |
| ✓   | EVENTO_RECURSO         | EVENTO                    | CASCADE     | Multivalor                |
| ✓   | HORARIO_EVENTO         | EVENTO                    | CASCADE     | Multivalor                |
| ✓   | ITEM_DOACAO            | DOACAO                    | CASCADE     | Multivalor                |
| ✓   | CERTIFICADO_DOACAO     | DOACAO                    | CASCADE     | Multivalor                |
| ✓   | HORARIO_BIBLIOTECA     | BIBLIOTECA                | CASCADE     | Multivalor                |
| ✓   | HORARIO_FUNCIONARIO    | FUNCIONARIO               | CASCADE     | Multivalor                |
| ✓   | FUNCIONARIO_HABILIDADE | FUNCIONARIO               | CASCADE     | Multivalor                |
| ✓   | BIBLIOTECA_RESPONSAVEL | BIBLIOTECA                | CASCADE     | Associativa               |
| ✓   | NIVEL_PROGRESSAO       | PROGRAMA_ALFABETIZACAO    | CASCADE     | Composição                |
| ✓   | PROGRAMA_MATERIAL      | PROGRAMA_ALFABETIZACAO    | CASCADE     | Associativa               |
| ✓   | PROGRAMA_FUNCIONARIO   | PROGRAMA_ALFABETIZACAO    | CASCADE     | Associativa               |
| ✓   | PARTICIPACAO_PROGRAMA  | LEITOR                    | CASCADE     | Associativa               |
| ✓   | PARTICIPACAO_PROGRAMA  | PROGRAMA_ALFABETIZACAO    | CASCADE     | Associativa               |
| ⊗   | SUSPENSAO              | LEITOR                    | NO ACTION   | Histórico legal           |
| ⊗   | SUSPENSAO              | EMPRESTIMO                | NO ACTION   | Rastreabilidade           |
| ⊗   | BIBLIOTECA_RESPONSAVEL | FUNCIONARIO               | NO ACTION   | Histórico organizacional  |
| ⊗   | AVALIACAO_EVENTO       | LEITOR                    | NO ACTION   | Histórico                 |
| ⊗   | LEITOR                 | BIBLIOTECA                | NO ACTION   | Activo organizacional     |
| ⊗   | FUNCIONARIO            | BIBLIOTECA                | NO ACTION   | Activo organizacional     |
| ⊗   | FUNCIONARIO            | FUNCAO_FUNCIONARIO        | NO ACTION   | Dados mestre              |
| ⊗   | MATERIAL_BIBLIOGRAFICO | BIBLIOTECA                | NO ACTION   | Activo patrimonial        |
| ⊗   | MATERIAL_BIBLIOGRAFICO | CATEGORIA                 | NO ACTION   | Dados mestre              |
| ⊗   | MATERIAL_BIBLIOGRAFICO | ITEM_DOACAO               | NO ACTION   | Rastreabilidade doação    |
| ⊗   | DOACAO                 | BIBLIOTECA                | NO ACTION   | **[v5]** Histórico doação |
| ⊗   | PROGRAMA_ALFABETIZACAO | BIBLIOTECA                | NO ACTION   | Activo organizacional     |
| ⊗   | PROGRAMA_MATERIAL      | MATERIAL_BIBLIOGRAFICO    | NO ACTION   | Activo patrimonial        |
| ⊗   | PROGRAMA_FUNCIONARIO   | FUNCIONARIO               | NO ACTION   | Auditoria                 |
| ⊗   | EMPRESTIMO             | LEITOR                    | NO ACTION   | Histórico legal           |
| ⊗   | EMPRESTIMO             | FUNCIONARIO               | NO ACTION   | Auditoria                 |
| ⊗   | EMPRESTIMO             | MATERIAL_BIBLIOGRAFICO    | NO ACTION   | Rastreabilidade           |
| ⊗   | EVENTO                 | FUNCIONARIO               | NO ACTION   | Histórico eventos         |
| ⊗   | EVENTO                 | BIBLIOTECA                | NO ACTION   | Histórico eventos         |
| ⊗   | TRANSFERENCIA          | MATERIAL_BIBLIOGRAFICO    | NO ACTION   | Auditoria patrimonial     |
| ⊗   | TRANSFERENCIA          | BIBLIOTECA (origem)       | NO ACTION   | Histórico                 |
| ⊗   | TRANSFERENCIA          | BIBLIOTECA (destino)      | NO ACTION   | Histórico                 |
| ⊗   | TRANSFERENCIA          | FUNCIONARIO (solicitante) | NO ACTION   | Auditoria                 |
| ⊗   | TRANSFERENCIA          | FUNCIONARIO (aprovador)   | NO ACTION   | Auditoria                 |
| ⊗   | DOACAO                 | DOADOR                    | NO ACTION   | Preserva histórico doador |
| ⊗   | AUDITORIA_OPERACOES    | FUNCIONARIO               | NO ACTION   | Auditoria                 |
| ⊗   | PERMISSAO_CARGO        | FUNCAO_FUNCIONARIO        | NO ACTION   | **[v5]** Dados mestre     |

---

## Constraints Críticas a Não Esquecer

| Tabela                   | Constraint                   | Tipo             | Definição                                                                               |
| ------------------------ | ---------------------------- | ---------------- | --------------------------------------------------------------------------------------- |
| `LEITOR`                 | `chk_status_leitor`          | CHECK            | `IN ('Activo','Suspenso','Bloqueado')`                                                  |
| `LEITOR`                 | `chk_historico_pontualidade` | CHECK            | `IN ('Pontual','Irregular','Mau')`                                                      |
| `ADULTO`                 | `chk_nivel_literacia`        | CHECK            | `IN ('Basico','Funcional','Avancado')`                                                  |
| `PROFESSOR`              | `chk_nivel_ensino`           | CHECK            | `IN ('Primario','Secundario','Tecnico','Universitario')`                                |
| `MATERIAL_BIBLIOGRAFICO` | `chk_origem_material`        | CHECK            | `IN ('Comprado','Doado','Transferido')`                                                 |
| `MATERIAL_BIBLIOGRAFICO` | `chk_estado_conservacao`     | CHECK            | `IN ('Bom','Degradado','Indisponivel')`                                                 |
| `MATERIAL_BIBLIOGRAFICO` | `chk_doado_item`             | CHECK            | `origem_material != 'Doado' OR id_itemDoado IS NOT NULL`                                |
| `MATERIAL_BIBLIOGRAFICO` | `chk_motivo_indisponivel`    | CHECK            | `estado_material_conservacao != 'Indisponivel' OR motivo_indisponibilidade IS NOT NULL` |
| `EBOOK`                  | `chk_url_formato`            | CHECK            | `formato NOT IN ('PDF','EPUB','MOBI') OR url_acesso IS NOT NULL`                        |
| `BIBLIOTECA`             | `chk_bib_estado`             | CHECK            | **[v5]** `IN ('Activo','Inactivo')`                                                     |
| `EVENTO`                 | `chk_status_evento`          | CHECK            | `IN ('Planeado','Realizado','Cancelado')`                                               |
| `AVALIACAO_EVENTO`       | `chk_nota`                   | CHECK            | `nota BETWEEN 1 AND 5`                                                                  |
| `EMPRESTIMO`             | `chk_estado_saida`           | CHECK            | `IN ('Bom','Degradado')`                                                                |
| `EMPRESTIMO`             | `chk_estado_retorno`         | CHECK            | `IN ('Bom','Degradado','Destruido','Perdido')`                                          |
| `EMPRESTIMO`             | `chk_data_devolucao`         | CHECK            | `data_devolucao IS NULL OR data_devolucao >= data_retirada`                             |
| `SUSPENSAO`              | `chk_estado_suspensao`       | CHECK            | `IN ('Activa','Cumprida','Reduzida')`                                                   |
| `SUSPENSAO`              | `chk_dias_suspensao`         | CHECK            | `dias_suspensao IN (7,15,30,60)`                                                        |
| `SUSPENSAO`              | `chk_data_fim`               | CHECK            | `data_fim > data_inicio`                                                                |
| `FUNCAO_FUNCIONARIO`     | `chk_nome_funcao`            | CHECK            | `IN ('Administrador','Coordenador','Bibliotecario','Assistente')`                       |
| `FUNCAO_FUNCIONARIO`     | `chk_nivel_acesso`           | CHECK            | `IN ('Administrador','Coordenador','Bibliotecario','Assistente')`                       |
| `BIBLIOTECA_RESPONSAVEL` | `chk_papel_responsavel`      | CHECK            | `IN ('Principal','Substituto')`                                                         |
| `TRANSFERENCIA`          | `chk_origem_destino`         | CHECK            | `cod_biblioteca_origem <> cod_biblioteca_destino`                                       |
| `TRANSFERENCIA`          | `chk_estado_transferencia`   | CHECK            | `IN ('Pendente','Aprovada','Rejeitada','Concluida')`                                    |
| `CERTIFICADO_DOACAO`     | `chk_tipo_cert`              | CHECK            | `IN ('Original','Reemissao','Honorifico')`                                              |
| `PROGRAMA_ALFABETIZACAO` | `chk_estado_programa`        | CHECK            | `IN ('Activo','Concluido','Suspenso')`                                                  |
| `PARTICIPACAO_PROGRAMA`  | `chk_estado_participacao`    | CHECK            | `IN ('Activo','Concluido','Desistiu')`                                                  |
| `ITEM_DOACAO`            | `chk_tipo_item`              | CHECK            | **[v5]** `IN ('Livro','Dinheiro','Recurso','Outro')`                                    |
| `PERMISSAO_CARGO`        | `chk_permitido`              | CHECK            | **[v5]** `IN (0,1)`                                                                     |
| `PERMISSAO_CARGO`        | `uq_perm_cargo_modulo_accao` | UNIQUE           | **[v5]** `(id_funcao, modulo, accao)`                                                   |
| `DOADOR`                 | —                            | Registo especial | `id_doador = 0`, `nome = 'Anonimo'`, `contacto = NULL` — nunca apagar (RN10)            |
| `AUDITORIA_OPERACOES`    | `chk_resultado_audit`        | CHECK            | `IN ('SUCESSO', 'FALHA')`                                                               |
