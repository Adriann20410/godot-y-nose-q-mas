extends CharacterBody3D

const SPEED = 2.5
const CHASE_SPEED = 4.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var vida: int = 5
var daño_ataque: int = 10
var distancia_deteccion: float = 12.0
var distancia_ataque: float = 1.5

var tiempo_cambio_direccion = 0.0
var direccion_actual = Vector3.ZERO

@onready var mesh = $MeshInstance3D if has_node("MeshInstance3D") else null

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	var jugador = get_tree().get_first_node_in_group("jugador")
	var en_rango_deteccion = false
	var distancia_jugador = 999.0

	if jugador:
		distancia_jugador = global_position.distance_to(jugador.global_position)
		if distancia_jugador <= distancia_deteccion:
			en_rango_deteccion = true

	if en_rango_deteccion:
		# Perseguir al jugador implacablemente
		var dir_persecucion = (jugador.global_position - global_position).normalized()
		dir_persecucion.y = 0
		direccion_actual = dir_persecucion
		if direccion_actual != Vector3.ZERO:
			look_at(global_position + direccion_actual, Vector3.UP)
		
		velocity.x = direccion_actual.x * CHASE_SPEED
		velocity.z = direccion_actual.z * CHASE_SPEED

		# Atacar si está a corta distancia
		if distancia_jugador <= distancia_ataque:
			if jugador.has_method("recibir_daño_externo"):
				jugador.recibir_daño_externo(daño_ataque)
	else:
		# Movimiento errante de patrulla
		tiempo_cambio_direccion -= delta
		if tiempo_cambio_direccion <= 0:
			tiempo_cambio_direccion = randf_range(4.0, 8.0)
			var angulo = randf() * TAU
			direccion_actual = Vector3(cos(angulo), 0, sin(angulo)).normalized()
			if direccion_actual != Vector3.ZERO:
				look_at(global_position + direccion_actual, Vector3.UP)
		
		if direccion_actual != Vector3.ZERO:
			velocity.x = direccion_actual.x * SPEED
			velocity.z = direccion_actual.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func recibir_daño(cantidad: int, _pos: Vector3):
	vida -= cantidad
	if mesh:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.RED
		mesh.material_override = material
		var timer = get_tree().create_timer(0.2)
		timer.timeout.connect(func(): if mesh: mesh.material_override = null)
	
	if vida <= 0:
		print("¡Monstruo derrotado!")
		queue_free()
