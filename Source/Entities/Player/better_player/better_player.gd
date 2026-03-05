extends CharacterBody2D

var current_state: String = "idle"
@export var SPEED: float = 200.0
@export var PROJECTILE_SPEED: float = 500.0

@export var entity_name: String = "player"

@export var LUNGE_DISTANCE: float = 80.0
@export var LUNGE_DURATION: float = 0.12
@export var knockback_decay := 800.0

var lunge_dir: Vector2 = Vector2.ZERO
var lunge_time_left: float = 0.0

const BURST_COUNT := 3
const BURST_INTERVAL := 0.08

var curr_weapon: String = "melee"

var is_attacking: bool = false
var is_shooting: bool = false
var is_parrying: bool = false     

var is_melee_hitbox_active: bool = false
var has_melee_hit: bool = false

var attack_direction: Vector2 = Vector2.ZERO
var last_move_dir: Vector2 = Vector2.RIGHT
var knockback: Vector2 = Vector2.ZERO
var can_dash: bool = true


const WRENCH_PROJECTILE := preload("res://Source/Entities/Projectiles/Wrench/wrench_projectile.tscn")

@onready var sprite_manager: Node2D = $SpriteManager
@onready var anim: AnimationPlayer = $PlayerAnimation
@onready var muzzle: Node2D = $SpriteManager/Muzzle
@onready var hitbox_component: Area2D = $SpriteManager/HitboxComponent
@onready var parry_window: Area2D = $SpriteManager/ParryWindow     
@export var dash_distance: float = 100.0  # how far to teleport
@export var dash_cooldown: float = 0.5   # seconds between dashes

signal parrying

func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)

	hitbox_component.hit_owner = entity_name
	hitbox_component.area_entered.connect(_on_hitbox_area_entered)

	parry_window.monitoring = true
	parry_window.monitorable = true

func apply_knockback(force: Vector2):
	knockback = force*5
	while knockback.length() > 0:
		knockback = knockback.move_toward(Vector2.ZERO, knockback_decay * get_process_delta_time())
		await get_tree().process_frame

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_weapon"):
		if curr_weapon == "melee":
			curr_weapon = "shoot"
		else:
			curr_weapon = "melee"

	if Input.is_action_just_pressed("better_parry"):
		try_parry()

	if is_parrying:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_attacking:
		if lunge_time_left > 0.0:
			var lunge_speed := LUNGE_DISTANCE / LUNGE_DURATION
			velocity = lunge_dir * lunge_speed
			lunge_time_left -= delta
		else:
			velocity = Vector2.ZERO

		move_and_slide()
		return

	var direction := Input.get_vector("left", "right", "up", "down")

	if direction.length() > 0.0:
		last_move_dir = direction.normalized()

	var mouse_dir := (get_global_mouse_position() - global_position).normalized()
	if mouse_dir == Vector2.ZERO:
		mouse_dir = last_move_dir

	if curr_weapon == "shoot":
		attack_direction = mouse_dir          
	else:
		attack_direction = last_move_dir        

	if direction.length() > 0.0:
		if direction.x < 0.0:
			sprite_manager.scale.x = 1
		elif direction.x > 0.0:
			sprite_manager.scale.x = -1
	else:
		if last_move_dir.x < 0.0:
			sprite_manager.scale.x = 1
		elif last_move_dir.x > 0.0:
			sprite_manager.scale.x = -1

	if Input.is_action_just_pressed("attack"):
		if curr_weapon == "melee":
			start_attack()
			velocity = Vector2.ZERO
			move_and_slide()
			return
		elif curr_weapon == "shoot" and not is_shooting:
			fire_burst()

	velocity = direction * SPEED + knockback*5
	
	if direction.length() > 0.0:
		if curr_weapon == "shoot":
			change_state("shooting")
		else:
			change_state("walking")
	else:
		change_state("idle")

	move_and_slide()

func _input(event):
	if Input.is_action_just_pressed("quit"): # Use "ui_cancel" if you chose the default
		get_tree().quit() # This will close the game

	if Input.is_action_just_pressed("blitz") and can_dash:
		blitz()

func blitz():
	# Teleport in the last move direction
	var dash_dir = Vector2.ZERO
	if last_move_dir.length() > 0:
		dash_dir = last_move_dir.normalized()
		sprite_manager.modulate = Color(1, 0, 1)  # RGB: purple
	else:
		dash_dir = last_move_dir  # fallback if no input
	global_position += dash_dir * dash_distance
	
	# Cooldown
	can_dash = false
	await get_tree().create_timer(dash_cooldown).timeout
	sprite_manager.modulate = Color(1, 1, 1)  # Reset to normal (white)
	can_dash = true

func change_state(new_state: String) -> void:
	if current_state == new_state:
		return

	current_state = new_state

	match current_state:
		"idle":
			anim.play("idle")
		"walking":
			anim.play("WalkLeft")
		"shooting":
			anim.play("shoot")
		"attack":
			anim.stop()
			anim.play("attack")
			anim.seek(0.0, true)
		"parry":
			anim.stop()
			anim.play("parry")
			anim.seek(0.0, true)


func start_attack() -> void:
	is_attacking = true

	lunge_dir = (get_global_mouse_position() - global_position).normalized()
	if lunge_dir == Vector2.ZERO:
		lunge_dir = last_move_dir

	lunge_time_left = LUNGE_DURATION

	if lunge_dir.x < 0.0:
		sprite_manager.scale.x = 1
	elif lunge_dir.x > 0.0:
		sprite_manager.scale.x = -1

	change_state("attack")



func try_parry() -> void:
	if is_attacking or is_parrying:
		return

	var overlappers := parry_window.get_overlapping_areas()

	for area in overlappers:
		if area is HitboxComponent:
			var hitbox := area as HitboxComponent

			if hitbox.hit_owner == "boss":
				var projectile := hitbox.get_parent()
				if projectile:
					projectile.queue_free()


				is_parrying = true
				change_state("parry")
				return
	



func fire_burst() -> void:
	is_shooting = true
	change_state("shooting")

	for i in BURST_COUNT:
		shoot_single()
		if i < BURST_COUNT - 1:
			await get_tree().create_timer(BURST_INTERVAL).timeout

	is_shooting = false


func shoot_single() -> void:
	var projectile := WRENCH_PROJECTILE.instantiate()

	var dir := (get_global_mouse_position() - muzzle.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = attack_direction

	projectile.rotation = dir.angle()
	ProjectileMotionComponent.get_child_component(projectile).shoot(
		muzzle.global_position,
		dir,
		PROJECTILE_SPEED,
		-1
	)
	HitboxComponent.get_child_component(projectile).init(1, "player")

	get_tree().current_scene.add_child(projectile)




func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		is_attacking = false
		has_melee_hit = false
		change_state("idle")
	elif anim_name == "parry":
		is_parrying = false
		change_state("idle")


func update_melee_active():
	is_melee_hitbox_active = !is_melee_hitbox_active


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		var hurtbox = area as HurtboxComponent

		if (
			hurtbox.can_accept_bullet_collision() and
			hurtbox.entity_name == "boss" and
			is_melee_hitbox_active and
			not has_melee_hit
		):
			has_melee_hit = true

			if hurtbox.bullet_impact_scene:
				var impact = hurtbox.bullet_impact_scene.instantiate()
				impact.global_position = global_position
				get_tree().current_scene.add_child(impact)
				
func hitstop(duration: float) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	emit_signal("parrying")
