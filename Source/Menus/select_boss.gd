extends CanvasLayer
class_name SelectBoss

@onready var game_container:GameContainer = get_parent()
@onready var play_button_hovered = false
@onready var shadow_button_hovered = false

@onready var button_y = %PlayButton.global_position.y
@onready var button_yh = button_y - 20
@onready var shadow_button_y = %Shadow.global_position.y
@onready var shadow_button_yh = shadow_button_y - 20

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	Engine.time_scale = 1

func _physics_process(delta:float) -> void:
	
	if play_button_hovered:
		var hover_tween:Tween = create_tween()
		hover_tween.tween_property(%PlayButton, "global_position:y", button_yh, 0.2)
	elif not play_button_hovered:
		var hover_tween:Tween = create_tween()
		hover_tween.tween_property(%PlayButton, "global_position:y", button_y, 0.2)

	if shadow_button_hovered:
		var shadow_hover_tween:Tween = create_tween()
		shadow_hover_tween.tween_property(%Shadow, "global_position:y", shadow_button_yh, 0.2)
	elif not shadow_button_hovered:
		var shadow_hover_tween:Tween = create_tween()
		shadow_hover_tween.tween_property(%Shadow, "global_position:y", shadow_button_y, 0.2)

func _on_play_mouse_entered() -> void:
	play_button_hovered = true


func _on_play_button_mouse_exited() -> void:
	play_button_hovered = false

func _on_play_button_pressed() -> void:
	game_container.spawn_level("furnace_comic")
	queue_free()
	pass # Replace with function body.
	



func _on_back_button_pressed():
	game_container.spawn_main_menu()
	queue_free()





func _on_shadow_mouse_entered():
	shadow_button_hovered = true


func _on_shadow_mouse_exited():
	shadow_button_hovered = false


func _on_shadow_pressed():
	game_container.spawn_level("shadow_comic")
	queue_free()
