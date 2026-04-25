extends HFSM

@export var horizontal_offset := 170.0
@export var vertical_offset := 150.0
@export var reposition_speed := 520.0
@export var reposition_acceleration := 1000.0
@export var position_tolerance := 18.0
@export var attack_hitbox_distance := 70.0
@export var attack_hit_radius := 105.0
@export var hitbox_rotation_speed := 10.0

var current_angle: float = 0.0
var facing_sign := 1.0 
var locked_facing_sign := 1.0

var combo_hitbox: HitboxComponent
var combo_hitbox_shape: CollisionShape2D
var damaged_targets: Dictionary = {}
var current_window_index := -1

func on_enter():
	combo_hitbox = character.get_node_or_null("ComboHitboxComponent") as HitboxComponent
	combo_hitbox_shape = character.get_node_or_null("ComboHitboxComponent/CollisionShape2D") as CollisionShape2D
	set_combo_hitbox_enabled(true)
	damaged_targets.clear()
	current_window_index = -1
	character.velocity = Vector2.ZERO
	update_window_state()
	locked_facing_sign = facing_sign

func update(delta):
	update_window_state()

	var dest := get_target_position()
	var to_target := dest - character.global_position
	if to_target.length() <= position_tolerance:
		character.global_position = dest
		character.velocity = Vector2.ZERO
	else:
		var desired_velocity := to_target.normalized() * reposition_speed
		character.velocity = character.velocity.move_toward(desired_velocity, reposition_acceleration * delta)

	var to_player := player.global_position - character.global_position
	flip_visuals(to_player)
	update_combo_hitbox_transform(get_target_position())

	var previous_position := character.global_position
	character.move_and_slide()
	apply_combo_hits(previous_position, character.global_position)

func check_transition(_delta) -> TransitionData:
	if animation_ended():
		character.velocity = Vector2.ZERO
		return TransitionData.new(true, "Pause")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(false, "")

func on_exit():
	set_combo_hitbox_enabled(false)
	character.velocity = Vector2.ZERO

func update_window_state() -> void:
	var new_window_index := get_window_index()
	if new_window_index == current_window_index:
		return
	current_window_index = new_window_index
	damaged_targets.clear()

func get_window_index() -> int:
	var progress := get_progress()
	if progress < 2.0:
		return 0
	if progress < 3.0:
		return 1
	if progress < 4.0:
		return 2
	return 3

func get_target_position() -> Vector2:
	match current_window_index:
		0:
			return player.global_position + Vector2(horizontal_offset, 0.0)
		1:
			return player.global_position + Vector2(-horizontal_offset, 0.0)
		2:
			return player.global_position + Vector2(0.0, vertical_offset)
		_:
			return player.global_position + Vector2(0.0, -vertical_offset)

func set_combo_hitbox_enabled(enabled: bool) -> void:
	if combo_hitbox_shape:
		combo_hitbox_shape.set_deferred("disabled", not enabled)
	if combo_hitbox:
		combo_hitbox.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED

func flip_visuals(direction: Vector2) -> void:
	var visuals := character.get_node_or_null("Visuals") as Node2D
	if visuals == null or is_zero_approx(direction.x):
		return

	facing_sign = -1.0 if direction.x > 0.0 else 1.0
	visuals.scale.x = facing_sign

func update_combo_hitbox_transform(_direction: Vector2) -> void:
	if combo_hitbox == null:
		return

	var target_facing := Vector2.ZERO

	match current_window_index:
		0:
			target_facing = Vector2.LEFT
		1:
			target_facing = Vector2.RIGHT
		2:
			target_facing = Vector2.UP
		_:
			target_facing = Vector2.DOWN
	target_facing.x *= locked_facing_sign

	var target_angle := target_facing.angle()

	var new_angle := lerp_angle(
		combo_hitbox.rotation,
		target_angle,
		hitbox_rotation_speed * get_process_delta_time()
	)

	combo_hitbox.rotation = new_angle

	var facing := Vector2.RIGHT.rotated(new_angle)
	combo_hitbox.position = facing * attack_hitbox_distance

func apply_combo_hits(from_position: Vector2, to_position: Vector2) -> void:
	if combo_hitbox == null:
		return
	for area in combo_hitbox.get_overlapping_areas():
		var hurtbox := area as HurtboxComponent
		try_apply_combo_hit(hurtbox)
	var player_hurtbox := player.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if player_hurtbox == null:
		return
	var closest_point := closest_point_on_segment(player_hurtbox.global_position, from_position, to_position)
	if closest_point.distance_to(player_hurtbox.global_position) <= attack_hit_radius:
		try_apply_combo_hit(player_hurtbox)

func try_apply_combo_hit(hurtbox: HurtboxComponent) -> void:
	if hurtbox == null:
		return
	if hurtbox.entity_name == combo_hitbox.hit_owner:
		return
	var target_id := hurtbox.get_instance_id()
	if damaged_targets.has(target_id):
		return
	damaged_targets[target_id] = true
	hurtbox._on_area_entered(combo_hitbox)

func closest_point_on_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> Vector2:
	var segment := segment_end - segment_start
	var segment_length_squared := segment.length_squared()
	if is_zero_approx(segment_length_squared):
		return segment_start
	var weight := clampf((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return segment_start + segment * weight
