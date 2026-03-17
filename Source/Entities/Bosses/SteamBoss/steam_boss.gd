extends CharacterBody2D
class_name SteamBoss

@export var player : CharacterBody2D

@export_group("Movement")
@export var chase_speed := 250.0
@export var acceleration := 1.0

@export_group("Firing")
#@export var burst_bullet_count := 5
#@export var burst_spread_angle := 15.0
#@export var radial_bullet_count := 12
#@export var bullet_speed := 400.0
#@export var bullet_damage := 20.0
#@export var bullet_lifetime := 3.0
#@export var pellet_scene: PackedScene

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
