extends HFSM

func check_transition(_delta) -> TransitionData:
	if works_longer_than(get_animation_length()):
		return TransitionData.new(true, "Idle")
	return TransitionData.new(false, "")

func on_enter() -> void:
	character.velocity = Vector2.ZERO
	if character and character.attack_hitbox:
		character.attack_hitbox.monitoring = true
		character.attack_hitbox.monitorable = true
		character.attack_hitbox.damage_enabled = true

func on_exit() -> void:
	if character and character.attack_hitbox:
		character.attack_hitbox.damage_enabled = false
