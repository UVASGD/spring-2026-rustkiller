extends CanvasLayer
class_name Credits

@onready var game_container:GameContainer = get_parent()


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

	Engine.time_scale = 1

func _physics_process(delta:float) -> void:
	pass



func _on_back_button_pressed():
	game_container.spawn_main_menu()
	queue_free()
