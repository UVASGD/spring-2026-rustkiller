extends HFSM

@export var steam_bursts_cooldown := 10.0

func choose_internal_move() -> TransitionData:
	return TransitionData.new(true, "Chase")

func update(_delta: float) -> void:
	var boss := character as HFSMSteamBoss
	if boss == null: return

func check_transition(_delta) -> TransitionData:
	# alive -> death etc if needed
	return TransitionData.new(false, "")
