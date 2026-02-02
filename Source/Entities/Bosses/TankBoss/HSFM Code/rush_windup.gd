extends HFSM

@export var next_attacks: Array[HFSM]
var ended: bool = false

func check_transition(_delta) -> TransitionData:
	if animation_ended():
		return TransitionData.new(true, next_attacks.pick_random().move_name)
	return TransitionData.new(false, "")

func on_enter():
	character.velocity = Vector2.ZERO
	character.gun_animation_player.play("GunIdle")

	if player:
		character.chase_point = (player.global_position - character.global_position).normalized()
