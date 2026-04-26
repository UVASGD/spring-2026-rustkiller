#The boss or game manager will call to spawn the steam blasts 
#When created, after some amount of time, the blast will trigger, 
#and if the player is in the blast they take damage

extends Node2D

# assumed not to do damage on the design doc
# @export var damage : int
@export var animPlayer: AnimationPlayer
@export var knockback_strength: int = 100

func _ready() -> void:
	animPlayer.play("blow")

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("apply_knockback"):
		var direction = Vector2.UP
		body.apply_knockback(direction * knockback_strength)
