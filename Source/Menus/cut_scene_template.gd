extends Node2D

var cur_panel = 0

@onready var panels = [$CanvasLayer/Panel1, $CanvasLayer/Panel2, $CanvasLayer/Panel3, $CanvasLayer/Panel4]
@onready var canvaslayer = $CanvasLayer
@onready var player = $AnimationPlayer

func _ready():
	# Hide all panels at start
	for panel in panels:
		panel.visible = false

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if cur_panel < panels.size():
			panels[cur_panel].visible = true
			cur_panel += 1
		else:
			# End cutscene
			shake()
			await get_tree().create_timer(2.0).timeout
			queue_free() 


func shake():
	#vibrate left and right
	player.play("Shake")
