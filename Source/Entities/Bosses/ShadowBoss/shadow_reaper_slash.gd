extends HFSM

var _charges_remaining := 0
var _was_parried := false

func on_enter() -> void:
	_charges_remaining = _get_reaper_melee_charge_count()
	_was_parried = false
	if character and character.has_method("begin_reaper_slash_cooldown"):
		character.begin_reaper_slash_cooldown()
	if character and character.has_method("set_reaper_hitbox_slash_damage"):
		character.set_reaper_hitbox_slash_damage()
	_begin_charge()

func on_exit() -> void:
	if character and character.has_method("set_reaper_hitbox_active"):
		character.set_reaper_hitbox_active(false)
	if character and character.has_method("reset_reaper_slash_movement"):
		character.reset_reaper_slash_movement()
	if character and character.has_method("stop_motion"):
		character.stop_motion()

func update(delta: float) -> void:
	if character == null:
		return

	if character.has_method("face_target"):
		character.face_target()

	if character.has_method("should_stop_reaper_slash_movement") and character.should_stop_reaper_slash_movement():
		if character.has_method("stop_motion"):
			character.stop_motion()
	else:
		if character.has_method("reaper_move_toward_target"):
			character.reaper_move_toward_target(delta)

func check_transition(_delta: float) -> TransitionData:
	if _was_parried:
		if character and character.has_method("should_enter_player_phase") and character.should_enter_player_phase():
			return TransitionData.new(true, "ReaperExit")
		return TransitionData.new(true, "ReaperPostMeleeIdle")
	if _animation_finished(_get_reaper_slash_animation()):
		_clear_animation_finished(_get_reaper_slash_animation())
		_charges_remaining -= 1
		if _charges_remaining > 0:
			_begin_charge()
			return TransitionData.new(false, "")
		if character and character.has_method("should_enter_player_phase") and character.should_enter_player_phase():
			return TransitionData.new(true, "ReaperExit")
		return TransitionData.new(true, "ReaperPostMeleeIdle")
	return TransitionData.new(false, "")

func _begin_charge() -> void:
	if character and character.has_method("reset_reaper_slash_movement"):
		character.reset_reaper_slash_movement()
	if character and character.has_method("set_reaper_hitbox_enabled"):
		character.set_reaper_hitbox_enabled(true)
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation(_get_reaper_slash_animation())

func parry_cancel() -> void:
	_was_parried = true
	_charges_remaining = 0
	if character and character.has_method("set_reaper_hitbox_active"):
		character.set_reaper_hitbox_active(false)
	if character and character.has_method("stop_reaper_slash_movement"):
		character.stop_reaper_slash_movement()
	if character and character.has_method("stop_motion"):
		character.stop_motion()

func _get_reaper_slash_animation() -> String:
	if character and character.has_method("get_reaper_slash_animation"):
		return character.get_reaper_slash_animation()
	return "r_slash"

func _get_reaper_melee_charge_count() -> int:
	if character and character.has_method("get_reaper_melee_charge_count"):
		return character.get_reaper_melee_charge_count()
	return 3

func _animation_finished(animation_name: String) -> bool:
	if character and character.has_method("was_visual_animation_finished"):
		return character.was_visual_animation_finished(animation_name)
	return false

func _clear_animation_finished(animation_name: String) -> void:
	if character and character.has_method("clear_visual_animation_finished"):
		character.clear_visual_animation_finished(animation_name)
