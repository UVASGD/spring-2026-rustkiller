class_name LockOnComponent
extends Node2D

var is_locked_on: bool = false
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	deactivate()
	

func activate() -> void:
	is_locked_on = true
	$LockonSymbol.visible = true
	animation_player.play("lockonsymbol")
	
func deactivate() -> void:
	is_locked_on = false
	$LockonSymbol.visible = false
	animation_player.stop()
