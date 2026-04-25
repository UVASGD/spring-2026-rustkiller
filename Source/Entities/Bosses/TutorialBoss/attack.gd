extends HFSM

func check_transition(_delta) -> TransitionData:
	if works_longer_than(get_animation_length()):
		return TransitionData.new(true, "Idle")
	return TransitionData.new(false, "")

func on_enter() -> void:
	character.velocity = Vector2.ZERO
