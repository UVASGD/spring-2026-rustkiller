extends HFSM

func on_enter() -> void:
	if character and character.has_method("stop_motion"):
		character.stop_motion()
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation(_get_reaper_disintegrate_animation())

func update(_delta: float) -> void:
	if character == null:
		return

	if character.has_method("stop_motion"):
		character.stop_motion()

func check_transition(_delta: float) -> TransitionData:
	if _animation_finished(_get_reaper_disintegrate_animation()):
		_clear_animation_finished(_get_reaper_disintegrate_animation())
		if character and character.has_method("mark_reaper_phase_complete"):
			character.mark_reaper_phase_complete()
	return TransitionData.new(false, "")

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
