extends HFSM

func check_transition(_delta) -> TransitionData:
	return TransitionData.new(false, "")

func on_enter() -> void:
	character.velocity = Vector2.ZERO

func update(_delta: float) -> void:
	character.velocity = Vector2.ZERO
