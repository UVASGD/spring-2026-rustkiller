extends Node

const FALLING_EYE_AUDIO := preload("res://Source/Resources/Audio/SFX/ShadowBoss/machine/Falling Eye.wav")
const IDLE_EYE_AUDIO := preload("res://Source/Resources/Audio/SFX/ShadowBoss/machine/Idle Eye.mp3")

@onready var audio_player: AudioStreamPlayer2D = $"../AudioStreamPlayer2D"
@onready var idle_player: AudioStreamPlayer2D = $"../AudioStreamPlayer2D2"


func play_falling_eye() -> void:
	if audio_player == null:
		return

	audio_player.stream = FALLING_EYE_AUDIO
	audio_player.stop()
	audio_player.play()

func play_idle_eye() -> void:
	if idle_player == null:
		return

	idle_player.stream = IDLE_EYE_AUDIO
	idle_player.stop()
	idle_player.play()

func stop_machine_eye_audio() -> void:
	if audio_player == null:
		pass
	else:
		audio_player.stop()

	if idle_player == null:
		return

	idle_player.stop()
