extends HFSM

@export var attack_interval: float = 0.5

func check_transition(_delta) -> TransitionData:
	if works_longer_than(attack_interval):
		return TransitionData.new(true, "Attack")
	return TransitionData.new(false, "")

func on_enter() -> void:
	character.velocity = Vector2.ZERO

func update(_delta: float) -> void:
	character.velocity = Vector2.ZERO
