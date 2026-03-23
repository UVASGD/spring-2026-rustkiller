extends HFSM

@export var volley_count := 5
@export var volley_interval := 0.18
@export var startup_delay := 0.12
@export var recovery_delay := 0.25
@export var projectile_rows := 7
@export var row_spacing := 24.0

var _volleys_fired := 0
var _timer := 0.0
var _in_recovery := false

func on_enter():
	character.velocity = Vector2.ZERO
	_volleys_fired = 0
	_timer = startup_delay
	_in_recovery = false
	_face_player()

func update(delta):
	character.velocity = Vector2.ZERO
	_face_player()
	_timer -= delta

	if _in_recovery:
		return

	if _timer <= 0.0 and _volleys_fired < volley_count:
		if character.has_method("fire_sine_projectile"):
			character.fire_sine_projectile(projectile_rows, row_spacing)
		_volleys_fired += 1
		_timer = volley_interval
		if _volleys_fired >= volley_count:
			_in_recovery = true
			_timer = recovery_delay

func check_transition(_delta) -> TransitionData:
	if _in_recovery and _timer <= 0.0:
		return TransitionData.new(true, "Pause")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(false, "")

func _face_player() -> void:
	var visuals := character.get_node_or_null("Visuals") as Node2D
	if visuals == null:
		return

	var direction_x := player.global_position.x - character.global_position.x
	if is_zero_approx(direction_x):
		return

	visuals.scale.x = 1.0 if direction_x < 0.0 else -1.0
