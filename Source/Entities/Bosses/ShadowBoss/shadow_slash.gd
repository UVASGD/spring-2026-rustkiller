extends HFSM

enum SlashPhase {
	DISAPPEAR,
	WAIT_TO_TELEPORT,
	WAIT_TO_SLASH,
	SLASH,
	WAIT_BETWEEN_SLASHES,
	REVERSE_DISAPPEAR,
}

var _phase := SlashPhase.DISAPPEAR
var _timer := 0.0
var _slashes_remaining := 0

func on_enter() -> void:
	if character and character.has_method("stop_motion"):
		character.stop_motion()
	_slashes_remaining = _get_slash_repeat_count()
	if character and character.has_method("begin_slash_cooldown"):
		character.begin_slash_cooldown()
	_start_disappear_phase()

func update(delta: float) -> void:
	if character == null:
		return

	if character.has_method("stop_motion"):
		character.stop_motion()
	_timer -= delta

	if _phase == SlashPhase.DISAPPEAR and _animation_finished("disappear"):
		_clear_animation_finished("disappear")
		_phase = SlashPhase.WAIT_TO_TELEPORT
		_timer = _get_teleport_delay()
	elif _phase == SlashPhase.WAIT_TO_TELEPORT and _timer <= 0.0:
		if character.has_method("teleport_next_to_target"):
			character.teleport_next_to_target()
		_phase = SlashPhase.WAIT_TO_SLASH
		_timer = 0.01
	elif _phase == SlashPhase.WAIT_TO_SLASH and _timer <= 0.0:
		_begin_slash_animation()
	elif _phase == SlashPhase.SLASH and _animation_finished("slash"):
		_clear_animation_finished("slash")
		if _slashes_remaining > 0:
			_phase = SlashPhase.WAIT_BETWEEN_SLASHES
			_timer = _get_time_between_slashes()
		else:
			_start_reverse_disappear_phase()
	elif _phase == SlashPhase.WAIT_BETWEEN_SLASHES and _timer <= 0.0:
		if character.has_method("teleport_next_to_target"):
			character.teleport_next_to_target()
		_phase = SlashPhase.WAIT_TO_SLASH
		_timer = 0.01
	elif _phase == SlashPhase.REVERSE_DISAPPEAR and _timer <= 0.0:
		_clear_animation_finished("disappear")

func check_transition(_delta: float) -> TransitionData:
	if _phase == SlashPhase.REVERSE_DISAPPEAR and _timer <= 0.0:
		_clear_animation_finished("disappear")
		return TransitionData.new(true, "Walk")
	return TransitionData.new(false, "")

func _get_animation_length_or(animation_name: String, fallback: float) -> float:
	if character and character.has_method("get_visual_animation_length"):
		return character.get_visual_animation_length(animation_name, fallback)
	if animator and animator.has_animation(animation_name):
		return animator.get_animation(animation_name).length
	return fallback

func _get_slash_repeat_count() -> int:
	if character and "slash_repeat_count" in character:
		return maxi(character.slash_repeat_count, 1)
	return 1

func _begin_slash_animation() -> void:
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation("slash")
	_phase = SlashPhase.SLASH
	_timer = _get_animation_length_or("slash", 1.3)
	_slashes_remaining -= 1

func _start_disappear_phase() -> void:
	_phase = SlashPhase.DISAPPEAR
	_timer = _get_animation_length_or("disappear", 0.5)
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation("disappear")

func _start_reverse_disappear_phase() -> void:
	_phase = SlashPhase.REVERSE_DISAPPEAR
	_timer = _get_animation_length_or("disappear", 0.5)
	if character and character.has_method("play_visual_animation_reverse"):
		character.play_visual_animation_reverse("disappear")

func _get_teleport_delay() -> float:
	if character and "slash_teleport_delay" in character:
		return maxf(character.slash_teleport_delay, 0.0)
	return 0.0

func _get_time_between_slashes() -> float:
	if character and "time_between_slashes" in character:
		return maxf(character.time_between_slashes, 0.0)
	return 0.0

func _animation_finished(animation_name: String) -> bool:
	if character and character.has_method("was_visual_animation_finished"):
		return character.was_visual_animation_finished(animation_name)
	return _timer <= 0.0

func _clear_animation_finished(animation_name: String) -> void:
	if character and character.has_method("clear_visual_animation_finished"):
		character.clear_visual_animation_finished(animation_name)
