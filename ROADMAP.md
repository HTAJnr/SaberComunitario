# ROADMAP — Saber Comunitário

## FASE 1 — Corrigir Routes Existentes (código do TP1)

- [x] `auth.js` — verificar login, sessão, demo user conforme §1 do frontend_guide
- [x] `dashboard.js` — verificar `/rede` (só Admin) e `/biblioteca` com campos correctos §4
- [x] `leitores.js` — verificar GET lista, GET perfil completo (subtipo + empréstimo activo + histórico + suspensões + multas), POST, PATCH, DELETE, PATCH `/status` §5
- [x] `emprestimos.js` — verificar GET lista, GET `validar-leitor`, POST `calcular-prazo`, POST criar, PATCH `devolver` (com resumo dias/multa/suspensão), PATCH `pagar-multa`, POST `preview-devolucao` §6 + §15
- [x] `materiais.js` — verificar GET lista, GET detalhe (subtipo + histórico + transferências), POST, PATCH, DELETE §7
- [x] `funcionarios.js` — verificar GET lista, GET detalhe, POST, PATCH, DELETE, PATCH `/acesso` (só Admin), GET `/me`, PATCH `/me`, PATCH `/me/senha` §2 + §12
- [x] `eventos.js` — verificar GET lista, POST criar (com horários + recursos), POST `/participantes`, DELETE `/participantes/:num_cartao`, PATCH `/status` §9
- [x] `doacoes.js` — verificar GET lista, POST criar, POST `/:id/certificado`, GET `/doadores`, POST `/doadores` §10

## FASE 2 — Implementar Routes em Falta

- [x] `transferencias.js` — GET lista (`?direcao&estado`), POST solicitar, PATCH aprovar, PATCH rejeitar, PATCH concluir §8
- [ ] `programas.js` — GET lista, POST criar, GET `/:cod/participantes`, POST `/participantes`, PATCH `/participantes/:num_cartao` §11
- [ ] `bibliotecas.js` — GET lista (só Admin), GET `/:cod`, POST (só Admin), PATCH §13
- [ ] `server.js` — montar as 3 novas routes

## FASE 3 — Endpoints e Validações em Falta

- [ ] `GET /api/leitores/:num_cartao/suspensoes` §14
- [ ] `PATCH /api/suspensoes/:id/reduzir` §14
- [ ] Validar respostas de erro padronizadas em todos os routes (formato `{ erro, codigo, mensagem, detalhes }` §16)
- [ ] Validar permissões por `nivel_acesso` em todas as rotas protegidas (matriz §3)

## FASE 4 — Frontend (BLOQUEADO até Fase 1–3 concluídas)

> Ver `resources/docs/SCREENS.md` para especificação completa de cada tela.

- [ ] TELA 02 — Leitores (wizard 02-B, drawer 02-C com 5 tabs, modais 02-D/E/F)
- [ ] TELA 03 — Empréstimos (wizard 03-D com prazo calculado, modal devolução 03-C com preview multa)
- [ ] TELA 04 — Materiais (wizard 04-D com 3 steps, drawer 04-B com 3 tabs)
- [ ] TELA 05 — Transferências
- [ ] TELA 06 — Eventos (com horários e recursos dinâmicos)
- [ ] TELA 07 — Doações (wizard 07-D com doador anónimo)
- [ ] TELA 08 — Programas de Alfabetização
- [ ] TELA 09 — Funcionários (wizard 09-E, modal permissões 09-D com preview)
- [ ] TELA 10 — Permissões
- [ ] TELA 11 — Biblioteca (vista Admin rede + vista Coord própria)
