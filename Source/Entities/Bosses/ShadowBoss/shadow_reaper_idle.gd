extends HFSM

func on_enter() -> void:
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation(_get_reaper_idle_animation())

func update(_delta: float) -> void:
	if character == null:
		return

	if character.has_method("play_visual_animation"):
		character.play_visual_animation(_get_reaper_idle_animation(), false)
	if character.has_method("stop_motion"):
		character.stop_motion()
	if character.has_method("face_target"):
		character.face_target()

func check_transition(_delta: float) -> TransitionData:
	if character and character.has_method("should_enter_player_phase") and character.should_enter_player_phase():
		return TransitionData.new(true, "ReaperExit")
	if works_longer_than(_get_idle_duration()) and character and character.has_method("can_start_reaper_slash") and character.can_start_reaper_slash():
		var next_attack_state := "ReaperSlash"
		if character.has_method("choose_reaper_attack_state"):
			next_attack_state = character.choose_reaper_attack_state()
		return TransitionData.new(true, next_attack_state)
	return TransitionData.new(false, "")

func _get_reaper_idle_animation() -> String:
	if character and character.has_method("get_reaper_idle_animation"):
		return character.get_reaper_idle_animation()
	return "r_idle"

func _get_idle_duration() -> float:
	if character and character.has_method("get_reaper_idle_duration"):
		return character.get_reaper_idle_duration()
	return 0.8
