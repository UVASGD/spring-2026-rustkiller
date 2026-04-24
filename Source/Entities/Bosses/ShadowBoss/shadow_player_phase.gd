extends HFSM

func check_transition(_delta: float) -> TransitionData:
	if character and character.has_method("should_enter_reaper_phase") and character.should_enter_reaper_phase():
		if character.has_method("enter_reaper_phase"):
			character.enter_reaper_phase()
		return TransitionData.new(true, "ReaperPhase")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	if character and character.has_method("consume_player_phase_appear_ready") and character.consume_player_phase_appear_ready():
		return TransitionData.new(true, "PlayerAppear")
	return TransitionData.new(true, "Walk")
