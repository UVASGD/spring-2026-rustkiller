extends Node2D
class_name GameContainer
#
@onready var main_menu_scene = preload("res://Source/Menus/main_menu.tscn")
#@onready var map_select_menu_scene = preload("res://Source/Menus/map_select_menu.tscn")
@onready var tutorial_scene = preload("res://Source/Levels/tutorial/tutorial.tscn")
#@onready var credits = preload("res://Source/Menus/Credits.tscn")
@onready var select_map = preload("res://Source/Menus/select_boss.tscn")
@onready var audio_player:AudioStreamPlayer = $AudioStreamPlayer

var is_audio_playing: bool = false

@onready var levels = {
	"furnace_comic": preload("res://Source/Levels/FurnaceComic.tscn"),
	"furnace_level": preload("res://Source/Levels/furnace/furnace_level.tscn"),
	"shadow_level": preload("res://Source/Levels/shadow_level/shadow_level.tscn")
}
#
func _ready():
	spawn_main_menu()
	#$AudioStreamPlayer.playing = true
	
func spawn_main_menu():
	if not is_audio_playing:
		play_audio()
	#$AudioStreamPlayer.playing = true
	var main_menu_inst = main_menu_scene.instantiate()
	add_child(main_menu_inst)
	
func spawn_map_select():
	if not is_audio_playing:
		play_audio()
	var map_sel_inst = select_map.instantiate()
	add_child(map_sel_inst)
	
func play_audio():
	audio_player.play()
	is_audio_playing = true
#
func spawn_level(name : String):
	var level_inst = levels.get(name).instantiate()
	#level_inst.global_position = Vector3(0,0,0)
	audio_player.stop()
	is_audio_playing = false
	add_child(level_inst)

func return_to_boss_select(from_node: Node = null) -> void:
	var active_child := _find_direct_child_for_node(from_node)
	if active_child:
		active_child.queue_free()

	call_deferred("spawn_map_select")

func _find_direct_child_for_node(node: Node) -> Node:
	var current := node
	while current:
		if current.get_parent() == self:
			return current
		current = current.get_parent()
	return null
#
#func spawn_tutorial():
	#var tutorial_inst = tutorial_scene.instantiate()
	#add_child(tutorial_inst)
	#
#func spawn_credits():
	#var credits_inst = credits.instantiate()
	#add_child(credits_inst)


func _on_audio_stream_player_finished():
	audio_player.play()
