extends Node2D

@export var min_pitch_scale := 0.8
@export var max_pitch_scale := 1.0

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	enable_active()
	$AnimationPlayer.play("skull")
	audio_player.pitch_scale = randf_range(minf(min_pitch_scale, max_pitch_scale), maxf(min_pitch_scale, max_pitch_scale))
	audio_player.play()
	await audio_player.finished
	queue_free()
	

func disable_active() -> void:
	hitbox.damage_enabled = false

func enable_active():
	hitbox.damage_enabled = true

#func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	#queue_free()
