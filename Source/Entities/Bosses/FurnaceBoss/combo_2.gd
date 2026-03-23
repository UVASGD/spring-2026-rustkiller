extends HFSM

@export var horizontal_offset := 170.0
@export var vertical_offset := 150.0
@export var reposition_speed := 520.0
@export var position_tolerance := 18.0
@export var attack_hitbox_distance := 70.0
@export var attack_hit_radius := 105.0

var _combo_hitbox: HitboxComponent
var _combo_hitbox_shape: CollisionShape2D
var _damaged_targets: Dictionary = {}
var _current_window_index := -1

func on_enter():
	_combo_hitbox = character.get_node_or_null("ComboHitboxComponent") as HitboxComponent
	_combo_hitbox_shape = character.get_node_or_null("ComboHitboxComponent/CollisionShape2D") as CollisionShape2D
	_set_combo_hitbox_enabled(true)
	_damaged_targets.clear()
	_current_window_index = -1
	character.velocity = Vector2.ZERO
	_update_window_state()

func update(_delta):
	_update_window_state()

	var target_position := _get_target_position()
	var to_target := target_position - character.global_position
	if to_target.length() <= position_tolerance:
		character.global_position = target_position
		character.velocity = Vector2.ZERO
	else:
		character.velocity = to_target.normalized() * reposition_speed

	var to_player := player.global_position - character.global_position
	_flip_visuals(to_player)
	_update_combo_hitbox_transform(to_player)

	var previous_position := character.global_position
	character.move_and_slide()
	_apply_combo_hits(previous_position, character.global_position)

func check_transition(_delta) -> TransitionData:
	if animation_ended():
		character.velocity = Vector2.ZERO
		return TransitionData.new(true, "Pause")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(false, "")

func on_exit():
	_set_combo_hitbox_enabled(false)
	character.velocity = Vector2.ZERO

func _update_window_state() -> void:
	var new_window_index := _get_window_index()
	if new_window_index == _current_window_index:
		return

	_current_window_index = new_window_index
	_damaged_targets.clear()

func _get_window_index() -> int:
	var progress := get_progress()
	if progress < 2.0:
		return 0
	if progress < 3.0:
		return 1
	if progress < 4.0:
		return 2
	return 3

func _get_target_position() -> Vector2:
	match _current_window_index:
		0:
			return player.global_position + Vector2(horizontal_offset, 0.0)
		1:
			return player.global_position + Vector2(-horizontal_offset, 0.0)
		2:
			return player.global_position + Vector2(0.0, vertical_offset)
		_:
			return player.global_position + Vector2(0.0, -vertical_offset)

func _set_combo_hitbox_enabled(enabled: bool) -> void:
	if _combo_hitbox_shape:
		_combo_hitbox_shape.set_deferred("disabled", not enabled)
	if _combo_hitbox:
		_combo_hitbox.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED

func _flip_visuals(direction: Vector2) -> void:
	var visuals := character.get_node_or_null("Visuals") as Node2D
	if visuals == null or is_zero_approx(direction.x):
		return

	visuals.scale.x = 1.0 if direction.x < 0.0 else -1.0

func _update_combo_hitbox_transform(direction: Vector2) -> void:
	if _combo_hitbox == null:
		return

	var facing := direction.normalized()
	if facing == Vector2.ZERO:
		facing = Vector2.DOWN

	_combo_hitbox.position = facing * attack_hitbox_distance
	_combo_hitbox.rotation = facing.angle()

func _apply_combo_hits(from_position: Vector2, to_position: Vector2) -> void:
	if _combo_hitbox == null:
		return

	for area in _combo_hitbox.get_overlapping_areas():
		var hurtbox := area as HurtboxComponent
		_try_apply_combo_hit(hurtbox)

	var player_hurtbox := player.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if player_hurtbox == null:
		return

	var closest_point := _closest_point_on_segment(player_hurtbox.global_position, from_position, to_position)
	if closest_point.distance_to(player_hurtbox.global_position) <= attack_hit_radius:
		_try_apply_combo_hit(player_hurtbox)

func _try_apply_combo_hit(hurtbox: HurtboxComponent) -> void:
	if hurtbox == null:
		return
	if hurtbox.entity_name == _combo_hitbox.hit_owner:
		return

	var target_id := hurtbox.get_instance_id()
	if _damaged_targets.has(target_id):
		return

	_damaged_targets[target_id] = true
	hurtbox._on_area_entered(_combo_hitbox)

func _closest_point_on_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> Vector2:
	var segment := segment_end - segment_start
	var segment_length_squared := segment.length_squared()
	if is_zero_approx(segment_length_squared):
		return segment_start

	var weight := clampf((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return segment_start + segment * weight
