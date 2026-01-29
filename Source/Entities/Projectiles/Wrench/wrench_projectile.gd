extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var timer:Timer = $Timer
@export var bullet_owner:String = "player"
var velocity: Vector2 = Vector2.ZERO


func _ready():
	anim.play("wrench")
	timer.start()
	# on the projectile root
	$HitboxComponent.hit_owner = bullet_owner

func _physics_process(delta: float) -> void:
	position += velocity * delta






func _on_timer_timeout():
	queue_free()




func _on_hitbox_component_area_entered(area):
	if area is HurtboxComponent:
		var hurtbox = area as HurtboxComponent
		
		if hurtbox.can_accept_bullet_collision():
			
			# Spawn impact effect if available
			if hurtbox.bullet_impact_scene:
				var impact = hurtbox.bullet_impact_scene.instantiate()
				impact.global_position = global_position
				get_tree().current_scene.add_child(impact)
			
			queue_free()
