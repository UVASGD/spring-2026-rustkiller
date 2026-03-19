extends Node2D

@export var lunge_distance: float = 80.0
@export var lunge_duration: float = 0.12
@export var projectile_speed:float = 500.0

@export var BURST_COUNT    := 3
@export var BURST_INTERVAL := 0.08
@export var  WRENCH_PROJECTILE := preload("res://Source/Entities/Projectiles/Wrench/wrench_projectile.tscn")

var a2_available: bool = false
var combo_window: bool = false
var is_shooting: bool = false

var is_melee_hitbox_active: bool = false
var has_melee_hit: bool = false

var lunge_dir: Vector2 = Vector2.ZERO
var lunge_time_left: float = 0.0
var attack_dir: Vector2 = Vector2.ZERO
