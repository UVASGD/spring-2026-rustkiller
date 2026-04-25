extends HFSM

enum AttackStage {
	DISAPPEAR,
	ATTACK,
	REAPPEAR,
}

var _stage := AttackStage.DISAPPEAR

func on_enter() -> void:
	_stage = AttackStage.DISAPPEAR
	if character and character.has_method("reset_reaper_slash_movement"):
		character.reset_reaper_slash_movement()
	if character and character.has_method("begin_reaper_slash_cooldown"):
		character.begin_reaper_slash_cooldown()
	if character and character.has_method("stop_motion"):
		character.stop_motion()
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation(_get_reaper_disintegrate_animation())

func on_exit() -> void:
	if character and character.has_method("reset_reaper_slash_movement"):
		character.reset_reaper_slash_movement()
	if character and character.has_method("stop_motion"):
		character.stop_motion()

func update(_delta: float) -> void:
	if character == null:
		return

	match _stage:
		AttackStage.ATTACK:
			if character.has_method("should_follow_during_reaper_triple") and character.should_follow_during_reaper_triple():
				if character.has_method("reaper_move_toward_target"):
					character.reaper_move_toward_target(_delta)
			else:
				if character.has_method("stop_motion"):
					character.stop_motion()
				if character.has_method("face_target"):
					character.face_target()
		_:
			if character.has_method("stop_motion"):
				character.stop_motion()
			if character.has_method("face_target"):
				character.face_target()

func check_transition(_delta: float) -> TransitionData:
	match _stage:
		AttackStage.DISAPPEAR:
			if _animation_finished(_get_reaper_disintegrate_animation()):
				_clear_animation_finished(_get_reaper_disintegrate_animation())
				if character and character.has_method("teleport_next_to_target"):
					character.teleport_next_to_target()
				if character and character.has_method("begin_reaper_triple_follow"):
					character.begin_reaper_triple_follow()
				_stage = AttackStage.ATTACK
				if character and character.has_method("play_visual_animation"):
					character.play_visual_animation(_get_reaper_triple_animation())
		AttackStage.ATTACK:
			if _animation_finished(_get_reaper_triple_animation()):
				_clear_animation_finished(_get_reaper_triple_animation())
				_stage = AttackStage.REAPPEAR
				if character and character.has_method("play_visual_animation_reverse"):
					character.play_visual_animation_reverse(_get_reaper_disintegrate_animation())
		AttackStage.REAPPEAR:
			if _animation_finished(_get_reaper_disintegrate_animation()):
				_clear_animation_finished(_get_reaper_disintegrate_animation())
				if character and character.has_method("should_enter_player_phase") and character.should_enter_player_phase():
					return TransitionData.new(true, "ReaperExit")
				return TransitionData.new(true, "ReaperIdle")
	return TransitionData.new(false, "")

func _get_reaper_triple_animation() -> String:
	if character and character.has_method("get_reaper_triple_animation"):
		return character.get_reaper_triple_animation()
	return "r_triple"

func _get_reaper_disintegrate_animation() -> String:
	if character and character.has_method("get_reaper_disintegrate_animation"):
		return character.get_reaper_disintegrate_animation()
	return "r_disintegrate"

func _animation_finished(animation_name: String) -> bool:
	if character and character.has_method("was_visual_animation_finished"):
		return character.was_visual_animation_finished(animation_name)
	return false

func _clear_animation_finished(animation_name: String) -> void:
	if character and character.has_method("clear_visual_animation_finished"):
		character.clear_visual_animation_finished(animation_name)
