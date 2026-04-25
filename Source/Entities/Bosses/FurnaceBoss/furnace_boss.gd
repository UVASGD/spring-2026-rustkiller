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
@onready var health_component = $HealthComponent as HealthComponent

var invulnerable := false
var phase_2_entered := false

func _ready():
	state_machine.player = player
	state_machine.character = self
	state_machine.animator = animation_player
	state_machine._accept_export_fields()
	state_machine._on_enter()
	animation_player.speed_scale = 1.0

func _physics_process(delta):
	state_machine._update(delta)

func is_invulnerable() -> bool:
	return invulnerable

func set_invulnerable(value: bool) -> void:
	invulnerable = value

func is_phase_2() -> bool:
	return phase_2_entered

func should_enter_phase_2() -> bool:
	return not phase_2_entered and health_component != null and health_component.health <= 0.0

func begin_phase_2() -> void:
	phase_2_entered = true
	velocity = Vector2.ZERO
	set_invulnerable(true)
	if health_component:
		health_component.health = health_component.max_health

func complete_phase_2_transition() -> void:
	velocity = Vector2.ZERO
	set_invulnerable(false)

func fire_sine_projectile(projectile_rows: int = 1, row_spacing: float = 28.0) -> void:
	if player == null:
		return

	var direction_to_player: Vector2 = (player.global_position - projectile_origin.global_position).normalized()
	if direction_to_player == Vector2.ZERO:
		direction_to_player = Vector2.DOWN

	var row_count := maxi(projectile_rows, 1)
	var perpendicular := Vector2(-direction_to_player.y, direction_to_player.x)
	var center_offset := float(row_count - 1) * 0.5

	for row_index in row_count:
		var projectile := SINE_PROJECTILE_SCENE.instantiate()
		var row_offset := perpendicular * ((float(row_index) - center_offset) * row_spacing)
		var row_factor := (float(row_index) - center_offset) / maxf(center_offset, 1.0)

		HitboxComponent.get_child_component(projectile).init(bullet_damage, "boss")
		var motion_component := ProjectileMotionComponent.get_child_component(projectile)
		motion_component.shoot(
			projectile_origin.global_position + row_offset,
			direction_to_player,
			bullet_speed,
			bullet_lifetime
		)
		if motion_component.has_method("configure_pattern"):
			var phase_offset := row_factor * 0.8 + randf_range(-0.2, 0.2)
			var amplitude_scale := randf_range(0.88, 1.12)
			var frequency_scale := randf_range(0.92, 1.08)
			var speed_scale := randf_range(0.96, 1.04)
			motion_component.configure_pattern(phase_offset, amplitude_scale, frequency_scale, speed_scale)

		get_tree().current_scene.add_child(projectile)

func parry_charge_attack() -> bool:
	var active_state := state_machine.get_lowest_active_state()
	if active_state and active_state.has_method("parry_cancel"):
		active_state.parry_cancel()
		return true
	return false
