extends CharacterBody2D
class_name ShadowBoss

const PLAYER_GROUP: StringName = "PLAYER"
const SHADOW_SKULL_SCENE := preload("res://Source/Entities/Projectiles/ShadowSkull/shadow_skull.tscn")
const SHADOW_BAT_SCENE := preload("res://Source/Entities/Projectiles/ShadowBat/shadow_bat.tscn")

@export var player: CharacterBody2D
@export var light_platform_path: NodePath

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

@export_group("Ranged Attack")
@export var range_attack_chance := 0.5
@export var range_cooldown := 4.0
@export var range_loop_count := 3
@export var skulls_per_range_loop := 3
@export var skull_spawn_radius := 120.0
@export var skull_spawn_min_distance := 42.0
@export_range(0.0, 1.0, 0.01) var skull_spawn_chance := 0.5

@onready var state_machine: HFSM = $ShadowHFSM
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("Visuals/AnimatedSprite2D")
@onready var visuals: Node2D = $Visuals
@onready var light_circle: Sprite2D = $LightCircle

var _is_invulnerable := false
var _knockback_velocity := Vector2.ZERO
var _slash_cooldown_remaining := 0.0
var _range_cooldown_remaining := 0.0
var _last_finished_visual_animation := ""
var _light_platform: Sprite2D

func _ready() -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(PLAYER_GROUP) as CharacterBody2D
	_light_platform = _find_light_platform()
	_update_light_platform_mask()

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
	if _range_cooldown_remaining > 0.0:
		_range_cooldown_remaining = maxf(_range_cooldown_remaining - delta, 0.0)

	state_machine._update(delta)
	_update_light_platform_mask()
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

func can_start_range() -> bool:
	return has_target() and _range_cooldown_remaining <= 0.0

func should_use_range_attack() -> bool:
	return can_start_range() and randf() <= range_attack_chance

func begin_range_cooldown() -> void:
	_range_cooldown_remaining = range_cooldown

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

func spawn_shadow_skulls_near_player() -> void:
	if not has_target():
		return

	var spawn_positions := _get_shadow_skull_spawn_positions()
	for spawn_position in spawn_positions:
		var projectile_scene := SHADOW_SKULL_SCENE if randf() < skull_spawn_chance else SHADOW_BAT_SCENE
		var projectile := projectile_scene.instantiate()
		projectile.global_position = spawn_position
		projectile.add_to_group("shadow_projectile")
		get_tree().current_scene.add_child(projectile)

func _get_shadow_skull_spawn_positions() -> Array[Vector2]:
	var spawn_positions: Array[Vector2] = []
	var skull_count := maxi(skulls_per_range_loop, 0)
	if skull_count <= 0:
		return spawn_positions

	var radius := maxf(skull_spawn_radius, 1.0)
	var min_distance := maxf(skull_spawn_min_distance, 1.0)
	var player_position := player.global_position
	var max_attempts := skull_count * 24
	var attempts := 0

	while spawn_positions.size() < skull_count and attempts < max_attempts:
		attempts += 1
		var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, radius)
		var candidate_position := player_position + offset
		if _is_shadow_skull_spawn_position_clear(candidate_position, spawn_positions, min_distance):
			spawn_positions.append(candidate_position)

	if spawn_positions.size() >= skull_count:
		return spawn_positions

	var ring_radius := min_distance
	while spawn_positions.size() < skull_count:
		var angle := TAU * float(spawn_positions.size()) / float(skull_count)
		var candidate_position := player_position + Vector2.RIGHT.rotated(angle) * ring_radius
		if _is_shadow_skull_spawn_position_clear(candidate_position, spawn_positions, min_distance):
			spawn_positions.append(candidate_position)
		ring_radius += min_distance

	return spawn_positions

func _is_shadow_skull_spawn_position_clear(candidate_position: Vector2, spawn_positions: Array[Vector2], min_distance: float) -> bool:
	for spawn_position in spawn_positions:
		if candidate_position.distance_to(spawn_position) < min_distance:
			return false
	for projectile in get_tree().get_nodes_in_group("shadow_projectile"):
		if not is_instance_valid(projectile) or not (projectile is Node2D):
			continue
		if candidate_position.distance_to(projectile.global_position) < min_distance:
			return false
	return true

func _find_light_platform() -> Sprite2D:
	if not light_platform_path.is_empty():
		var platform_from_path := get_node_or_null(light_platform_path) as Sprite2D
		if platform_from_path:
			return platform_from_path

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	var platform := current_scene.find_child("Platform", true, false) as Sprite2D
	if platform:
		return platform

	return current_scene.find_child("platform", true, false) as Sprite2D

func _update_light_platform_mask() -> void:
	if _light_platform == null:
		_light_platform = _find_light_platform()
	if _light_platform == null or _light_platform.texture == null:
		return

	var shader_material := light_circle.material as ShaderMaterial
	if shader_material == null:
		return

	shader_material.set_shader_parameter("platform_mask", _light_platform.texture)
	shader_material.set_shader_parameter("platform_global_position", _light_platform.global_position)
	shader_material.set_shader_parameter("platform_scale", _light_platform.global_transform.get_scale())
	shader_material.set_shader_parameter("platform_rotation", _light_platform.global_transform.get_rotation())
	shader_material.set_shader_parameter("platform_texture_size", _light_platform.texture.get_size())
