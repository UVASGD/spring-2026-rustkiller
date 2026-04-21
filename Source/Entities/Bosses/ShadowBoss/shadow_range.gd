extends HFSM

enum RangePhase {
	START,
	LOOP,
	END,
}

var _phase := RangePhase.START
var _timer := 0.0
var _loops_remaining := 0


func on_enter() -> void:
	if character and character.has_method("stop_motion"):
		character.stop_motion()

	_loops_remaining = _get_range_loop_count()
	_start_phase()


func on_exit() -> void:
	_loops_remaining = 0
	if character and character.has_method("begin_range_cooldown"):
		character.begin_range_cooldown()


func update(delta: float) -> void:
	if character == null:
		return

	if character.has_method("stop_motion"):
		character.stop_motion()
	if character.has_method("face_target"):
		character.face_target()

	_timer -= delta

	if _phase == RangePhase.START and _animation_finished("player_range_start"):
		_clear_animation_finished("player_range_start")
		_start_loop_phase()
	elif _phase == RangePhase.LOOP and _timer <= 0.0:
		_loops_remaining -= 1
		if _loops_remaining > 0:
			_start_loop_phase()
		else:
			_start_end_phase()
	elif _phase == RangePhase.END and _timer <= 0.0:
		_clear_animation_finished("player_range_end")


func check_transition(_delta: float) -> TransitionData:
	if _phase == RangePhase.END and (_animation_finished("player_range_end") or _timer <= 0.0):
		_clear_animation_finished("player_range_end")
		return TransitionData.new(true, "Walk")
	return TransitionData.new(false, "")


func _start_phase() -> void:
	_phase = RangePhase.START
	_timer = _get_animation_length_or("player_range_start", 0.4)
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation("player_range_start")


func _start_loop_phase() -> void:
	_phase = RangePhase.LOOP
	_timer = _get_animation_length_or("player_range_loop", 0.9)
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation("player_range_loop")
	if character and character.has_method("spawn_shadow_skulls_near_player"):
		character.spawn_shadow_skulls_near_player()


func _start_end_phase() -> void:
	_phase = RangePhase.END
	_loops_remaining = 0
	_timer = _get_animation_length_or("player_range_end", 0.7)
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation("player_range_end")


func _get_range_loop_count() -> int:
	if character and "range_loop_count" in character:
		return maxi(character.range_loop_count, 1)
	return 1


func _get_animation_length_or(animation_name: String, fallback: float) -> float:
	if character and character.has_method("get_visual_animation_length"):
		return character.get_visual_animation_length(animation_name, fallback)
	if animator and animator.has_animation(animation_name):
		return animator.get_animation(animation_name).length
	return fallback


func _animation_finished(animation_name: String) -> bool:
	if character and character.has_method("was_visual_animation_finished"):
		return character.was_visual_animation_finished(animation_name)
	return _timer <= 0.0


func _clear_animation_finished(animation_name: String) -> void:
	if character and character.has_method("clear_visual_animation_finished"):
		character.clear_visual_animation_finished(animation_name)
