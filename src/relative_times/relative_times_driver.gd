class_name RelativeTimesDriver
extends RefCounted


var plid := 0
var name := ""
var car := ""

var lap := 0
var times: Array[float] = []
var last_updated_index := -1

var position := 0
var car_class: CarClass = null
var class_position := 0


func _init(driver_plid: int, driver_name: String, driven_car: String, size: int) -> void:
	plid = driver_plid
	name = driver_name
	car = driven_car
	times.clear()
	var _discard := times.resize(size)


func clear() -> void:
	plid = 0
	name = ""
	car = ""
	lap = 0
	last_updated_index = -1
	position = 0
	car_class = null
	class_position = 0
	var size := times.size()
	times.clear()
	var _discard := times.resize(size)
