extends Node2D
@onready var ComicSprite: Sprite2D = $FurnaceComicSpriteSheetTransparent
@onready var audioplayer: AudioStreamPlayer2D = $AudioStreamPlayer2D

var audio_paths = [
	"res://Source/Resources/Audio/SFX/Intro Comic FurnaceP1.wav",
	""
]

var frameNumber = 0
