extends CharacterBody2D
class_name FurnaceBoss

@export var player : CharacterBody2D

@export_group("Movement")
@export var chase_speed := 250.0
@export var acceleration := 1.0

@export_group("Firing")
@export var burst_bullet_count := 5
@export var burst_spread_angle := 15.0
@export var radial_bullet_count := 12
@export var bullet_speed := 400.0
@export var bullet_damage := 20.0
@export var bullet_lifetime := 3.0
@export var pellet_scene: PackedScene

@onready var state_machine = $FurnaceHFSM as HFSM
@onready var animation_player = $AnimationPlayer

func _ready():
	state_machine.player = player
	state_machine.character = self
	state_machine.animator = animation_player
	state_machine._accept_export_fields()
	state_machine._on_enter()
	animation_player.speed_scale = 0.1

func _physics_process(delta):
	state_machine._update(delta)

#func _on_gun_animation_finish(anim_name: String):
	#gun_animation_player.play("GunIdle")
#
#func _fire_burst():
	#if not pellet_scene or not player:
		#return
		#
	#var direction_to_player = (player.global_position - tank_sprite_gun.global_position).normalized()
	#var base_angle = direction_to_player.angle()
	#var spread_rad = deg_to_rad(burst_spread_angle)
	#
	#for i in burst_bullet_count:
		#var random_angle = randf_range(-spread_rad / 2.0, spread_rad / 2.0)
		#var bullet_direction = Vector2.from_angle(base_angle + random_angle)
		#
		#var bullet = pellet_scene.instantiate()
		#bullet.damage = bullet_damage
		#bullet.hit_owner = "boss"
		#bullet.direction = bullet_direction
		#bullet.speed = bullet_speed
		#bullet.lifetime = bullet_lifetime
		#bullet.global_position = tank_sprite_gun.global_position
		#
		#get_tree().current_scene.add_child(bullet)
#
#func _fire_radial():
	#if not pellet_scene or not player:
		#return
		#
	#var angle_step = TAU / radial_bullet_count 
	#
	#for i in radial_bullet_count:
		#var angle = angle_step * i
		#var bullet_direction = Vector2.from_angle(angle)
		#
		#var bullet = pellet_scene.instantiate()
		#bullet.damage = bullet_damage
		#bullet.hit_owner = "boss"
		#bullet.direction = bullet_direction
		#bullet.speed = bullet_speed
		#bullet.lifetime = bullet_lifetime
		#bullet.global_position = tank_sprite_gun.global_position
		#
		#get_tree().current_scene.add_child(bullet)
