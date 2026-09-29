extends Control

#region VARIÁVEIS DA INTERFACE
var prato_selecionado: int = -1 
var pessoa_selecionada: int = -1 
var tempero_selecionado: String = "" 
var escolha_rato_tipo: String = "" 
var pratos_selecionados: Array = [] 
var motivo_inbox: String = "" 
var tempo_discussao: int = 120
var voto_selecionado: int = -1 # Guarda em quem o jogador atual está votando
var fase_passagem: String = "noite"
#endregion

#region INICIALIZAÇÃO
func _ready() -> void:
	# Menu Debug Lateral
	$VBoxContainer/BtnSetup.pressed.connect(_on_btn_setup_pressed)
	$VBoxContainer/BtnDia.pressed.connect(_on_btn_dia_pressed)
	$VBoxContainer/BtnVotacao.pressed.connect(_on_btn_votacao_pressed)
	$VBoxContainer/BtnNoitePassagem.pressed.connect(_on_btn_noite_passagem_pressed)
	$VBoxContainer/BtnNoiteAcao.pressed.connect(_on_btn_noite_acao_pressed)
	$VBoxContainer/BtnAmanhecer.pressed.connect(_on_btn_amanhecer_pressed)
	
	# Votaçao
	$PainelVotacao/BtnConfirmarVoto.pressed.connect(_on_btn_confirmar_voto_pressed)
	$PainelSeguranca/BtnFecharSeguranca.pressed.connect(_on_btn_fechar_seguranca_pressed)
	$PainelResultadoVotacao/BtnContinuarResultado.pressed.connect(_on_btn_continuar_resultado_pressed)
	
	# Noite e Pop-ups
	$PainelPassagem/BtnSouEu.pressed.connect(_on_btn_sou_eu_pressed)
	$PainelAcao/BtnConfirmarAcao.pressed.connect(_on_btn_confirmar_acao_pressed)
	$PainelInbox/BtnFecharInbox.pressed.connect(_on_btn_fechar_inbox_pressed)
	
	# Telas Dia e Timer
	$PainelAmanhecer/BtnIniciarDia.pressed.connect(_on_btn_iniciar_dia_pressed)
	$PainelDia/TimerDia.timeout.connect(_on_timer_dia_timeout)
	$PainelDia/BtnEncerrarReuniao.pressed.connect(_on_btn_encerrar_reuniao_pressed)
	
	# Botões Cozinheiro
	$PainelAcao/ContainerTemperos/BtnSal.pressed.connect(_on_btn_sal_pressed)
	$PainelAcao/ContainerTemperos/BtnPimenta.pressed.connect(_on_btn_pimenta_pressed)
	$PainelAcao/ContainerTemperos/BtnNenhum.pressed.connect(_on_btn_nenhum_pressed) 
	
	# Botões Rato
	$PainelAcao/ContainerEscolhaRato/BtnCheirarPratos.pressed.connect(_on_btn_cheirar_pratos_pressed)
	$PainelAcao/ContainerEscolhaRato/BtnCheirarPessoas.pressed.connect(_on_btn_cheirar_pessoas_pressed)

	esconder_tudo()
	
func comecar_o_jogo_de_verdade() -> void:
	GameManager.iniciar_partida(6) # Você escolhe quantos jogadores são aqui
	
	# Inicia a tela de DIA automaticamente
	esconder_tudo()
	$PainelDia.show()
	tempo_discussao = 120
	atualizar_texto_relogio()
	$PainelDia/TimerDia.start()

func esconder_tudo() -> void:
	$PainelPassagem.hide()
	$PainelAcao.hide()
	$PainelInbox.hide() 
	$PainelAmanhecer.hide()
	$PainelDia.hide()
	$PainelVotacao.hide()
	$PainelSeguranca.hide()
	$PainelResultadoVotacao.hide()
#endregion

#region BOTÕES DO MENU LATERAL DE TESTE
func _on_btn_setup_pressed() -> void:
	esconder_tudo()
	GameManager.mudar_estado(GameManager.EstadoJogo.SETUP)

func _on_btn_dia_pressed() -> void:
	_on_btn_iniciar_dia_pressed()

func _on_btn_votacao_pressed() -> void:
	fase_passagem = "votacao" # <-- AVISANDO A INTERFACE
	esconder_tudo()
	GameManager.mudar_estado(GameManager.EstadoJogo.VOTACAO)
	$PainelVotacao.show()
	preparar_tela_votacao()

func _on_btn_noite_passagem_pressed() -> void:
	fase_passagem = "noite" # <-- AVISANDO A INTERFACE
	esconder_tudo()
	GameManager.mudar_estado(GameManager.EstadoJogo.NOITE_PASSAGEM)
	if GameManager.estado_atual == GameManager.EstadoJogo.NOITE_PASSAGEM:
		$PainelPassagem.show()
		preparar_tela_passagem()

func _on_btn_noite_acao_pressed() -> void:
	fase_passagem = "noite" # <-- AVISANDO A INTERFACE
	esconder_tudo()
	GameManager.mudar_estado(GameManager.EstadoJogo.NOITE_ACAO)
	$PainelAcao.show()
	configurar_tela_por_cargo()

func _on_btn_amanhecer_pressed() -> void:
	esconder_tudo()
	GameManager.mudar_estado(GameManager.EstadoJogo.AMANHECER)
	$PainelAmanhecer/LabelRelatorio.text = GameManager.relatorio_amanhecer
	$PainelAmanhecer.show()
#endregion

#region TELA DO DIA E CRONÔMETRO
func _on_btn_iniciar_dia_pressed() -> void:
	var status_partida = GameManager.verificar_vitoria()
	
	if status_partida != "CONTINUA":
		exibir_tela_vitoria(status_partida)
		return # Para a execução aqui e não inicia o dia
		
	esconder_tudo()
	GameManager.mudar_estado(GameManager.EstadoJogo.DIA)
	$PainelDia.show()
	tempo_discussao = 120
	atualizar_texto_relogio()
	$PainelDia/TimerDia.start()

func _on_btn_encerrar_reuniao_pressed() -> void:
	$PainelDia/TimerDia.stop()
	esconder_tudo()
	print("⏭️ REUNIÃO ENCERRADA MAIS CEDO! Indo para a Votação...")
	
	GameManager.mudar_estado(GameManager.EstadoJogo.VOTACAO)
	iniciar_passagem_votacao()

func _on_timer_dia_timeout() -> void:
	tempo_discussao -= 1
	atualizar_texto_relogio()
	
	if tempo_discussao <= 0:
		$PainelDia/TimerDia.stop()
		esconder_tudo()
		print("⏰ TEMPO ESGOTADO! Indo para a Votação...")
		GameManager.mudar_estado(GameManager.EstadoJogo.VOTACAO)
		iniciar_passagem_votacao()

func atualizar_texto_relogio() -> void:
	var minutos = tempo_discussao / 60
	var segundos = tempo_discussao % 60
	$PainelDia/LabelRelogio.text = "%02d:%02d" % [minutos, segundos]
#endregion

#region CONTROLE DE PASSA-E-REPASSA
func preparar_tela_passagem() -> void:
	var jogador = GameManager.get_jogador_atual() 
	$PainelPassagem/BtnSouEu.hide()
	$PainelPassagem/LabelPassagem.text = "Passe o celular para:\n" + jogador.nome 
	await get_tree().create_timer(4.0).timeout
	$PainelPassagem/LabelPassagem.text = "Você é o(a) " + jogador.nome + "?" 
	$PainelPassagem/BtnSouEu.show()

func _on_btn_sou_eu_pressed() -> void:
	esconder_tudo()
	
	if fase_passagem == "votacao":
		preparar_tela_votacao()
		return 
		
	GameManager.mudar_estado(GameManager.EstadoJogo.NOITE_ACAO)
	var id_atual = GameManager.get_jogador_atual().id
	
	if GameManager.caixas_de_entrada.has(id_atual) and GameManager.caixas_de_entrada[id_atual].size() > 0:
		var recados = ""
		for msg in GameManager.caixas_de_entrada[id_atual]: recados += msg + "\n\n"
		motivo_inbox = "mensagens_iniciais"
		$PainelInbox/LabelMensagemInbox.text = recados
		$PainelInbox.show()
		GameManager.caixas_de_entrada[id_atual].clear() 
	else:
		$PainelAcao.show()
		configurar_tela_por_cargo()
		
func iniciar_passagem_votacao() -> void:
	fase_passagem = "votacao"
	esconder_tudo()
	$PainelPassagem.show()
	
	var jogador = GameManager.fila_de_votacao[GameManager.indice_jogador_votacao] 
	$PainelPassagem/BtnSouEu.hide()
	$PainelPassagem/LabelPassagem.text = "VOTAÇÃO:\n\nPasse o celular para\n" + jogador.nome 
	
	await get_tree().create_timer(2.0).timeout
	
	$PainelPassagem/LabelPassagem.text = "Você é o(a) " + jogador.nome + "?" 
	$PainelPassagem/BtnSouEu.show()

func _on_btn_fechar_inbox_pressed() -> void:
	$PainelInbox.hide()
	if motivo_inbox == "mensagens_iniciais":
		$PainelAcao.show()
		configurar_tela_por_cargo()
	elif motivo_inbox == "resultado_detetive":
		esconder_tudo()
		GameManager.indice_jogador_noite += 1
		GameManager.mudar_estado(GameManager.EstadoJogo.NOITE_PASSAGEM)
		if GameManager.estado_atual == GameManager.EstadoJogo.NOITE_PASSAGEM:
			$PainelPassagem.show()
			preparar_tela_passagem()
#endregion

#region CONFIGURAÇÃO DA TELA DE AÇÃO NOTURNA
func configurar_tela_por_cargo() -> void:
	var cargo_atual = GameManager.get_jogador_atual().cargo 
	var cargos_prato = ["Guloso", "Ansioso", "Mordomo", "Cozinheiro"]
	var cargos_pessoa = ["Detetive", "Fofoqueiro", "Egoísta"]
	
	prato_selecionado = -1
	tempero_selecionado = ""
	pessoa_selecionada = -1 
	escolha_rato_tipo = ""
	pratos_selecionados.clear()
	
	$PainelAcao/ContainerTemperos/BtnSal.modulate = Color(1.0, 1.0, 1.0)
	$PainelAcao/ContainerTemperos/BtnPimenta.modulate = Color(1.0, 1.0, 1.0)
	$PainelAcao/ContainerTemperos/BtnNenhum.modulate = Color(1.0, 1.0, 1.0)
	$PainelAcao/ContainerEscolhaRato/BtnCheirarPratos.modulate = Color(1.0, 1.0, 1.0)
	$PainelAcao/ContainerEscolhaRato/BtnCheirarPessoas.modulate = Color(1.0, 1.0, 1.0)
	
	$PainelAcao/ScrollContainerPratos.hide() 
	$PainelAcao/ContainerTemperos.hide()
	$PainelAcao/ScrollContainerPessoas.hide() 
	$PainelAcao/ContainerEscolhaRato.hide()
	$PainelAcao/LabelAviso.hide() 
	
	if cargo_atual in cargos_prato:
		$PainelAcao/ScrollContainerPratos.show() 
		gerar_pratos_na_tela()
	elif cargo_atual in cargos_pessoa:
		$PainelAcao/ScrollContainerPessoas.show() 
		gerar_pessoas_na_tela()
	elif cargo_atual == "Rato": 
		$PainelAcao/ContainerEscolhaRato.show()
		
	if cargo_atual == "Cozinheiro":
		$PainelAcao/ContainerTemperos.show()
		$PainelAcao/ContainerTemperos/BtnSal.text = "Sal (" + str(GameManager.estoque_sal) + ")"
		$PainelAcao/ContainerTemperos/BtnPimenta.text = "Pimenta (" + str(GameManager.estoque_pimenta) + ")"
		$PainelAcao/ContainerTemperos/BtnSal.disabled = GameManager.estoque_sal <= 0
		$PainelAcao/ContainerTemperos/BtnPimenta.disabled = GameManager.estoque_pimenta <= 0
#endregion

#region GERADORES VISUAIS (MESA E SUSPEITOS)
func gerar_pratos_na_tela() -> void:
	var container = $PainelAcao/ScrollContainerPratos/ContainerPratos
	for filho in container.get_children(): filho.queue_free()
		
	var cargo_atual = GameManager.get_jogador_atual().cargo
	
	# --- LÓGICA NOVA: O AVISO DO RATO PARA O GULOSO ---
	var faro_do_rato = {}
	if cargo_atual == "Guloso":
		faro_do_rato = GameManager.obter_faro_do_rato()
		if faro_do_rato.size() > 0:
			$PainelAcao/LabelAviso.text = "🐀 O Rato cheirou pratos para você!"
			$PainelAcao/LabelAviso.show()
	# --------------------------------------------------
		
	for i in range(GameManager.pratos_na_mesa):
		var btn_prato = Button.new()
		btn_prato.custom_minimum_size = Vector2(80, 80)
		
		var estilo_circulo = StyleBoxFlat.new()
		
		# --- SISTEMA DE CORES DOS PRATOS ---
		if faro_do_rato.has(i):
			if faro_do_rato[i] == true:
				estilo_circulo.bg_color = Color(0.8, 0.2, 0.2) # VERMELHO (Foi mexido!)
			else:
				estilo_circulo.bg_color = Color(0.2, 0.8, 0.2) # VERDE (Intacto)
		else:
			estilo_circulo.bg_color = Color(0.85, 0.85, 0.85) # CINZA (Padrão)
		# -----------------------------------
		
		estilo_circulo.corner_radius_top_left = 40
		estilo_circulo.corner_radius_top_right = 40
		estilo_circulo.corner_radius_bottom_left = 40
		estilo_circulo.corner_radius_bottom_right = 40
		
		btn_prato.add_theme_stylebox_override("normal", estilo_circulo)
		btn_prato.add_theme_stylebox_override("hover", estilo_circulo) 
		btn_prato.add_theme_stylebox_override("pressed", estilo_circulo)
		
		btn_prato.text = str(i + 1)
		btn_prato.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
		
		container.add_child(btn_prato)
		btn_prato.pressed.connect(_on_prato_clicado.bind(i))
		
func _on_prato_clicado(id_prato: int) -> void:
	var cargo = GameManager.get_jogador_atual().cargo 
	var container = $PainelAcao/ScrollContainerPratos/ContainerPratos
	
	if cargo == "Rato" and escolha_rato_tipo == "pratos":
		if id_prato in pratos_selecionados: pratos_selecionados.erase(id_prato)
		elif pratos_selecionados.size() < 2: pratos_selecionados.append(id_prato)
			
		for i in range(container.get_child_count()):
			container.get_child(i).modulate = Color(1.0, 0.8, 0.2) if i in pratos_selecionados else Color(1.0, 1.0, 1.0)
	else:
		prato_selecionado = id_prato
		for i in range(container.get_child_count()):
			container.get_child(i).modulate = Color(1.0, 0.8, 0.2) if i == prato_selecionado else Color(1.0, 1.0, 1.0)

func gerar_pessoas_na_tela() -> void:
	var container = $PainelAcao/ScrollContainerPessoas/ContainerPessoas
	var cargo_atual = GameManager.get_jogador_atual().cargo
	for filho in container.get_children(): filho.queue_free()
		
	for j in GameManager.jogadores:
		if j.id == GameManager.get_jogador_atual().id or not j.vivo: continue
		if cargo_atual == "Detetive" and not GameManager.alvo_ja_agiu_nesta_noite(j.id): continue 
			
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var btn_foto = Button.new()
		btn_foto.custom_minimum_size = Vector2(80, 80)
		
		var estilo_circulo = StyleBoxFlat.new()
		estilo_circulo.bg_color = Color(0.3, 0.3, 0.3)
		estilo_circulo.corner_radius_top_left = 40
		estilo_circulo.corner_radius_top_right = 40
		estilo_circulo.corner_radius_bottom_left = 40
		estilo_circulo.corner_radius_bottom_right = 40
		
		btn_foto.add_theme_stylebox_override("normal", estilo_circulo)
		btn_foto.add_theme_stylebox_override("hover", estilo_circulo)
		btn_foto.add_theme_stylebox_override("pressed", estilo_circulo)
		
		btn_foto.set_meta("id", j.id)
		btn_foto.pressed.connect(_on_pessoa_clicada.bind(j.id))
		
		var lbl = Label.new()
		lbl.text = j.nome
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		
		vbox.add_child(btn_foto)
		vbox.add_child(lbl)
		container.add_child(vbox)
		
func _on_pessoa_clicada(id_pessoa: int) -> void:
	pessoa_selecionada = id_pessoa
	for vbox in $PainelAcao/ScrollContainerPessoas/ContainerPessoas.get_children():
		var btn = vbox.get_child(0)
		btn.modulate = Color(1.0, 0.8, 0.2) if btn.get_meta("id") == pessoa_selecionada else Color(1.0, 1.0, 1.0)
#endregion

#region BOTÕES ESPECÍFICOS (COZINHEIRO E RATO)
func _on_btn_sal_pressed() -> void:
	tempero_selecionado = "Sal"
	$PainelAcao/ContainerTemperos/BtnSal.modulate = Color(0.5, 1.0, 0.5)
	$PainelAcao/ContainerTemperos/BtnPimenta.modulate = Color(1.0, 1.0, 1.0)
	$PainelAcao/ContainerTemperos/BtnNenhum.modulate = Color(1.0, 1.0, 1.0)
	$PainelAcao/LabelAviso.hide()
	$PainelAcao/ScrollContainerPratos.show() 

func _on_btn_pimenta_pressed() -> void:
	tempero_selecionado = "Pimenta"
	$PainelAcao/ContainerTemperos/BtnPimenta.modulate = Color(1.0, 0.4, 0.4)
	$PainelAcao/ContainerTemperos/BtnSal.modulate = Color(1.0, 1.0, 1.0)
	$PainelAcao/ContainerTemperos/BtnNenhum.modulate = Color(1.0, 1.0, 1.0)
	$PainelAcao/LabelAviso.hide()
	$PainelAcao/ScrollContainerPratos.show() 

func _on_btn_nenhum_pressed() -> void:
	tempero_selecionado = "Nenhum"
	$PainelAcao/ContainerTemperos/BtnNenhum.modulate = Color(0.6, 0.8, 1.0) 
	$PainelAcao/ContainerTemperos/BtnSal.modulate = Color(1.0, 1.0, 1.0)
	$PainelAcao/ContainerTemperos/BtnPimenta.modulate = Color(1.0, 1.0, 1.0)
	prato_selecionado = -1
	for btn in $PainelAcao/ScrollContainerPratos/ContainerPratos.get_children(): 
		btn.modulate = Color(1.0, 1.0, 1.0)
	$PainelAcao/ScrollContainerPratos.hide() 
	$PainelAcao/LabelAviso.text = "Você decidiu não usar temperos esta noite."
	$PainelAcao/LabelAviso.show()

func _on_btn_cheirar_pratos_pressed() -> void:
	escolha_rato_tipo = "pratos"
	pratos_selecionados.clear()
	pessoa_selecionada = -1 
	$PainelAcao/ContainerEscolhaRato/BtnCheirarPratos.modulate = Color(0.8, 0.6, 1.0) 
	$PainelAcao/ContainerEscolhaRato/BtnCheirarPessoas.modulate = Color(1.0, 1.0, 1.0)
	$PainelAcao/ScrollContainerPessoas.hide() 
	$PainelAcao/ScrollContainerPratos.show() 
	gerar_pratos_na_tela()

func _on_btn_cheirar_pessoas_pressed() -> void:
	escolha_rato_tipo = "pessoas"
	pratos_selecionados.clear()
	pessoa_selecionada = -1 
	$PainelAcao/ContainerEscolhaRato/BtnCheirarPessoas.modulate = Color(0.8, 0.6, 1.0) 
	$PainelAcao/ContainerEscolhaRato/BtnCheirarPratos.modulate = Color(1.0, 1.0, 1.0)
	$PainelAcao/ScrollContainerPratos.hide() 
	$PainelAcao/ScrollContainerPessoas.show() 
	gerar_pessoas_na_tela()
#endregion

#region REGISTRO E CONFIRMAÇÃO DE AÇÕES DA NOITE
func _on_btn_confirmar_acao_pressed() -> void:
	var cargo = GameManager.get_jogador_atual().cargo 
	
	# Travas
	if cargo == "Cozinheiro" and tempero_selecionado == "": return
	if cargo in ["Guloso", "Ansioso", "Mordomo"] and prato_selecionado == -1 and tempero_selecionado != "Nenhum": return
	if cargo in ["Detetive", "Fofoqueiro", "Egoísta"] and pessoa_selecionada == -1: return
	if cargo == "Rato":
		if escolha_rato_tipo == "": return
		if escolha_rato_tipo == "pratos" and pratos_selecionados.size() < 2: return
		if escolha_rato_tipo == "pessoas" and pessoa_selecionada == -1: return
			
	esconder_tudo()
	
	# Envios
	if cargo == "Cozinheiro":
		if tempero_selecionado == "Nenhum": GameManager.registrar_acao_noturna("dormiu", -1)
		else: 
			GameManager.registrar_acao_noturna("temperou_com_" + tempero_selecionado.to_lower(), prato_selecionado)
			if tempero_selecionado == "Sal": GameManager.estoque_sal -= 1
			else: GameManager.estoque_pimenta -= 1
				
	elif cargo in ["Guloso", "Ansioso", "Mordomo"]:
		GameManager.registrar_acao_noturna("interagiu_com_prato", prato_selecionado)
		
	elif cargo in ["Detetive", "Fofoqueiro", "Egoísta"]:
		if cargo == "Detetive":
			GameManager.registrar_acao_noturna("investigou_pessoa", pessoa_selecionada, false)
			var alvo_mexeu = false
			if GameManager.acoes_noturnas.has(pessoa_selecionada):
				var acao_al = GameManager.acoes_noturnas[pessoa_selecionada]["acao"]
				if acao_al in ["interagiu_com_prato", "temperou_com_sal", "temperou_com_pimenta", "cheirou_pratos"]:
					alvo_mexeu = true
			
			motivo_inbox = "resultado_detetive"
			$PainelInbox/LabelMensagemInbox.text = "🔍 O alvo que você seguiu TOCOU na comida!" if alvo_mexeu else "🔍 O alvo que você seguiu NÃO tocou na comida."
			$PainelInbox.show()
			return 
		else: 
			GameManager.registrar_acao_noturna("investigou_pessoa", pessoa_selecionada)
			if cargo == "Egoísta":
				alvo_do_egoista = pessoa_selecionada
				
	elif cargo == "Rato":
		if escolha_rato_tipo == "pratos": 
			GameManager.registrar_acao_noturna("cheirou_pratos", pratos_selecionados.duplicate())
		else: 
			GameManager.registrar_acao_noturna("cheirou_pessoa", pessoa_selecionada, false) # False para nao passar o turno
			
			# Puxa os dados da pessoa que ele cheirou
			var alvo = null
			for j in GameManager.jogadores:
				if j.id == pessoa_selecionada:
					alvo = j
					break
			
			# Abre o painel do Inbox para o Rato ler o cargo
			motivo_inbox = "resultado_detetive" #
			$PainelInbox/LabelMensagemInbox.text = "🐀 FARO DO RATO\n\nVocê farejou o cheiro de " + alvo.nome + "...\n\nEssa pessoa é o(a) " + alvo.cargo.to_upper() + "!"
			$PainelInbox.show()
			return 
			
	else:
		GameManager.registrar_acao_noturna("esperou", -1)
	
	# Verificação de Encerramento ou Próximo Turno
	if GameManager.estado_atual == GameManager.EstadoJogo.NOITE_PASSAGEM:
		$PainelPassagem.show()
		preparar_tela_passagem() 
	elif GameManager.estado_atual == GameManager.EstadoJogo.AMANHECER:
		esconder_tudo()
		$PainelAmanhecer/LabelRelatorio.text = GameManager.relatorio_amanhecer
		$PainelAmanhecer.show()
#endregion

#region TELA DE VOTAÇÃO
func preparar_tela_votacao() -> void:
	voto_selecionado = -1
	$PainelVotacao.show()
	$PainelVotacao/ScrollContainerPessoas/ContainerPessoas.show()
	gerar_pessoas_votacao()
	
	var jogador_atual = GameManager.fila_de_votacao[GameManager.indice_jogador_votacao]
	$PainelVotacao/LabelVotante.text = "Vez de " + jogador_atual.nome + " votar:"

func gerar_pessoas_votacao() -> void:
	var container = $PainelVotacao/ScrollContainerPessoas/ContainerPessoas
	for filho in container.get_children(): filho.queue_free()
		
	var jogador_votando = GameManager.fila_de_votacao[GameManager.indice_jogador_votacao]
	
	for j in GameManager.jogadores:
		if not j.vivo: continue 
			
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var btn_foto = Button.new()
		btn_foto.custom_minimum_size = Vector2(80, 80)
		
		var estilo_circulo = StyleBoxFlat.new()
		estilo_circulo.bg_color = Color(0.8, 0.2, 0.2) 
		estilo_circulo.corner_radius_top_left = 40
		estilo_circulo.corner_radius_top_right = 40
		estilo_circulo.corner_radius_bottom_left = 40
		estilo_circulo.corner_radius_bottom_right = 40
		
		btn_foto.add_theme_stylebox_override("normal", estilo_circulo)
		btn_foto.add_theme_stylebox_override("hover", estilo_circulo)
		btn_foto.add_theme_stylebox_override("pressed", estilo_circulo)
		
		btn_foto.set_meta("id_jogador", j.id)
		btn_foto.pressed.connect(_on_pessoa_votacao_clicada.bind(j.id))
		
		# --- LÓGICA DO CIRCULOZINHO (BADGE) DE VOTOS ---
		var qtd_votos = 0
		for id_votante in GameManager.votos_da_rodada.keys():
			var id_votado = GameManager.votos_da_rodada[id_votante]
			
			if id_votado == j.id: 
				var peso_do_voto = 1
				for jog in GameManager.jogadores:
					if jog.id == id_votante and jog.cargo == "Aristocrata":
						peso_do_voto = 2
						break
				qtd_votos += peso_do_voto
			
		# O Segurança vê os votos (ou todo mundo vê se o modo for aberto)
		if qtd_votos > 0 and (jogador_votando.cargo == "Segurança" or not GameManager.modo_voto_secreto):
			var badge_style = StyleBoxFlat.new()
			badge_style.bg_color = Color(1.0, 0.8, 0.2) # Amarelo vivo
			badge_style.corner_radius_top_left = 15
			badge_style.corner_radius_top_right = 15
			badge_style.corner_radius_bottom_left = 15
			badge_style.corner_radius_bottom_right = 15
			
			var badge = Label.new()
			badge.text = str(qtd_votos)
			badge.add_theme_stylebox_override("normal", badge_style)
			badge.add_theme_color_override("font_color", Color(0, 0, 0))
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			badge.custom_minimum_size = Vector2(24, 24)
			
			# Posiciona no canto superior direito do botão
			badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			badge.position = Vector2(60, -5) 
			
			btn_foto.add_child(badge)
		# -----------------------------------------------
		
		var lbl = Label.new()
		lbl.text = j.nome
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		
		vbox.add_child(btn_foto)
		vbox.add_child(lbl)
		container.add_child(vbox)

func _on_pessoa_votacao_clicada(id_pessoa: int) -> void:
	var jogador_votando = GameManager.fila_de_votacao[GameManager.indice_jogador_votacao]
	
	if jogador_votando.cargo == "Segurança":
		voto_selecionado = id_pessoa
		abrir_painel_seguranca(id_pessoa)
	else:
		voto_selecionado = id_pessoa
		_atualizar_cores_votacao()

func _atualizar_cores_votacao() -> void:
	for vbox in $PainelVotacao/ScrollContainerPessoas/ContainerPessoas.get_children():
		var btn = vbox.get_child(0)
		if btn.get_meta("id_jogador") == voto_selecionado:
			btn.modulate = Color(1.0, 0.8, 0.2) 
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)

# --- SISTEMA EXCLUSIVO DO SEGURANÇA ---
func abrir_painel_seguranca(id_alvo: int) -> void:
	_atualizar_cores_votacao() # Seleciona visualmente por baixo
	var alvo = null
	for j in GameManager.jogadores:
		if j.id == id_alvo: alvo = j
			
	var texto_info = "Ficha de Investigação: " + alvo.nome + "\n\n"
	
	# Verificando em quem o alvo votou
	if GameManager.votos_da_rodada.has(id_alvo):
		var voto_do_alvo = GameManager.votos_da_rodada[id_alvo]
		var nome_votado = "Alguém"
		for j in GameManager.jogadores:
			if j.id == voto_do_alvo: nome_votado = j.nome
		texto_info += "👉 Votou em: " + nome_votado + "\n\n"
	else:
		texto_info += "👉 Votou em: (Ainda não votou)\n\n"
		
	# Verificando quem votou no alvo
	var eleitores = []
	for id_votante in GameManager.votos_da_rodada.keys():
		if GameManager.votos_da_rodada[id_votante] == id_alvo:
			for j in GameManager.jogadores:
				if j.id == id_votante: eleitores.append(j.nome)
				
	if eleitores.size() > 0:
		texto_info += "🎯 Recebeu votos de:\n- " + "\n- ".join(eleitores)
	else:
		texto_info += "🎯 Recebeu votos de: Ninguém"
		
	$PainelSeguranca/LabelFicha.text = texto_info
	$PainelSeguranca.show()

func _on_btn_fechar_seguranca_pressed() -> void:
	$PainelSeguranca.hide()

func _on_btn_confirmar_voto_pressed() -> void:
	if voto_selecionado == -1: return
		
	var jogador_votando = GameManager.fila_de_votacao[GameManager.indice_jogador_votacao]
	GameManager.votos_da_rodada[jogador_votando.id] = voto_selecionado
	
	GameManager.indice_jogador_votacao += 1
	
	if GameManager.indice_jogador_votacao < GameManager.fila_de_votacao.size():
		# Tem mais gente para votar, passa o celular
		iniciar_passagem_votacao()
	else:
		# ACABOU A VOTAÇÃO! Chama a matemática e mostra o resultado na tela:
		GameManager.apurar_votacao()
		esconder_tudo()
		$PainelResultadoVotacao/LabelResultado.text = GameManager.relatorio_votacao
		$PainelResultadoVotacao.show()

func _on_btn_continuar_resultado_pressed() -> void:
	var status_partida = GameManager.verificar_vitoria()
	
	if status_partida != "CONTINUA":
		exibir_tela_vitoria(status_partida)
	else:
		fase_passagem = "noite"
		esconder_tudo()
		GameManager.mudar_estado(GameManager.EstadoJogo.NOITE_PASSAGEM)
		if GameManager.estado_atual == GameManager.EstadoJogo.NOITE_PASSAGEM:
			$PainelPassagem.show()
			preparar_tela_passagem()
#endregion

#region TELA DE VITÓRIA E REVELAÇÃO DE CARGOS
func exibir_tela_vitoria(resultado: String) -> void:
	esconder_tudo()
	
	var icone = $PainelVitoria/IconeFaccao
	var titulo = $PainelVitoria/Titulo
	var subtitulo = $PainelVitoria/Subtitulo
	var lista = $PainelVitoria/ScrollContainer/ListaJogadores
	
	# 1. Aplicando os Textos e Cores
	if resultado == "VITORIA_BEM":
		# icone.texture = preload("res://assets/image_77585b.png") # Caminho do seu Frango Azul
		titulo.text = "A MESA SOBREVIVEU!"
		titulo.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2)) 
		subtitulo.text = "Os sabotadores foram eliminados. Vocês podem comer em paz."
		
	elif resultado == "VITORIA_MAL":
		# icone.texture = preload("res://assets/image_7741f5.png") # Caminho do seu Prato Quebrado
		titulo.text = "OS DEVORADORES VENCERAM!"
		titulo.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2)) 
		subtitulo.text = "A fome consumiu a mesa. Eles tomaram o controle."
		
	elif resultado == "VITORIA_EGOISTA":
		# icone.texture = preload("res://assets/image_81af7b.png") # Caminho do seu Rosto com Coroa
		titulo.text = "O REI DO CAOS!"
		titulo.add_theme_color_override("font_color", Color(0.9, 0.7, 0.1)) 
		subtitulo.text = "O Egoísta foi o único a sobrar. A mesa agora é só dele."
		
	elif resultado == "VITORIA_FARSANTE":
		# Se tiver um ícone de máscaras de teatro, coloque aqui. Senão, deixe null.
		icone.texture = null 
		titulo.text = "O GRANDE TRUQUE!"
		titulo.add_theme_color_override("font_color", Color(0.6, 0.2, 0.8)) # Roxo
		subtitulo.text = "O Farsante enganou a todos e foi expulso como planejava!"
		
	elif resultado == "EMPATE_MORTE_GERAL":
		icone.texture = null 
		titulo.text = "TODOS MORRERAM"
		titulo.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6)) 
		subtitulo.text = "A paranoia e a escassez destruíram a mesa inteira."
		
	# 2. Revelando quem era quem
	var texto_revelacao = "🔍 QUEM ERA QUEM:\n\n"
	for j in GameManager.jogadores:
		var status = "💀 " if not j.vivo else "👤 "
		var nome_formatado = j.nome
		var cargo_formatado = j.cargo.to_upper()
		texto_revelacao += status + nome_formatado + " era o/a " + cargo_formatado + "\n"
		
	lista.text = texto_revelacao
	$PainelVitoria.show()

func _on_btn_jogar_novamente_pressed() -> void:
	$PainelVitoria.hide()
	esconder_tudo()
	GameManager.mudar_estado(GameManager.EstadoJogo.SETUP)
#endregion
