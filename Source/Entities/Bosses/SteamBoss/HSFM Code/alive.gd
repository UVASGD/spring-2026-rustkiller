extends HFSM

@export var steam_bursts_cooldown := 10.0

func choose_internal_move() -> TransitionData:
	return TransitionData.new(true, "Chase")

func update(_delta: float) -> void:
	var boss := character as HFSMSteamBoss
	if boss == null: return

func check_transition(_delta) -> TransitionData:
	var boss := character as HFSMSteamBoss
	if boss == null: return
	if boss.check_phase_transition():
		return TransitionData.new(true, "Awaken2")
	return TransitionData.new(false, "")
