class_name LockOnComponent
extends Node2D

var is_locked_on: bool = false

func _ready() -> void:
	deactivate()
	

func activate() -> void:
	is_locked_on = true

	
func deactivate() -> void:
	is_locked_on = false
