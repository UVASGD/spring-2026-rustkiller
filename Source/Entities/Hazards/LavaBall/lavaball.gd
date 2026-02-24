extends Node
class_name LavaBall

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: Sprite2D = $Sprite2D
var time_elapsed: float = 0
@export var time_activate: int = 1
var activated: bool = false
@export var time_despawn: int = 3


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_elapsed += delta
	if not activated and time_elapsed >= time_activate:
		activate()
	if time_elapsed >= time_despawn:
		queue_free()
	
func activate():
	hitbox.monitorable = true
	hitbox.monitoring = true
	activated = true
	sprite.frame += 1
