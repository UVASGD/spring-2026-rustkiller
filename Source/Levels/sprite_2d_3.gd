extends Sprite2D

@export var fade_start_y: float = -100
@export var fade_end_y: float = 100
@export var min_alpha: float = 0.5  # never go below this

@export var player: CharacterBody2D

func _process(delta):
	if player == null:
		return

	var y = player.global_position.y
	var t = clamp((y - fade_start_y) / (fade_end_y - fade_start_y), 0.0, 1.0)
	var alpha = lerp(1.0, min_alpha, t)
	modulate.a = alpha
