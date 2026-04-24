extends Node2D

@onready var hitbox: HitboxComponent = $HitboxComponent


func _ready() -> void:
	enable_active()
	$AnimationPlayer.play("skull")
	

func disable_active() -> void:
	hitbox.damage_enabled = false

func enable_active():
	hitbox.damage_enabled = true

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()
