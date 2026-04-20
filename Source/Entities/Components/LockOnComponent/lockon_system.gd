class_name LockOnSystem
extends Node

@export var camera: Camera2D
@export var player: Node2D
@export var lerp_speed: float = 5.0
@export var default_zoom: float = 1.0
@export var lock_on_range: float = 500.0
@export var padding: float = 100.0

@export var shake_timer: float = 0.0
@export var shake_duration: float = 0.1
@export var shake_magnitude: float = 20.0


var current_target: LockOnComponent = null
var available_targets: Array[LockOnComponent] = []

func _ready() -> void:
	#camera = player.get_node()
	camera.zoom = Vector2(default_zoom, default_zoom)
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
	if current_target and is_instance_valid(current_target):
		_update_camera_for_lock_on(delta)
	else:
		_update_camera_default(delta)

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
	shake_magnitude = lerpf(20.0, 40.0, damage_ratio)

func _input(event):
	if event.is_action_pressed("lockon"):
		_find_all_targets()
		toggle_lock_on()

func _on_player_parrying() -> void:
	shake_timer = shake_duration

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
	camera.global_position = camera.global_position.lerp(target_pos, lerp_speed * delta)
	
	var distance = player.global_position.distance_to(current_target.global_position)
	var required_zoom = (distance + padding) / get_viewport().get_visible_rect().size.x
	var target_zoom = max(default_zoom / (required_zoom * 2.0), 0.3)
	
	camera.zoom = camera.zoom.lerp(Vector2(target_zoom, target_zoom), lerp_speed * delta)

func _update_camera_default(delta: float) -> void:
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
