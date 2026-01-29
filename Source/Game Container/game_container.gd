extends Node2D
class_name GameContainer
#
@onready var main_menu_scene = preload("res://Source/Menus/main_menu.tscn")
#@onready var map_select_menu_scene = preload("res://Source/Menus/map_select_menu.tscn")
#@onready var tutorial_scene = preload("res://Source/Menus/tutorial.tscn")
#@onready var credits = preload("res://Source/Menus/Credits.tscn")
#

@onready var levels = {
	"Parallax_showcase": preload("res://Source/Levels/test_level_parallax.tscn")
}
#
func _ready():
	spawn_main_menu()
	#$AudioStreamPlayer.playing = true
	
func spawn_main_menu():
	#$AudioStreamPlayer.playing = true
	var main_menu_inst = main_menu_scene.instantiate()
	add_child(main_menu_inst)
	
#func spawn_map_select_menu(is_versus:bool):
	#var map_select_menu_inst = map_select_menu_scene.instantiate()
	#map_select_menu_inst.is_versus = is_versus
	#add_child(map_select_menu_inst)
#
func spawn_level(name : String):
	var level_inst = levels.get(name).instantiate()
	#level_inst.global_position = Vector3(0,0,0)
	add_child(level_inst)
#
#func spawn_tutorial():
	#var tutorial_inst = tutorial_scene.instantiate()
	#add_child(tutorial_inst)
	#
#func spawn_credits():
	#var credits_inst = credits.instantiate()
	#add_child(credits_inst)
