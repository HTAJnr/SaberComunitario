function autenticar(req, res, next) {
  if (!req.session.funcionario) {
    return res.status(401).json({
      erro: true,
      codigo: 'NAO_AUTENTICADO',
      mensagem: 'Sessão expirada. Faça login novamente.'
    });
  }
  next();
}

function exigirNivel(...niveis) {
  return [
    autenticar,
    (req, res, next) => {
      const nivel = req.session.nivel_acesso || req.session.funcionario?.NIVEL_ACESSO || '';
      if (!niveis.includes(nivel)) {
        return res.status(403).json({
          erro: true,
          codigo: 'SEM_PERMISSAO',
          mensagem: 'Nível de acesso insuficiente para esta operação.'
        });
      }
      next();
    }
  ];
}

module.exports = { autenticar, exigirNivel };
