-- EMPRÉSTIMO
CREATE INDEX ie_cartao ON EMPRESTIMO(num_cartao);
CREATE INDEX ie_material ON EMPRESTIMO(cod_material);
CREATE INDEX ie_dt_ret ON EMPRESTIMO(data_retirada);
CREATE INDEX ie_prazo ON EMPRESTIMO(prazo_devolucao);
CREATE INDEX ie_dt_dev ON EMPRESTIMO(data_devolucao);

-- MATERIAL
CREATE INDEX im_categ ON MATERIAL_BIBLIOGRAFICO(cod_categoria);
CREATE INDEX im_bib ON MATERIAL_BIBLIOGRAFICO(cod_biblioteca);
CREATE INDEX im_tit ON MATERIAL_BIBLIOGRAFICO(titulo);
CREATE INDEX im_aut ON MATERIAL_BIBLIOGRAFICO(autor);
CREATE INDEX im_est ON MATERIAL_BIBLIOGRAFICO(estado_material_conservacao);

-- LEITOR
CREATE INDEX il_nome ON LEITOR(nome_completo);
CREATE INDEX il_local ON LEITOR(localizacao_leitor);
CREATE INDEX il_bib ON LEITOR(cod_biblioteca);

-- TRANSFERÊNCIA
CREATE INDEX it_mat ON TRANSFERENCIA(cod_material);
CREATE INDEX it_est ON TRANSFERENCIA(estado_transferencia);
CREATE INDEX it_orig ON TRANSFERENCIA(cod_biblioteca_origem);
CREATE INDEX it_dest ON TRANSFERENCIA(cod_biblioteca_destino);

-- DOAÇÃO
CREATE INDEX id_doa ON DOACAO(id_doador);
CREATE INDEX id_dt ON DOACAO(data_doacao);

-- EVENTO
CREATE INDEX iev_bib ON EVENTO(cod_biblioteca);
CREATE INDEX iev_dt ON EVENTO(data_evento);

-- PARTICIPAÇÃO
CREATE INDEX ip_ev ON PARTICIPACAO_EVENTO(id_evento);

-- FUNCIONÁRIO
CREATE INDEX if_bib ON FUNCIONARIO(cod_biblioteca);
CREATE INDEX if_func ON FUNCIONARIO(id_funcao);
CREATE INDEX if_form   ON FUNCIONARIO(formacao);

-- PROGRAMA_ALFABETIZACAO
CREATE INDEX iprog_bib ON PROGRAMA_ALFABETIZACAO(cod_biblioteca);
CREATE INDEX iprog_est ON PROGRAMA_ALFABETIZACAO(estado_programa);

-- PARTICIPACAO_PROGRAMA
CREATE INDEX ipp_prog  ON PARTICIPACAO_PROGRAMA(cod_programa);
CREATE INDEX ipp_nivel ON PARTICIPACAO_PROGRAMA(id_nivel_atual);

-- ADULTO
CREATE INDEX ia_lit ON ADULTO(nivel_literacia);

-- SUSPENSAO
CREATE INDEX isusp_nc  ON SUSPENSAO(num_cartao);
CREATE INDEX isusp_emp ON SUSPENSAO(id_emprestimo);
CREATE INDEX isusp_est ON SUSPENSAO(estado_suspensao);

-- HORARIO_BIBLIOTECA
CREATE INDEX ihb_bib ON HORARIO_BIBLIOTECA(cod_biblioteca);

-- HORARIO_FUNCIONARIO
CREATE INDEX ihf_func ON HORARIO_FUNCIONARIO(cod_funcionario);

-- BIBLIOTECA_RESPONSAVEL
CREATE INDEX ibr_func ON BIBLIOTECA_RESPONSAVEL(cod_funcionario);

-- HORARIO_EVENTO
CREATE INDEX ihev_ev ON HORARIO_EVENTO(id_evento);

-- ADULTO_INTERESSE
CREATE INDEX iai_nc ON ADULTO_INTERESSE(num_cartao);

-- AVALIACAO_EVENTO
CREATE INDEX iav_ev   ON AVALIACAO_EVENTO(id_evento);
CREATE INDEX iav_leit ON AVALIACAO_EVENTO(num_cartao);

-- FUNCIONARIO_HABILIDADE
CREATE INDEX ifh_func ON FUNCIONARIO_HABILIDADE(cod_funcionario);

-- EVENTO
CREATE INDEX iev_status ON EVENTO(status_evento);
CREATE INDEX iev_resp   ON EVENTO(cod_funcionario_responsavel);