extends CharacterBody2D
class_name HFSMSteamBoss

@export var player: CharacterBody2D
@export var is_dormant := true  # Start dormant until player is detected or intro sequence finishes

@export_group("Movement")
@export var chase_speed := 220.0
@export var acceleration := 900.0

@export_group("Ranges")
@export var close_range := 80.0          # Slash / ExplosiveBurst
@export var steam_blast_range := 200.0   # Range in order to attempt a steam blast
@export var out_of_range := 320.0        # Lunge if player farther than this

@export_group("SteamBlast")
@export var steam_push_strength_p1 := 60.0
@export var steam_blast_cooldown_p1 := 15.0
@export var steam_blast_cooldown_p2 := 10.0
@export var steam_blast_cooldown_p3 := 7.0
@export var steam_push_multiplier_p2 := 1.15
@export var steam_push_multiplier_p3 := 1.3

@export_group("Lunge")
@export var lunge_speed := 650.0
@export var lunge_time := 0.35

@export_group("Warp Burst (Phase 3)")
@export var warp_burst_cooldown := 10.0
@export var warp_reappear_distance := 80.0
@export var warp_burst_pre_delay := 0.25

@export_group("Phase")
@export var max_health := 100
@export var phase2_health_threshold := 0.5 # enter p2 at <= 50%
@export var phase3_health_threshold := 0.15 # enter p3 at <= 15%

@onready var state_machine := $SteamBossHFSM as HFSM
@onready var animator := $AnimationPlayer as AnimationPlayer
@onready var lunge_hitbox := $LungeHitbox as Area2D

var _cooldowns := {} # String -> next-ready ms timestamp
var health := 100
var phase := 1
var _steam_burst_cd := 8.0
var _steam_burst_charges := 1

func _ready():
	health = max_health
	state_machine.player = player
	state_machine.character = self
	state_machine.animator = animator
	state_machine._accept_export_fields()
	state_machine._on_enter()

func _physics_process(delta: float) -> void:
	state_machine._update(delta)

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	_check_phase_transition()

func _check_phase_transition() -> void:
	if phase == 1 and float(health) <= float(max_health) * phase2_health_threshold:
		_enter_phase_2()
	elif phase == 2 and float(health) <= float(max_health) * phase3_health_threshold:
		_enter_phase_3()

func _enter_phase_2() -> void:
	phase = 2
	_steam_burst_charges = 2
	_steam_burst_cd = 5.0
	# Optional phase transition anim if it exists
	if animator and animator.has_animation("phase_1_to_2"):
		animator.play("phase_1_to_2")
func _enter_phase_3() -> void:
	phase = 3
	_steam_burst_charges = 3
	_steam_burst_cd = 3.0
	
	# Optional phase transition anim if it exists
	if animator and animator.has_animation("phase_2_to_3"):
		animator.play("phase_2_to_3")

func get_push_strength() -> float:
	if phase == 1:
		return steam_push_strength_p1
	elif phase == 2:
		return steam_push_strength_p1 * steam_push_multiplier_p2
	else:
		return steam_push_strength_p1 * steam_push_multiplier_p3

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
			_deal_damage_to_player(15)

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
	elif phase == 2:
		cd = steam_blast_cooldown_p2
	else:
		cd = steam_blast_cooldown_p3
	
	set_cd("steam_blast", cd)



func do_explosive_burst() -> void:
	# AoE circle around the boss
	var burst_radius := close_range * 1.5
	var burst_damage := 25

	# Check if player is in range
	if player and dist_to_player() <= burst_radius:
		var knockback_dir := (player.global_position - global_position).normalized()
		player.velocity += knockback_dir * get_push_strength() * 1.2
		_deal_damage_to_player(burst_damage)

	# VFX: expanding ring
	var particles := GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 48
	particles.lifetime = 0.6

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0  # full circle
	mat.initial_velocity_min = 200.0
	mat.initial_velocity_max = 350.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 3.0
	mat.scale_max = 6.0
	mat.color = Color(1.0, 0.5, 0.2, 0.9)
	particles.process_material = mat

	add_child(particles)
	get_tree().create_timer(1.2).timeout.connect(particles.queue_free)

	# Screen shake (if you have a camera with a shake method)
	_try_screen_shake(8.0, 0.3)

	set_cd("explosive_burst", 5.0)


func do_slash() -> void:
	# Melee hit in front of the boss
	var slash_range := close_range
	var slash_half_angle := deg_to_rad(45.0)  # 90° total angle
	var slash_damage := 20

	# Check if player is in range and in front of the boss
	if player and dist_to_player() <= slash_range:
		var angle_to_player := dir_to_player().angle()
		if abs(angle_to_player) <= slash_half_angle:
			player.velocity += dir_to_player() * get_push_strength() * 0.8
			_deal_damage_to_player(slash_damage)

	# VFX: radial slash effect
	var particles := GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 32
	particles.lifetime = 0.4

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0  # full circle
	mat.initial_velocity_min = 150.0
	mat.initial_velocity_max = 300.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = Color(1.0, 0.2, 0.2, 0.8)
	particles.process_material = mat

	add_child(particles)
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

	set_cd("slash", 1.5)


func do_lunge_thrust() -> void:
	# Enable the thrust hitbox at the peak of the lunge
	if not lunge_hitbox:
		push_warning("SteamBoss: LungeHitbox node not found")
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
			_deal_damage_to_player(lunge_damage)

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

	_try_screen_shake(5.0, 0.2)

	# Disable the hitbox after a short window, then start cooldown
	get_tree().create_timer(0.15).timeout.connect(_disable_lunge_hitbox)
	set_cd("lunge", 4.0)


func _disable_lunge_hitbox() -> void:
	if lunge_hitbox:
		var shape := lunge_hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape:
			shape.disabled = true

#TODO: implement grate bursts as a separate node that calls back to the boss, instead of boss directly controlling them. This is more modular and allows for more complex patterns (e.g. staggered bursts instead of all at once).
func spawn_grate_steam_bursts() -> void:
	# Phase 1: once, default cd
	# Phase 2: twice, 5s cd
	var bursts_to_fire := _steam_burst_charges

	var grates := get_tree().get_nodes_in_group("steam_grates")
	for _i in range(bursts_to_fire):
		for grate in grates:
			if grate.has_method("burst"):
				grate.burst()

	set_cd("steam_bursts", _steam_burst_cd)

func burst() -> void:
	# This is a public method you can call on the boss to trigger a burst effect,
	# e.g. from a SteamGrate node or as part of a state machine sequence.
	do_explosive_burst()

# ---------- internal helpers ----------

func _deal_damage_to_player(amount: int) -> void:
	if not player:
		return
	# Option 1: If your player has a take_damage() method
	if player.has_method("take_damage"):
		player.take_damage(amount)
		return
	# Option 2: If your player uses a Health component
	if player.has_method("get_node"):
		var health = player.get_node_or_null("Health")
		if health and health.has_method("take_damage"):
			health.take_damage(amount)
			return
	push_warning("SteamBoss: player has no take_damage method or Health node")

func _try_screen_shake(intensity: float, duration: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(intensity, duration)

func can_use_warp_burst() -> bool:
	# Phase 3 only, off cooldown, and player NOT in explosive burst range
	if phase < 3:
		return false
	if not cd_ready("warp_burst"):
		return false
	if not player:
		return false
	var burst_radius := close_range * 1.5
	return dist_to_player() > burst_radius

func do_warp_burst() -> void:
	if not can_use_warp_burst():
		return

	# Start cooldown immediately so it can't be retriggered during sequence
	set_cd("warp_burst", warp_burst_cooldown)

	# Optional "armor drop / disappear" animation
	if animator and animator.has_animation("warp_burst_start"):
		animator.play("warp_burst_start")

	# Disable hitbox while disappearing
	_disable_lunge_hitbox()

	# Short delay before teleport
	await get_tree().create_timer(warp_burst_pre_delay).timeout

	if not player:
		return

	# Reappear behind player (opposite player's facing/movement direction fallback)
	var behind_dir := Vector2.LEFT
	if "velocity" in player and (player.velocity as Vector2).length() > 1.0:
		behind_dir = -(player.velocity as Vector2).normalized()
	else:
		# fallback: opposite of boss->player vector
		behind_dir = -global_position.direction_to(player.global_position)

	global_position = player.global_position + behind_dir * warp_reappear_distance

	# Face player after reappearing
	var face_dir := dir_to_player()
	if lunge_hitbox:
		lunge_hitbox.rotation = face_dir.angle()

	# Optional reappear animation
	if animator and animator.has_animation("warp_burst_reappear"):
		animator.play("warp_burst_reappear")

	# Small timing window, then burst
	await get_tree().create_timer(0.12).timeout
	do_explosive_burst()

func wake_up() -> void:
	is_dormant = false

func set_dormant(value: bool) -> void:
	is_dormant = value
	if is_dormant:
		stop_motion()
