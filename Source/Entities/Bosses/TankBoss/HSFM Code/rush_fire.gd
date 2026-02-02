extends HFSM

var rush_duration := 0.5
var has_fired := false
var has_collided := false

@export_enum("GunFireBurst", "GunFireRadial") var fire_type: String


func check_transition(_delta) -> TransitionData:
	if works_longer_than(rush_duration) or has_collided:
		return TransitionData.new(true, "RushWinddown")
	return TransitionData.new(false, "")

func on_enter():
	rush_duration = randf_range(0.5, 0.75)
	has_fired = false
	has_collided = false
	
	character.gun_animation_player.play(fire_type)
	character.visuals.scale.x = sign(character.chase_point.x)

func update(delta):
	var desired_velocity = character.chase_point * character.chase_speed
	character.velocity = character.velocity.move_toward(desired_velocity, character.acceleration * delta)
	character.move_and_slide()
	
	for i in range(character.get_slide_collision_count()):
		var collision := character.get_slide_collision(i)
		var collider := collision.get_collider()
		if collider.is_in_group("PLAYER"):
			has_collided = true

func on_exit():
	character.velocity = Vector2.ZERO
