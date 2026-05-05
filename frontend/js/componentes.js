// ════════════════════════════════════════════════
//  Componentes reutilizáveis — usar sempre estes.
//  Nunca recriar inline o que já existe aqui.
// ════════════════════════════════════════════════

function emptyState(icone, msg, sub) {
  return `<div class="empty-state">
    <div class="empty-state-icon">${icone}</div>
    <div class="empty-state-text">${msg}</div>
    ${sub ? `<div class="empty-state-sub">${sub}</div>` : ''}
  </div>`;
}
