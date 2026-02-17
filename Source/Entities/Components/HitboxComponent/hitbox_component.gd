@tool
class_name HitboxComponent
extends Area2D

@export var damage: float
@export var hit_owner: String

static func get_child_component(node: Node) -> HitboxComponent:
	for child in node.get_children():
		if child is HitboxComponent:
			return child as HitboxComponent
	return null
	
func init(new_damage: float, new_hit_owner: String) -> void:
	damage = new_damage
	hit_owner = new_hit_owner
	
