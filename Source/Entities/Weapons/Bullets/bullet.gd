extends Node2D
class_name Bullet

@onready var hitbox: HitboxComponent = $HitboxComponent
var _has_hit: bool = false


func _process(_delta: float) -> void:
	pass

func _ready() -> void:
	hitbox.area_entered.connect(_on_hitbox_area_entered)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		var hurtbox = area as HurtboxComponent
		if hurtbox.can_accept_bullet_collision() and hurtbox.entity_name != hitbox.hit_owner:
			_has_hit = true
			
			# Spawn impact effect if available
			if hurtbox.bullet_impact_scene:
				var impact = hurtbox.bullet_impact_scene.instantiate()
				impact.global_position = global_position
				get_tree().current_scene.add_child(impact)
			
			queue_free()
