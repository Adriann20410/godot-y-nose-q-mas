extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var sensibilidad_raton = 0.003

@onready var camara = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
@onready var gridmap = get_node("/root/Mundo/GridMap")

# --- REFERENCIAS A LA UI ---
@onready var slot_0 = $Interfaz/ContenedorUI/HBoxContainer/Slot0
@onready var slot_1 = $Interfaz/ContenedorUI/HBoxContainer/Slot1

var id_bloque_actual = 0
var total_bloques = 2 

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	actualizar_hotbar_visual() # Llamamos al inicio para que se ilumine el primero

# --- FUNCIÓN PARA CAMBIAR EL COLOR DE LOS SLOTS ---
func actualizar_hotbar_visual():
	if id_bloque_actual == 0:
		slot_0.modulate = Color(2, 2, 2) # Brilla más (seleccionado)
		slot_1.modulate = Color(1, 1, 1) # Normal
	else:
		slot_0.modulate = Color(1, 1, 1) # Normal
		slot_1.modulate = Color(2, 2, 2) # Brilla más (seleccionado)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensibilidad_raton)
		camara.rotate_x(-event.relative.y * sensibilidad_raton)
		camara.rotation.x = clamp(camara.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			id_bloque_actual = (id_bloque_actual + 1) % total_bloques
			actualizar_hotbar_visual() # ACTUALIZAMOS UI
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			id_bloque_actual = (id_bloque_actual - 1 + total_bloques) % total_bloques
			actualizar_hotbar_visual() # ACTUALIZAMOS UI

	# (El código de romper/poner sigue igual abajo...)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if gridmap and raycast.is_colliding():
			var punto_colision = raycast.get_collision_point() - raycast.get_collision_normal() * 0.5
			gridmap.set_cell_item(gridmap.local_to_map(punto_colision), -1)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if gridmap and raycast.is_colliding():
			var punto_colision = raycast.get_collision_point() + raycast.get_collision_normal() * 0.5
			gridmap.set_cell_item(gridmap.local_to_map(punto_colision), id_bloque_actual)

func _physics_process(delta):
	# (El código de movimiento sigue igual...)
	if not is_on_floor(): velocity.y -= gravity * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor(): velocity.y = JUMP_VELOCITY
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
