extends HFSM

func update(delta: float) -> void:
	var boss := character as HFSMSteamBoss
	if boss:
		boss.chase_step(delta)

func check_transition(_delta: float) -> TransitionData:
	var boss := character as HFSMSteamBoss
	if boss == null or player == null:
		return TransitionData.new(false, "")

	var d := boss.dist_to_player()

	# Close: Explosive (if ready) else Slash
	if d <= boss.close_range:
		if boss.cd_ready("explosive_burst"):
			return TransitionData.new(true, "ExplosiveBlast")
		return TransitionData.new(true, "Slash")

	# In range: SteamBlast (15s CD)
	if d <= boss.steam_blast_range and boss.cd_ready("steam_blast"):
		return TransitionData.new(true, "SteamBlast")

	# Out of range: Lunge (no cooldown specified in your text; add if you want)
	if d >= boss.out_of_range and boss.cd_ready("lunge"):
		return TransitionData.new(true, "Lunge")

	return TransitionData.new(false, "")
