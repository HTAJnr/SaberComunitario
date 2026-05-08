# Yasin — Nó MateriaisDB
### Sistema de Gestão de Bibliotecas Comunitárias Distribuído
**Ambiente:** Oracle 10g XE, CentOS 6.8, SQL*Plus
**Referências obrigatórias:** DD v3, Regras de Negócio v3 (RN04, RN05, RN06, RN09), Guia BD2 Tema 8

---

## O teu nó no sistema

O MateriaisDB é o repositório central do catálogo bibliográfico. É o nó que armazena todos os materiais físicos e digitais do sistema, responde a consultas de disponibilidade vindas de outros nós, e coordena as transferências de materiais entre bibliotecas.

Outros nós dependem directamente do teu para funcionar correctamente — o EmpréstimosDB precisa de saber se um material existe e se pode ser emprestado antes de criar qualquer empréstimo. Se o teu nó devolver informação errada ou estiver mal configurado, o sistema inteiro produz resultados inválidos.

---

## Fase 1 — Estrutura local do nó

### 1.1 — Tabelas do teu domínio

As tabelas que pertencem ao MateriaisDB são as seguintes, todas definidas no DD v3:
- `CATEGORIA`
- `MATERIAL_BIBLIOGRAFICO`
- `LIVRO_FISICO`
- `EBOOK`
- `PERIODICO`
- `TRANSFERENCIA`

**O que fazer:**
Cria todas estas tabelas no teu schema (`usr_materiaisdb`), usando a tablespace de dados para os dados e a tablespace de índices para os índices — ambas criadas na Fase Comum. Consulta o DD v3 para os tipos de dados, tamanhos, constraints e regras de integridade referencial de cada tabela. Não inventes nada que não esteja documentado.

Depois de criar cada tabela, verifica no dicionário de dados do Oracle que ela foi criada na tablespace correcta. Regista esse output no relatório.

Cria índices nas colunas mais consultadas. Pensa: quais são as pesquisas mais frequentes num catálogo bibliográfico? Por título? Por estado de conservação? Por biblioteca? Justifica no relatório a escolha de cada índice e em que tablespace foi criado.

**O que registar no relatório:**
- Output da query ao dicionário de dados confirmando cada tabela na tablespace correcta
- Lista de índices criados com a justificação de cada um
- Quaisquer erros encontrados e como os resolveste

---

### 1.2 — A decisão de fragmentação e porquê

Esta é a tarefa conceptualmente mais importante da tua fase 1. O professor vai perguntar sobre isto na defesa — tens de conseguir explicar sem olhar para papel.

**O problema que a fragmentação resolve:**
O sistema tem múltiplas bibliotecas espalhadas por diferentes localidades de Moçambique. Cada biblioteca trabalha maioritariamente com os seus próprios materiais — a Biblioteca de Nampula raramente precisa de consultar materiais da Biblioteca de Maputo no dia-a-dia. Guardar todos os materiais num único bloco indistinto significa que qualquer consulta local tem de percorrer dados irrelevantes para ela. Isso é ineficiente e vai contra o princípio de autonomia local numa BD distribuída.

**A fragmentação que implementas:**
Fragmentação horizontal de `MATERIAL_BIBLIOGRAFICO` com base no campo `id_biblioteca`. Cada fragmento é um subconjunto de linhas — os materiais de uma biblioteca ou grupo de bibliotecas. A tabela completa é reconstruída pela união de todos os fragmentos.

Implementa os fragmentos como vistas. Num sistema completamente distribuído, cada fragmento viveria no nó da sua biblioteca — no vosso trabalho, o MateriaisDB agrega todos os fragmentos, e as vistas representam essa divisão lógica.

**As 3 regras que tens de demonstrar (Guia BD2 Tema 8):**
- **Completude:** todos os materiais aparecem em pelo menos um fragmento
- **Reconstrução:** a união de todos os fragmentos devolve exactamente a tabela original
- **Disjuntividade:** cada material aparece num único fragmento

**Vista de serviço para outros nós:**
Cria uma vista que expõe apenas o que outros nós precisam de saber sobre os materiais — disponibilidade para empréstimo e estado de conservação. Não exponhas dados patrimoniais ou administrativos desnecessários. Concede acesso a esta vista ao utilizador de leitura do nó que a vai consumir.

**O que registar no relatório:**
- As vistas de fragmento com a explicação do critério de divisão escolhido
- Uma query que demonstra a Reconstrução: contagem total em `MATERIAL_BIBLIOGRAFICO` deve ser igual à contagem total na vista global
- Explicação escrita das 3 regras aplicadas ao teu caso concreto

**Pergunta de validação (responde por escrito antes de avançar):**
> Porquê escolheste `id_biblioteca` como critério de fragmentação e não `ano_publicacao` ou `idioma`? Que princípio da BD distribuída guiou essa escolha? O que perderias em termos de desempenho ou autonomia local com outro critério?

---

## Fase 2 — Lógica do nó

### 2.1 — RN05: Actualização do estado do material na devolução

**Contexto (lê a RN05 completa antes de começar):**
Quando um material é devolvido, o funcionário avalia o seu estado físico. Conforme esse estado, o registo em `MATERIAL_BIBLIOGRAFICO` tem de ser actualizado — um material destruído ou perdido passa a indisponível com o motivo correspondente; um material degradado mantém-se disponível mas com estado actualizado.

**O que implementar:**
A tabela `EMPRESTIMO` não existe no teu nó — pertence ao EmpréstimosDB. A tua responsabilidade é criar uma **procedure** que o EmpréstimosDB possa chamar remotamente via database link quando processa uma devolução. A procedure recebe o código do material e o estado de retorno registado pelo funcionário, e actualiza `MATERIAL_BIBLIOGRAFICO` de acordo com as regras exactas da RN05.

Consulta a RN05 para perceber todos os estados de retorno possíveis, o que cada um implica para `estado_material_conservacao`, e quando `motivo_indisponibilidade` tem de ser preenchido. A procedure tem de cobrir todos esses casos.

Depois de criar a procedure, concede permissão de execução ao utilizador de aplicação do EmpréstimosDB — sem esse GRANT, o outro nó não consegue chamá-la.

**O que registar no relatório:**
- Descrição do que a procedure faz, caso a caso, conforme a RN05
- Porquê foi implementada como procedure e não como trigger (pensa: onde está a tabela EMPRESTIMO?)
- Confirmação de que o GRANT de execução foi feito ao utilizador correcto

---

### 2.2 — RN06: Protecção de materiais durante transferências

**Contexto (lê a RN06 completa):**
Uma transferência tem um fluxo de estados definido: Pendente → Aprovada → Concluída (ou Rejeitada). Duas restrições críticas: material com empréstimo activo não pode ser transferido; material com transferência pendente ou aprovada não pode ser emprestado.

**O que implementar:**
Dois triggers na tabela `TRANSFERENCIA`.

O primeiro actua antes de qualquer INSERT. Tem de verificar junto do EmpréstimosDB — via database link — se o material em causa tem empréstimo activo. Se tiver, rejeita com mensagem clara. Também verifica se já existe outra transferência activa para o mesmo material.

O segundo actua antes de qualquer UPDATE de estado. Garante que o fluxo de estados é respeitado conforme a RN06 — não é possível alterar uma transferência já concluída ou rejeitada, e os únicos caminhos válidos entre estados são os definidos na regra. Quando uma transferência passa a concluída, o campo `id_biblioteca` do material tem de ser actualizado para reflectir a nova localização.

**O que registar no relatório:**
- Descrição do que cada trigger faz e o momento exacto em que actua
- Explicação de porquê o primeiro trigger faz uma consulta remota e o que isso implica se o EmpréstimosDB estiver offline

---

### 2.3 — RN09: E-books em suportes físicos

**Contexto (lê a RN09):**
Formatos digitais como PDF, EPUB e MOBI exigem URL de acesso. Suportes físicos como CD e PEN não têm URL — seria sem sentido. A regra está implementada como CHECK constraint na tabela `EBOOK`.

**O que verificar:**
Confirma que o teu CREATE TABLE de `EBOOK` inclui esta constraint exactamente como definida na RN09. Verifica no dicionário de dados do Oracle que a constraint existe. Regista esse output.

---

### 2.4 — Testes obrigatórios da Fase 2

Para cada cenário, prepara os dados necessários, executa a operação e regista o output real do SQL*Plus no relatório. Não inventes resultados — o que o sistema produziu é o que vai para o relatório.

**Cenário 1 — RN05: Devolução com estado destruído**
Cria um material de teste com estado `'Bom'`. Chama a procedure passando esse material com estado de retorno `'Destruido'`. Verifica que o campo `estado_material_conservacao` passou para `'Indisponivel'` e que `motivo_indisponibilidade` está preenchido com o valor correcto da RN05.

**Cenário 2 — RN05: Devolução com estado degradado**
Com outro material em estado `'Bom'`, chama a procedure com estado `'Degradado'`. Verifica que o estado passou para `'Degradado'` e que o material não ficou indisponível — continua apto para empréstimo.

**Cenário 3 — RN06: Transferência bloqueada por empréstimo activo**
Coordena com o Yannis para garantir que existe um empréstimo activo para um material específico no EmpréstimosDB. Tenta criar uma transferência para esse material. O sistema deve rejeitar com mensagem de erro.

**Cenário 4 — RN06: Fluxo de estados inválido**
Cria uma transferência e coloca-a em estado `'Concluida'`. Tenta fazer um UPDATE para qualquer outro estado. O sistema deve rejeitar.

**Cenário 5 — RN09: E-book digital sem URL (deve falhar)**
Tenta inserir em `EBOOK` um registo com formato `'PDF'` e `url_acesso` a NULL. O sistema deve rejeitar por violação de constraint.

**Cenário 6 — RN09: E-book em suporte físico sem URL (deve passar)**
Insere em `EBOOK` um registo com formato `'CD'` e `url_acesso` a NULL. O sistema deve aceitar sem erros.

**Cenário 7 — Reconstrução do fragmento**
Faz uma contagem de linhas directamente em `MATERIAL_BIBLIOGRAFICO` e outra na vista global que reconstrói os fragmentos. Os dois valores têm de ser iguais. Regista ambos os outputs lado a lado.

**Pergunta de validação:**
> O trigger de protecção de transferência consulta o EmpréstimosDB via database link. O que acontece se o EmpréstimosDB estiver offline quando alguém tenta criar uma transferência? É um problema de disponibilidade ou de consistência? Como o Oracle se comporta nessa situação em Oracle 10g?

---

## Fase 3 — Distribuição e Backup

### 3.1 — Exposição de dados para outros nós

Verifica que todas as vistas necessárias estão acessíveis aos utilizadores correctos. Pensa em quem precisa de quê:
- O EmpréstimosDB precisa de verificar disponibilidade de materiais antes de criar empréstimos
- O EventosBibliotecasDB precisa de saber quais materiais existem para planeamento de eventos temáticos (enunciado)
- O BibliotecaNacionalDB precisa de uma visão global do catálogo

Para cada caso, confirma que a vista existe e que o GRANT foi feito. Testa o acesso remoto — pede a um colega para fazer um SELECT na tua vista a partir do nó dele e regista o resultado no teu relatório.

**O que registar:**
- Lista de vistas expostas, a quem, e para quê
- Output do teste de acesso remoto feito com um colega

---

### 3.2 — Backup e Recovery do MateriaisDB

**Contexto:**
O catálogo de materiais é um activo patrimonial. Perder esses dados significa perder o registo de todos os bens bibliográficos do sistema. O backup tem de ser feito com a base de dados aberta — backup a quente — porque o catálogo é consultado continuamente pelos outros nós.

**O que fazer:**
Faz um backup a quente do datafile da tua tablespace de dados. O processo envolve colocar a tablespace em modo backup, copiar o ficheiro fisicamente para um directório de backup, e terminar o modo backup. Consulta o Guia BD2 e os materiais das aulas para os comandos correctos no SQL*Plus e no terminal CentOS.

Depois de fazer o backup, simula uma falha: apaga o datafile da tua tablespace. Tenta aceder à tabela `MATERIAL_BIBLIOGRAFICO` e regista o erro que aparece. Depois faz o recovery — restaura o ficheiro a partir do backup e usa os archived log files para aplicar as alterações ocorridas depois do backup. Verifica que os dados voltaram.

**O que registar:**
- Passos do backup com os outputs reais de cada comando
- Output do erro após simular a falha
- Passos do recovery com os outputs
- Output final confirmando que os dados voltaram

**Pergunta de validação:**
> O recovery usou archived log files. Porquê foram necessários e não bastou restaurar o ficheiro de backup? O que é o processo de Roll Forward? Se não tivesses activado ARCHIVELOG na Fase Comum, conseguias fazer este recovery? O que terias de fazer em alternativa?

---

## Checklist final — MateriaisDB

- [ ] Todas as tabelas criadas na tablespace correcta e verificadas no dicionário de dados
- [ ] Índices criados na tablespace de índices com justificação documentada
- [ ] Vistas de fragmento horizontal criadas com demonstração das 3 regras
- [ ] Vista de disponibilidade para outros nós criada com GRANTs correctos
- [ ] Procedure de actualização de estado do material criada com GRANT ao EmpréstimosDB
- [ ] Trigger de protecção de INSERT em TRANSFERENCIA criado e testado
- [ ] Trigger de validação de fluxo de estados de TRANSFERENCIA criado e testado
- [ ] CHECK constraint de EBOOK verificada no dicionário de dados
- [ ] Todos os 7 cenários de teste executados com outputs reais registados
- [ ] Acesso remoto testado e confirmado com um colega
- [ ] Backup a quente executado e documentado
- [ ] Recovery simulado e documentado
- [ ] Todas as perguntas de validação respondidas por escrito no relatório
