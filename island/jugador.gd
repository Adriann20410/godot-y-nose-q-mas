extends CharacterBody3D

const SPEED = 5.0
const SPRINT_SPEED = 8.5
const JUMP_VELOCITY = 4.5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var sensibilidad_raton = 0.003
var modo_vuelo: bool = false
var inventario_abierto: bool = false

var salud: int = 100
var estamina: float = 100.0
var hambre: float = 100.0
var contador_hambre: float = 0.0
var velocidad_caida_max: float = 0.0

@onready var camara = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
@onready var gridmap = get_node("/root/Mundo/GridMap")
@onready var mano_item = $Camera3D/ManoItem if has_node("Camera3D/ManoItem") else null

@onready var slot_0 = $Interfaz/ContenedorUI/HBoxContainer/Slot0
@onready var slot_1 = $Interfaz/ContenedorUI/HBoxContainer/Slot1
@onready var slot_2 = $Interfaz/ContenedorUI/HBoxContainer/Slot2
@onready var slot_3 = $Interfaz/ContenedorUI/HBoxContainer/Slot3
@onready var slot_4 = $Interfaz/ContenedorUI/HBoxContainer/Slot4
@onready var slot_5 = $Interfaz/ContenedorUI/HBoxContainer/Slot5

@onready var panel_inventario = $Interfaz/PanelInventario if has_node("Interfaz/PanelInventario") else null
@onready var slot_6 = $Interfaz/PanelInventario/GridContainer/Slot6 if has_node("Interfaz/PanelInventario/GridContainer/Slot6") else null
@onready var slot_7 = $Interfaz/PanelInventario/GridContainer/Slot7 if has_node("Interfaz/PanelInventario/GridContainer/Slot7") else null
@onready var slot_8 = $Interfaz/PanelInventario/GridContainer/Slot8 if has_node("Interfaz/PanelInventario/GridContainer/Slot8") else null
@onready var slot_9 = $Interfaz/PanelInventario/GridContainer/Slot9 if has_node("Interfaz/PanelInventario/GridContainer/Slot9") else null
@onready var slot_10 = $Interfaz/PanelInventario/GridContainer/Slot10 if has_node("Interfaz/PanelInventario/GridContainer/Slot10") else null
@onready var slot_11 = $Interfaz/PanelInventario/GridContainer/Slot11 if has_node("Interfaz/PanelInventario/GridContainer/Slot11") else null

@onready var texto_salud = $Interfaz/TextoSalud if has_node("Interfaz/TextoSalud") else null
@onready var texto_hambre = $Interfaz/TextoHambre if has_node("Interfaz/TextoHambre") else null
@onready var texto_estamina = $Interfaz/TextoEstamina if has_node("Interfaz/TextoEstamina") else null

var id_bloque_actual = 0
var total_hotbar = 6 
var slot_seleccionado_inventario = -1

var colores_items = {
	0: Color(0.55, 0.27, 0.07), # Tierra
	1: Color(0.5, 0.5, 0.5),     # Piedra
	2: Color(0.4, 0.2, 0.0),     # Madera (Tronco)
	3: Color(0.1, 0.5, 0.1),     # Hojas
	4: Color(0.7, 0.5, 0.3),     # Tablón de Madera
	5: Color(0.2, 0.6, 0.9),     # Pico
	6: Color(0.8, 0.4, 0.1),     # Hacha
	7: Color(1.0, 0.9, 0.2),     # Antorcha
	8: Color(0.2, 0.2, 0.2), 9: Color(0.2, 0.2, 0.2), 10: Color(0.2, 0.2, 0.2), 11: Color(0.2, 0.2, 0.2)
}

var tipos_items_inventario = {
	0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5,
	6: 6, 7: 7, 8: 8, 9: 9, 10: 10, 11: 11
}

var inventario = {
	0: 50, 1: 30, 2: 20, 3: 40, 4: 5, 5: 1, 6: 1, 7: 4,
	8: 0, 9: 0, 10: 0, 11: 0  
}

func _ready():
	add_to_group("jugador")
	global_position = Vector3(0, 40, 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if panel_inventario: panel_inventario.visible = false
	actualizar_inventario_visual()
	actualizar_textos_ui()
	conectar_slots_gui()

func conectar_slots_gui():
	var lista_slots = [slot_0, slot_1, slot_2, slot_3, slot_4, slot_5, slot_6, slot_7, slot_8, slot_9, slot_10, slot_11]
	for i in range(lista_slots.size()):
		var s = lista_slots[i]
		if s and not s.is_connected("gui_input", _on_slot_gui_input.bind(i)):
			s.gui_input.connect(_on_slot_gui_input.bind(i))

func _on_slot_gui_input(event: InputEvent, idx_slot: int):
	if inventario_abierto and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if slot_seleccionado_inventario == -1:
			slot_seleccionado_inventario = idx_slot
		else:
			var temp_id = tipos_items_inventario[slot_seleccionado_inventario]
			var temp_cant = inventario[slot_seleccionado_inventario]
			
			tipos_items_inventario[slot_seleccionado_inventario] = tipos_items_inventario[idx_slot]
			inventario[slot_seleccionado_inventario] = inventario[idx_slot]
			
			tipos_items_inventario[idx_slot] = temp_id
			inventario[idx_slot] = temp_cant
			
			slot_seleccionado_inventario = -1
			actualizar_inventario_visual()

func actualizar_inventario_visual():
	var lista_slots = [slot_0, slot_1, slot_2, slot_3, slot_4, slot_5, slot_6, slot_7, slot_8, slot_9, slot_10, slot_11]
	
	for i in range(lista_slots.size()):
		var s = lista_slots[i]
		if s:
			var id_real = tipos_items_inventario[i]
			if i < total_hotbar and i == id_bloque_actual:
				s.modulate = Color(1.8, 1.8, 1.8)
			else:
				s.modulate = Color(1, 1, 1)
				
			if colores_items.has(id_real):
				s.self_modulate = colores_items[id_real]
				
			if s.has_node("Label"): 
				s.get_node("Label").text = str(inventario[i])

	actualizar_mano_visual()

func actualizar_mano_visual():
	if not mano_item: return
	var mat = StandardMaterial3D.new()
	var id_en_mano = tipos_items_inventario[id_bloque_actual]
	mat.albedo_color = colores_items[id_en_mano] if colores_items.has(id_en_mano) else Color.WHITE
	mano_item.material_override = mat

func recoger_item(id_bloque: int):
	for i in range(12):
		if tipos_items_inventario[i] == id_bloque:
			inventario[i] += 1
			actualizar_inventario_visual()
			return
	for i in range(12):
		if inventario[i] == 0:
			tipos_items_inventario[i] = id_bloque
			inventario[i] = 1
			actualizar_inventario_visual()
			return

func actualizar_textos_ui():
	if texto_salud: texto_salud.text = "Salud: " + str(salud) + " / 100"
	if texto_hambre: texto_hambre.text = "Hambre: " + str(int(hambre)) + " / 100"
	if texto_estamina: texto_estamina.text = "Estamina: " + str(int(estamina)) + " / 100"

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if inventario_abierto:
			inventario_abierto = false
			if panel_inventario: panel_inventario.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		inventario_abierto = not inventario_abierto
		if panel_inventario: panel_inventario.visible = inventario_abierto
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if inventario_abierto else Input.MOUSE_MODE_CAPTURED)

	# --- NUEVA FUNCIÓN: CRAFTEO RÁPIDO (TECLA C) ---
	# Convierte 1 Madera (ID 2) en 4 Tablones (ID 4)
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		craftear_madera_a_tablones()

	# --- NUEVA FUNCIÓN: SOLTAR ÍTEM AL SUELO (TECLA Q) ---
	if not inventario_abierto and event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		soltar_item_activo()

	if not inventario_abierto and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensibilidad_raton)
		camara.rotate_x(-event.relative.y * sensibilidad_raton)
		camara.rotation.x = clamp(camara.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		modo_vuelo = not modo_vuelo
		velocity = Vector3.ZERO

	if not inventario_abierto and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			id_bloque_actual = (id_bloque_actual + 1) % total_hotbar
			actualizar_inventario_visual()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			id_bloque_actual = (id_bloque_actual - 1 + total_hotbar) % total_hotbar
			actualizar_inventario_visual()

	# Romper bloques
	if not inventario_abierto and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if gridmap and raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider and collider.has_method("recibir_daño"):
				collider.recibir_daño(1, global_position)
				return
			
			var punto_colision = raycast.get_collision_point() - raycast.get_collision_normal() * 0.5
			var posicion_grid = gridmap.local_to_map(punto_colision)
			var id_bloque_roto = gridmap.get_cell_item(posicion_grid)
			
			if id_bloque_roto != -1:
				gridmap.set_cell_item(posicion_grid, -1)
				gridmap.soltar_item(gridmap.map_to_local(posicion_grid), id_bloque_roto)

	# Colocar bloques
	elif not inventario_abierto and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if gridmap and raycast.is_colliding():
			var id_a_colocar = tipos_items_inventario[id_bloque_actual]
			if id_a_colocar >= 5: return
			if inventario[id_bloque_actual] > 0:
				var punto_colision = raycast.get_collision_point() + raycast.get_collision_normal() * 0.5
				var posicion_grid = gridmap.local_to_map(punto_colision)
				gridmap.set_cell_item(posicion_grid, id_a_colocar)
				inventario[id_bloque_actual] -= 1
				actualizar_inventario_visual()

func craftear_madera_a_tablones():
	# Busca si el jugador tiene Madera (ID 2) en su inventario
	for i in range(12):
		if tipos_items_inventario[i] == 2 and inventario[i] > 0:
			inventario[i] -= 1
			if inventario[i] == 0: tipos_items_inventario[i] = 0
			
			# Añade Tablones (ID 4)
			recoger_item(4)
			recoger_item(4)
			recoger_item(4)
			recoger_item(4)
			print(">>> ¡Crafteado con éxito: 1 Madera = 4 Tablones! <<<")
			actualizar_inventario_visual()
			return
	print(">>> No tienes madera (ID 2) para craftear. <<<")

func soltar_item_activo():
	var id_en_mano = tipos_items_inventario[id_bloque_actual]
	if inventario[id_bloque_actual] > 0:
		inventario[id_bloque_actual] -= 1
		if gridmap:
			var pos_drop = global_position - transform.basis.z * 1.5 + Vector3(0, 0.5, 0)
			gridmap.soltar_item(pos_drop, id_en_mano)
		actualizar_inventario_visual()

func _physics_process(delta):
	if inventario_abierto:
		velocity = Vector3.ZERO
		return

	contador_hambre += delta
	if contador_hambre >= 3.0:
		contador_hambre = 0.0
		if hambre > 0: hambre -= 1.0
		else:
			salud = max(0, salud - 2)
			if salud == 0:
				salud = 100; hambre = 100.0; global_position = Vector3(0, 40, 0)
		actualizar_textos_ui()

	var velocidad_actual = SPEED
	if Input.is_key_pressed(KEY_SHIFT) and estamina > 0:
		velocidad_actual = SPRINT_SPEED
		estamina = max(0.0, estamina - delta * 30.0)
	else:
		estamina = min(100.0, estamina + delta * 15.0)
	actualizar_textos_ui()

	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if modo_vuelo:
		velocidad_caida_max = 0.0
		velocity.x = direction.x * (SPEED * 1.5)
		velocity.z = direction.z * (SPEED * 1.5)
		var movimiento_vertical = 0.0
		if Input.is_key_pressed(KEY_SPACE): movimiento_vertical += 1.0
		if Input.is_key_pressed(KEY_CTRL): movimiento_vertical -= 1.0
		velocity.y = movimiento_vertical * (SPEED * 1.5)
	else:
		if not is_on_floor():
			velocity.y -= gravity * delta
			if velocity.y < 0: velocidad_caida_max = min(velocidad_caida_max, velocity.y)
		else:
			if velocidad_caida_max < -12.0:
				var daño = int(abs(velocidad_caida_max) - 12.0) * 4
				salud = max(0, salud - daño)
				actualizar_textos_ui()
				if salud == 0:
					salud = 100; hambre = 100.0; global_position = Vector3(0, 40, 0)
					actualizar_textos_ui()
			velocidad_caida_max = 0.0
			if Input.is_action_just_pressed("ui_accept") and is_on_floor(): velocity.y = JUMP_VELOCITY

		if direction:
			velocity.x = direction.x * velocidad_actual
			velocity.z = direction.z * velocidad_actual
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
