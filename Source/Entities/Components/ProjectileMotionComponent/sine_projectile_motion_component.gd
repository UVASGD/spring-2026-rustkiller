extends ProjectileMotionComponent

var perp_direction: Vector2
var sine_amplitude: float = 400.0
var sine_frequency: float = 10.0
var phase_offset: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	perp_direction = Vector2(-direction.y, direction.x)

func configure_pattern(new_phase_offset: float, amplitude_scale: float = 1.0, frequency_scale: float = 1.0, speed_scale: float = 1.0) -> void:
	phase_offset = new_phase_offset
	sine_amplitude *= amplitude_scale
	sine_frequency *= frequency_scale
	speed *= speed_scale


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if perp_direction == Vector2.ZERO:
		perp_direction = Vector2(-direction.y, direction.x)

	var sine_offset := sin(_lifetime_timer * sine_frequency + phase_offset) * sine_amplitude
	var parent: Node = get_parent()
	if parent is RigidBody2D:
		parent.linear_velocity = direction * speed + perp_direction * sine_offset
	else:
		parent.global_position += (direction * speed + perp_direction * sine_offset) * delta

	_lifetime_timer += delta
	if lifetime > 0 and _lifetime_timer >= lifetime:
		get_parent().queue_free()
	
