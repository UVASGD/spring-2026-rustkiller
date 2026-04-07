extends HFSM

func on_enter():
	if character.has_method("set_invulnerable"):
		character.set_invulnerable(true)

func check_transition(_delta) -> TransitionData:
	if animation_ended():
		return TransitionData.new(true, "Alive")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(false, "")

func on_exit():
	if character.has_method("set_invulnerable"):
		character.set_invulnerable(false)
