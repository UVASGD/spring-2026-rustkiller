extends HFSM

@export var awaken_animation: String = "Awaken"
@export var player_move_threshold: float = 6.0
@export var awaken_when_player_moves := true

var _player_start_pos: Vector2
var _awaken_started := false

func on_enter() -> void:
    _awaken_started = false
    if player:
        _player_start_pos = player.global_position

    _set_boss_visible(false)
    _set_boss_active(false)
    animation = awaken_animation

func update(_delta: float) -> void:
    if _awaken_started:
        return

    if awaken_when_player_moves and _player_moved():
        _awaken_started = true
        _set_boss_visible(true)
        _set_boss_active(false)

func check_transition(_delta: float) -> TransitionData:
    # IMPORTANT: do not transition to "Alive" here.
    # Clear dormancy and let top steam_hsfm.gd choose Alive.
    if _awaken_started and animation_ended():
        _set_boss_active(true)

        var boss := character as HFSMSteamBoss
        if boss:
            boss.is_dormant = false

        return TransitionData.new(false, "awaken complete; top hfsm will switch to Alive")

    return TransitionData.new(false, "")

func _player_moved() -> bool:
    if player == null:
        return false
    return player.global_position.distance_to(_player_start_pos) > player_move_threshold

func _set_boss_visible(v: bool) -> void:
    if character:
        character.visible = v

func _set_boss_active(v: bool) -> void:
    if character == null:
        return
    for n in character.get_children():
        if n is CollisionShape2D:
            n.disabled = not v
        elif n is Area2D:
            n.monitoring = v
            n.monitorable = v
