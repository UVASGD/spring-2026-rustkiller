extends Node2D
class_name ProjectileMotionComponent


var direction: Vector2 = Vector2.DOWN
var speed: float = 800.0
var lifetime: float = 0.5
var _lifetime_timer: float = 0.0

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	# can be overriden, should be called by child classes if overridden
	get_parent().global_position += direction * speed * delta

	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		get_parent().queue_free()
		
func shoot(initial_loc: Vector2, new_direction: Vector2, new_speed: float, new_lifetime: float) -> void:
	get_parent().global_position = initial_loc
	direction = new_direction.normalized()
	speed = new_speed
	lifetime = new_lifetime
	
static func get_child_component(node: Node) -> ProjectileMotionComponent:
	for child in node.get_children():
		if child is ProjectileMotionComponent:
			return child as ProjectileMotionComponent
	return null		
