extends Node2D

@onready var enemy := $Enemy
@onready var state_label := $UI/HUD/StateLabel
@onready var hint_label := $UI/HUD/HintLabel
@onready var bar := $UI/HUD/SuspicionBar

var debug_on := true

func _ready() -> void:
    _sync_debug()

func _process(delta: float) -> void:
    if Input.is_action_just_pressed("ui_accept"):
        debug_on = not debug_on
        _sync_debug()

    bar.value = enemy.suspicion
    state_label.text = "Sentinel: %s   |   Suspicion: %d%%" % [enemy.state_name(), int(enemy.suspicion)]

func _sync_debug() -> void:
    $UI/HUD.visible = debug_on
    hint_label.text = "Arrows: move   |   Enter/Space: toggle HUD"
