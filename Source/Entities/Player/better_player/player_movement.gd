class_name PlayerMovement
extends Node

@export var dash_distance: float  = 100.0
@export var dash_cooldown: float  = 0.5
@export var knockback_decay: float = 800.0
@export var _player: CharacterBody2D


var knockback: Vector2 = Vector2.ZERO
var can_dash: bool = true

var blitz_multiplier: float = 1.0
var is_blitzing: bool = false


func setup(player: CharacterBody2D) -> void:
	_player = player

func compute_velocity(direction: Vector2, delta: float) -> Vector2:
	_decay_knockback(delta)

	var speed_multiplier = _player.speed * blitz_multiplier
	return direction * speed_multiplier + knockback
	
func try_blitz() -> void:
	if not can_dash:
		return
	_perform_blitz()

func _decay_knockback(delta: float) -> void:
	if knockback == Vector2.ZERO:
		return
	knockback = knockback.move_toward(Vector2.ZERO, knockback_decay * delta)

func _perform_blitz() -> void:
	#instant dash
	#var dash_dir: Vector2 = _player.last_move_dir.normalized() if _player.last_move_dir.length() > 0 else Vector2.ZERO
	#_player.global_position += dash_dir * dash_distance
	#_player.sprite_manager.modulate = Color(1, 0, 1)

	#can_dash = false
	#await _player.get_tree().create_timer(dash_cooldown).timeout

	#_player.sprite_manager.modulate = Color(1, 1, 1)
	#can_dash = true
	
	
	#quick dash forward but cant phase through things
	var dash_dir: Vector2 = _player.last_move_dir.normalized()
	if dash_dir == Vector2.ZERO:
		return

	if not can_dash:
		return

	can_dash = false
	is_blitzing = true

	blitz_multiplier = 6.0  # adjust feel (4–10 typical)
	_player.sprite_manager.modulate = Color(1, 0, 1)

	await _player.get_tree().create_timer(0.12).timeout

	blitz_multiplier = 1.0
	is_blitzing = false

	_player.sprite_manager.modulate = Color(1, 1, 1)

	await _player.get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
