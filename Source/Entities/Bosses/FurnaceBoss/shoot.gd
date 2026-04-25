extends HFSM

@export var shot_count := 3
@export var shot_interval := 0.35
@export var startup_delay := 0.15
@export var recovery_delay := 0.2
@export var projectile_rows := 1
@export var row_spacing := 28.0

var shots_fired := 0
var timer := 0.0
var in_recovery := false

func on_enter():
	character.velocity = Vector2.ZERO
	shots_fired = 0
	timer = startup_delay
	in_recovery = false
	face_player()

func update(delta):
	character.velocity = Vector2.ZERO
	face_player()
	timer -= delta

	if in_recovery:
		return

	if timer <= 0.0 and shots_fired < shot_count:
		if character.has_method("fire_sine_projectile"):
			character.fire_sine_projectile(projectile_rows, row_spacing)
		shots_fired += 1
		timer = shot_interval
		if shots_fired >= shot_count:
			in_recovery = true
			timer = recovery_delay

func check_transition(_delta) -> TransitionData:
	if in_recovery and timer <= 0.0:
		return TransitionData.new(true, "Pause")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(false, "")

func face_player() -> void:
	var visuals := character.get_node_or_null("Visuals") as Node2D
	if visuals == null:
		return
	var direction_x := player.global_position.x - character.global_position.x
	if is_zero_approx(direction_x):
		return
	visuals.scale.x = 1.0 if direction_x < 0.0 else -1.0
