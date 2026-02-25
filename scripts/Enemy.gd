extends CharacterBody2D

# "Sentinel" AI demo:
# - Wanders between generated waypoints
# - Builds a suspicion meter when it can see the player
# - Pursues when suspicion maxes
# - Investigates last known position when LOS breaks
# - Tags player with knockback + cooldown

enum State { WANDER, INVESTIGATE, PURSUE }

@export var stroll_speed: float = 115.0
@export var pursue_speed: float = 175.0

@export var view_radius: float = 260.0
@export var view_angle_deg: float = 60.0   # half-angle, cone = +/- this
@export var suspicion_gain_per_sec: float = 55.0
@export var suspicion_decay_per_sec: float = 30.0

@export var tag_radius: float = 55.0
@export var tag_cooldown_sec: float = 1.2
@export var knockback_strength: float = 520.0

@export var arena_min := Vector2(40, 90)
@export var arena_max := Vector2(860, 560)

var state: int = State.WANDER
var suspicion: float = 0.0               # 0..100
var last_seen_pos: Vector2
var _tag_cooldown_left: float = 0.0
var _waypoint: Vector2
var _waypoint_refresh_left: float = 0.0

var player: Node2D
var facing := Vector2.RIGHT

func _ready() -> void:
    player = get_parent().get_node("Player") as Node2D
    last_seen_pos = global_position
    _pick_new_waypoint()

func _physics_process(delta: float) -> void:
    _tag_cooldown_left = maxf(0.0, _tag_cooldown_left - delta)
    _waypoint_refresh_left = maxf(0.0, _waypoint_refresh_left - delta)

    var can_see := _can_see_player()

    if can_see:
        last_seen_pos = player.global_position
        suspicion = minf(100.0, suspicion + suspicion_gain_per_sec * delta)
    else:
        suspicion = maxf(0.0, suspicion - suspicion_decay_per_sec * delta)

    # State transitions
    if suspicion >= 100.0:
        state = State.PURSUE
    elif state == State.PURSUE and not can_see:
        state = State.INVESTIGATE
    elif state == State.INVESTIGATE and global_position.distance_to(last_seen_pos) < 18.0 and suspicion < 35.0:
        state = State.WANDER

    match state:
        State.WANDER:
            _wander(delta)
        State.INVESTIGATE:
            _investigate(delta)
        State.PURSUE:
            _pursue(delta)

    move_and_slide()

func _wander(delta: float) -> void:
    if _waypoint_refresh_left <= 0.0 or global_position.distance_to(_waypoint) < 16.0:
        _pick_new_waypoint()

    var dir := (_waypoint - global_position).normalized()
    _set_facing(dir)
    velocity = dir * stroll_speed

func _investigate(delta: float) -> void:
    var dir := (last_seen_pos - global_position)
    if dir.length() < 8.0:
        velocity = Vector2.ZERO
        return

    dir = dir.normalized()
    _set_facing(dir)
    velocity = dir * stroll_speed

func _pursue(delta: float) -> void:
    var to_player := (player.global_position - global_position)
    var dist := to_player.length()

    if dist > 0.001:
        var dir := to_player / dist
        _set_facing(dir)
        velocity = dir * pursue_speed
    else:
        velocity = Vector2.ZERO

    if dist <= tag_radius and _tag_cooldown_left <= 0.0:
        _tag_cooldown_left = tag_cooldown_sec
        var push_dir := (player.global_position - global_position).normalized()
        if player.has_method("apply_knockback"):
            player.apply_knockback(push_dir * knockback_strength)

func _pick_new_waypoint() -> void:
    # Unique-ish: picks from a jittered "lattice" and adds a small random wiggle.
    var cell := Vector2(randi_range(0, 10), randi_range(0, 6))
    var base := arena_min + Vector2(cell.x * 80.0, cell.y * 70.0)
    _waypoint = Vector2(
        clampf(base.x + randf_range(-28.0, 28.0), arena_min.x, arena_max.x),
        clampf(base.y + randf_range(-22.0, 22.0), arena_min.y, arena_max.y)
    )
    _waypoint_refresh_left = randf_range(1.6, 3.2)

func _set_facing(dir: Vector2) -> void:
    if dir.length() > 0.001:
        facing = dir.normalized()

func _can_see_player() -> bool:
    var to_player := player.global_position - global_position
    var dist := to_player.length()
    if dist > view_radius:
        return false

    # Angle gate (cone)
    var dir := to_player / maxf(dist, 0.0001)
    var angle := rad_to_deg(acos(clampf(facing.dot(dir), -1.0, 1.0)))
    if angle > view_angle_deg:
        return false

    # Line of sight via raycast (collides with walls if you add them later).
    var space_state := get_world_2d().direct_space_state
    var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position)
    query.exclude = [self]
    query.collide_with_areas = true
    query.collide_with_bodies = true
    var hit := space_state.intersect_ray(query)

    # If nothing blocks, we see the player. If something hits, allow seeing only if the collider *is* the player.
    if hit.is_empty():
        return true

    return hit.get("collider") == player

func state_name() -> String:
    match state:
        State.WANDER: return "WANDER"
        State.INVESTIGATE: return "INVESTIGATE"
        State.PURSUE: return "PURSUE"
    return "UNKNOWN"
