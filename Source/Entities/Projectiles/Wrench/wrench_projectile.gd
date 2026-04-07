extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var timer:Timer = $Timer
@onready var hitbox: HitboxComponent = $HitboxComponent
var velocity: Vector2 = Vector2.ZERO


func _ready():
	anim.play("wrench")
	timer.start()

func _physics_process(delta: float) -> void:
	pass


func _on_timer_timeout():
	queue_free()


func _on_hitbox_area_entered(area):
	if area is HurtboxComponent:
		var hurtbox = area as HurtboxComponent
		
		if hurtbox.can_accept_bullet_collision() and hurtbox.entity_name != hitbox.hit_owner:
			
			# Spawn impact effect if available
			if hurtbox.bullet_impact_scene:
				var impact = hurtbox.bullet_impact_scene.instantiate()
				impact.global_position = global_position
				get_tree().current_scene.add_child(impact)
			
			queue_free()
