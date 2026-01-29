extends CanvasLayer
class_name MainMenu

@onready var game_container = get_parent()
@onready var play_button_hovered = false

@onready var button_y = %PlayButton.global_position.y
@onready var button_yh = button_y - 20

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

	Engine.time_scale = 1

func _physics_process(delta:float) -> void:
	
	if play_button_hovered:
		var hover_tween:Tween = create_tween()
		hover_tween.tween_property(%PlayButton, "global_position:y", button_yh, 0.2)
	elif not play_button_hovered:
		var hover_tween:Tween = create_tween()
		hover_tween.tween_property(%PlayButton, "global_position:y", button_y, 0.2)

func _on_play_mouse_entered() -> void:
	play_button_hovered = true


func _on_play_button_mouse_exited() -> void:
	play_button_hovered = false

func _on_play_button_pressed() -> void:
	game_container.spawn_level("Parallax_showcase")
	queue_free()
	pass # Replace with function body.
	
func _on_exit_button_pressed() -> void:
	get_tree().quit()
