extends Node
class_name LavaBoulder

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: AnimatedSprite2D = $GroundAOE
@onready var animPlayer: AnimationPlayer = $AnimationPlayer
var time_elapsed: float = 0
@export var time_animate: int = 1
var activated: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_elapsed += delta
	if not activated and time_elapsed >= time_animate:
		animPlayer.play("fall")
	
func activate():
	hitbox.monitorable = true
	hitbox.monitoring = true
	activated = true
	
func deactivate():
	hitbox.monitorable = false
	hitbox.monitoring = false
	activated = false

func _on_ground_aoe_animation_finished() -> void:
	if sprite.animation == "enter":
		sprite.play("loop")
