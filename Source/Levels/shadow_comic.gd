extends Node2D
class_name shadow_comic
@export var panel_sounds: Array[AudioStream] = []

@onready var panels = [
	$PanelsContainer/Panel1,
	$PanelsContainer/Panel2,
	$PanelsContainer/Panel3,
	$PanelsContainer/Panel4,
	$PanelsContainer/Panel5
]

@onready var sfx_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var sfx_constant: AudioStreamPlayer2D = $Constant
@onready var game_container: GameContainer = get_parent() as GameContainer

var current_panel := -1

signal cutscene_finished

func _ready() -> void:
	for panel in panels:
		panel.modulate.a = 0.0

	sfx_constant.finished.connect(_on_constant_finished)
	sfx_constant.play()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		advance_panel()

func advance_panel() -> void:
	current_panel += 1

	if current_panel >= panels.size():
		cutscene_finished.emit()
		if game_container:
			game_container.call_deferred("spawn_level", "shadow_level")
		queue_free()
		return

	if current_panel == 3:
		sfx_constant.stop()

	if current_panel == panels.size() - 1:
		show_final_panel()
	else:
		phase_in_panel(panels[current_panel])

	play_panel_sfx(current_panel)

func phase_in_panel(panel) -> void:
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.4) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

func show_final_panel() -> void:
	phase_in_panel(panels[panels.size() - 1])

func play_panel_sfx(index: int) -> void:
	if index < panel_sounds.size() and panel_sounds[index] != null:
		sfx_player.stream = panel_sounds[index]
		sfx_player.play()

func _on_constant_finished() -> void:
	if current_panel >= panels.size() - 1:
		return
	sfx_constant.play()
