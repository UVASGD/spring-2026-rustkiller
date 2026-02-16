extends Node2D
class_name Bullet

@onready var hitbox: HitboxComponent = $HitboxComponent
@export var hit_owner:String
var _has_hit: bool = false
var damage: float


func _process(_delta: float) -> void:
	pass

func _ready() -> void:
	hitbox.damage = damage
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hitbox.hit_owner = hit_owner	

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		var hurtbox = area as HurtboxComponent
		
		if hurtbox.can_accept_bullet_collision() and hurtbox.entity_name != "boss":
			_has_hit = true
			
			# Spawn impact effect if available
			if hurtbox.bullet_impact_scene:
				var impact = hurtbox.bullet_impact_scene.instantiate()
				impact.global_position = global_position
				get_tree().current_scene.add_child(impact)
			
			queue_free()
