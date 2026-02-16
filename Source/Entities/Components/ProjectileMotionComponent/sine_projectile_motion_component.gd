extends ProjectileMotionComponent

var perp_direction: Vector2
var sine_amplitude: float = 400.0
var sine_frequency: float = 10.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	perp_direction = Vector2(-direction.y, direction.x)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var parent: Node = get_parent()
	if parent is RigidBody2D:
		parent.linear_velocity = (direction * speed + 
			perp_direction * sin(_lifetime_timer * sine_frequency) * sine_amplitude)
	else:
		parent.global_position += (direction * speed + 
			perp_direction * sin(_lifetime_timer * sine_frequency) * sine_amplitude) * delta

	_lifetime_timer += delta
	if lifetime > 0 and _lifetime_timer >= lifetime:
		get_parent().queue_free()
	
