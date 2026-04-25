extends Area2D

@onready var light: PointLight2D = $PointLight2D

func _ready() -> void:
	# draw a circle using a polygon
	var polygon := Polygon2D.new()
	var points := PackedVector2Array()
	var radius := 30.0
	var segments := 32
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	polygon.polygon = points
	polygon.color = Color(1.0, 0.9, 0.2, 0.5)
	add_child(polygon)

func _process(_delta: float) -> void:
	light.energy = 2.0 + sin(Time.get_ticks_msec() * 0.005) * 0.6
