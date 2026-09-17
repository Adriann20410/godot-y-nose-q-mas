extends DirectionalLight3D

# Velocidad del ciclo (cuanto mayor sea el número, más rápido pasa el tiempo)
@export var velocidad_ciclo: float = 0.2

func _process(delta):
	# Hacemos que el sol gire constantemente en el eje X
	rotation.x += deg_to_rad(velocidad_ciclo) * delta
	
	# Mantenemos el ángulo controlado entre 0 y 360 grados (TAU)
	rotation.x = wrapf(rotation.x, 0, TAU)
	
	# Si el sol está por debajo del horizonte, es de noche (reducimos la luz)
	if rotation.x > PI:
		light_energy = 0.03 # Luz tenue simulando la luna
		shadow_enabled = false
	else:
		# Si está arriba, es de día (la luz sube de intensidad gradualmente)
		light_energy = 1.0
		shadow_enabled = true
