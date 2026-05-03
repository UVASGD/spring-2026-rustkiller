extends HFSM

@export var hover_height := 140.0
@export var arena_left_x := -220.0
@export var arena_right_x := 220.0
@export var reposition_speed := 500.0
@export var reposition_acceleration := 3000.0
@export var position_tolerance := 18.0
@export var windup_time := 0.2
@export var attack_hitbox_distance := 70.0
@export var attack_hit_radius := 105.0

var phase := "reposition"
var timer := 0.0
var target_position := Vector2.ZERO
var combo_hitbox: HitboxComponent
var combo_hitbox_shape: CollisionShape2D
var damaged_targets: Dictionary = {}

func on_enter():
	combo_hitbox = character.get_node_or_null("ComboHitboxComponent") as HitboxComponent
	combo_hitbox_shape = character.get_node_or_null("ComboHitboxComponent/CollisionShape2D") as CollisionShape2D
	set_combo_hitbox_enabled(false)

	phase = "reposition"
	timer = 0.0
	damaged_targets.clear()
	character.velocity = Vector2.ZERO
	target_position = Vector2(
		clampf(player.global_position.x, arena_left_x, arena_right_x),
		player.global_position.y - hover_height
	)
	flip_visuals()
	update_combo_hitbox_transform(Vector2.DOWN)

func update(delta):
	print(timer)
	match phase:
		"reposition":
			target_position = Vector2(
				clampf(player.global_position.x, arena_left_x, arena_right_x),
				player.global_position.y - hover_height
			)
			flip_visuals()
			var to_target := target_position - character.global_position
			if to_target.length() <= position_tolerance:
				character.global_position = target_position
				character.velocity = Vector2.ZERO
				phase = "windup"
				timer = windup_time
			else:
				var desired_velocity := to_target.normalized() * reposition_speed
				character.velocity = character.velocity.move_toward(desired_velocity, reposition_acceleration * delta)
				character.move_and_slide()
		"windup":
			flip_visuals()
			character.velocity = Vector2.ZERO
			timer -= delta
			if timer <= 0.0:
				phase = "slam"
				timer = get_animation_length() - 1
				damaged_targets.clear()
				character.velocity = Vector2.ZERO
		"slam":
			flip_visuals()
			character.velocity = Vector2.ZERO
			update_combo_hitbox_transform(player.global_position - character.global_position)
			apply_combo_hits(character.global_position, character.global_position)
			timer -= delta

func check_transition(_delta) -> TransitionData:
	if phase == "slam" and timer <= 0.0:
		character.velocity = Vector2.ZERO
		return TransitionData.new(true, "Pause")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(false, "")

func on_exit():
	set_combo_hitbox_enabled(false)
	character.velocity = Vector2.ZERO

func set_combo_hitbox_enabled(enabled: bool) -> void:
	if combo_hitbox_shape:
		combo_hitbox_shape.set_deferred("disabled", not enabled)
	if combo_hitbox:
		combo_hitbox.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED

func flip_visuals() -> void:
	var visuals := character.get_node_or_null("Visuals") as Node2D
	if visuals == null:
		return
	var direction_x := player.global_position.x - character.global_position.x
	if is_zero_approx(direction_x):
		return
	visuals.scale.x = 1.0 if direction_x < 0.0 else -1.0

func update_combo_hitbox_transform(direction: Vector2) -> void:
	if combo_hitbox == null:
		return
	var facing := direction.normalized()
	if facing == Vector2.ZERO:
		facing = Vector2.DOWN
	combo_hitbox.position = facing * attack_hitbox_distance
	combo_hitbox.rotation = facing.angle()

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
	hurtbox.apply_hitbox(combo_hitbox)

func closest_point_on_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> Vector2:
	var segment := segment_end - segment_start
	var segment_length_squared := segment.length_squared()
	if is_zero_approx(segment_length_squared):
		return segment_start
	var weight := clampf((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return segment_start + segment * weight
