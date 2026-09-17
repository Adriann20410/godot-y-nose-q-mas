extends Control

var btn_jugar
var btn_salir

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Buscamos los botones de forma segura dentro de _ready
	btn_jugar = get_node("CenterContainer/VBoxContainer/BtnJugar")
	btn_salir = get_node("CenterContainer/VBoxContainer/BtnSalir")
	
	if btn_jugar:
		btn_jugar.pressed.connect(_on_btn_jugar_pressed)
	if btn_salir:
		btn_salir.pressed.connect(_on_btn_salir_pressed)

func _on_btn_jugar_pressed():
	get_tree().change_scene_to_file("res://mundo.tscn")

func _on_btn_salir_pressed():
	get_tree().quit()
