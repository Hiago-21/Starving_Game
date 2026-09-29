extends Node

#region ENUMS E VARIÁVEIS GLOBAIS
enum EstadoJogo { SETUP, DIA, VOTACAO, NOITE_PASSAGEM, NOITE_ACAO, AMANHECER }
var estado_atual: EstadoJogo = EstadoJogo.SETUP

# --- DADOS DA PARTIDA ---
var jogadores: Array = []
var pratos_na_mesa: int = 0
var dia_atual: int = 1
var comeram_nesta_noite: Array = [] 
var relatorio_amanhecer: String = ""
var vencedor_imediato: String = ""
var alvo_do_egoista: int = -1

# --- CONTROLE DA NOITE ---
var indice_jogador_noite: int = 0 
var acoes_noturnas: Dictionary = {} 
var fila_da_noite: Array = [] 
var caixas_de_entrada: Dictionary = {}

# --- CONTROLE DE VOTAÇÃO ---
var modo_voto_secreto: bool = true # Se for false, todos veem os votos
var votos_da_rodada: Dictionary = {} # Guarda quem votou em quem: {id_votante: id_votado}
var fila_de_votacao: Array = [] # Lista de quem ainda precisa votar
var indice_jogador_votacao: int = 0
var relatorio_votacao: String = "" # Mensagem de quem foi expulso (ou se o Farsante ganhou)

# --- ESTOQUE E RECURSOS ---
var estoque_sal: int = 2
var estoque_pimenta: int = 2

# --- CARGOS ---
var cargos_na_partida: Array = [] 
const TODOS_CARGOS = ["Guloso", "Rato", "Mordomo", "Cozinheiro", "Ansioso", "Detetive", "Fofoqueiro", "Segurança", "Egoísta", "Farsante", "Aristocrata"]
#endregion

#region MÁQUINA DE ESTADOS PRINCIPAL
func _ready() -> void:
	randomize()
	print("GameManager iniciado. Estado atual: SETUP")
	mudar_estado(EstadoJogo.SETUP)

func mudar_estado(novo_estado: EstadoJogo) -> void:
	estado_atual = novo_estado
	print("--- MUDANÇA DE ESTADO: ", EstadoJogo.keys()[estado_atual], " ---")
	
	match estado_atual:
		EstadoJogo.SETUP: _ao_entrar_setup()
		EstadoJogo.DIA: _ao_entrar_dia()
		EstadoJogo.VOTACAO: _ao_entrar_votacao()
		EstadoJogo.NOITE_PASSAGEM: _ao_entrar_noite_passagem()
		EstadoJogo.NOITE_ACAO: _ao_entrar_noite_acao()
		EstadoJogo.AMANHECER: _ao_entrar_amanhecer()

func _ao_entrar_setup() -> void:
	print("Lógica de SETUP: Aguardando iniciar a partida...")
	iniciar_partida(6)

func _ao_entrar_dia() -> void:
	print("Lógica de DIA: Cronômetro iniciado, jogadores discutindo.")
	
func _ao_entrar_votacao() -> void:
	print("Lógica de VOTACAO iniciada.")
	fila_de_votacao.clear()
	votos_da_rodada.clear()
	indice_jogador_votacao = 0
	
	var seguranca = null
	for j in jogadores:
		if j.vivo:
			if j.cargo == "Segurança":
				seguranca = j
			else:
				fila_de_votacao.append(j)
				
	# 1. Embaralha todo mundo de forma aleatória
	fila_de_votacao.shuffle()
	
	# 2. Insere o Segurança no meio do tiroteio
	if seguranca != null:
		# Se só sobrar o Segurança e mais 1 pessoa, ele entra em último inevitavelmente
		if fila_de_votacao.size() <= 1:
			fila_de_votacao.append(seguranca)
		else:
			# Escolhe uma posição que NUNCA seja 0 (primeiro) e NUNCA seja no final absoluto
			var posicao_aleatoria = randi_range(1, fila_de_votacao.size() - 1)
			fila_de_votacao.insert(posicao_aleatoria, seguranca)
#endregion

#region SETUP E PREPARAÇÃO DA PARTIDA
func iniciar_partida(quantidade_jogadores: int) -> void:
	jogadores.clear()
	dia_atual = 1
	vencedor_imediato = ""
	estoque_sal = 2
	estoque_pimenta = 2
	
	indice_jogador_noite = 0
	acoes_noturnas.clear()
	comeram_nesta_noite.clear()
	fila_da_noite.clear()
	
	definir_cargos_por_quantidade(quantidade_jogadores)
	
	for i in range(quantidade_jogadores):
		var novo_jogador = {
			"id": i,
			"nome": "Jogador " + str(i + 1),
			"cargo": cargos_na_partida[i],
			"hp": 3,
			"vivo": true,
			"mutado": false
		}
		jogadores.append(novo_jogador)
	
	pratos_na_mesa = jogadores.size() + 1
	print("✅ Partida iniciada com ", quantidade_jogadores, " jogadores!")
	mudar_estado(EstadoJogo.DIA)

func definir_cargos_por_quantidade(qtd_jogadores: int) -> void:
	cargos_na_partida.clear()
	
	# SACO 1: O Motor
	if qtd_jogadores <= 7: cargos_na_partida.append_array(["Guloso", "Rato", "Cozinheiro"])
	elif qtd_jogadores <= 11: cargos_na_partida.append_array(["Guloso", "Guloso", "Rato", "Cozinheiro"])
	else: cargos_na_partida.append_array(["Guloso", "Guloso", "Guloso", "Rato", "Cozinheiro"])
		
	# SACO 2: Informação
	var pool_info = ["Detetive", "Fofoqueiro"]
	pool_info.shuffle()
	cargos_na_partida.append(pool_info[0]) 
	if qtd_jogadores >= 9: cargos_na_partida.append(pool_info[1])
		
	# SACO 3: O Caos
	var saco_de_caos = ["Mordomo", "Ansioso", "Egoísta", "Aristocrata"]
	if qtd_jogadores >= 7: saco_de_caos.append("Farsante")
	if qtd_jogadores >= 8: saco_de_caos.append("Segurança")
	
	while cargos_na_partida.size() < qtd_jogadores:
		if saco_de_caos.size() > 0: cargos_na_partida.append(saco_de_caos.pop_front())
		else: cargos_na_partida.append("Ansioso")
			
	cargos_na_partida.shuffle()
	print("🎲 Cargos (", qtd_jogadores, " jogadores): ", cargos_na_partida)
#endregion

#region MOTOR DA MADRUGADA (FILA INTELIGENTE)
func _ao_entrar_noite_passagem() -> void:
	if indice_jogador_noite == 0:
		gerar_fila_da_noite()
		
	if indice_jogador_noite < fila_da_noite.size():
		var jogador_atual = fila_da_noite[indice_jogador_noite]
		print("TELA PRETA: Passe o celular para ID ", jogador_atual.id)
	else:
		processar_madrugada() 
		indice_jogador_noite = 0
		mudar_estado(EstadoJogo.AMANHECER)

func _ao_entrar_noite_acao() -> void:
	if fila_da_noite.size() == 0:
		print("⚠️ Fila da noite estava vazia (pulada pelo botão). Gerando agora...")
		gerar_fila_da_noite()
		
	var jogador_atual = fila_da_noite[indice_jogador_noite]
	print("TELA DE AÇÃO: ", jogador_atual.nome, " (", jogador_atual.cargo, ") está agindo.")

func gerar_fila_da_noite() -> void:
	fila_da_noite.clear()
	var jogadores_vivos = []
	for j in jogadores:
		if j.vivo: jogadores_vivos.append(j)
			
	var fila_valida = false
	var limite_fofoqueiro = max(0, jogadores_vivos.size() - 3)
	var meio_da_fila = jogadores_vivos.size() / 2
	var tentativas = 0
	
	while not fila_valida and tentativas < 1000:
		tentativas += 1
		var tentativa_fila = jogadores_vivos.duplicate()
		tentativa_fila.shuffle()
		
		var index_fofa = -1
		var index_det = -1
		var index_guloso = -1
		var max_interagente = -1 # Descobre quem foi o último a mexer nos pratos (Cozinheiro ou Mordomo)
		
		for i in range(tentativa_fila.size()):
			var c = tentativa_fila[i].cargo
			if c == "Fofoqueiro": index_fofa = i
			elif c == "Detetive": index_det = i
			elif c == "Guloso": index_guloso = i
			elif c == "Cozinheiro" or c == "Mordomo":
				if i > max_interagente: max_interagente = i
				
		var ok_fofa = (index_fofa == -1) or (index_fofa <= limite_fofoqueiro)
		var ok_det = (index_det == -1) or (index_det >= meio_da_fila)
		var ok_guloso = (index_guloso == -1 or max_interagente == -1) or (index_guloso > max_interagente)
				
		if ok_fofa and ok_det and ok_guloso:
			fila_da_noite = tentativa_fila
			fila_valida = true
			
	if not fila_valida: fila_da_noite = jogadores_vivos.duplicate()
	
func get_jogador_atual() -> Dictionary:
	if fila_da_noite.size() > 0 and indice_jogador_noite < fila_da_noite.size():
		return fila_da_noite[indice_jogador_noite]
	elif jogadores.size() > 0 and indice_jogador_noite < jogadores.size():
		return jogadores[indice_jogador_noite]
	return {}
#endregion

#region AÇÕES NOTURNAS (REGISTRO E CONFLITOS)
func registrar_acao_noturna(acao: String, alvo: Variant = -1, avancar_turno: bool = true) -> void:
	var jogador_atual = fila_da_noite[indice_jogador_noite]
	var id_atual = jogador_atual.id
	
	acoes_noturnas[id_atual] = { "acao": acao, "alvo": alvo }
	
	if jogador_atual.cargo == "Egoísta" and acao == "investigou_pessoa":
		alvo_do_egoista = alvo
	
	if jogador_atual.cargo == "Fofoqueiro" and acao == "investigou_pessoa":
		var p_investigada = null
		for j in jogadores:
			if j.id == alvo:
				p_investigada = j
				break
				
		if p_investigada:
			var ouvintes = []
			for i in range(indice_jogador_noite + 1, fila_da_noite.size()):
				ouvintes.append(fila_da_noite[i])
				
			ouvintes.shuffle() 
			if ouvintes.size() >= 2:
				var ouv1 = ouvintes[0]
				var ouv2 = ouvintes[1]
				if not caixas_de_entrada.has(ouv1.id): caixas_de_entrada[ouv1.id] = []
				if not caixas_de_entrada.has(ouv2.id): caixas_de_entrada[ouv2.id] = []
				caixas_de_entrada[ouv1.id].append("🗣️ FOFOCA: " + p_investigada.nome + " foi investigado(a) esta noite!")
				caixas_de_entrada[ouv2.id].append("🗣️ FOFOCA: Um passarinho contou que existe um(a) " + p_investigada.cargo + " nesta mesa...")
	
	if avancar_turno:
		indice_jogador_noite += 1
		mudar_estado(EstadoJogo.NOITE_PASSAGEM)

func processar_madrugada() -> void:
	var pratos_disputados = {}
	for i in range(jogadores.size()):
		var j = jogadores[i]
		if acoes_noturnas.has(j.id):
			var acao = acoes_noturnas[j.id]["acao"]
			var alvo = acoes_noturnas[j.id]["alvo"]
			
			if (acao == "interagiu_com_prato" or acao.begins_with("temperou_com")) and typeof(alvo) == TYPE_INT and alvo != -1:
				if not pratos_disputados.has(alvo): pratos_disputados[alvo] = []
				pratos_disputados[alvo].append(j)
			elif acao == "cheirou_pratos" and typeof(alvo) == TYPE_ARRAY:
				for prato_id in alvo:
					if not pratos_disputados.has(prato_id): pratos_disputados[prato_id] = []
					pratos_disputados[prato_id].append(j)

	for prato_id in pratos_disputados.keys():
		resolver_conflito_de_prato(prato_id, pratos_disputados[prato_id])

func resolver_conflito_de_prato(prato_id: int, envolvidos: Array) -> void:
	var comedores = []
	var interagentes = []
	var tempero_aplicado = "" 
	
	for j in envolvidos:
		if j.cargo in ["Guloso", "Ansioso"]: comedores.append(j)
		else: interagentes.append(j)
			
	var prato_protegido = false
	for inter in interagentes:
		if inter.cargo == "Mordomo": prato_protegido = true
			
	if prato_protegido:
		comedores = [] 
		
	for inter in interagentes:
		if inter.cargo == "Cozinheiro" and not prato_protegido:
			var acao_coz = acoes_noturnas[inter.id]["acao"]
			if acao_coz == "temperou_com_sal": tempero_aplicado = "Sal"
			elif acao_coz == "temperou_com_pimenta": tempero_aplicado = "Pimenta"
		
	if comedores.size() == 1:
		var vencedor = comedores[0]
		comeram_nesta_noite.append(vencedor.id)
		
		if tempero_aplicado == "Sal": vencedor.hp += 1
		elif tempero_aplicado == "Pimenta": vencedor.hp -= 1

func alvo_ja_agiu_nesta_noite(id_alvo: int) -> bool:
	var index_det = -1
	var index_alvo = -1
	for i in range(fila_da_noite.size()):
		if fila_da_noite[i].cargo == "Detetive": index_det = i
		if fila_da_noite[i].id == id_alvo: index_alvo = i
	return index_alvo < index_det
#endregion

#region O AMANHECER (FOME E MORTES)
func _ao_entrar_amanhecer() -> void:
	var mortos_da_noite = []
	relatorio_amanhecer = "🌅 RELATÓRIO DO DIA " + str(dia_atual + 1) + "\n\n"
	
	# 1. Matemática da Comida
	var comida_do_dia = pratos_na_mesa - comeram_nesta_noite.size()
	var pessoas_famintas = []
	var ansiosos_que_falharam = []
	
	# 2. Separando quem precisa de comida
	for j in jogadores:
		if j.vivo:
			if j.cargo == "Ansioso":
				if not comeram_nesta_noite.has(j.id):
					ansiosos_que_falharam.append(j)
			else:
				pessoas_famintas.append(j)
				
	var total_bocas = pessoas_famintas.size() + ansiosos_que_falharam.size()
	var houve_briga = false
	
	# 3. A Lógica da Distribuição
	if comida_do_dia >= total_bocas:
		relatorio_amanhecer += "🍽️ Havia comida para todos! A refeição foi tranquila.\n"
	elif comida_do_dia >= pessoas_famintas.size():
		relatorio_amanhecer += "🍽️ A comida deu apenas para as pessoas normais.\n"
		for ansioso in ansiosos_que_falharam:
			ansioso.hp -= 1
			relatorio_amanhecer += "😰 " + ansioso.nome + " ficou muito nervoso e não conseguiu comer!\n"
	else:
		houve_briga = true
		relatorio_amanhecer += "⚔️ A COMIDA ACABOU! Vocês brigaram pelos restos e ninguém se alimentou direito!\n"
		for faminto in pessoas_famintas:
			# O Guloso só toma dano se também não comeu à noite
			if faminto.cargo == "Guloso" and comeram_nesta_noite.has(faminto.id):
				continue 
			
			faminto.hp -= 1
			
		for ansioso in ansiosos_que_falharam:
			ansioso.hp -= 1
	
	# 4. Checando as baixas do dia
	for j in jogadores:
		if j.vivo and j.hp <= 0:
			j.vivo = false
			mortos_da_noite.append(j)
	
	if mortos_da_noite.size() > 0:
		relatorio_amanhecer += "\nInfelizmente, tivemos baixa(s):\n"
		for morto in mortos_da_noite:
			relatorio_amanhecer += "💀 " + morto.nome + " (Era o/a " + morto.cargo + ")\n"
			
	dia_atual += 1
	comeram_nesta_noite.clear()
	acoes_noturnas.clear()
	verificar_vitoria()
	
	# 5. Recalculando os pratos para o próximo turno
	var vivos_count = 0
	for j in jogadores:
		if j.vivo: vivos_count += 1
	pratos_na_mesa = vivos_count 
	
	# MUTAÇÃO DO RATO
	var guloso_vivo = false
	var rato_vivo = null
	
	for j in jogadores:
		if j.vivo:
			if j.cargo == "Guloso":
				guloso_vivo = true
			elif j.cargo == "Rato":
				rato_vivo = j
				
	# Se não tem Guloso, mas o Rato está vivo, a evolução acontece!
	if not guloso_vivo and rato_vivo != null:
		rato_vivo.cargo = "Guloso"
		rato_vivo.mutado = true
#endregion

#region RESULTADO DA VOTAÇÃO
func apurar_votacao() -> void:
	var contagem_votos = {}
	
	for id_votante in votos_da_rodada.keys():
		var id_votado = votos_da_rodada[id_votante]
		var peso_do_voto = 1
		
		for j in jogadores:
			if j.id == id_votante and j.cargo == "Aristocrata":
				peso_do_voto = 2
				break
				
		if contagem_votos.has(id_votado):
			contagem_votos[id_votado] += peso_do_voto
		else:
			contagem_votos[id_votado] = peso_do_voto
			
	var mais_votado = -1
	var max_votos = 0
	var houve_empate = false
	
	for id_candidato in contagem_votos.keys():
		var qtd = contagem_votos[id_candidato]
		if qtd > max_votos:
			max_votos = qtd
			mais_votado = id_candidato
			houve_empate = false
		elif qtd == max_votos:
			houve_empate = true
			
	if houve_empate:
		relatorio_votacao = "⚖️ EMPATE!\n\nA mesa não conseguiu chegar a um consenso. Ninguém será expulso hoje. A noite cai novamente..."
	else:
		var jogador_expulso = null
		for j in jogadores:
			if j.id == mais_votado:
				jogador_expulso = j
				break
				
		jogador_expulso.vivo = false
		
		if jogador_expulso.cargo == "Farsante":
			vencedor_imediato = "VITORIA_FARSANTE" 
			relatorio_votacao = "🎭 O FARSANTE FOI EXPULSO E VENCEU O JOGO!"
			
		elif jogador_expulso.cargo == "Egoísta":
			relatorio_amanhecer += "\n💥 O Egoísta surtou ao ser expulso! Todos tomam dano!"
			var id_alvo_rancor = alvo_do_egoista
			if acoes_noturnas.has(jogador_expulso.id):
				id_alvo_rancor = acoes_noturnas[jogador_expulso.id]["alvo"]
				
			var vivos_count = 0
			for j in jogadores:
				if j.vivo and j.id != jogador_expulso.id:
					j.hp -= 1
					if j.id == id_alvo_rancor:
						j.hp -= 1
					
					if j.hp <= 0:
						j.vivo = false
					else:
						vivos_count += 1
						
			if vivos_count == 0:
				relatorio_amanhecer += "\n👑 O Egoísta eliminou todos na sala, voltou para a mesa e venceu sozinho!"
				jogador_expulso.vivo = true 
				jogador_expulso.hp = 1
			
			pratos_na_mesa = vivos_count
			
		else:
			for j in jogadores:
				if j.vivo and j.cargo == "Egoísta" and alvo_do_egoista == jogador_expulso.id:
					j.hp += 1
#endregion

#region INFORMAÇÃO DO RATO
func obter_faro_do_rato() -> Dictionary:
	var pratos_cheirados = []
	var resultado_faro = {}
	
	# 1. Procura o que o Rato fez esta noite
	for id_jogador in acoes_noturnas.keys():
		var info = acoes_noturnas[id_jogador]
		var e_rato = false
		for j in jogadores:
			if j.id == id_jogador and j.cargo == "Rato":
				e_rato = true
				break
		
		if e_rato and info["acao"] == "cheirou_pratos":
			pratos_cheirados = info["alvo"] # Pega a lista com os 2 pratos
			break
			
	# 2. Verifica se alguém (além do Rato) tocou nesses pratos
	for prato_id in pratos_cheirados:
		var foi_mexido = false
		for id_outro in acoes_noturnas.keys():
			var outra_acao = acoes_noturnas[id_outro]
			
			var outro_cargo = ""
			for j in jogadores:
				if j.id == id_outro:
					outro_cargo = j.cargo
					break
			
			# Se alguém que não é o Rato interagiu com ESSE prato específico
			if outro_cargo != "Rato" and typeof(outra_acao["alvo"]) == TYPE_INT and outra_acao["alvo"] == prato_id:
				foi_mexido = true
				break
				
		# Guarda no dicionário: true = Perigo (Vermelho), false = Limpo (Verde)
		resultado_faro[prato_id] = foi_mexido 
		
	return resultado_faro
#endregion

#region FIM DE JOGO
func verificar_vitoria() -> String:
	if vencedor_imediato != "": return vencedor_imediato
	var total_vivos = 0
	var mal_vivos = 0
	var egoista_vivo = false
	
	for j in jogadores:
		if j.vivo:
			total_vivos += 1
			# Conta como "Mal" tanto o Guloso quanto o Rato
			if j.cargo == "Guloso" or j.cargo == "Rato":
				mal_vivos += 1
			elif j.cargo == "Egoísta":
				egoista_vivo = true

	# 1. Empate por Morte Geral (Surto do Egoísta ou fome matou geral)
	if total_vivos == 0:
		return "EMPATE_MORTE_GERAL"
		
	# 2. Vitória do Egoísta (Sobrou apenas ele)
	if total_vivos == 1 and egoista_vivo:
		return "VITORIA_EGOISTA"
		
	# 3. Vitória do Mal (Número de maus >= 50% dos vivos)
	if mal_vivos >= (float(total_vivos) / 2.0):
		return "VITORIA_MAL"
		
	# 4. Vitória do Bem (Não sobrou ninguém do Mal e o Egoísta não ganhou sozinho)
	if mal_vivos == 0:
		return "VITORIA_BEM"
		
	# 5. Se nada disso aconteceu, o jogo continua!
	return "CONTINUA"
#endregion
