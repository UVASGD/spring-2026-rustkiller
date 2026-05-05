extends HFSM

@export var aim_time := 0.6
@export var charge_duration := 0.45
@export var charge_speed := 850.0
@export var charge_acceleration := 12000.0
@export var between_charge_wait_time := 0.05
@export var charge_hitbox_distance := 70.0
@export var charge_hit_radius := 95.0

var phase := "aim"
var timer := 0.0
var charges_remaining := 0
var locked_charge_direction := Vector2.RIGHT
var charge_hitbox: HitboxComponent
var charge_hitbox_shape: CollisionShape2D
var damaged_targets: Dictionary = {}
var charge_sound: AudioStreamPlayer2D
var was_parried := false

func on_enter():
	charge_sound = get_node_or_null("Charge_Sound") as AudioStreamPlayer2D
	charge_hitbox = character.get_node_or_null("ChargeHitboxComponent") as HitboxComponent
	charge_hitbox_shape = character.get_node_or_null("ChargeHitboxComponent/CollisionShape2D") as CollisionShape2D
	if charge_hitbox:
		charge_hitbox.manual_damage_application = true
	set_charge_hitbox_enabled(false)
	character.velocity = Vector2.ZERO
	phase = "aim"
	timer = aim_time
	charges_remaining = 2
	was_parried = false
	damaged_targets.clear()
	locked_charge_direction = get_target_direction()
	flip_visuals(locked_charge_direction)
	update_charge_hitbox_transform(locked_charge_direction)

func update(delta: float):
	timer -= delta

	match phase:
		"aim":
			var aim_direction := get_target_direction()
			locked_charge_direction = aim_direction
			flip_visuals(aim_direction)
			update_charge_hitbox_transform(aim_direction)
			character.velocity = Vector2.ZERO
			if timer <= 0.0:
				start_charge()
		"wait":
			flip_visuals(locked_charge_direction)
			update_charge_hitbox_transform(locked_charge_direction)
			character.velocity = Vector2.ZERO
			if timer <= 0.0:
				phase = "aim"
				timer = aim_time
				damaged_targets.clear()
		"charge":
			update_charge_hitbox_transform(locked_charge_direction)
			var target_velocity := locked_charge_direction * charge_speed
			character.velocity = character.velocity.move_toward(target_velocity, charge_acceleration * delta)

	var previous_position := character.global_position
	character.move_and_slide()

	if phase == "charge":
		apply_charge_hits(previous_position, character.global_position)

func check_transition(_delta) -> TransitionData:
	if was_parried:
		set_charge_hitbox_enabled(false)
		character.velocity = Vector2.ZERO
		return TransitionData.new(true, "Pause")

	if phase != "charge" or timer > 0.0:
		return TransitionData.new(false, "")

	set_charge_hitbox_enabled(false)
	character.velocity = Vector2.ZERO
	charges_remaining -= 1

	if charges_remaining > 0:
		phase = "wait"
		timer = between_charge_wait_time
		damaged_targets.clear()
		return TransitionData.new(false, "")

	return TransitionData.new(true, "Pause")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(false, "")

func on_exit():
	set_charge_hitbox_enabled(false)
	character.velocity = Vector2.ZERO

func parry_cancel() -> void:
	set_charge_hitbox_enabled(false)
	was_parried = true
	phase = "wait"
	timer = 0.0
	charges_remaining = 0
	character.velocity = Vector2.ZERO

func start_charge() -> void:
	if charge_sound:
		charge_sound.play()
	phase = "charge"
	timer = charge_duration
	damaged_targets.clear()
	set_charge_hitbox_enabled(true)

func get_target_direction() -> Vector2:
	var target_direction := direction_to_player()
	if target_direction == Vector2.ZERO:
		return locked_charge_direction
	return target_direction

func flip_visuals(direction: Vector2) -> void:
	var visuals := character.get_node_or_null("Visuals") as Node2D
	if visuals == null or is_zero_approx(direction.x):
		return
	visuals.scale.x = 1.0 if direction.x < 0.0 else -1.0

func set_charge_hitbox_enabled(enabled: bool) -> void:
	if charge_hitbox_shape:
		charge_hitbox_shape.set_deferred("disabled", not enabled)
	if charge_hitbox:
		charge_hitbox.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
		charge_hitbox.monitoring = enabled
		charge_hitbox.monitorable = enabled
		charge_hitbox.damage_enabled = enabled

func update_charge_hitbox_transform(direction: Vector2) -> void:
	if charge_hitbox == null:
		return
	var facing := direction
	if facing == Vector2.ZERO:
		facing = Vector2.RIGHT
	facing = facing.normalized()
	charge_hitbox.position = facing * charge_hitbox_distance
	charge_hitbox.rotation = facing.angle()

func apply_charge_hits(from_position: Vector2, to_position: Vector2) -> void:
	if charge_hitbox == null:
		return
	for area in charge_hitbox.get_overlapping_areas():
		var hurtbox := area as HurtboxComponent
		try_apply_charge_hit(hurtbox)
	var player_hurtbox := player.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if player_hurtbox == null:
		return
	var closest_point := closest_point_on_segment(player_hurtbox.global_position, from_position, to_position)
	if closest_point.distance_to(player_hurtbox.global_position) <= charge_hit_radius:
		try_apply_charge_hit(player_hurtbox)

func try_apply_charge_hit(hurtbox: HurtboxComponent) -> void:
	if hurtbox == null:
		return
	if hurtbox.entity_name == charge_hitbox.hit_owner:
		return
	var target_id := hurtbox.get_instance_id()
	if damaged_targets.has(target_id):
		return
	damaged_targets[target_id] = true
	hurtbox.apply_hitbox(charge_hitbox)

func closest_point_on_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> Vector2:
	var segment := segment_end - segment_start
	var segment_length_squared := segment.length_squared()
	if is_zero_approx(segment_length_squared):
		return segment_start
	var weight := clampf((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return segment_start + segment * weight
