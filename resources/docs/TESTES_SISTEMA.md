# Cenários de Teste — Saber Comunitário

Sistema de Gestão de Bibliotecas Comunitárias Distribuído — BD2, ISCTEM 2026  
**Data:** 2026-06-02 · **Estado do sistema:** dados de seed instalados (v5)

---

## Como usar este documento

Cada secção corresponde a um **nó Oracle** gerido por um elemento do grupo. Os testes de cada nó podem ser executados **em paralelo** — não dependem uns dos outros, excepto na secção final de [Verificação Cross-Node](#5-verificação-cross-node-todos-os-nós-em-simultâneo).

Para cada teste:

- Regista o resultado observado (✅ Passou / ❌ Falhou / ⚠️ Comportamento inesperado)
- Em caso de falha, copia a mensagem de erro e o estado da consola do servidor

**Estado esperado por código de cor:**
- `✅ DEVE PASSAR` — acção legítima, esperamos sucesso
- `❌ DEVE FALHAR` — regra de negócio impede a acção; esperamos mensagem de erro clara

---

## Utilizadores do sistema (dados de seed)

| Utilizador | Email | Senha | Nível | Biblioteca | Código |
|---|---|---|---|---|---|
| Ana Maria Sitoe | `ana.sitoe@sabercom.mz` | `AS2026@Saber` | **Administrador** | Maputo (BIBMPC0001) | FUC20250001 |
| Carlos Nhambiu | `carlos.nhambiu@sabercom.mz` | `CN2026@Saber` | **Coordenador** | Maputo (BIBMPC0001) | FUC20250002 |
| Beatriz Cossa | `beatriz.cossa@sabercom.mz` | `BC2026@Saber` | **Bibliotecário** | Maputo (BIBMPC0001) | FUC20250003 |
| Domingos Machava | `domingos.machava@sabercom.mz` | `DM2026@Saber` | **Assistente** | Maputo (BIBMPC0001) | FUC20250004 |
| Esperança Bila | `esperanca.bila@sabercom.mz` | `EB2026@Saber` | **Coordenador** | Xai-Xai (BIBGZA0001) | FUC20250005 |
| Fernando Mondlane | `fernando.mondlane@sabercom.mz` | `FM2026@Saber` | **Bibliotecário** | Xai-Xai (BIBGZA0001) | FUC20250006 |
| Graça Tembe | `graca.tembe@sabercom.mz` | `GT2026@Saber` | **Assistente** | Xai-Xai (BIBGZA0001) | FUC20250007 |
| Helder Zunguze | `helder.zunguze@sabercom.mz` | `HZ2026@Saber` | **Coordenador** | Beira (BIBSOF0001) | FUC20250008 |
| Ilda Macuacua | `ilda.macuacua@sabercom.mz` | `IM2026@Saber` | **Bibliotecário** | Beira (BIBSOF0001) | FUC20250009 |
| Jorge Nuvunga | `jorge.nuvunga@sabercom.mz` | `JN2026@Saber` | **Assistente** | Beira (BIBSOF0001) | FUC20251000 |
| Lúcia Mussagy | `lucia.mussagy@sabercom.mz` | `AS2026@Saber` | **Coordenador** | Quelimane (BIBQLM0001) | FUC20250011 |
| Osvaldo Jamo | `osvaldo.jamo@sabercom.mz` | `BC2026@Saber` | **Bibliotecário** | Quelimane (BIBQLM0001) | FUC20250012 |
| Sónia Chicusse | `sonia.chicusse@sabercom.mz` | `DM2026@Saber` | **Assistente** | Quelimane (BIBQLM0001) | FUC20250013 |
| Paulo Laice | `paulo.laice@sabercom.mz` | `HZ2026@Saber` | **Coordenador** | Nampula (BIBNMP0001) | FUC20250014 |
| Amélia Nassone | `amelia.nassone@sabercom.mz` | `IM2026@Saber` | **Bibliotecário** | Nampula (BIBNMP0001) | FUC20250015 |
| Zacarias Mussa | `zacarias.mussa@sabercom.mz` | `GT2026@Saber` | **Assistente** | Nampula (BIBNMP0001) | FUC20250016 |

### Login de demonstração (sem BD)
| Campo | Valor |
|---|---|
| Email | `demo@biblioteca.mz` |
| Senha | `demo` |

---

## Leitores de referência (dados de seed)

| Num. Cartão | Nome | Tipo | Biblioteca | Observações |
|---|---|---|---|---|
| MPC20250001 | Maria Chissano | Adulto | BIBMPC0001 | Status: Activo |
| MPC20250002 | Pedro Cumbe | Adulto + Professor | BIBMPC0001 | Status: Activo |
| MPC20250003 | João Nhaca | Criança | BIBMPC0001 | Status: Activo |
| GZA20250001 | Rosa Temane | Adulto | BIBGZA0001 | Status: Activo (tinha suspensão cumprida) |
| GZA20250002 | Abel Chivambo | Adulto + Professor | BIBGZA0001 | Status: Activo |
| SOF20250001 | Angelina Mabunda | Criança | BIBSOF0001 | Status: Activo |
| SOF20250002 | António Fonseca | Adulto | BIBSOF0001 | Status: Activo (teve atraso >60 dias no passado) |
| QLM20250001 | Carolina Mussa | Adulto | BIBQLM0001 | Status: Activo |
| QLM20250002 | David João | Adulto + Professor | BIBQLM0001 | Status: Activo |
| NMP20250001 | Fátima Abib | Adulto | BIBNMP0001 | Status: Activo |
| NMP20250002 | Elias Nassir | Criança | BIBNMP0001 | Status: Activo |

---

## Materiais de referência (dados de seed)

| Código | Título | Tipo | Biblioteca | Estado | Nota |
|---|---|---|---|---|---|
| MAT20190001 | Vozes Anoitecidas | Livro | BIBMPC0001 | Activo (emprestado a MPC20250001 — em aberto) | |
| MAT20190002 | Neighbours | Livro | BIBMPC0001 | Disponível | |
| MAT20190003 | Terra Sonâmbula (ex. 1) | Livro | BIBMPC0001 | Activo (emprestado a MPC20250002 — prazo 2026-06-01) | |
| MAT20190004 | Terra Sonâmbula (ex. 2) | Livro | BIBMPC0001 | Em transferência Pendente (T1 → BIBGZA0001) | |
| MAT20240001 | O Leão e o Coelho Astuto | Livro infantil | BIBMPC0001 | Activo (emprestado a MPC20250003 — prazo 2026-06-02) | |
| MAT20200002 | Agricultura Familiar | Livro | BIBGZA0001 | Em transferência Pendente (T3 → BIBNMP0001) | |
| MAT20210001 | A Balada de Amor ao Vento | Livro | BIBGZA0001 | Activo (emprestado — prazo 2026-06-01) | |
| MAT20210002 | Contos do Nasreddin | Livro infantil | BIBSOF0001 | Em transferência Pendente (T9 → BIBGZA0001) | |
| MAT20240005 | Introdução à Informática | Livro | BIBSOF0001 | Disponível | |
| MAT20250010 | História Natural de Moçambique | Livro | BIBQLM0001 | Activo (emprestado a QLM20250001) | |
| MAT20250011 | Contos do Rio Licungo | Livro | BIBQLM0001 | Activo (emprestado a QLM20250002 — prazo 2026-06-02) | |
| MAT20230001 | Guia de Saúde Materno-Infantil | eBook | BIBMPC0001 | Activo (emprestado a MPC20250001 — em aberto) | |
| MAT20230002 | Programação Python para Iniciantes | eBook | BIBMPC0001 | Activo (emprestado — em aberto) | |
| MAT20250013 | Literatura Macua — Antologia | Livro | BIBNMP0001 | Em transferência Aprovada (T2 → BIBQLM0001) | |

---

## 1. Nó BibliotecaNacionalDB — VM Hélder (BIBMPC0001)

> **Responsável:** Hélder  
> **Utilizadores a usar:** Ana (Admin), Carlos (Coord), Beatriz (Biblio), Domingos (Assist)

### 1.1 Autenticação

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T01 | `✅ DEVE PASSAR` Login normal | Ana Sitoe | `ana.sitoe@sabercom.mz` / `AS2026@Saber` | Sessão iniciada, nivel_acesso = Administrador, dashboard da rede visível |
| T02 | `✅ DEVE PASSAR` Login Coordenador | Carlos Nhambiu | `carlos.nhambiu@sabercom.mz` / `CN2026@Saber` | Sessão iniciada, dashboard só da biblioteca |
| T03 | `✅ DEVE PASSAR` Login Demo | — | `demo@biblioteca.mz` / `demo` | Login sem tocar na BD, banner de demo visível |
| T04 | `❌ DEVE FALHAR` Senha errada | Ana Sitoe | `ana.sitoe@sabercom.mz` / `WrongPass` | Mensagem "Credenciais inválidas" |
| T05 | `❌ DEVE FALHAR` Email inexistente | — | `nao.existe@sabercom.mz` / qualquer | Mensagem "Credenciais inválidas" |

### 1.2 Controlo de Acesso (permissões por nível)

| # | Acção | Utilizador | Esperado |
|---|---|---|---|
| T06 | `✅ DEVE PASSAR` Ver dashboard da rede | Ana (Admin) | Tabela com todas as 5 bibliotecas e indicadores globais |
| T07 | `❌ DEVE FALHAR` Ver dashboard da rede | Carlos (Coord) | Opção não visível no menu ou HTTP 403 |
| T08 | `❌ DEVE FALHAR` Aceder módulo Permissões | Beatriz (Biblio) | Opção não disponível na interface |
| T09 | `❌ DEVE FALHAR` Aceder módulo Permissões | Carlos (Coord) | Opção não disponível na interface |
| T10 | `✅ DEVE PASSAR` Ver módulo Permissões | Ana (Admin) | Lista de cargos visível |
| T11 | `❌ DEVE FALHAR` Eliminar leitor | Domingos (Assist) | Botão eliminar ausente na interface |
| T12 | `❌ DEVE FALHAR` Eliminar leitor | Carlos (Coord) | HTTP 403 ou botão ausente |
| T13 | `✅ DEVE PASSAR` Eliminar leitor | Ana (Admin) | Leitor eliminado (use um recém-criado para este teste) |

### 1.3 Leitores (CRUD)

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T14 | `✅ DEVE PASSAR` Cadastrar adulto | Beatriz (Biblio) | Nome: "Teste Novo", Profissão: "Estudante", ... | Leitor criado com num_cartao gerado, aparece na lista |
| T15 | `✅ DEVE PASSAR` Cadastrar criança | Carlos (Coord) | Nome: "Criança Teste", Responsável: "Pai Teste", classe: "2a" | Leitor tipo Criança criado |
| T16 | `✅ DEVE PASSAR` Ver detalhe do leitor | Domingos (Assist) | Seleccionar MPC20250001 (Maria Chissano) | Dados completos, histórico de empréstimos visível |
| T17 | `❌ DEVE FALHAR` Alterar status do leitor | Domingos (Assist) | Tentar suspender MPC20250002 | HTTP 403 — Assistente não pode alterar status |
| T18 | `✅ DEVE PASSAR` Alterar status — suspender | Carlos (Coord) | Suspender MPC20250002 manualmente | Status muda para Suspenso |
| T19 | `✅ DEVE PASSAR` Reactivar leitor | Carlos (Coord) | Reactivar MPC20250002 (acabado de suspender no T18) | Status volta a Activo |
| T20 | `❌ DEVE FALHAR` Editar leitor | Domingos (Assist) | Tentar editar MPC20250001 | Botão editar ausente ou HTTP 403 |
| T21 | `✅ DEVE PASSAR` Editar leitor | Beatriz (Biblio) | Editar contacto de MPC20250001 | Dados actualizados |

### 1.4 Empréstimos

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T22 | `✅ DEVE PASSAR` Criar empréstimo | Beatriz (Biblio) | Leitor: MPC20250002, Material: MAT20190002 | Empréstimo criado (MAT20190002 está disponível) |
| T23 | `❌ DEVE FALHAR` Criar empréstimo — leitor com empréstimo activo | Beatriz (Biblio) | Leitor: MPC20250002 (acabou de ter no T22), qualquer material | Erro "Leitor já tem um empréstimo activo" |
| T24 | `✅ DEVE PASSAR` Devolver empréstimo | Beatriz (Biblio) | Devolver o empréstimo criado em T22 | Estado muda para devolvido, material disponível |
| T25 | `❌ DEVE FALHAR` Criar empréstimo — material com empréstimo activo | Carlos (Coord) | Leitor: qualquer activo, Material: MAT20190001 (já emprestado) | Erro de material indisponível |
| T26 | `❌ DEVE FALHAR` Criar empréstimo — criança com material para adultos | Beatriz (Biblio) | Leitor: MPC20250003 (João — criança), Material: MAT20190001 (Literatura, faixa Adulto) | Erro "Material não permitido para crianças" |
| T27 | `✅ DEVE PASSAR` Criar empréstimo — criança com material infantil | Beatriz (Biblio) | Leitor: MPC20250003, Material: MAT20240001 (O Leão e o Coelho — Infantil) | **Nota:** MAT20240001 pode estar emprestado; se sim, use outro material infantil disponível |
| T28 | `✅ DEVE PASSAR` Ver lista de empréstimos | Domingos (Assist) | — | Lista de empréstimos da biblioteca visível com estado e prazo |
| T29 | `✅ DEVE PASSAR` Ver multas em aberto | Carlos (Coord) | — | Empréstimos vencidos com multa calculada (MAT20190001, MAT20230002 com prazo expirado) |
| T30 | `✅ DEVE PASSAR` Marcar multa como paga | Beatriz (Biblio) | Empréstimo com multa | Multa marcada como paga |
| T31 | `❌ DEVE FALHAR` Eliminar empréstimo | Carlos (Coord) | Tentar eliminar empréstimo histórico | HTTP 403 — só Administrador pode eliminar |
| T32 | `✅ DEVE PASSAR` Eliminar empréstimo | Ana (Admin) | Eliminar empréstimo devolvido | Empréstimo removido do histórico |

### 1.5 Funcionários

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T33 | `✅ DEVE PASSAR` Ver lista funcionários | Carlos (Coord) | — | Lista de funcionários da biblioteca com cargo |
| T34 | `❌ DEVE FALHAR` Ver funcionários | Beatriz (Biblio) | — | Opção não visível no menu |
| T35 | `✅ DEVE PASSAR` Cadastrar funcionário | Carlos (Coord) | Nome: "Teste Func", Cargo: Assistente | Funcionário criado |
| T36 | `✅ DEVE PASSAR` Editar funcionário | Ana (Admin) | Editar dados do FUC20250004 (Domingos) | Dados actualizados |
| T37 | `❌ DEVE FALHAR` Eliminar coordenador activo | Ana (Admin) | Tentar eliminar Carlos Nhambiu (FUC20250002) | Erro "Coordenador não pode ser removido enquanto for responsável de biblioteca" (trigger no EventosDB) |
| T38 | `✅ DEVE PASSAR` Eliminar funcionário sem responsabilidade | Ana (Admin) | Eliminar o funcionário criado em T35 | Funcionário removido |

### 1.6 Doações

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T39 | `✅ DEVE PASSAR` Ver doações | Carlos (Coord) | — | Lista de doações com doador, data e valor total |
| T40 | `❌ DEVE FALHAR` Ver doações | Beatriz (Biblio) | — | Opção não visível (Bibliotecário não tem acesso) |
| T41 | `✅ DEVE PASSAR` Registar doação — doador individual, valor ≥ 1000 MT | Carlos (Coord) | Doador: Manuel Guebuza (id=2), 1 item: valor 1000 MT, qtd 1 | Doação criada + **certificado gerado automaticamente** pelo trigger |
| T42 | `✅ DEVE PASSAR` Verificar certificado gerado | Carlos (Coord) | Ver detalhe da doação do T41 | Certificado CERT-2026-XXXX visível |
| T43 | `✅ DEVE PASSAR` Registar doação — doador individual, valor < 1000 MT | Carlos (Coord) | Doador: Manuel Guebuza (id=2), valor 500 MT, qtd 1 | Doação criada, **sem certificado** gerado |
| T44 | `✅ DEVE PASSAR` Registar doação — doador institucional, valor > 1000 MT | Carlos (Coord) | Doador: Editora Moçambicana (id=3), valor 5000 MT | Doação criada, **sem certificado** (tipo Institucional não gera) |
| T45 | `❌ DEVE FALHAR` Eliminar doador anónimo | Ana (Admin) | Tentar eliminar doador ID 0 (Anónimo) | Erro "O doador Anónimo (ID 0) não pode ser eliminado" (trigger) |
| T46 | `✅ DEVE PASSAR` Emitir certificado manual | Carlos (Coord) | Doação sem certificado (ex: doação 3 — Editora) | Certificado emitido manualmente |

### 1.7 Permissões (Admin only)

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T47 | `✅ DEVE PASSAR` Ver cargos | Ana (Admin) | — | Lista: Administrador, Coordenador, Bibliotecário, Assistente com contagem de funcionários |
| T48 | `✅ DEVE PASSAR` Ver funcionários de um cargo | Ana (Admin) | Seleccionar cargo Bibliotecário | Beatriz, Fernando, Ilda, Osvaldo, Amélia listados |
| T49 | `✅ DEVE PASSAR` Alterar cargo de funcionário | Ana (Admin) | Promover Domingos (Assist → Coord) | Cargo actualizado, nível de acesso muda |
| T50 | `✅ DEVE PASSAR` Reverter cargo | Ana (Admin) | Reverter Domingos para Assistente | Cargo volta ao original |

---

## 2. Nó MateriaisDB — VM Yasin (BIBMPC0001 mas ligado a MateriaisDB)

> **Responsável:** Yasin  
> **Ligação:** Aplicação apontada para MateriaisDB como nó de entrada  
> **Utilizadores a usar:** Carlos (Coord), Beatriz (Biblio), Ana (Admin), Esperança Bila (de BIBGZA — para testar transferências cross-library)

### 2.1 Materiais (CRUD)

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T51 | `✅ DEVE PASSAR` Ver lista materiais | Beatriz (Biblio) | — | Lista de materiais da biblioteca com categoria, estado, tipo |
| T52 | `✅ DEVE PASSAR` Adicionar livro físico | Beatriz (Biblio) | Título: "Novo Livro Teste", Autor: "Autor Teste", Categoria: Literatura, Biblioteca: BIBMPC0001 | Material criado, aparece na lista |
| T53 | `✅ DEVE PASSAR` Adicionar eBook | Carlos (Coord) | Título: "Ebook Teste", URL: "https://teste.mz/livro.pdf", Formato: PDF | Material tipo eBook criado |
| T54 | `✅ DEVE PASSAR` Editar material | Beatriz (Biblio) | Editar estado de MAT20190002 (Neighbours) para "Degradado" | Estado actualizado |
| T55 | `❌ DEVE FALHAR` Eliminar material | Beatriz (Biblio) | Tentar eliminar MAT20190002 | HTTP 403 — Bibliotecário não pode eliminar |
| T56 | `✅ DEVE PASSAR` Eliminar material | Carlos (Coord) | Eliminar o material criado em T52 | Material removido |
| T57 | `❌ DEVE FALHAR` Adicionar material | Domingos (Assist) | Qualquer | HTTP 403 — Assistente não pode adicionar |

### 2.2 Transferências — fluxo completo

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T58 | `✅ DEVE PASSAR` Ver lista transferências | Carlos (Coord) | — | 10 transferências seed visíveis (Pendente, Aprovada, Concluída, Rejeitada) |
| T59 | `✅ DEVE PASSAR` Criar transferência — material disponível, 2 exemplares | Carlos (Coord) | Material: MAT20190003 (Terra Sonâmbula ex.1), Origem: BIBMPC0001, Destino: BIBGZA0001 | Transferência criada (estado Pendente) — **MPC0001 tem 2 exemplares de Terra Sonâmbula** |
| T60 | `❌ DEVE FALHAR` Criar transferência — material com empréstimo activo | Carlos (Coord) | Material: MAT20190001 (Vozes Anoitecidas — emprestado) | Erro "Material tem empréstimo activo" (trigger) |
| T61 | `❌ DEVE FALHAR` Criar transferência — material com transferência activa | Carlos (Coord) | Material: MAT20190004 (Terra Sonâmbula ex.2 — já tem T1 Pendente) | Erro "Material já tem uma transferência activa" (trigger) |
| T62 | `❌ DEVE FALHAR` Criar transferência — único exemplar | Carlos (Coord) | Material: MAT20240003 (O Olho de Hertzog — único exemplar) | Erro "Transferência bloqueada: último exemplar disponível" (trigger protege_ultimo_exemplar) |
| T63 | `❌ DEVE FALHAR` Criar transferência — origem = destino | Carlos (Coord) | Origem: BIBMPC0001, Destino: BIBMPC0001 | Erro "Biblioteca origem deve ser diferente da destino" |
| T64 | `✅ DEVE PASSAR` Aprovar transferência | Carlos (Coord) | Aprovar T59 criada em T59 | Estado muda para Aprovada |
| T65 | `❌ DEVE FALHAR` Fluxo inválido — Pendente → Concluída | Carlos (Coord) | Tentar concluir T3 (estado Pendente) directamente | Erro "Fluxo inválido: Pendente → Concluída" (trigger) |
| T66 | `✅ DEVE PASSAR` Concluir transferência | Carlos (Coord) | Concluir T64 (estado Aprovada) | Estado Concluída; `cod_biblioteca` do material actualizado para BIBGZA0001 (trigger) |
| T67 | `❌ DEVE FALHAR` Alterar transferência já concluída | Carlos (Coord) | Tentar qualquer alteração em T4 (Concluída) | Erro "Transferência já está Concluída" (trigger) |
| T68 | `✅ DEVE PASSAR` Rejeitar transferência | Carlos (Coord) | Rejeitar T3 (Pendente: BIBGZA0001 → BIBNMP0001) | Estado muda para Rejeitada |
| T69 | `❌ DEVE FALHAR` Transferência — Assistente | Domingos (Assist) | — | Opção não visível |

---

## 3. Nó EmpréstimosDB — VM Yannis (BIBSOF0001 como nó de entrada)

> **Responsável:** Yannis  
> **Ligação:** Aplicação apontada para EmpréstimosDB  
> **Utilizadores a usar:** Helder (Coord/Beira), Ilda (Biblio/Beira), Jorge (Assist/Beira), Ana (Admin/Maputo — para verificar cross-node)

### 3.1 Empréstimos — regras de negócio críticas

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T70 | `✅ DEVE PASSAR` Criar empréstimo normal | Ilda (Biblio) | Leitor: SOF20250002 (António), Material: MAT20240005 (Introdução Informática) | Empréstimo criado, prazo = hoje + 14 dias |
| T71 | `✅ DEVE PASSAR` Devolver sem atraso | Ilda (Biblio) | Devolver empréstimo do T70 (prazo futuro) | Devolvido sem suspensão, histórico actualizado |
| T72 | `✅ DEVE PASSAR` Ver suspensões activas | Helder (Coord) | — | Tabela de suspensões visível (GZA20250001 tem suspensão cumprida) |
| T73 | `✅ DEVE PASSAR` Ver empréstimos vencidos (dashboard) | Helder (Coord) | — | Empréstimos com prazo expirado destacados (NMP20250002, MPC20250001, SOF20250002 têm vencidos nos dados de seed) |
| T74 | `❌ DEVE FALHAR` Criar empréstimo — leitor suspenso | Ilda (Biblio) | Suspender SOF20250002 manualmente (Carlos/Admin), depois tentar criar empréstimo | Erro "Leitor não pode emprestar. Status: Suspenso" |
| T75 | `❌ DEVE FALHAR` Criar empréstimo — leitor bloqueado | Ilda (Biblio) | Leitor: SOF20250002 se estiver bloqueado (verificar estado) | Erro "Leitor não pode emprestar. Status: Bloqueado" |
| T76 | `✅ DEVE PASSAR` Reduzir suspensão | Helder (Coord) | Seleccionar suspensão activa, reduzir dias | Dias de suspensão actualizados |
| T77 | `❌ DEVE FALHAR` Reduzir suspensão | Jorge (Assist) | — | HTTP 403 — Assistente não pode reduzir |

### 3.2 Programas de Alfabetização

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T78 | `✅ DEVE PASSAR` Ver programas | Jorge (Assist) | — | Lista de programas activos (5 programas seed visíveis) |
| T79 | `✅ DEVE PASSAR` Ver detalhe do programa | Ilda (Biblio) | Seleccionar PROBIBSOF20250001 (Beira Digital) | Descrição, participantes, materiais e funcionários |
| T80 | `✅ DEVE PASSAR` Criar programa | Helder (Coord) | Nome: "Programa Teste Beira", Biblioteca: BIBSOF0001, Público: Iniciantes, Duração: 12 semanas | Programa criado |
| T81 | `✅ DEVE PASSAR` Gerir participantes — inscrever leitor | Ilda (Biblio) | Programa: PROBIBSOF20250001, Leitor: SOF20250001 (Angelina) | Participação registada |
| T82 | `✅ DEVE PASSAR` Avançar nível de participante | Ilda (Biblio) | SOF20250001 no programa Beira Digital: avançar de Módulo 1 para Módulo 2 | Nível actualizado |
| T83 | `❌ DEVE FALHAR` Criar programa | Jorge (Assist) | — | HTTP 403 — Assistente não pode criar programas |
| T84 | `✅ DEVE PASSAR` Ver programa de outra biblioteca | Helder (Coord) | Navegar até PROBIBMPC20250001 (Maputo) | Dados visíveis (transparência cross-node) |

### 3.3 Cross-node: Empréstimos visíveis de outros nós

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T85 | `✅ DEVE PASSAR` Ver empréstimo criado no Nó 1 | Helder (Coord) | Verificar lista de empréstimos | Empréstimos criados na VM do Hélder (nó NacionalDB) devem estar visíveis aqui via snapshots |
| T86 | `✅ DEVE PASSAR` Verificar leitor de outra biblioteca | Ilda (Biblio) | Pesquisar leitor MPC20250001 (Maria — Maputo) | Dados do leitor visíveis (via snapshot snap_leitor) |

---

## 4. Nó EventosBibliotecasDB — VM Gerson (BIBGZA0001 como nó de entrada)

> **Responsável:** Gerson  
> **Ligação:** Aplicação apontada para EventosBibliotecasDB  
> **Utilizadores a usar:** Esperança Bila (Coord/Xai-Xai), Fernando Mondlane (Biblio/Xai-Xai), Graça Tembe (Assist/Xai-Xai)

### 4.1 Eventos — CRUD e fluxo de estados

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T87 | `✅ DEVE PASSAR` Ver lista de eventos | Graça (Assist) | — | 10 eventos seed visíveis com estado, data e capacidade |
| T88 | `✅ DEVE PASSAR` Ver detalhe de evento | Fernando (Biblio) | Evento 2: "Dia da Criança na Biblioteca" | Dados completos + recursos + participações |
| T89 | `✅ DEVE PASSAR` Criar evento | Esperança (Coord) | Título: "Tarde de Leitura — Julho 2026", Data: 2026-07-15 (Quarta — BIBGZA0001 abre Qua), Capacidade: 30 | Evento criado com estado Planeado |
| T90 | `✅ DEVE PASSAR` Criar evento | Fernando (Biblio) | Título: "Oficina de Leitura", Data: 2026-08-05 | Evento criado |
| T91 | `❌ DEVE FALHAR` Cancelar evento | Fernando (Biblio) | Tentar cancelar evento 9 (Clube Paulo Coelho) | HTTP 403 — Bibliotecário não pode cancelar |
| T92 | `✅ DEVE PASSAR` Cancelar evento | Esperança (Coord) | Cancelar o evento criado em T90 | Estado muda para Cancelado |
| T93 | `❌ DEVE FALHAR` Criar evento | Graça (Assist) | — | HTTP 403 — Assistente não pode criar eventos |
| T94 | `✅ DEVE PASSAR` Inscrever participante em evento | Graça (Assist) | Evento 9 (BIBGZA0001), Leitor: GZA20250001 | Participação registada |
| T95 | `✅ DEVE PASSAR` Confirmar presença | Fernando (Biblio) | Evento 2, Leitor GZA20250001 | Presença confirmada (presenca_confirmacao = 'S') |
| T96 | `✅ DEVE PASSAR` Ver evento de outra biblioteca | Esperança (Coord) | Navegar até Evento 7 (BIBMPC0001 — Semana Leitura Infantil) | Dados visíveis (transparência cross-node) |

### 4.2 Bibliotecas — Gestão da rede

| # | Acção | Utilizador | Dados | Esperado |
|---|---|---|---|---|
| T97 | `✅ DEVE PASSAR` Ver lista de bibliotecas | Ana (Admin) — fazer login | — | 5 bibliotecas com localização, capacidade, contacto |
| T98 | `✅ DEVE PASSAR` Ver detalhe de biblioteca | Esperança (Coord) | Seleccionar BIBGZA0001 | Horários, responsável, contacto |
| T99 | `❌ DEVE FALHAR` Ver módulo Bibliotecas (rede) | Esperança (Coord) | Tentar aceder Bibliotecas (rede) | Opção não visível — só Admin vê a rede |
| T100 | `✅ DEVE PASSAR` Ver biblioteca própria | Esperança (Coord) | Ir a "Minha Biblioteca" | Dados de BIBGZA0001 visíveis |

---

## 5. Verificação Cross-Node — Todos os nós em simultâneo

> Estes testes exigem que **pelo menos dois nós estejam online ao mesmo tempo**. Cada acção é feita num nó e o resultado verificado noutro.
>
> **Pré-requisito:** Snapshots instalados (passos 3, 4 e 5 do README).

### 5.1 Propagação de dados entre nós

| # | Acção no Nó A | Verificação no Nó B | Esperado |
|---|---|---|---|
| TC01 | **[Nó Hélder/NacionalDB]** Beatriz cria novo leitor: "Verificação Cross Node", Adulto | **[Nó Yannis/EmpréstimosDB]** Pesquisar o leitor recém-criado | Leitor visível (via snapshot snap_leitor) — após refresh do snapshot |
| TC02 | **[Nó Hélder/NacionalDB]** Beatriz cria empréstimo para MPC20250002 — MAT20190002 | **[Nó Yasin/MateriaisDB]** Verificar estado de MAT20190002 | Material aparece como indisponível para transferência (trigger trg_transferencia_insert bloqueia via emprestimo_activo) |
| TC03 | **[Nó Hélder/NacionalDB]** Carlos cria evento na BIBMPC0001 | **[Nó Gerson/EventosBibliotecasDB]** Ver lista de eventos | Novo evento visível (EventosDB é o nó master de eventos) |
| TC04 | **[Nó Yasin/MateriaisDB]** Carlos solicita transferência de MAT20240003 (único exemplar) | **[Nó Yasin]** Confirmar erro | Erro "último exemplar disponível" — nó MateriaisDB protege via trigger |
| TC05 | **[Nó Yannis/EmpréstimosDB]** Ilda devolve empréstimo com 10 dias de atraso (ajustar data no formulário) | **[Nó Hélder/NacionalDB]** Ver status do leitor | Leitor com status "Suspenso" (trigger trg_aplica_suspensao actualiza via dblink cross-node) |
| TC06 | **[Nó Gerson/EventosBibliotecasDB]** Esperança regista biblioteca responsável Fernando Mondlane | **[Nó Hélder/NacionalDB]** Ana tenta eliminar Fernando | Erro "Coordenador não pode ser removido enquanto for responsável" (trigger impede_exclusao_coordenador via dblink EventosBibliotecasDB) |
| TC07 | **[Nó Hélder/NacionalDB]** Carlos regista doação Individual de 1200 MT (Manuel Guebuza) | **[Nó Hélder]** Ver certificados | Certificado CERT-2026-XXXX gerado automaticamente (trigger gera_certificado_automatico) |
| TC08 | **[Nó Yasin/MateriaisDB]** Carlos conclui transferência T2 (BIBNMP0001 → BIBQLM0001, MAT20250013) | **[Nó Hélder ou Gerson]** Consultar material MAT20250013 | Material agora aparece na BIBQLM0001 (cod_biblioteca actualizado pelo trigger trg_transferencia_fluxo) |
| TC09 | **[Qualquer nó]** Login com Ana (Admin) | **[Outro nó]** Login com Ana | Interface idêntica — nível de acesso Admin reflectido em todos os nós via snapshot repl_funcionarios |
| TC10 | **[Nó Yannis]** Criar empréstimo para SOF20250002 com material MAT20240005 | **[Nó Yasin]** Tentar criar transferência de MAT20240005 | Erro "Material tem empréstimo activo" — EmprestimosDB confirma via snapshot emprestimo_activo |

---

## 6. Testes de Segurança e Robustez

| # | Acção | Esperado |
|---|---|---|
| TS01 | Tentar aceder `/api/leitores` sem sessão (Postman/curl) | HTTP 401 — "Não autenticado" |
| TS02 | Tentar `GET /api/funcionarios` com sessão de Bibliotecário | HTTP 403 — "Acesso negado" |
| TS03 | Tentar `DELETE /api/leitores/MPC20250001` com sessão de Coordenador | HTTP 403 |
| TS04 | Login com utilizador demo → tentar criar empréstimo via UI | Erro "Utilizador demo não pode realizar esta acção" |
| TS05 | Submeter formulário com campos obrigatórios vazios (ex: criar leitor sem nome) | HTTP 400 com mensagem descritiva dos campos em falta |
| TS06 | Tentar fazer dois logins simultâneos com o mesmo utilizador | Segundo login substitui sessão (comportamento Express Session) |

---

## 7. Checklist Final — antes de fechar os testes

- [ ] Cada nó consegue fazer login independente (sem o outro nó online)
- [ ] Os 4 níveis de acesso (Admin, Coord, Biblio, Assist) têm as opções correctas no menu
- [ ] Criar + devolver empréstimo funciona end-to-end (com trigger de suspensão se atraso)
- [ ] Certificado é gerado automaticamente para doação Individual ≥ 1000 MT
- [ ] Transferência segue o fluxo Pendente → Aprovada → Concluída; fluxo invertido é bloqueado
- [ ] Leitor criado num nó é visível noutro nó (após snapshot refresh)
- [ ] Suspensão criada no EmpréstimosDB actualiza status do leitor no NacionalDB
- [ ] Último exemplar de um título não pode ser transferido
- [ ] Material com empréstimo activo não pode ser transferido

---

## 8. Tabela de Regras de Negócio Testadas

| Regra | Onde é aplicada | Testes |
|---|---|---|
| RN01 — Limite 1 empréstimo por leitor | Trigger `trg_valida_emprestimo` (EmprestimosDB) | T23 |
| RN02 — Leitor activo obrigatório | Trigger `trg_valida_emprestimo` (EmprestimosDB) | T74, T75 |
| RN03 — Suspensão progressiva por atraso | Trigger `trg_aplica_suspensao` (EmprestimosDB) | TC05 |
| RN04 — Bloqueio por atraso > 60 dias | Trigger `trg_aplica_suspensao` (EmprestimosDB) | (estado seed SOF20250002) |
| RN05 — Faixa etária em empréstimos para crianças | Trigger `trg_valida_emprestimo` (EmprestimosDB) | T26 |
| RN06 — Fluxo de estados de transferência | Trigger `trg_transferencia_fluxo` (MateriaisDB) | T65, T67 |
| RN07 — Protecção último exemplar | Trigger `protege_ultimo_exemplar_*` (MateriaisDB) | T62 |
| RN08 — Certificado automático Individual ≥ 1000 MT | Trigger `gera_certificado_automatico` (NacionalDB) | T41, T43, T44, TC07 |
| RN09 — Funcionário da origem/destino correcto | Trigger `trg_valida_transferencia` (MateriaisDB) | T63 |
| RN10 — Doador anónimo inviolável | Trigger `trg_protege_doador_anonimo` (NacionalDB) | T45 |
| RN11 — Coordenador responsável não pode ser eliminado | Trigger `impede_exclusao_coordenador` (NacionalDB) | T37, TC06 |
| RN12 — Acesso por nível de cargo | Middleware `exigirNivel` (backend) | T07, T08, T11, T31, T57... |

---

*Documento gerado com base nos scripts SQL de seed e triggers do sistema Saber Comunitário v5 — 2026-06-02*
