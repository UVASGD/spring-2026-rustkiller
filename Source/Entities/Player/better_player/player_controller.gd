class_name PlayerController
extends CharacterBody2D

@export var entity_name: String = "player"
@export var speed: float = 200.0
@export var hp: int = 3

var current_state: String = "idle"
var curr_weapon: String = "melee"
var last_move_dir: Vector2 = Vector2.RIGHT

signal parrying

@onready var sprite_manager: Node2D       = $SpriteManager
@onready var anim_player: AnimationPlayer = $PlayerAnimation
@onready var cursor: Node2D               = $Cursor

@onready var _movement: PlayerMovement = $PlayerMovement
@onready var _combat: PlayerCombat     = $PlayerCombat

func _ready() -> void:
	_combat.setup(self)
	_movement.setup(self)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	if Input.is_action_just_pressed("blitz"):
		_movement.try_blitz()

func _physics_process(delta: float) -> void:
	_handle_weapon_switch()

	match current_state:
		"parrying":
			velocity = Vector2.ZERO
			move_and_slide()
			return
		"attacking":
			_combat.process_attack(delta)
			move_and_slide()
			return

	_handle_movement_input(delta)
	move_and_slide()

func _handle_weapon_switch() -> void:
	if Input.is_action_just_pressed("switch_weapon"):
		cursor.set_weapon_mode(curr_weapon)
		curr_weapon = "shoot" if curr_weapon == "melee" else "melee"

func _handle_movement_input(delta: float) -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	if direction.length() > 0.0:
		last_move_dir = direction.normalized()

	_flip_sprite(direction)

	if Input.is_action_just_pressed("better_parry"):
		_combat.try_parry()
		return

	if Input.is_action_just_pressed("attack"):
		_combat.handle_attack_input()
		return

	velocity = _movement.compute_velocity(direction, delta)

	if direction.length() > 0.0:
		anim_player.play("shoot" if curr_weapon == "shoot" else "WalkLeft")
	else:
		anim_player.play("idle")

func _flip_sprite(direction: Vector2) -> void:
	var facing := direction if direction.length() > 0.0 else last_move_dir
	if facing.x < 0.0:
		sprite_manager.scale.x = 1
	elif facing.x > 0.0:
		sprite_manager.scale.x = -1

func set_state(new_state: String) -> void:
	current_state = new_state

func emit_parrying() -> void:
	emit_signal("parrying")
