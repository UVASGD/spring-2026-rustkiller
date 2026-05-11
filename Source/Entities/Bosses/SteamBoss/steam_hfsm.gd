extends HFSM

# Top layer:
# - Dormant (waiting / intro)
# - Alive   (contains combat substates)

func check_transition(_delta) -> TransitionData:
	return TransitionData.new(false, "top layer single active flow")

func choose_internal_move() -> TransitionData:
	var boss := character as HFSMSteamBoss
	if not boss:
		return TransitionData.new(true, "Awaken")

	if boss.is_dormant:
		return TransitionData.new(true, "Awaken")

	return TransitionData.new(true, "Alive")
