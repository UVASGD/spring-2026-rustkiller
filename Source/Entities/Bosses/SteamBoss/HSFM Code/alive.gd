extends HFSM

@export var steam_bursts_cooldown := 10.0

func choose_internal_move() -> TransitionData:
	return TransitionData.new(true, "Chase")

func update(_delta: float) -> void:
	var boss := character as HFSMSteamBoss
	if boss == null: return

	# Steam bursts from grates every 10s (not tied to boss directly)
	if boss.cd_ready("grate_bursts"):
		boss.set_cd("grate_bursts", steam_bursts_cooldown)
		boss.spawn_grate_steam_bursts()

func check_transition(_delta) -> TransitionData:
	# alive -> death etc if needed
	return TransitionData.new(false, "")
