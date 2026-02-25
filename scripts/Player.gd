extends CharacterBody2D

@export var speed: float = 240.0
@export var friction: float = 18.0

var _external_velocity := Vector2.ZERO

func apply_knockback(push: Vector2) -> void:
    _external_velocity += push

func _physics_process(delta: float) -> void:
    var dir := Vector2.ZERO
    dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

    var desired := dir.normalized() * speed
    _external_velocity = _external_velocity.move_toward(Vector2.ZERO, friction * speed * delta)

    velocity = desired + _external_velocity
    move_and_slide()
