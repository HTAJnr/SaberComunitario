-- EMPRÉSTIMO
CREATE INDEX ie_cartao ON EMPRESTIMO(num_cartao);
CREATE INDEX ie_material ON EMPRESTIMO(id_material);
CREATE INDEX ie_dt_ret ON EMPRESTIMO(data_retirada);
CREATE INDEX ie_prazo ON EMPRESTIMO(prazo_devolucao);
CREATE INDEX ie_dt_dev ON EMPRESTIMO(data_devolucao);

-- MATERIAL
CREATE INDEX im_categ ON MATERIAL_BIBLIOGRAFICO(id_categoria);
CREATE INDEX im_bib ON MATERIAL_BIBLIOGRAFICO(id_biblioteca);
CREATE INDEX im_tit ON MATERIAL_BIBLIOGRAFICO(titulo);
CREATE INDEX im_aut ON MATERIAL_BIBLIOGRAFICO(autor);
CREATE INDEX im_est ON MATERIAL_BIBLIOGRAFICO(estado_material_conservacao);

-- LEITOR
CREATE INDEX il_nome ON LEITOR(nome_completo);
CREATE INDEX il_local ON LEITOR(localizacao_leitor);

-- TRANSFERÊNCIA
CREATE INDEX it_mat ON TRANSFERENCIA(id_material);
CREATE INDEX it_est ON TRANSFERENCIA(estado_transferencia);
CREATE INDEX it_orig ON TRANSFERENCIA(id_biblioteca_origem);
CREATE INDEX it_dest ON TRANSFERENCIA(id_biblioteca_destino);

-- DOAÇÃO
CREATE INDEX id_doa ON DOACAO(id_doador);
CREATE INDEX id_dt ON DOACAO(data_doacao);

-- EVENTO
CREATE INDEX iev_bib ON EVENTO(id_biblioteca);
CREATE INDEX iev_dt ON EVENTO(data_evento);

-- PARTICIPAÇÃO
CREATE INDEX ip_ev ON PARTICIPACAO_EVENTO(id_evento);

-- FUNCIONÁRIO
CREATE INDEX if_bib ON FUNCIONARIO(id_biblioteca);
CREATE INDEX if_func ON FUNCIONARIO(id_funcao);