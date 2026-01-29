extends CharacterBody2D
class_name TankBoss

@export var display_state:bool = false
@export var chase_speed := 250.0
@export var acceleration := 1.0
@export var rush_timer: Timer
@export var idle_timer: Timer
@export var fire_idle_timer: Timer


@export_group("Gun Floaty Effect")
@export var gun_follow_speed := 5.0  
@export var gun_rotation_lag := 0.15 
var target_gun_rotation := 0.0

@export var gun_sway_amount := 15.0  
@export var gun_sway_speed := 2.0
var gun_sway_offset := 0.0

@export_group("Firing")
@export var burst_bullet_count := 5
@export var burst_spread_angle := 15.0
@export var radial_bullet_count := 12
@export var bullet_speed := 400.0
@export var bullet_damage := 20.0
@export var bullet_lifetime := 3.0
@export var pellet_scene: PackedScene

var state_machine: CallableStateMachine
var gun_state_machine: CallableStateMachine

const PLAYER_GROUP: StringName = "PLAYER"
var target

var chase_point: Vector2

@onready var body_animation_player = $AnimationPlayer
@onready var gun_animation_player = $GunAnimationPlayer
@onready var tank_sprite_body = $Visuals/TankBody
@onready var tank_sprite_gun = $Visuals/TankGun

func _ready():
	
	if display_state:
		$FireStateLabel.visible = true
		$StateLabel.visible = true
	else:
		$FireStateLabel.visible = false
		$StateLabel.visible = false
	
	$HurtboxComponent.entity_name = "boss"
	
	state_machine = CallableStateMachine.new()
	gun_state_machine = CallableStateMachine.new()
	state_machine.transitioned.connect(_on_state_transition)
	gun_state_machine.transitioned.connect(_on_gun_state_transition)
	
	idle_timer.timeout.connect(_on_idle_timeout)
	rush_timer.timeout.connect(_on_chase_timeout)
	
	fire_idle_timer.timeout.connect(_on_fire_idle_timeout)
	
	state_machine.add_states(state_idle, enter_idle, exit_idle)
	state_machine.add_states(state_rush, enter_rush, exit_rush)
	state_machine.add_states(state_rush_end, enter_rush_end, exit_rush_end)
	
	gun_state_machine.add_states(state_fire_idle, enter_fire_idle, Callable())
	gun_state_machine.add_states(state_fire_burst, enter_fire_burst, exit_fire_burst)
	gun_state_machine.add_states(state_fire_radial, enter_fire_radial, exit_fire_radial)
	
	state_machine.set_initial_state(state_idle)
	gun_state_machine.set_initial_state(state_fire_idle)
	target = get_tree().get_first_node_in_group(PLAYER_GROUP)
	
	body_animation_player.animation_finished.connect(_on_animation_finished)
	gun_animation_player.animation_finished.connect(_on_gun_animation_finished)
	
func _physics_process(_delta):
	state_machine.update(_delta)
	_update_gun_rotation(_delta)
	if velocity.x != 0:
		$Visuals.scale.x = sign(velocity.x)

func _update_gun_rotation(delta: float):
	if target:
		var direction_to_player = (target.global_position - tank_sprite_gun.global_position).normalized()
		target_gun_rotation = direction_to_player.angle()
	
	tank_sprite_gun.rotation = lerp_angle(
		tank_sprite_gun.rotation, 
		target_gun_rotation - tank_sprite_body.rotation,  
		gun_follow_speed * delta
	)

#region Idle

func enter_idle(): 
	velocity = Vector2.ZERO
	body_animation_player.play("TankSpin")
	idle_timer.start()

func state_idle(delta: float): 
	pass

func exit_idle(): 
	idle_timer.stop()

func _on_idle_timeout():
	var valid_attack_states = [state_rush]
	state_machine.change_state(valid_attack_states.pick_random())
	#state_machine.change_state(state_fire_burst)
#endregion

#region Rush
func enter_rush():
	velocity = Vector2.ZERO
	body_animation_player.play("TankRushStart")
	chase_point = target.global_position - global_position
	rush_timer.start()
	
	rush_timer.wait_time = randf_range(1,2)
	rush_timer.timeout.connect(_on_chase_timeout)
	
	add_child(rush_timer)
	
func state_rush(delta: float):
	var desired_velocity := chase_point.normalized() * chase_speed

	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider.is_in_group("PLAYER"):
			state_machine.change_state(state_rush_end)
			return

func exit_rush(): pass

func _on_rush_start_finished(anim_name: String):
	if anim_name == "TankRushStart":
		body_animation_player.play("TankRushing")

func _on_chase_timeout():
	state_machine.change_state(state_rush_end)
#endregion

#region RushEnd	
func enter_rush_end():
	velocity = Vector2.ZERO
	body_animation_player.play("TankRushEnd")
	rush_timer.stop()

func state_rush_end(delta: float): 
	pass

func exit_rush_end():
	pass
#endregion

#region FireIdle
func enter_fire_idle(): 
	gun_animation_player.play("GunIdle")
	fire_idle_timer.start()

func state_fire_idle(delta: float): 
	pass

func exit_fire_idle(): 
	fire_idle_timer.stop()
	
func _on_fire_idle_timeout():
	var valid_attack_states	 = [state_fire_burst, state_fire_radial]
	gun_state_machine.change_state(valid_attack_states.pick_random())
#endregion

#region FireBurst
func enter_fire_burst():
	velocity = Vector2.ZERO
	gun_animation_player.play("GunFireBurst")
	_fire_burst_at_player()
	
func state_fire_burst(delta: float):
	pass
	
func exit_fire_burst():
	pass
		
func _fire_burst_at_player():
	if not pellet_scene or not target:
		return
		
	var direction_to_player = (target.global_position - tank_sprite_gun.global_position).normalized()
	var base_angle = direction_to_player.angle()
	var spread_rad = deg_to_rad(burst_spread_angle)
	
	for i in burst_bullet_count:
		var random_angle = randf_range(-spread_rad / 2.0, spread_rad / 2.0)
		var bullet_direction = Vector2.from_angle(base_angle + random_angle)
		
		var bullet = pellet_scene.instantiate() as Bullet
		add_bullet_attributes(bullet, bullet_direction)
		
		get_tree().current_scene.add_child(bullet)
#endregion

#region FireRadial
func enter_fire_radial():
	velocity = Vector2.ZERO
	gun_animation_player.play("GunFireRadial")
	_fire_radial_burst()
	
func state_fire_radial(delta: float):
	pass
	
func exit_fire_radial():
	pass
		
func _fire_radial_burst():
	if not pellet_scene:
		return
		
	var angle_step = TAU / radial_bullet_count 
	
	for i in radial_bullet_count:
		var angle = angle_step * i
		var bullet_direction = Vector2.from_angle(angle)
		
		var bullet = pellet_scene.instantiate() as Bullet
		add_bullet_attributes(bullet, bullet_direction)
		
		get_tree().current_scene.add_child(bullet)
#endregion

func _on_animation_finished(anim_name: String):
	match anim_name:
		"TankRushStart":
			body_animation_player.play("TankRushing")
		"TankRushEnd":
			state_machine.change_state(state_idle)
			
func _on_gun_animation_finished(anim_name: String):
	match anim_name:
		"GunFireBurst":
			gun_state_machine.change_state(state_fire_idle)
		"GunFireRadial":
			gun_state_machine.change_state(state_fire_idle)
			
func _on_state_transition(new_state_name: String):
	$StateLabel.text = new_state_name

func _on_gun_state_transition(new_state_name: String):
	$FireStateLabel.text = new_state_name
	
func add_bullet_attributes(bullet: Bullet, bullet_dir):
	bullet.damage = bullet_damage
	bullet.hit_owner = "boss"

	bullet.direction = bullet_dir
	bullet.speed = bullet_speed
	bullet.lifetime = bullet_lifetime
	bullet.global_position = tank_sprite_gun.global_position
