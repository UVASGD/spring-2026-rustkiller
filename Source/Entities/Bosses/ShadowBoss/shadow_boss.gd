extends CharacterBody2D
class_name ShadowBoss

const PLAYER_GROUP: StringName = "PLAYER"
const SHADOW_SKULL_SCENE := preload("res://Source/Entities/Projectiles/ShadowSkull/shadow_skull.tscn")
const SHADOW_BAT_SCENE := preload("res://Source/Entities/Projectiles/ShadowBat/shadow_bat.tscn")
const REAPER_PROJECTILE_SCENE := preload("res://Source/Entities/Projectiles/Reaper/reaper_projectile.tscn")

@export var player: CharacterBody2D
@export var light_platform_path: NodePath
@export var machine_path: NodePath

@export_group("Phase")
@export var start_in_player_phase := false
@export var animal_idle_animation: StringName = &"animal_idle"
@export var animal_transform_animation: StringName = &"animal_snake_transform"
@export var animal_slither_animation: StringName = &"animal_snake_slither"
@export var animal_ouroboros_animation: StringName = &"animal_snake_ouroboros"

@export_group("Reaper")
@export var reaper_appear_animation: StringName = &"r_appear"
@export var reaper_disintegrate_animation: StringName = &"r_disintegrate"
@export var reaper_idle_animation: StringName = &"r_idle"
@export var reaper_slash_animation: StringName = &"r_slash"
@export var reaper_triple_animation: StringName = &"r_triple"
@export var reaper_projectile_slash_animation: StringName = &"r_proj_slash"
@export var reaper_idle_duration := 0.8
@export var reaper_move_speed := 180.0
@export var reaper_slash_damage := 25.0
@export var reaper_slash_cooldown := 1.2
@export var reaper_projectile_damage := 18.0
@export var reaper_projectile_speed := 450.0
@export var reaper_projectile_lifetime := 4.0
@export var reaper_projectile_attack_side_padding := 84.0
@export var reaper_projectile_volley_count := 3

@export_group("Animal")
@export var animal_idle_duration := 1.25
@export var animal_move_speed := 90.0
@export var animal_attack_stop_distance := 72.0
@export var animal_attack_damage := 20.0

@export_group("Movement")
@export var move_speed := 120.0
@export var acceleration := 8.0
@export var orbit_radius := 140.0
@export var orbit_reengage_radius := 180.0
@export var orbit_direction := 1.0
@export var walk_before_slash_time := 2.0
@export var slash_damage := 20.0
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
@onready var projectile_origin: Marker2D = $Visuals/projectile_origin
@onready var light_circle: Sprite2D = $LightCircle
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var ouroboros_hitbox: HitboxComponent = $OuroborosHitbox
@onready var slash_hitbox: HitboxComponent = $PlayerHitbox
@onready var reaper_hitbox: HitboxComponent = $ReaperHitbox
@onready var healthbar: CanvasItem = $Healthbar

var _is_invulnerable := false
var _knockback_velocity := Vector2.ZERO
var _slash_cooldown_remaining := 0.0
var _reaper_slash_cooldown_remaining := 0.0
var _range_cooldown_remaining := 0.0
var _last_finished_visual_animation := ""
var _light_platform: Sprite2D
var _reaper_phase_active := false
var _reaper_phase_switch_ready := false
var _reaper_phase_complete := false
var _player_phase_active := false
var _player_phase_switch_ready := false
var _reaper_slash_should_stop := false
var _reaper_triple_should_follow_target := false
var _reaper_attack_index := 0
var _machine: ShadowBossMachine
var _machine_intermission_active := false
var _machine_waiting_for_defeat := false
var _machine_waiting_for_restore := false
var _machine_waiting_for_player_death := false
var _machine_pending_phase := ""
var _player_phase_appear_ready := false
var _phase_hitbox_shape_defaults: Dictionary = {}

func _ready() -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(PLAYER_GROUP) as CharacterBody2D
	_light_platform = _find_light_platform()
	_machine = _find_machine()
	_update_light_platform_mask()
	_reaper_phase_active = start_in_player_phase
	_reaper_phase_switch_ready = start_in_player_phase
	_player_phase_active = start_in_player_phase
	_player_phase_switch_ready = start_in_player_phase
	_configure_ouroboros_hitbox()
	_configure_slash_hitbox()
	_configure_reaper_hitbox()
	_cache_phase_hitbox_shape_defaults()
	_sync_hurtbox_flip()

	if animation_player:
		animation_player.animation_finished.connect(_on_visual_animation_finished)
	if animated_sprite and not animated_sprite.animation_finished.is_connected(_on_animated_sprite_animation_finished):
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
	if is_instance_valid(_machine):
		_machine.phase_gate_destroyed.connect(_on_machine_phase_gate_destroyed)

	state_machine.player = player
	state_machine.character = self
	state_machine.animator = animation_player
	state_machine._accept_export_fields()
	state_machine._on_enter()

func _physics_process(delta: float) -> void:
	if _slash_cooldown_remaining > 0.0:
		_slash_cooldown_remaining = maxf(_slash_cooldown_remaining - delta, 0.0)
	if _reaper_slash_cooldown_remaining > 0.0:
		_reaper_slash_cooldown_remaining = maxf(_reaper_slash_cooldown_remaining - delta, 0.0)
	if _range_cooldown_remaining > 0.0:
		_range_cooldown_remaining = maxf(_range_cooldown_remaining - delta, 0.0)
	if health_component and not health_component.has_health_remaining:
		if _is_currently_in_move(&"AnimalPhase") and not is_instance_valid(_machine):
			_reaper_phase_switch_ready = true
		elif _is_currently_in_move(&"ReaperPhase") and not is_instance_valid(_machine):
			_player_phase_switch_ready = true
	if _should_begin_machine_intermission():
		_begin_machine_intermission()

	if _machine_intermission_active:
		stop_motion()
		_knockback_velocity = Vector2.ZERO
		_update_light_platform_mask()
		if _machine_waiting_for_player_death and was_visual_animation_finished("death"):
			clear_visual_animation_finished("death")
			_start_machine_shadow_defeat()
		elif _machine_waiting_for_restore and was_visual_animation_finished("shadow_defeat"):
			clear_visual_animation_finished("shadow_defeat")
			_finish_machine_intermission()
		elif not _machine_waiting_for_player_death and not _machine_waiting_for_defeat and was_visual_animation_finished("shadow_defeat"):
			clear_visual_animation_finished("shadow_defeat")
			_open_machine_phase_gate()
		return

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

func can_start_reaper_slash() -> bool:
	return has_target() and _reaper_slash_cooldown_remaining <= 0.0

func begin_reaper_slash_cooldown() -> void:
	_reaper_slash_cooldown_remaining = reaper_slash_cooldown

func choose_reaper_attack_state() -> String:
	var attack_states := ["ReaperSlash", "ReaperProjectileSlash", "ReaperTriple"]
	var next_state: String = attack_states[_reaper_attack_index % attack_states.size()]
	_reaper_attack_index = (_reaper_attack_index + 1) % attack_states.size()
	return next_state

func can_start_range() -> bool:
	return has_target() and _range_cooldown_remaining <= 0.0

func should_start_in_player_phase() -> bool:
	return start_in_player_phase

func should_enter_reaper_phase() -> bool:
	return _reaper_phase_switch_ready

func enter_reaper_phase() -> void:
	if not _reaper_phase_active:
		_refill_health_for_phase()
	_reaper_phase_active = true
	_player_phase_active = false
	_player_phase_appear_ready = false
	_reaper_phase_switch_ready = false
	_player_phase_switch_ready = false
	_reaper_phase_complete = false
	_machine_pending_phase = ""
	reset_reaper_slash_movement()
	_reaper_attack_index = 0
	_restore_after_machine_intermission()
	enable_phase_hitboxes()
	stop_motion()

func should_enter_player_phase() -> bool:
	return _player_phase_switch_ready

func enter_player_phase() -> void:
	if not _player_phase_active:
		_refill_health_for_phase()
	_player_phase_active = true
	_reaper_phase_active = false
	_player_phase_switch_ready = false
	_reaper_phase_complete = false
	_machine_pending_phase = ""
	reset_reaper_slash_movement()
	_reaper_attack_index = 0
	_restore_after_machine_intermission()
	enable_phase_hitboxes()
	stop_motion()

func _refill_health_for_phase() -> void:
	if health_component == null:
		return

	health_component.has_died = false
	health_component.health = health_component.max_health

func get_animal_idle_animation() -> String:
	return String(animal_idle_animation)

func get_animal_transform_animation() -> String:
	return String(animal_transform_animation)

func get_animal_slither_animation() -> String:
	return String(animal_slither_animation)

func get_animal_ouroboros_animation() -> String:
	return String(animal_ouroboros_animation)

func get_animal_idle_duration() -> float:
	return maxf(animal_idle_duration, 0.0)

func get_reaper_appear_animation() -> String:
	return String(reaper_appear_animation)

func get_reaper_disintegrate_animation() -> String:
	return String(reaper_disintegrate_animation)

func get_reaper_idle_animation() -> String:
	return String(reaper_idle_animation)

func get_reaper_slash_animation() -> String:
	return String(reaper_slash_animation)

func get_reaper_triple_animation() -> String:
	return String(reaper_triple_animation)

func get_reaper_projectile_slash_animation() -> String:
	return String(reaper_projectile_slash_animation)

func get_reaper_idle_duration() -> float:
	return maxf(reaper_idle_duration, 0.0)

func get_reaper_projectile_volley_count() -> int:
	return maxi(reaper_projectile_volley_count, 1)

func animal_move_toward_target(delta: float) -> void:
	if not has_target():
		stop_motion()
		return

	var direction := global_position.direction_to(player.global_position)
	var desired_velocity := direction * animal_move_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta * 100.0)
	_face_direction(direction)

func is_near_animal_attack_target() -> bool:
	return has_target() and distance_to_target() <= animal_attack_stop_distance

func triple_attack() -> void:
	_reaper_triple_should_follow_target = false

func begin_reaper_triple_follow() -> void:
	_reaper_triple_should_follow_target = true

func should_follow_during_reaper_triple() -> bool:
	return _reaper_triple_should_follow_target

func reaper_move_toward_target(delta: float) -> void:
	if not has_target():
		stop_motion()
		return

	var direction := global_position.direction_to(player.global_position)
	var desired_velocity := direction * reaper_move_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta * 100.0)
	_face_direction(direction)

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
		if animation_player.is_playing() and animation_player.current_animation != animation_name:
			animation_player.stop()
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
		if animation_player.is_playing() and animation_player.current_animation != animation_name:
			animation_player.stop()
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

func _configure_ouroboros_hitbox() -> void:
	if ouroboros_hitbox == null:
		return

	ouroboros_hitbox.hit_owner = "boss"
	ouroboros_hitbox.damage = animal_attack_damage
	ouroboros_hitbox.damage_enabled = true

func _configure_slash_hitbox() -> void:
	if slash_hitbox == null:
		return

	slash_hitbox.hit_owner = "boss"
	slash_hitbox.damage = slash_damage
	slash_hitbox.damage_enabled = true

func _configure_reaper_hitbox() -> void:
	if reaper_hitbox == null:
		return

	reaper_hitbox.hit_owner = "boss"
	reaper_hitbox.damage = reaper_slash_damage
	reaper_hitbox.damage_enabled = true

func disable_phase_hitboxes() -> void:
	_disable_hitbox_collision_shapes(ouroboros_hitbox)
	_disable_hitbox_collision_shapes(slash_hitbox)
	_disable_hitbox_collision_shapes(reaper_hitbox)

func enable_phase_hitboxes() -> void:
	_enable_hitbox(ouroboros_hitbox)
	_enable_hitbox(slash_hitbox)
	_enable_hitbox(reaper_hitbox)
	_restore_phase_hitbox_shape_defaults()

func _disable_hitbox_collision_shapes(hitbox: HitboxComponent) -> void:
	if hitbox == null:
		return

	hitbox.monitoring = false
	hitbox.monitorable = false
	hitbox.damage_enabled = false

	for child in hitbox.get_children():
		_disable_collision_shapes_recursive(child)

func _cache_phase_hitbox_shape_defaults() -> void:
	_phase_hitbox_shape_defaults.clear()
	_cache_hitbox_shape_defaults(ouroboros_hitbox)
	_cache_hitbox_shape_defaults(slash_hitbox)
	_cache_hitbox_shape_defaults(reaper_hitbox)

func _cache_hitbox_shape_defaults(hitbox: HitboxComponent) -> void:
	if hitbox == null:
		return

	var shape_defaults: Dictionary = {}
	_collect_collision_shape_defaults(hitbox, shape_defaults)
	_phase_hitbox_shape_defaults[hitbox] = shape_defaults

func _collect_collision_shape_defaults(node: Node, shape_defaults: Dictionary) -> void:
	var collision_shape := node as CollisionShape2D
	if collision_shape:
		shape_defaults[collision_shape] = collision_shape.disabled

	for child in node.get_children():
		_collect_collision_shape_defaults(child, shape_defaults)

func _restore_phase_hitbox_shape_defaults() -> void:
	_restore_hitbox_shape_defaults(ouroboros_hitbox)
	_restore_hitbox_shape_defaults(slash_hitbox)
	_restore_hitbox_shape_defaults(reaper_hitbox)

func _restore_hitbox_shape_defaults(hitbox: HitboxComponent) -> void:
	if hitbox == null or not _phase_hitbox_shape_defaults.has(hitbox):
		return

	var shape_defaults: Dictionary = _phase_hitbox_shape_defaults[hitbox]
	for collision_shape in shape_defaults.keys():
		if is_instance_valid(collision_shape):
			collision_shape.disabled = shape_defaults[collision_shape]

func _disable_collision_shapes_recursive(node: Node) -> void:
	var collision_shape := node as CollisionShape2D
	if collision_shape:
		collision_shape.disabled = true

	for child in node.get_children():
		_disable_collision_shapes_recursive(child)

func _enable_hitbox(hitbox: HitboxComponent) -> void:
	if hitbox == null:
		return

	hitbox.monitoring = true
	hitbox.monitorable = true
	hitbox.damage_enabled = true

func _on_visual_animation_finished(animation_name: StringName) -> void:
	_last_finished_visual_animation = String(animation_name)

func _on_animated_sprite_animation_finished() -> void:
	if animated_sprite == null:
		return

	_last_finished_visual_animation = String(animated_sprite.animation)

func _face_direction(direction: Vector2) -> void:
	if direction.x == 0.0:
		return

	visuals.scale.x = 1.0 if direction.x < 0.0 else -1.0
	_sync_hurtbox_flip()

func _sync_hurtbox_flip() -> void:
	_sync_area_flip(hurtbox_component)
	_sync_area_flip(ouroboros_hitbox)
	_sync_area_flip(slash_hitbox)
	_sync_area_flip(reaper_hitbox)

func _sync_area_flip(area: Area2D) -> void:
	if area == null:
		return

	var area_scale := area.scale
	area_scale.x = visuals.scale.x
	area.scale = area_scale

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

func stop_reaper_slash_movement() -> void:
	_reaper_slash_should_stop = true
	stop_motion()

func should_stop_reaper_slash_movement() -> bool:
	return _reaper_slash_should_stop

func reset_reaper_slash_movement() -> void:
	_reaper_slash_should_stop = false

func move_to_reaper_projectile_attack_side() -> void:
	global_position = _get_reaper_projectile_attack_position()
	stop_motion()
	face_target()

func spawn_reaper_projectile() -> void:
	if not has_target():
		return

	var projectile := REAPER_PROJECTILE_SCENE.instantiate()
	if projectile is Node2D:
		var projectile_node := projectile as Node2D
		var projectile_scale := projectile_node.scale
		projectile_scale.x = visuals.scale.x
		projectile_node.scale = projectile_scale

	var projectile_hitbox := HitboxComponent.get_child_component(projectile)
	if projectile_hitbox:
		projectile_hitbox.init(reaper_projectile_damage, "boss")

	var motion_component := ProjectileMotionComponent.get_child_component(projectile)
	var spawn_position := projectile_origin.global_position if projectile_origin != null else global_position
	var direction_to_target := (player.global_position - spawn_position).normalized()
	if direction_to_target == Vector2.ZERO:
		direction_to_target = Vector2.LEFT if visuals.scale.x > 0.0 else Vector2.RIGHT

	if motion_component:
		motion_component.shoot(
			spawn_position,
			direction_to_target,
			reaper_projectile_speed,
			reaper_projectile_lifetime
		)

	projectile.add_to_group("shadow_projectile")

	var current_scene := get_tree().current_scene
	if current_scene:
		current_scene.add_child(projectile)
	else:
		add_child(projectile)

func mark_reaper_phase_complete() -> void:
	_reaper_phase_complete = true

func is_reaper_phase_complete() -> bool:
	return _reaper_phase_complete

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

func _find_machine() -> ShadowBossMachine:
	if not machine_path.is_empty():
		var machine_from_path := get_node_or_null(machine_path) as ShadowBossMachine
		if machine_from_path:
			return machine_from_path

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	return current_scene.find_child("ShadowBossMachine", true, false) as ShadowBossMachine

func _get_reaper_projectile_attack_position() -> Vector2:
	var side_sign := _get_reaper_projectile_attack_side_sign()
	var attack_position := global_position

	if _light_platform != null and _light_platform.texture != null:
		var platform_scale := _light_platform.global_transform.get_scale()
		var half_width := _light_platform.texture.get_size().x * absf(platform_scale.x) * 0.5
		var horizontal_extent := maxf(half_width - reaper_projectile_attack_side_padding, 0.0)
		attack_position.x = _light_platform.global_position.x + side_sign * horizontal_extent
	else:
		attack_position.x += side_sign * 260.0

	if has_target():
		attack_position.y = player.global_position.y

	return attack_position

func _get_reaper_projectile_attack_side_sign() -> float:
	if not has_target():
		return -1.0 if randf() < 0.5 else 1.0

	var arena_center_x := _light_platform.global_position.x if _light_platform != null else player.global_position.x
	return -1.0 if player.global_position.x >= arena_center_x else 1.0

func _should_begin_machine_intermission() -> bool:
	if _machine_intermission_active:
		return false
	if _reaper_phase_switch_ready or _player_phase_switch_ready:
		return false
	if _machine_pending_phase != "":
		return false
	if health_component == null or health_component.has_health_remaining:
		return false
	if not _is_currently_in_move(&"PlayerPhase") \
	and not _is_currently_in_move(&"AnimalPhase") \
	and not _is_currently_in_move(&"ReaperPhase"):
		return false
	return is_instance_valid(_machine)

func _begin_machine_intermission() -> void:
	_machine_intermission_active = true
	_machine_waiting_for_defeat = false
	_machine_waiting_for_restore = false
	_machine_waiting_for_player_death = false
	_reaper_phase_switch_ready = false
	_player_phase_switch_ready = false
	_machine_pending_phase = _get_next_phase_after_current_form()
	set_invulnerable(true)
	_set_boss_hittable(false)
	disable_phase_hitboxes()
	if healthbar:
		healthbar.visible = false
	stop_motion()
	clear_visual_animation_finished()
	if _should_play_player_phase_death_animation():
		_start_player_phase_death_animation()
	else:
		_start_machine_shadow_defeat()

func _open_machine_phase_gate() -> void:
	_machine_waiting_for_defeat = true
	if is_instance_valid(_machine):
		_machine.open_phase_gate()
		return
	_on_machine_phase_gate_destroyed()

func _on_machine_phase_gate_destroyed() -> void:
	_machine_waiting_for_defeat = false
	if _machine_pending_phase == "":
		_finish_final_boss_sequence()
		return
	_machine_waiting_for_restore = true
	clear_visual_animation_finished("shadow_defeat")
	play_visual_animation_reverse("shadow_defeat")

func _finish_machine_intermission() -> void:
	_machine_intermission_active = false
	_machine_waiting_for_restore = false
	_machine_waiting_for_player_death = false
	if _machine_pending_phase == "Reaper":
		_reaper_phase_switch_ready = true
	elif _machine_pending_phase == "Player":
		_player_phase_appear_ready = true
		_player_phase_switch_ready = true
	_machine_pending_phase = ""

func _finish_final_boss_sequence() -> void:
	_machine_intermission_active = false
	_machine_waiting_for_restore = false
	_machine_waiting_for_player_death = false
	_machine_pending_phase = ""
	_player_phase_appear_ready = false
	if is_instance_valid(_machine):
		_machine.queue_free()
		_machine = null
	queue_free()

func _restore_after_machine_intermission() -> void:
	set_invulnerable(false)
	_set_boss_hittable(true)
	if healthbar:
		healthbar.visible = true
	if animation_player:
		animation_player.playback_active = true
	if light_circle:
		light_circle.modulate = Color(1, 1, 1, 1)
	if animated_sprite:
		animated_sprite.modulate = Color(1, 1, 1, 1)

func _get_next_phase_after_current_form() -> String:
	if _is_currently_in_move(&"AnimalPhase"):
		return "Reaper"
	if _is_currently_in_move(&"ReaperPhase"):
		return "Player"
	if _is_currently_in_move(&"PlayerPhase"):
		return ""
	return ""

func _should_play_player_phase_death_animation() -> bool:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return false
	if not animated_sprite.sprite_frames.has_animation(&"death"):
		return false
	return _is_currently_in_move(&"PlayerPhase")

func _start_player_phase_death_animation() -> void:
	_machine_waiting_for_player_death = true
	if animation_player:
		animation_player.pause()
	clear_visual_animation_finished("death")
	animated_sprite.play(&"death")

func _start_machine_shadow_defeat() -> void:
	_machine_waiting_for_player_death = false
	clear_visual_animation_finished("shadow_defeat")
	play_visual_animation("shadow_defeat")

func consume_player_phase_appear_ready() -> bool:
	var should_appear := _player_phase_appear_ready
	_player_phase_appear_ready = false
	return should_appear

func _is_currently_in_move(target_move_name: StringName, move: HFSM = state_machine) -> bool:
	if move == null:
		return false
	if StringName(move.move_name) == target_move_name:
		return true
	if not move.is_container:
		return false
	if move.current_move == null or move.current_move == move:
		return false
	return _is_currently_in_move(target_move_name, move.current_move)

func _set_boss_hittable(enabled: bool) -> void:
	if hurtbox_component:
		hurtbox_component.monitoring = enabled
		hurtbox_component.monitorable = enabled

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
