extends Node2D

@onready var audio_player:AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) 
	audio_player.play()
	


func _on_audio_stream_player_finished():
	audio_player.play()
