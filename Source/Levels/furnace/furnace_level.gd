extends Node2D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) 
	$AudioStreamPlayer.play()

func _on_audio_stream_player_finished():
	$AudioStreamPlayer.play()
