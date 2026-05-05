@tool
class_name HitboxComponent
extends Area2D

@export var damage: float
@export var hit_owner: String
@export var knockback_strength: float = 400.0
@export var damage_enabled: bool = true
@export var manual_damage_application: bool = false
var velocity: Vector2 = Vector2.ZERO


static func get_child_component(node: Node) -> HitboxComponent:
	for child in node.get_children():
		if child is HitboxComponent:
			return child as HitboxComponent
	return null

func init(new_damage: float, new_hit_owner: String) -> void:
	damage = new_damage
	hit_owner = new_hit_owner
	damage_enabled = true

func _on_body_entered(body: Node2D) -> void:
		if not damage_enabled or damage <= 0.0:
			return
		if body.has_method("apply_knockback"):
			var direction = (body.global_position - global_position).normalized()	
			body.apply_knockback(direction * knockback_strength)
