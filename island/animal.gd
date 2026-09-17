extends CharacterBody3D

const SPEED = 2.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var tiempo_cambio_direccion = 0.0
var direccion_actual = Vector3.ZERO

func _physics_process(delta):
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	# Cambiar de dirección de forma aleatoria cada cierto tiempo
	tiempo_cambio_direccion -= delta
	if tiempo_cambio_direccion <= 0:
		tiempo_cambio_direccion = randf_range(3.0, 7.0)
		var angulo = randf() * TAU
		direccion_actual = Vector3(cos(angulo), 0, sin(angulo)).normalized()
		
		# Mirar hacia donde camina
		if direccion_actual != Vector3.ZERO:
			look_at(global_position + direccion_actual, Vector3.UP)

	# Moverse en la dirección elegida
	if direccion_actual != Vector3.ZERO:
		velocity.x = direccion_actual.x * SPEED
		velocity.z = direccion_actual.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
