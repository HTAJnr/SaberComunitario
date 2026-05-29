const { getNoOrigem } = require('../db');

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

function exigirNo(...nos) {
  return (req, res, next) => {
    const noActual = getNoOrigem();
    if (!nos.includes(noActual)) {
      return res.status(403).json({
        erro: true,
        codigo: 'NO_ERRADO',
        mensagem: `Operação exclusiva do nó ${nos.join(' ou ')}. Nó actual: ${noActual}.`,
      });
    }
    next();
  };
}

module.exports = { autenticar, exigirNivel, exigirNo };
