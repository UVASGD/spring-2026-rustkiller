extends HFSM

enum AttackStage {
	APPEAR,
	SLASH,
	DISAPPEAR,
}

var _stage := AttackStage.APPEAR
var _slashes_remaining := 0

func on_enter() -> void:
	_stage = AttackStage.APPEAR
	_slashes_remaining = _get_projectile_volley_count()
	if character and character.has_method("begin_reaper_slash_cooldown"):
		character.begin_reaper_slash_cooldown()
	if character and character.has_method("stop_motion"):
		character.stop_motion()
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation(_get_reaper_disintegrate_animation())

func on_exit() -> void:
	if character and character.has_method("stop_motion"):
		character.stop_motion()

func update(_delta: float) -> void:
	if character == null:
		return

	if character.has_method("stop_motion"):
		character.stop_motion()
	if character.has_method("face_target"):
		character.face_target()

func check_transition(_delta: float) -> TransitionData:
	if character == null:
		return TransitionData.new(false, "")

	match _stage:
		AttackStage.APPEAR:
			if _animation_finished(_get_reaper_disintegrate_animation()):
				_clear_animation_finished(_get_reaper_disintegrate_animation())
				if character.has_method("move_to_reaper_projectile_attack_side"):
					character.move_to_reaper_projectile_attack_side()
				_begin_next_slash()
		AttackStage.SLASH:
			if _animation_finished(_get_reaper_projectile_slash_animation()):
				_clear_animation_finished(_get_reaper_projectile_slash_animation())
				_slashes_remaining -= 1
				if _slashes_remaining > 0:
					_begin_next_slash()
				else:
					_stage = AttackStage.DISAPPEAR
					if character.has_method("play_visual_animation_reverse"):
						character.play_visual_animation_reverse(_get_reaper_disintegrate_animation())
		AttackStage.DISAPPEAR:
			if _animation_finished(_get_reaper_disintegrate_animation()):
				_clear_animation_finished(_get_reaper_disintegrate_animation())
				if character.has_method("should_enter_player_phase") and character.should_enter_player_phase():
					return TransitionData.new(true, "ReaperExit")
				return TransitionData.new(true, "ReaperIdle")

	return TransitionData.new(false, "")

func _begin_next_slash() -> void:
	_stage = AttackStage.SLASH
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation(_get_reaper_projectile_slash_animation())

func _get_projectile_volley_count() -> int:
	if character and character.has_method("get_reaper_projectile_volley_count"):
		return character.get_reaper_projectile_volley_count()
	return 3

func _get_reaper_projectile_slash_animation() -> String:
	if character and character.has_method("get_reaper_projectile_slash_animation"):
		return character.get_reaper_projectile_slash_animation()
	return "r_proj_slash"

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
