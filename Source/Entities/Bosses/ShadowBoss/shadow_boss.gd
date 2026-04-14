extends CharacterBody2D
class_name ShadowBoss

const PLAYER_GROUP: StringName = "PLAYER"

@export var player: CharacterBody2D

@export_group("Movement")
@export var move_speed := 120.0
@export var acceleration := 8.0
@export var orbit_radius := 140.0
@export var orbit_reengage_radius := 180.0
@export var orbit_direction := 1.0
@export var walk_before_slash_time := 2.0
@export var slash_teleport_offset := 85
@export var slash_cooldown := 1.5
@export var slash_repeat_count := 3
@export var slash_teleport_delay := 0.15
@export var time_between_slashes := 0.2

@onready var state_machine: HFSM = $ShadowHFSM
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("Visuals/AnimatedSprite2D")
@onready var visuals: Node2D = $Visuals

var _is_invulnerable := false
var _knockback_velocity := Vector2.ZERO
var _slash_cooldown_remaining := 0.0
var _last_finished_visual_animation := ""

func _ready() -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(PLAYER_GROUP) as CharacterBody2D

	if animation_player:
		animation_player.animation_finished.connect(_on_visual_animation_finished)

	state_machine.player = player
	state_machine.character = self
	state_machine.animator = animation_player
	state_machine._accept_export_fields()
	state_machine._on_enter()

func _physics_process(delta: float) -> void:
	if _slash_cooldown_remaining > 0.0:
		_slash_cooldown_remaining = maxf(_slash_cooldown_remaining - delta, 0.0)

	state_machine._update(delta)
	velocity += _knockback_velocity
	move_and_slide()
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, acceleration * delta * 120.0)

func is_invulnerable() -> bool:
	return _is_invulnerable

func set_invulnerable(value: bool) -> void:
	_is_invulnerable = value

func apply_knockback(force: Vector2) -> void:
	_knockback_velocity += force

func stop_motion() -> void:
	velocity = Vector2.ZERO
	_knockback_velocity = Vector2.ZERO

func has_target() -> bool:
	return is_instance_valid(player)

func distance_to_target() -> float:
	if not has_target():
		return INF
	return global_position.distance_to(player.global_position)

func should_orbit_target() -> bool:
	return distance_to_target() <= orbit_radius

func should_chase_target() -> bool:
	return distance_to_target() > orbit_reengage_radius

func can_start_slash() -> bool:
	return has_target() and _slash_cooldown_remaining <= 0.0

func begin_slash_cooldown() -> void:
	_slash_cooldown_remaining = slash_cooldown

func move_toward_target(delta: float) -> void:
	if not has_target():
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta * 100.0)
		return

	var direction := global_position.direction_to(player.global_position)
	var desired_velocity := direction * move_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta * 100.0)
	_face_direction(direction)

func orbit_target(delta: float) -> void:
	if not has_target():
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta * 100.0)
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	if is_zero_approx(distance):
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta * 100.0)
		return

	var radial_direction := to_player / distance
	var tangent_direction := Vector2(-radial_direction.y, radial_direction.x) * signf(orbit_direction)
	var radius_error := distance - orbit_radius
	var correction_strength := clampf(radius_error / maxf(orbit_radius, 1.0), -0.65, 0.65)
	var desired_direction := (tangent_direction + radial_direction * correction_strength).normalized()
	var desired_velocity := desired_direction * move_speed

	velocity = velocity.move_toward(desired_velocity, acceleration * delta * 100.0)
	_face_direction(desired_direction)

func play_visual_animation(animation_name: String, restart: bool = true) -> void:
	if restart:
		_last_finished_visual_animation = ""

	if animation_player and animation_player.has_animation(animation_name):
		if restart or animation_player.current_animation != animation_name:
			animation_player.play(animation_name)
		return

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(animation_name):
		if restart or animated_sprite.animation != animation_name:
			animated_sprite.play(animation_name)
		elif not animated_sprite.is_playing():
			animated_sprite.play()
		return

func play_visual_animation_reverse(animation_name: String) -> void:
	_last_finished_visual_animation = ""

	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play_backwards(animation_name)
		return

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name, -1.0, true)

func get_visual_animation_length(animation_name: String, fallback: float = 0.0) -> float:
	if animation_player and animation_player.has_animation(animation_name):
		return animation_player.get_animation(animation_name).length

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(animation_name):
		var sprite_frames := animated_sprite.sprite_frames
		var frame_count := sprite_frames.get_frame_count(animation_name)
		var animation_speed := sprite_frames.get_animation_speed(animation_name)
		if frame_count > 0 and animation_speed > 0.0:
			var total_duration := 0.0
			for frame_index in frame_count:
				total_duration += sprite_frames.get_frame_duration(animation_name, frame_index)
			return total_duration / animation_speed

	return fallback

func was_visual_animation_finished(animation_name: String) -> bool:
	return _last_finished_visual_animation == animation_name

func clear_visual_animation_finished(animation_name: String = "") -> void:
	if animation_name == "" or _last_finished_visual_animation == animation_name:
		_last_finished_visual_animation = ""

func _on_visual_animation_finished(animation_name: StringName) -> void:
	_last_finished_visual_animation = String(animation_name)

func _face_direction(direction: Vector2) -> void:
	if direction.x == 0.0:
		return

	visuals.scale.x = 1.0 if direction.x < 0.0 else -1.0

func face_target() -> void:
	if not has_target():
		return

	_face_direction(player.global_position - global_position)

func teleport_next_to_target() -> void:
	if not has_target():
		return

	var side := signf(global_position.x - player.global_position.x)
	if is_zero_approx(side):
		side = -1.0 if randf() < 0.5 else 1.0

	global_position = player.global_position + Vector2(side * slash_teleport_offset, 0.0)
	stop_motion()
	face_target()
