extends CharacterBody2D
class_name FurnaceBoss

const SINE_PROJECTILE_SCENE := preload("res://Source/Entities/Projectiles/SineProjectile/SineProjectile.tscn")

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
@onready var projectile_origin = $Visuals/projectile_origin

func _ready():
	state_machine.player = player
	state_machine.character = self
	state_machine.animator = animation_player
	state_machine._accept_export_fields()
	state_machine._on_enter()
	animation_player.speed_scale = 1.0

func _physics_process(delta):
	state_machine._update(delta)

func fire_sine_projectile() -> void:
	if player == null:
		return

	var projectile := SINE_PROJECTILE_SCENE.instantiate()
	var direction_to_player: Vector2 = (player.global_position - projectile_origin.global_position).normalized()
	if direction_to_player == Vector2.ZERO:
		direction_to_player = Vector2.DOWN

	HitboxComponent.get_child_component(projectile).init(bullet_damage, "boss")
	ProjectileMotionComponent.get_child_component(projectile).shoot(
		projectile_origin.global_position,
		direction_to_player,
		bullet_speed,
		bullet_lifetime
	)

	get_tree().current_scene.add_child(projectile)

func parry_charge_attack() -> bool:
	var active_state := state_machine.get_lowest_active_state()
	if active_state and active_state.has_method("parry_cancel"):
		active_state.parry_cancel()
		return true
	return false

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
