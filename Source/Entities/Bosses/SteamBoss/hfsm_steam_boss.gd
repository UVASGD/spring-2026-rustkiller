extends CharacterBody2D
class_name HFSMSteamBoss

@export var player: CharacterBody2D

@export_group("Movement")
@export var chase_speed := 220.0
@export var acceleration := 900.0

@export_group("Ranges")
@export var close_range := 80.0          # Slash / ExplosiveBurst
@export var steam_blast_range := 200.0   # Range in order to attempt a steam blast
@export var out_of_range := 320.0        # Lunge if player farther than this

@export_group("SteamBlast")
@export var steam_push_strength_p1 := 600.0
@export var steam_blast_cooldown_p1 := 7.0
@export var steam_blast_cooldown_p2 := 3.0
@export var steam_push_multiplier_p2 := 1.5

@export_group("SteamBursts")
@export var steamBurstHazard: PackedScene

@export_group("Lunge")
@export var lunge_speed := 650.0
@export var lunge_time := 0.35

@export_group("Phase")
@export var max_health := 500

@onready var state_machine := $SteamBossHFSM as HFSM
@onready var animator := $AnimationPlayer as AnimationPlayer
@onready var lunge_hitbox := $LungeHitbox as Area2D
@onready var health_component := $HealthComponent as HealthComponent
@onready var hurtbox_component := $HurtboxComponent as HurtboxComponent
@onready var healthbar := $Healthbar
@onready var visuals := $Visuals

var _cooldowns := {} # String -> next-ready ms timestamp
var phase := 1
@export var _steam_burst_cd := 13.0
var _steam_burst_charges := 3
var invulnerable := false

var defeat_sequence_started: bool = false
const DEFEAT_FADE_DURATION := 0.75
const RETURN_TO_BOSS_SELECT_DELAY := 5.0

func _ready():
	health_component.max_health = max_health
	health_component.health = max_health
	state_machine.player = player
	state_machine.character = self
	state_machine.animator = animator
	state_machine._accept_export_fields()
	state_machine._on_enter()

func _physics_process(delta: float) -> void:
	state_machine._update(delta)

# Returns true if we should transition from phase 1->2
func check_phase_transition() -> bool:
	if phase == 1 and health_component.health <= 0:
		_enter_phase_2()
		return true
	if phase == 2 and health_component.health <= 0:
		_start_defeat_sequence()
	return false

func _enter_phase_2() -> void:
	set_invulnerable(true)
	phase = 2
	health_component.health = max_health
	_steam_burst_charges = 5
	_steam_burst_cd = 10.0
	

func get_push_strength() -> float:
	if phase == 1:
		return steam_push_strength_p1
	else:
		return steam_push_strength_p1 * steam_push_multiplier_p2

# ---------- utilities used by states ----------
func now_ms() -> int:
	return Time.get_ticks_msec()

func cd_ready(key: String) -> bool:
	return now_ms() >= int(_cooldowns.get(key, 0))

func set_cd(key: String, seconds: float) -> void:
	_cooldowns[key] = now_ms() + int(seconds * 1000.0)

func dist_to_player() -> float:
	if not player: return INF
	return global_position.distance_to(player.global_position)

func dir_to_player() -> Vector2:
	if not player: return Vector2.ZERO
	return global_position.direction_to(player.global_position)

func stop_motion() -> void:
	velocity = Vector2.ZERO

func chase_step(delta: float) -> void:
	if not player: return
	var desired := dir_to_player() * chase_speed
	velocity = velocity.move_toward(desired, acceleration * delta)
	move_and_slide()

func do_lunge_step(_delta: float, dir: Vector2) -> void:
	velocity = dir * lunge_speed
	move_and_slide()

# ----- attack hooks -----

# This attack will almost always connect because it only triggers if the player is in range.
# That's fine just keep that in mind.
func do_steam_blast_cone() -> void:
	if not player:
		return

	var push_dir := (player.global_position - global_position).normalized()
	var cone_half_angle := deg_to_rad(35.0)  # 70° total cone
	var cone_range := steam_blast_range

	
	# Damage + push anything in the cone (just the player for now)
	var to_player := (player.global_position - global_position)
	if to_player.length() <= cone_range:
		var angle_to_player := push_dir.angle_to(to_player.normalized())
		if abs(angle_to_player) <= cone_half_angle:
			player.apply_knockback(push_dir * get_push_strength())

	# VFX: spawn particles
	var particles := GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 24
	particles.lifetime = 0.5
	particles.position = Vector2.ZERO
	particles.rotation = push_dir.angle()

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 35.0
	mat.initial_velocity_min = 300.0
	mat.initial_velocity_max = 500.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 2.0
	mat.scale_max = 4.0
	mat.color = Color(0.85, 0.85, 0.85, 0.7)
	particles.process_material = mat

	add_child(particles)
	# Auto-free after particles finish
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

	var cd := 0.0
	if phase == 1:
		cd = steam_blast_cooldown_p1
	else:
		cd = steam_blast_cooldown_p2
	
	set_cd("steam_blast", cd)

### This code has never worked. Will keep for inspiration once lunge animation is ready 

func do_lunge_thrust() -> void:
	# Enable the thrust hitbox at the peak of the lunge
	if not lunge_hitbox:
		print("SteamBoss: LungeHitbox node not found")
		return

	var lunge_damage := 30

	# Point the hitbox toward the player
	lunge_hitbox.rotation = dir_to_player().angle()

	# Enable the collision shape
	var shape := lunge_hitbox.get_node("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.disabled = false

	# Check for overlapping bodies right now
	for body in lunge_hitbox.get_overlapping_bodies():
		if body == player:
			var knockback_dir := dir_to_player()
			player.velocity += knockback_dir * lunge_speed * 0.6

	# VFX: impact burst
	var particles := GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.35

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 250.0
	mat.initial_velocity_max = 400.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 2.0
	mat.scale_max = 4.0
	mat.color = Color(1.0, 0.6, 0.1, 0.85)
	particles.process_material = mat
	particles.rotation = dir_to_player().angle()

	add_child(particles)
	get_tree().create_timer(0.8).timeout.connect(particles.queue_free)

	# Disable the hitbox after a short window, then start cooldown
	get_tree().create_timer(0.15).timeout.connect(_disable_lunge_hitbox)
	set_cd("lunge", 4.0)


func _disable_lunge_hitbox() -> void:
	if lunge_hitbox:
		var shape := lunge_hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape:
			shape.disabled = true
			
### end			
			
func spawn_grate_steam_bursts() -> void:
	# Phase 1: three times, default cd
	# Phase 2: five times, 5s cd
	var bursts_to_fire := _steam_burst_charges
	
	for _i in range(bursts_to_fire):
		var burst_instance = steamBurstHazard.instantiate() as Node2D
		
		if _i == 0:
		# First burst is directly on the player
			burst_instance.global_position = player.global_position
		else:
			var random_dir = Vector2.UP.rotated(randf() * TAU)
			var distance = 200.0
			burst_instance.global_position = player.global_position + (random_dir * distance)
		
		get_parent().add_child(burst_instance)

	set_cd("steam_bursts", _steam_burst_cd)

# ---------- internal helpers ----------

func set_invulnerable(value: bool) -> void:
	invulnerable = value

func is_invulnerable() -> bool:
	return invulnerable
	
func _start_defeat_sequence() -> void:
	if defeat_sequence_started:
		return

	defeat_sequence_started = true
	velocity = Vector2.ZERO
	set_invulnerable(true)
	set_physics_process(false)
	if animator:
		animator.stop()
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", false)
		hurtbox_component.set_deferred("monitorable", false)
	if healthbar:
		healthbar.visible = false

	var fade_tween := create_tween()
	if visuals:
		fade_tween.tween_property(visuals, "modulate", Color(1.0, 1.0, 1.0, 0.0), DEFEAT_FADE_DURATION)
	await fade_tween.finished
	await get_tree().create_timer(RETURN_TO_BOSS_SELECT_DELAY, true, false, true).timeout

	var game_container := _find_game_container()
	if game_container:
		game_container.call_deferred("return_to_boss_select", self)

func _find_game_container() -> GameContainer:
	var current: Node = get_parent()
	while current:
		if current is GameContainer:
			return current as GameContainer
		current = current.get_parent()
	return null		
