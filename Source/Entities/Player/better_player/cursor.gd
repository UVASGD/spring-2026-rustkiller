extends Node2D

@export var orbit_radius: float = 40.0
@export var dot_radius: float = 6.0
@export var dot_color: Color = Color(1, 1, 1, 0.9)

var _dot_pos: Vector2 = Vector2.ZERO
var _player: Node2D

func _ready() -> void:
	_player = get_parent()

func _process(_delta: float) -> void:
	global_position = _player.global_position
	
	# Convert mouse to local space AFTER setting global_position
	var mouse_local := to_local(get_global_mouse_position())
	var mouse_dir := mouse_local.normalized()
	_dot_pos = mouse_dir * orbit_radius
	queue_redraw()

func _draw() -> void:
	draw_circle(_dot_pos, dot_radius, dot_color)
	draw_circle(_dot_pos, dot_radius * 0.4, Color(0, 0, 0, 0.5))
	
func set_weapon_mode(weapon: String) -> void:
	if weapon == "shoot":
		dot_color = Color(1, 1, 1, 0.95)
	else:
		dot_color = Color(0.3, 0.8, 1.0, 0.95)
	queue_redraw()
