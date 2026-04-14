extends HFSM

enum MoveMode {
	CHASE,
	ORBIT,
}

var _mode := MoveMode.CHASE
var _time_until_slash := 0.0

func on_enter() -> void:
	_sync_mode()
	_time_until_slash = _get_walk_before_slash_time()
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation("walk", false)

func update(delta: float) -> void:
	if character == null:
		return

	_time_until_slash = maxf(_time_until_slash - delta, 0.0)
	_sync_mode()
	if _mode == MoveMode.ORBIT:
		character.orbit_target(delta)
	else:
		character.move_toward_target(delta)

func check_transition(_delta: float) -> TransitionData:
	if _time_until_slash <= 0.0 and character and character.has_method("can_start_slash") and character.can_start_slash():
		return TransitionData.new(true, "Slash")
	return TransitionData.new(false, "")

func _sync_mode() -> void:
	if character == null or not character.has_method("has_target") or not character.has_target():
		_mode = MoveMode.CHASE
		return

	if _mode == MoveMode.CHASE and character.should_orbit_target():
		_mode = MoveMode.ORBIT
	elif _mode == MoveMode.ORBIT and character.should_chase_target():
		_mode = MoveMode.CHASE

func _get_walk_before_slash_time() -> float:
	if character and "walk_before_slash_time" in character:
		return maxf(character.walk_before_slash_time, 0.0)
	return 0.0
