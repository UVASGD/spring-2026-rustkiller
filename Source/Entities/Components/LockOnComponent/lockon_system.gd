class_name LockOnSystem
extends Node

@export var camera: Camera2D
@export var player: Node2D
@export var lerp_speed: float = 5.0
@export var default_zoom: float = 1.0
@export var max_lock_on_zoom: float = 10.0
@export var lock_on_range: float = 500.0
@export var padding: float = 50.0
@export var max_lock_on_follow_distance_multiplier: float = 2.0

@export var shake_timer: float = 0.0
@export var shake_duration: float = 0.1
@export var shake_magnitude: float = 20.0


var current_target: LockOnComponent = null
var available_targets: Array[LockOnComponent] = []
var _last_safe_camera_position: Vector2 = Vector2.ZERO
var _last_safe_camera_zoom: Vector2 = Vector2.ONE

func _ready() -> void:
	#camera = player.get_node()
	camera.enabled = true
	camera.zoom = Vector2(default_zoom, default_zoom)
	_last_safe_camera_position = camera.global_position
	_last_safe_camera_zoom = camera.zoom
	# Connect to player's "parrying" signal
	if player and player.has_signal("parrying"):
		player.parrying.connect(_on_player_parrying)
	player.get_node("HealthComponent").health_changed.connect(_on_player_health_changed)
	var boss := get_tree().get_first_node_in_group("boss")
	if boss:
		var boss_health_component := boss.get_node_or_null("HealthComponent")
		if boss_health_component and boss_health_component.has_signal("health_changed"):
			boss_health_component.health_changed.connect(_on_boss_health_changed)

func _physics_process(delta: float) -> void:
	_recover_camera_if_needed()

	if _can_use_lock_on_target():
		_update_camera_for_lock_on(delta)
	else:
		if current_target != null:
			unlock()
		_update_camera_default(delta)

	_store_safe_camera_state()
	_apply_camera_shake(delta)
	
func _apply_camera_shake(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		
		# Strength falls off over time
		var t := shake_timer / shake_duration
		var offset := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * shake_magnitude * t

		camera.offset = offset
	else:
		camera.offset = Vector2.ZERO

func _on_player_health_changed(health_update: HealthComponent.HealthUpdate) -> void:
	_apply_damage_shake(health_update)

func _on_boss_health_changed(health_update: HealthComponent.HealthUpdate) -> void:
	_apply_damage_shake(health_update)

func _apply_damage_shake(health_update: HealthComponent.HealthUpdate) -> void:
	var damage_taken := health_update.previous_health - health_update.health
	if damage_taken <= 0.0:
			return

	var damage_ratio := clampf(damage_taken / maxf(health_update.max_health, 1.0), 0.0, 1.0)
	shake_timer = maxf(shake_timer, lerpf(0.1, 0.3, damage_ratio))
	shake_magnitude = lerpf(10.0, 20.0, damage_ratio)

func _input(event):
	if event.is_action_pressed("lockon"):
		_find_all_targets()
		toggle_lock_on()

func _on_player_parrying() -> void:
	shake_timer = shake_duration

func trigger_damage_shake(damage_ratio: float = 0.0) -> void:
	damage_ratio = clampf(damage_ratio, 0.0, 1.0)
	shake_timer = maxf(shake_timer, lerpf(0.1, 0.3, damage_ratio))
	shake_magnitude = lerpf(20.0, 40.0, damage_ratio)

func toggle_lock_on() -> void:
	if current_target:
		unlock()
	else:
		lock_on_nearest_to_cursor()

func lock_on_nearest_to_cursor() -> void:
	var mouse_pos = camera.get_global_mouse_position()
	var nearest_target: LockOnComponent = null
	var nearest_distance: float = INF
	
	for target in available_targets:
		if not is_instance_valid(target):
			continue
			
		var distance = mouse_pos.distance_to(target.global_position)
		
		if distance <= lock_on_range and distance < nearest_distance:
			nearest_distance = distance
			nearest_target = target
	
	if nearest_target:
		current_target = nearest_target
		current_target.activate()

func unlock() -> void:
	if current_target:
		current_target.deactivate()
		current_target = null

func _update_camera_for_lock_on(delta: float) -> void:
	var target_pos = (player.global_position + current_target.global_position) / 2.0
	if not _is_finite_vector2(target_pos):
		unlock()
		_update_camera_default(delta)
		return

	camera.global_position = camera.global_position.lerp(target_pos, lerp_speed * delta)
	
	var distance = player.global_position.distance_to(current_target.global_position)
	var required_zoom = (distance + padding) / get_viewport().get_visible_rect().size.x
	var target_zoom = minf(max(default_zoom / (required_zoom * 2.0), 0.3), max_lock_on_zoom)
	if not is_finite(target_zoom):
		unlock()
		_update_camera_default(delta)
		return
	
	camera.zoom = camera.zoom.lerp(Vector2(target_zoom, target_zoom), lerp_speed * delta)

func _update_camera_default(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not _is_finite_vector2(player.global_position):
		return

	camera.global_position = camera.global_position.lerp(player.global_position, lerp_speed * delta)
	camera.zoom = camera.zoom.lerp(Vector2(default_zoom, default_zoom), lerp_speed * delta)

func _find_all_targets() -> void:
	## TODO: Make target selecting "rotate" between available targets, 
	## that's why this function exists
	available_targets.clear()
	var all_nodes = get_tree().root.find_children("*", "LockOnComponent", true, false)
	for node in all_nodes:
		if node is LockOnComponent:
			available_targets.append(node)

func _can_use_lock_on_target() -> bool:
	if current_target == null:
		return false
	if not is_instance_valid(current_target):
		return false
	if player == null or not is_instance_valid(player):
		return false
	if camera == null or not is_instance_valid(camera):
		return false
	if not current_target.is_inside_tree():
		return false
	if not _is_finite_vector2(player.global_position):
		return false
	if not _is_finite_vector2(current_target.global_position):
		return false
	if not _is_finite_vector2(camera.global_position):
		return false
	if not _is_finite_vector2(camera.zoom):
		return false

	var follow_distance_limit := lock_on_range * maxf(max_lock_on_follow_distance_multiplier, 1.0)
	if player.global_position.distance_to(current_target.global_position) > follow_distance_limit:
		return false

	return true

func _recover_camera_if_needed() -> void:
	if camera == null or not is_instance_valid(camera):
		return

	if not _is_finite_vector2(camera.global_position):
		camera.global_position = _last_safe_camera_position

	if not _is_finite_vector2(camera.zoom):
		camera.zoom = _last_safe_camera_zoom

func _store_safe_camera_state() -> void:
	if camera == null or not is_instance_valid(camera):
		return
	if _is_finite_vector2(camera.global_position):
		_last_safe_camera_position = camera.global_position
	if _is_finite_vector2(camera.zoom):
		_last_safe_camera_zoom = camera.zoom

func _is_finite_vector2(value: Vector2) -> bool:
	return is_finite(value.x) and is_finite(value.y)
