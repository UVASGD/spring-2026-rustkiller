extends Node
class_name LavaBoulder

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: Sprite2D = $GroundAOE
@onready var animPlayer: AnimationPlayer = $AnimationPlayer
var time_elapsed: float = 0
@export var time_animate: int = 1
var activated: bool = false
@export var time_despawn: int = 3


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_elapsed += delta
	if not activated and time_elapsed >= time_animate:
		animPlayer.play("fall")
	if time_elapsed >= time_despawn:
		queue_free()
	
func activate():
	hitbox.monitorable = true
	hitbox.monitoring = true
	activated = true
	sprite.frame += 1
