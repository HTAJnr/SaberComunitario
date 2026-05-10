# VW_AUDITORIA — Interface Padronizada de Auditoria

## Contexto

O backend do Saber Comunitário usa uma única query para ler registos de auditoria:

```
SELECT * FROM VW_AUDITORIA ORDER BY data_operacao DESC
```

O Oracle resolve `VW_AUDITORIA` para a tabela do schema activo — se o servidor arrancar com `DB_USER=usr_emprestimosdb`, resolve para os dados do Yannis; com `DB_USER=usr_eventosdb`, resolve para os do Gerson. Isso é transparência de localização aplicada à auditoria: o backend não sabe em que nó está, não precisa de saber.

**Cada um de vós precisa de criar esta view no seu schema.** Sem ela, a tela de auditoria vai dar erro quando o servidor correr no vosso nó.

---

## O que precisas de criar

Uma view chamada exactamente `VW_AUDITORIA` no teu schema (`usr_emprestimosdb`, `usr_materiaisdb` ou `usr_eventosdb`).

A view tem de expor estas colunas — com estes nomes exactos:

| Coluna | Tipo | Descrição |
|---|---|---|
| `id_auditoria` | NUMBER | Chave da linha de auditoria |
| `data_operacao` | DATE | Quando aconteceu |
| `operacao` | VARCHAR2 | Nome da operação (ex: `'CRIAR_EMPRESTIMO'`) |
| `resultado` | VARCHAR2 | `'SUCESSO'` ou `'FALHA'` |
| `motivo_falha` | VARCHAR2 | Preenchido quando resultado = `'FALHA'`, NULL nos outros casos |
| `nos_afetados` | VARCHAR2 | Nós envolvidos (ex: `'BibliotecaNacionalDB, MateriaisDB'`) |
| `observacoes` | VARCHAR2 | Notas adicionais |
| `no_origem` | VARCHAR2 | **Literal hardcoded** que identifica o teu nó — ver abaixo |

O campo `no_origem` é um literal de texto fixo que identificas o teu nó. Não vem de nenhuma coluna da tua tabela — é definido directamente na view. Usa o nome do teu nó:
- Yannis → `'EMPRESTIMOS'`
- Yasin → `'MATERIAIS'`
- Gerson → `'EVENTOS'`

---

## Como construir a view

A view é um `SELECT` sobre a tua tabela de auditoria manual (a que criaste com `PRAGMA AUTONOMOUS_TRANSACTION`). Mapeia as colunas da tua tabela para os nomes padronizados acima.

As tuas tabelas têm colunas específicas do domínio (ex: `num_cartao`, `cod_material`, `id_evento`) que o backend não usa na tela geral — não precisas de as incluir, mas podes se quiseres (o backend ignora colunas extras).

O que importa é que as **8 colunas listadas acima existam com esses nomes exactos**.

Se a tua tabela de auditoria tiver nomes de colunas ligeiramente diferentes dos padronizados, usa `AS` para os renomear na view:

```sql
-- Exemplo genérico (não copiar directamente — adapta às tuas colunas)
CREATE OR REPLACE VIEW VW_AUDITORIA AS
SELECT
    id_auditoria,
    data_operacao,
    operacao,
    resultado,
    motivo_falha,
    nos_afetados,
    observacoes,
    'NOME_DO_TEU_NO' AS no_origem
FROM NOME_DA_TUA_TABELA_AUDITORIA;
```

---

## Mapeamento por colega

### Yannis — EmpréstimosProgramasDB

A tua tabela chama-se `AUDITORIA_EMPRESTIMOS`. As tuas colunas são: `id_auditoria`, `data_operacao`, `operacao`, `num_cartao`, `cod_material`, `id_emprestimo`, `resultado`, `motivo_falha`, `nos_afetados`, `observacoes`.

Todas as colunas padronizadas já existem na tua tabela com os mesmos nomes. Basta seleccioná-las e adicionar o literal `'EMPRESTIMOS' AS no_origem`.

### Yasin — MateriaisDB

A tua tabela chama-se `AUDITORIA_MATERIAIS`. As tuas colunas incluem: `id_auditoria`, `data_operacao`, `operacao`, `cod_material`, `id_transferencia`, `estado_anterior`, `estado_novo`, `resultado`, `motivo_falha`, `nos_afetados`, `observacoes`.

Todas as colunas padronizadas já existem. Adiciona `'MATERIAIS' AS no_origem`.

### Gerson — EventosBibliotecasDB

A tua tabela chama-se `AUDITORIA_EVENTOS`. As tuas colunas incluem: `id_auditoria`, `data_operacao`, `operacao`, `id_evento`, `cod_biblioteca`, `num_cartao`, `resultado`, `motivo_falha`, `nos_afetados`, `observacoes`.

Todas as colunas padronizadas já existem. Adiciona `'EVENTOS' AS no_origem`.

---

## Verificação

Depois de criar a view, confirma com:

```sql
SELECT * FROM VW_AUDITORIA WHERE ROWNUM <= 5;
```

Se retornar linhas (ou zero linhas sem erro), está correcto. Se der `ORA-00942: table or view does not exist`, a view não foi criada no schema correcto. Verifica que estás ligado com o utilizador certo (`usr_emprestimosdb`, `usr_materiaisdb` ou `usr_eventosdb`).

---

## Porquê isto funciona

O backend conecta-se ao Oracle com um `DB_USER` específico (definido no `.env` de cada instância). Quando escreve `SELECT * FROM VW_AUDITORIA`, o Oracle procura `VW_AUDITORIA` no schema desse utilizador. Se o utilizador for `usr_emprestimosdb`, encontra a view do Yannis. Se for `usr_eventosdb`, encontra a do Gerson.

É o mesmo princípio dos sinónimos — transparência de localização — mas aplicado a uma view local em vez de um objecto remoto.
