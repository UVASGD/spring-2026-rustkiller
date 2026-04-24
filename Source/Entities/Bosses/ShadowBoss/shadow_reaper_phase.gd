extends HFSM

func check_transition(_delta: float) -> TransitionData:
	if character and character.has_method("should_enter_player_phase") and character.should_enter_player_phase():
		if character.has_method("enter_player_phase"):
			character.enter_player_phase()
		return TransitionData.new(true, "PlayerPhase")
	if character and character.has_method("is_reaper_phase_complete") and character.is_reaper_phase_complete():
		if character.has_method("enter_player_phase"):
			character.enter_player_phase()
		return TransitionData.new(true, "PlayerPhase")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(true, "ReaperAppear")
