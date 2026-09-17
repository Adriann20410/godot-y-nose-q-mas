extends GridMap

@export var ancho_mundo: int = 128
@export var profundidad_mundo: int = 128
@export var altura_maxima: int = 16
@export var profundidad_suelo: int = -16

const RUTA_GUARDADO = "user://partida_isla_v3.json"
var lista_drops = []

var tiempo_dia: float = 0.0
@export var velocidad_ciclo: float = 0.015
@onready var sol = $DirectionalLight3D if has_node("DirectionalLight3D") else null
var world_env: WorldEnvironment = null

func _ready():
	cell_size = Vector3(1, 1, 1)
	
	generar_mesh_library_procedural()

	if not has_node("WorldEnvironment"):
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		add_child(world_env)
	else:
		world_env = $WorldEnvironment

	# --- ILUMINACIÓN ÓPTIMA PARA JUEGOS DE BLOQUES ---
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.2, 0.45, 0.8)
	sky_mat.sky_horizon_color = Color(0.6, 0.7, 0.85)
	sky_mat.ground_bottom_color = Color(0.1, 0.1, 0.1)
	sky_mat.ground_horizon_color = Color(0.25, 0.25, 0.25)
	sky.sky_material = sky_mat
	env.sky = sky
	
	env.tonemap_exposure = 1.1
	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.sdfgi_read_sky_light = true
	env.sdfgi_cascades = 4
	env.sdfgi_min_cell_size = 0.2
	env.sdfgi_energy = 1.2
	
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 2.0
	
	env.glow_enabled = true
	env.glow_intensity = 0.3
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	world_env.environment = env

	if sol:
		sol.shadow_enabled = true
		sol.shadow_bias = 0.01
		sol.directional_shadow_max_distance = 120.0

	var cargar_ok = false
	if FileAccess.file_exists(RUTA_GUARDADO):
		var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
		var json = JSON.new()
		if json.parse(archivo.get_as_text()) == OK:
			var datos = json.get_data()
			if datos and datos.has("bloques") and datos["bloques"].size() > 0:
				cargar_ok = true
		archivo.close()

	if cargar_ok:
		cargar_partida()
		spawnear_entidades()
		liberar_jugador()
	else:
		await generar_mundo_procedural()

# --- GENERADOR DE TEXTURAS PIXELADAS CLÁSICAS (16x16) PARA CADA BLOQUE ---
func generar_mesh_library_procedural():
	var nuevo_lib = MeshLibrary.new()
	
	var configs = {
		0: {"color": Color(0.52, 0.26, 0.08), "freq": 0.4},  # Tierra
		1: {"color": Color(0.53, 0.53, 0.53), "freq": 0.5},  # Piedra
		2: {"color": Color(0.38, 0.22, 0.10), "freq": 0.3},  # Madera
		3: {"color": Color(0.12, 0.45, 0.18), "freq": 0.6},  # Hojas
		4: {"color": Color(0.68, 0.48, 0.28), "freq": 0.3},  # Tablón
		5: {"color": Color(0.18, 0.18, 0.18), "freq": 0.7},  # Carbón
		6: {"color": Color(0.75, 0.65, 0.55), "freq": 0.6},  # Hierro
		7: {"color": Color(0.90, 0.45, 0.15), "freq": 0.6},  # Cobre
		8: {"color": Color(0.85, 0.88, 0.95), "freq": 0.5},  # Plata
		9: {"color": Color(0.10, 0.90, 1.00), "freq": 0.4}   # Diamante
	}
	
	for id in configs.keys():
		nuevo_lib.create_item(id)
		var mesh = BoxMesh.new()
		mesh.size = Vector3(1, 1, 1)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = configs[id]["color"]
		mat.roughness = 0.9
		
		# --- ESTO ES LA CLAVE PARA GRÁFICOS DE BLOQUES RETRO ---
		# Forzar filtrado Nearest Neighbor para que los píxeles se vean nítidos y cuadrados
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		
		# Crear textura pixelada de 16x16 (estilo clásico de Minecraft)
		var noise = FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_CELLULAR
		noise.frequency = configs[id]["freq"]
		noise.fractal_octaves = 2
		
		var tex = NoiseTexture2D.new()
		tex.width = 16
		tex.height = 16
		tex.noise = noise
		tex.seamless = true
		mat.albedo_texture = tex
		
		if id == 8 or id == 9:
			mat.emission_enabled = true
			mat.emission = configs[id]["color"]
			mat.emission_energy_multiplier = 1.5
		
		mesh.surface_set_material(0, mat)
		nuevo_lib.set_item_mesh(id, mesh)
		
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(1, 1, 1)
		nuevo_lib.set_item_shapes(id, [box_shape, Transform3D.IDENTITY])
		
	mesh_library = nuevo_lib

func _process(delta):
	tiempo_dia += delta * velocidad_ciclo
	if tiempo_dia >= TAU: tiempo_dia = 0.0
	
	if sol:
		sol.rotation.x = tiempo_dia
		var angulo_sol = sin(tiempo_dia)
		if angulo_sol > 0.0:
			sol.light_energy = clamp(angulo_sol * 1.8, 0.2, 1.6)
			sol.light_color = Color(1.0, 0.98, 0.92)
		else:
			sol.light_energy = 0.25
			sol.light_color = Color(0.45, 0.55, 0.85)

	var jugador = get_tree().get_first_node_in_group("jugador")
	for i in range(lista_drops.size() - 1, -1, -1):
		var d = lista_drops[i]
		if is_instance_valid(d["nodo"]):
			d["nodo"].rotate_y(delta * 2.0)
			if jugador and d["nodo"].global_position.distance_to(jugador.global_position) < 2.0:
				if jugador.has_method("recoger_item"): jugador.recoger_item(d["id"])
				d["nodo"].queue_free()
				lista_drops.remove_at(i)
		else:
			lista_drops.remove_at(i)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_G: guardar_partida()
	if event is InputEventKey and event.pressed and event.keycode == KEY_L: cargar_partida()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R: reiniciar_mundo()

func reiniciar_mundo():
	if FileAccess.file_exists(RUTA_GUARDADO):
		var dir = DirAccess.open("user://")
		if dir: dir.remove("partida_isla_v3.json")
	for d in lista_drops:
		if is_instance_valid(d["nodo"]): d["nodo"].queue_free()
	lista_drops.clear()
	for hijo in get_children():
		if hijo.has_method("recibir_daño"): hijo.queue_free()
	
	print(">>> REGENERANDO MUNDO CON ESTILO DE BLOQUES CLÁSICO... <<<")
	await generar_mundo_procedural()

func soltar_item(pos: Vector3, id_tipo: int):
	var nodo_drop = MeshInstance3D.new()
	var mesh = BoxMesh.new(); mesh.size = Vector3(0.35, 0.35, 0.35)
	nodo_drop.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	var colores_drop = {
		0: Color(0.52, 0.26, 0.08), 1: Color(0.53, 0.53, 0.53),
		2: Color(0.38, 0.22, 0.10), 3: Color(0.12, 0.45, 0.18),
		4: Color(0.68, 0.48, 0.28), 5: Color(0.18, 0.18, 0.18),
		6: Color(0.75, 0.65, 0.55), 7: Color(0.90, 0.45, 0.15),
		8: Color(0.85, 0.88, 0.95), 9: Color(0.10, 0.90, 1.00)
	}
	mat.albedo_color = colores_drop[id_tipo] if colores_drop.has(id_tipo) else Color.WHITE
	if id_tipo == 8 or id_tipo == 9:
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 2.0
	nodo_drop.material_override = mat
	add_child(nodo_drop)
	nodo_drop.global_position = pos + Vector3(0, 0.5, 0)
	lista_drops.append({"nodo": nodo_drop, "id": id_tipo})

func generar_mundo_procedural() -> void:
	clear()
	var ruido_terreno = FastNoiseLite.new()
	ruido_terreno.seed = randi()
	ruido_terreno.noise_type = FastNoiseLite.TYPE_PERLIN
	ruido_terreno.frequency = 0.012
	
	var ruido_bosque = FastNoiseLite.new()
	ruido_bosque.seed = randi() + 99
	ruido_bosque.noise_type = FastNoiseLite.TYPE_PERLIN
	ruido_bosque.frequency = 0.035
	
	var ruido_cuevas = FastNoiseLite.new()
	ruido_cuevas.seed = randi() + 777
	ruido_cuevas.noise_type = FastNoiseLite.TYPE_PERLIN
	ruido_cuevas.frequency = 0.04
	
	var ruido_minerales = FastNoiseLite.new()
	ruido_minerales.seed = randi() + 555
	ruido_minerales.noise_type = FastNoiseLite.TYPE_SIMPLEX
	ruido_minerales.frequency = 0.15
	
	var alturas_suelo = {}
	var contador_iteraciones = 0
	
	for x in range(-ancho_mundo / 2, ancho_mundo / 2):
		for z in range(-profundidad_mundo / 2, profundidad_mundo / 2):
			var valor_ruido = ruido_terreno.get_noise_2d(x, z)
			var altura = int(round((valor_ruido + 1.0) / 2.0 * altura_maxima)) + 12
			alturas_suelo[Vector2i(x, z)] = altura
			
			var es_ladera = false
			for dx in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					var vec_vecino = Vector2i(x + dx, z + dz)
					if alturas_suelo.has(vec_vecino) and abs(alturas_suelo[vec_vecino] - altura) >= 2:
						es_ladera = true
						break
				if es_ladera: break
			
			for y in range(profundidad_suelo, altura + 1):
				if y == profundidad_suelo:
					set_cell_item(Vector3i(x, y, z), 1)
					continue
				
				var es_cueva = false
				var cueva_val = abs(ruido_cuevas.get_noise_3d(float(x), float(y), float(z)))
				
				if y > profundidad_suelo + 1 and y < altura - 3:
					if cueva_val < 0.13: es_cueva = true
				elif y >= altura - 3 and y <= altura and es_ladera:
					if cueva_val < 0.07: es_cueva = true
				
				if es_cueva: continue
				
				var id_bloque = 1 if y < altura - 3 else 0
				
				if id_bloque == 1 and y < altura - 2:
					var val_min = abs(ruido_minerales.get_noise_3d(float(x), float(y), float(z)))
					
					if val_min > 0.72:
						id_bloque = 9  # Diamante
					elif val_min > 0.64:
						id_bloque = 8  # Plata
					elif val_min > 0.56:
						id_bloque = 7  # Cobre
					elif val_min > 0.48:
						id_bloque = 6  # Hierro
					elif val_min > 0.38:
						id_bloque = 5  # Carbón
				
				set_cell_item(Vector3i(x, y, z), id_bloque)
		
		contador_iteraciones += 1
		if contador_iteraciones % 8 == 0:
			await get_tree().process_frame
				
	for x in range(-ancho_mundo / 2 + 8, ancho_mundo / 2 - 8):
		for z in range(-profundidad_mundo / 2 + 8, profundidad_mundo / 2 - 8):
			var pos_2d = Vector2i(x, z)
			if not alturas_suelo.has(pos_2d): continue
			var altura_suelo = alturas_suelo[pos_2d]
			
			if get_cell_item(Vector3i(x, altura_suelo, z)) == -1: continue
				
			var factor_bosque = ruido_bosque.get_noise_2d(x, z)
			if factor_bosque > 0.35 and randf() > 0.75:
				var altura_tronco = 4
				for t in range(altura_tronco): 
					set_cell_item(Vector3i(x, altura_suelo + 1 + t, z), 2)
				var base_copa = altura_suelo + altura_tronco - 1
				for hx in range(-1, 2):
					for hz in range(-1, 2):
						for hy in range(0, 3):
							if hy == 2 and (abs(hx) == 1 and abs(hz) == 1): continue
							var pos_hoja = Vector3i(x + hx, base_copa + hy, z + hz)
							if hy == 0 and hx == 0 and hz == 0: continue
							set_cell_item(pos_hoja, 3)

	spawnear_entidades()
	liberar_jugador()
	print(">>> ¡MUNDO GENERADO CON ESTILO DE BLOQUES RETRO Y PIXEL ART! <<<")

func liberar_jugador():
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.global_position = Vector3(0, 40, 0)

func guardar_partida():
	var celdas_guardadas = []
	for celda in get_used_cells():
		var id_item = get_cell_item(celda)
		if id_item != -1: celdas_guardadas.append({"x": celda.x, "y": celda.y, "z": celda.z, "id": id_item})
	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	archivo.store_string(JSON.stringify({"bloques": celdas_guardadas}))
	archivo.close()

func cargar_partida():
	if not FileAccess.file_exists(RUTA_GUARDADO): return
	clear()
	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	var json = JSON.parse_string(archivo.get_as_text())
	if json and json.has("bloques"):
		for b in json["bloques"]:
			set_cell_item(Vector3i(b["x"], b["y"], b["z"]), b["id"])
	archivo.close()

func spawnear_entidades():
	var escena_animal = load("res://animal.tscn")
	if escena_animal:
		for i in range(10):
			var animal = escena_animal.instantiate()
			var rx = randi_range(-40, 40); var rz = randi_range(-40, 40)
			var altura_suelo = 25
			for y in range(35, 0, -1):
				if get_cell_item(Vector3i(rx, y, rz)) != -1: altura_suelo = y + 1; break
			animal.global_position = Vector3(rx, altura_suelo, rz)
			add_child(animal)

	var escena_enemigo = load("res://enemigo.tscn")
	if escena_enemigo:
		for i in range(8):
			var enemigo = escena_enemigo.instantiate()
			var rx = randi_range(-40, 40); var rz = randi_range(-40, 40)
			var altura_suelo = 25
			for y in range(35, 0, -1):
				if get_cell_item(Vector3i(rx, y, rz)) != -1: altura_suelo = y + 1; break
			enemigo.global_position = Vector3(rx, altura_suelo, rz)
			add_child(enemigo)
