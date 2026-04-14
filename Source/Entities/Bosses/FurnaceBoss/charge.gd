extends HFSM

@export var aim_time := 0.6
@export var charge_duration := 0.25
@export var charge_speed := 850.0
@export var hit_slowdown_duration := 0.25
@export var charge_hitbox_distance := 70.0
@export var charge_hit_radius := 95.0

var timer := 0.0
var locked_charge_direction := Vector2.RIGHT
var is_charging := false
var has_hit := false
var hit_slowdown_timer := 0.0
var _charge_hitbox: HitboxComponent
var _charge_hitbox_shape: CollisionShape2D
var _damaged_targets: Dictionary = {}

func on_enter():
	$Charge_Sound.play()
	_charge_hitbox = character.get_node_or_null("ChargeHitboxComponent") as HitboxComponent
	_charge_hitbox_shape = character.get_node_or_null("ChargeHitboxComponent/CollisionShape2D") as CollisionShape2D
	_set_charge_hitbox_enabled(false)
	character.velocity = Vector2.ZERO
	timer = aim_time
	is_charging = false
	has_hit = false
	hit_slowdown_timer = 0.0
	_damaged_targets.clear()
	locked_charge_direction = _get_target_direction()
	_flip_visuals(locked_charge_direction)
	_update_charge_hitbox_transform(locked_charge_direction)

func update(delta : float):
	timer -= delta

	if not is_charging:
		var aim_direction := _get_target_direction()
		locked_charge_direction = aim_direction
		_flip_visuals(aim_direction)
		_update_charge_hitbox_transform(aim_direction)
		character.velocity = Vector2.ZERO

		if timer <= 0.0:
			is_charging = true
			timer = charge_duration
			_damaged_targets.clear()
			_set_charge_hitbox_enabled(true)
			character.velocity = locked_charge_direction * charge_speed
	else:
		_update_charge_hitbox_transform(locked_charge_direction)
		if has_hit:
			hit_slowdown_timer -= delta
			var slow_ratio := maxf(hit_slowdown_timer / hit_slowdown_duration, 0.0)
			character.velocity = locked_charge_direction * charge_speed * slow_ratio
		else:
			character.velocity = locked_charge_direction * charge_speed

	var previous_position := character.global_position
	character.move_and_slide()
	if is_charging:
		_apply_charge_hits(previous_position, character.global_position)

func check_transition(_delta) -> TransitionData:
	if is_charging and timer <= 0.0:
		_set_charge_hitbox_enabled(false)
		character.velocity = Vector2.ZERO
		return TransitionData.new(true, "Pause")
	if has_hit and hit_slowdown_timer <= 0.0:
		_set_charge_hitbox_enabled(false)
		character.velocity = Vector2.ZERO
		return TransitionData.new(true, "Pause")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(false, "")

func _get_target_direction() -> Vector2:
	var target_direction := direction_to_player()
	if target_direction == Vector2.ZERO:
		return locked_charge_direction
	return target_direction

func _flip_visuals(direction: Vector2) -> void:
	var visuals := character.get_node_or_null("Visuals") as Node2D
	if visuals == null or is_zero_approx(direction.x):
		return

	visuals.scale.x = 1.0 if direction.x < 0.0 else -1.0

func on_exit():
	_set_charge_hitbox_enabled(false)
	character.velocity = Vector2.ZERO

func parry_cancel() -> void:
	_set_charge_hitbox_enabled(false)
	is_charging = false
	timer = 0.0
	character.velocity = Vector2.ZERO

func _set_charge_hitbox_enabled(enabled: bool) -> void:
	if _charge_hitbox_shape:
		_charge_hitbox_shape.set_deferred("disabled", not enabled)
	if _charge_hitbox:
		_charge_hitbox.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED

func _update_charge_hitbox_transform(direction: Vector2) -> void:
	if _charge_hitbox == null:
		return

	var facing := direction.normalized()
	if facing == Vector2.ZERO:
		facing = Vector2.RIGHT

	_charge_hitbox.position = facing * charge_hitbox_distance
	_charge_hitbox.rotation = facing.angle()

func _apply_charge_hits(from_position: Vector2, to_position: Vector2) -> void:
	if _charge_hitbox == null:
		return

	for area in _charge_hitbox.get_overlapping_areas():
		var hurtbox := area as HurtboxComponent
		_try_apply_charge_hit(hurtbox)

	var player_hurtbox := player.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if player_hurtbox == null:
		return

	var closest_point := _closest_point_on_segment(player_hurtbox.global_position, from_position, to_position)
	if closest_point.distance_to(player_hurtbox.global_position) <= charge_hit_radius:
		_try_apply_charge_hit(player_hurtbox)

func _try_apply_charge_hit(hurtbox: HurtboxComponent) -> void:
	if hurtbox == null:
		return
	if hurtbox.entity_name == _charge_hitbox.hit_owner:
		return

	var target_id := hurtbox.get_instance_id()
	if _damaged_targets.has(target_id):
		return

	_damaged_targets[target_id] = true
	hurtbox._on_area_entered(_charge_hitbox)
	has_hit = true
	hit_slowdown_timer = hit_slowdown_duration

func _closest_point_on_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> Vector2:
	var segment := segment_end - segment_start
	var segment_length_squared := segment.length_squared()
	if is_zero_approx(segment_length_squared):
		return segment_start

	var weight := clampf((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return segment_start + segment * weight
