class_name Utils
extends Node

const PLAYER_GROUP: String = "PLAYER"

static func get_random_direction() -> Vector2:
	return Vector2.RIGHT.rotated(randf() * TAU)

func get_player() -> Player:
	return get_tree().get_first_node_in_group(PLAYER_GROUP)
