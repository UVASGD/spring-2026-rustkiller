extends Node
class_name SfxManager

const SNAKE_ENCIRCLE := preload("res://Source/Resources/Audio/SFX/ShadowBoss/animal/Snake encircle.mp3")
const WOLF_INIT := preload("res://Source/Resources/Audio/SFX/ShadowBoss/animal/Wolf awaken.mp3")
const WOLF_ENCIRCLE := preload("res://Source/Resources/Audio/SFX/ShadowBoss/animal/Wolf Run.mp3")
const WOLF_ATTACK := preload("res://Source/Resources/Audio/SFX/ShadowBoss/animal/Wolf charge.mp3")

const REAPER_ARRIVAL_AUDIO := preload("res://Source/Resources/Audio/SFX/ShadowBoss/Reaper/Reaper Arrival.mp3")
const REAPER_SLASH_AUDIO := preload("res://Source/Resources/Audio/SFX/ShadowBoss/Reaper/Reaper Slash.mp3")
const REAPER_OUT := preload("res://Source/Resources/Audio/SFX/ShadowBoss/Reaper/Reaper out.mp3")
const REAPER_TRIPLE := preload("res://Source/Resources/Audio/SFX/ShadowBoss/Reaper/Reaper Trio.mp3")


const PLAYER_ARRIVAL_AUDIO := preload("res://Source/Resources/Audio/SFX/ShadowBoss/Player/Shadow Protag Arrival.mp3")
const PLAYER_ATTACK := preload("res://Source/Resources/Audio/SFX/ShadowBoss/Player/Dark swipe.mp3")

@onready var audio_player: AudioStreamPlayer2D = $"../AudioStreamPlayer2D"

func play_reaper_arrival_audio() -> void:
	if audio_player == null:
		return

	audio_player.pitch_scale = 1.0
	audio_player.stream = REAPER_ARRIVAL_AUDIO
	audio_player.stop()
	audio_player.play()

func play_player_arrival_audio() -> void:
	if audio_player == null:
		return

	audio_player.pitch_scale = 1.0
	audio_player.stream = PLAYER_ARRIVAL_AUDIO
	audio_player.stop()
	audio_player.play()

func play_player_attack() -> void:
	if audio_player == null:
		return

	audio_player.pitch_scale = 1.0
	audio_player.stream = PLAYER_ATTACK
	audio_player.stop()
	audio_player.play()

func play_snake_encircle() -> void:
	if audio_player == null:
		return

	audio_player.pitch_scale = 1.0
	audio_player.stream = SNAKE_ENCIRCLE
	audio_player.stop()
	audio_player.play()

func play_wolf_init() -> void:
	if audio_player == null:
		return

	audio_player.pitch_scale = 1.0
	audio_player.stream = WOLF_INIT
	audio_player.stop()
	audio_player.play()

func play_wolf_encircle() -> void:
	if audio_player == null:
		return

	audio_player.pitch_scale = 1.0
	audio_player.stream = WOLF_ENCIRCLE
	audio_player.stop()
	audio_player.play()

func play_wolf_attack() -> void:
	if audio_player == null:
		return

	audio_player.pitch_scale = 1.0
	audio_player.stream = WOLF_ATTACK
	audio_player.stop()
	audio_player.play()

func play_reaper_out():
	if audio_player == null:
		return

	audio_player.pitch_scale = 1.0
	audio_player.stream = REAPER_OUT
	audio_player.stop()
	audio_player.play()
	
func play_reaper_triple():
	if audio_player == null:
		return

	audio_player.pitch_scale = 1.0
	audio_player.stream = REAPER_TRIPLE
	audio_player.stop()
	audio_player.play()

func reaper_slash_audio() -> void:
	if audio_player == null:
		return

	audio_player.pitch_scale = 1.0
	audio_player.stream = REAPER_SLASH_AUDIO
	audio_player.stop()
	audio_player.play()

func reaper_proj_audio() -> void:
	if audio_player == null:
		return

	audio_player.pitch_scale = 0.8
	audio_player.stream = REAPER_SLASH_AUDIO
	audio_player.stop()
	audio_player.play()
	await audio_player.finished
	if audio_player:
		audio_player.pitch_scale = 1.0
