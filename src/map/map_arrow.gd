class_name MapArrow
extends Sprite2D


var arrow := preload("res://src/map/arrow.png")
var paused := false

var plid := 0
var driver := ""

var last_position := Vector3.ZERO
var last_heading := 0.0
var last_speed := 0.0
var last_direction := 0.0
var last_ang_vel := 0.0
var last_update_time := 0.0

var base_color := Color.WEB_GREEN
var current_color := base_color
var blue_flag := false
var yellow_flag := false
var in_pits := false

var tween: Tween = null


func _ready() -> void:
	texture = arrow
	scale = Vector2.ONE * 0.5
	modulate = base_color


func _process(_delta: float) -> void:
	if paused:
		return
	update(Time.get_ticks_msec() / 1000.0 - last_update_time)


func set_color(color: Color) -> void:
	base_color = color
	if in_pits:
		show_pitlane()
	else:
		stop_pitlane()


func show_flags() -> void:
	if tween:
		stop_flags()
	tween = create_tween()
	tween = tween.set_loops(0).set_parallel(false)
	var _discard: Variant = tween.tween_property(self, "modulate",
			Color.BLUE if blue_flag else current_color, 0)
	_discard = tween.tween_interval(0.5)
	_discard = tween.tween_property(self, "modulate",
			Color.YELLOW if yellow_flag else current_color, 0)
	_discard = tween.tween_interval(0.5)


func show_pitlane() -> void:
	current_color = base_color * Color(1, 1, 1, 0.3)
	modulate = current_color


func stop_flags() -> void:
	if tween:
		tween.kill()
	modulate = current_color


func stop_pitlane() -> void:
	current_color = base_color
	modulate = current_color


func update(extra_time := 0.0) ->  void:
	position = Vector2(last_position.x, -last_position.y) \
			+ extra_time * last_speed * Vector2(0, -1).rotated(-last_direction)
	position /= 4.0
	rotation = -last_heading - extra_time * last_ang_vel


func update_data(compcar: CompCar) -> void:
	last_update_time = Time.get_ticks_msec() / 1000.0
	last_position = compcar.gis_position
	last_heading = compcar.gis_heading
	last_speed = compcar.gis_speed
	last_direction = compcar.gis_direction
	last_ang_vel = compcar.gis_angular_velocity
