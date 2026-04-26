extends Node2D
class_name ShadowBossMachine

signal phase_gate_destroyed

@export var player_path: NodePath
@export var platform_path: NodePath

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $HurtboxComponent/CollisionShape2D
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var healthbar: CanvasItem = $Healthbar
@onready var machine_sfx: Node = $machine_sfx
var _player: Node2D
var _platform: Sprite2D

enum MachineState {
	TRACKING,
	OPENING,
	VULNERABLE,
	CLOSING,
}

var _state := MachineState.TRACKING

func _ready() -> void:
	_player = _find_player()
	_platform = _find_platform()
	if health_component:
		health_component.died.connect(_on_health_component_died)
	_set_phase_gate_active(false)
	if healthbar:
		healthbar.visible = false
	_update_animation_for_player_position()

func _process(_delta: float) -> void:
	_update_animation_for_player_position()

func _find_player() -> Node2D:
	if not player_path.is_empty():
		var player_from_path := get_node_or_null(player_path) as Node2D
		if player_from_path:
			return player_from_path

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	return current_scene.find_child("BetterPlayer", true, false) as Node2D

func _find_platform() -> Sprite2D:
	if not platform_path.is_empty():
		var platform_from_path := get_node_or_null(platform_path) as Sprite2D
		if platform_from_path:
			return platform_from_path

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	return current_scene.find_child("Platform", true, false) as Sprite2D

func _update_animation_for_player_position() -> void:
	if anim_sprite == null:
		return
	if _state != MachineState.TRACKING:
		return
	if _player == null:
		_player = _find_player()
	if _platform == null:
		_platform = _find_platform()
	if _player == null or _platform == null or _platform.texture == null:
		_play_animation(&"idle")
		return

	var platform_width := _get_platform_texture_width()
	if platform_width <= 0.0:
		_play_animation(&"idle")
		return

	var player_local_position := _platform.to_local(_player.global_position)
	var left_edge := -platform_width * 0.5 if _platform.centered else 0.0
	var third_width := platform_width / 3.0
	var relative_x := player_local_position.x - left_edge

	if relative_x < third_width:
		_play_animation(&"left")
	elif relative_x > third_width * 2.0:
		_play_animation(&"right")
	else:
		_play_animation(&"idle")

func _play_animation(animation_name: StringName) -> void:
	if anim_sprite.animation == animation_name and anim_sprite.is_playing():
		return
	anim_sprite.play(animation_name)

func open_phase_gate() -> void:
	if anim_sprite == null or _state != MachineState.TRACKING:
		return

	if health_component:
		health_component.has_died = false
		health_component.health = health_component.max_health

	_state = MachineState.OPENING
	_set_phase_gate_active(false)
	if healthbar:
		healthbar.visible = true
	anim_sprite.play(&"eyepop_TEMP")
	if machine_sfx and machine_sfx.has_method("play_falling_eye"):
		machine_sfx.play_falling_eye()

func close_phase_gate() -> void:
	if anim_sprite == null or _state != MachineState.VULNERABLE:
		return

	_state = MachineState.CLOSING
	_set_phase_gate_active(false)
	if machine_sfx and machine_sfx.has_method("stop_machine_eye_audio"):
		machine_sfx.stop_machine_eye_audio()
	anim_sprite.play(&"eyepop_TEMP", -1.0, true)

func is_invulnerable() -> bool:
	return _state != MachineState.VULNERABLE

func _set_phase_gate_active(enabled: bool) -> void:
	if hurtbox_component:
		hurtbox_component.monitoring = enabled
		hurtbox_component.monitorable = enabled
	if collision_shape:
		collision_shape.disabled = not enabled

func _on_health_component_died() -> void:
	close_phase_gate()

func _get_platform_world_width() -> float:
	if _platform == null or _platform.texture == null:
		return 0.0

	return _platform.texture.get_size().x * absf(_platform.global_scale.x)

func _get_platform_texture_width() -> float:
	if _platform == null or _platform.texture == null:
		return 0.0

	return _platform.texture.get_size().x

func _on_animated_sprite_2d_animation_finished() -> void:
	match _state:
		MachineState.OPENING:
			_state = MachineState.VULNERABLE
			anim_sprite.play(&"eyepop_IDLE")
			if machine_sfx and machine_sfx.has_method("play_idle_eye"):
				machine_sfx.play_idle_eye()
			_set_phase_gate_active(true)
		MachineState.CLOSING:
			_state = MachineState.TRACKING
			if healthbar:
				healthbar.visible = false
			_update_animation_for_player_position()
			phase_gate_destroyed.emit()
		_:
			_update_animation_for_player_position()
