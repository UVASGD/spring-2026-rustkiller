extends HFSM

func on_enter() -> void:
	_set_boss_active(false)

func update(_delta: float) -> void:
	pass

func check_transition(_delta: float) -> TransitionData:
	if animation_ended():
		_set_boss_active(true)

		var boss := character as HFSMSteamBoss
		if boss:
			boss.set_invulnerable(false)
		if boss.phase == 1:	
			return TransitionData.new(true, "Alive")
		else:
			return TransitionData.new(true, "Alive2")

	return TransitionData.new(false, "")

func _set_boss_active(v: bool) -> void:
	var boss := character as HFSMSteamBoss
	boss.set_invulnerable(not v)
	if character == null:
		return
	for n in character.get_children():
		if n is CollisionShape2D:
			n.disabled = not v
		elif n is Area2D:
			n.monitoring = v
			n.monitorable = v
