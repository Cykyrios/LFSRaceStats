extends Node


var file: FileAccess = null
var file_open := false


func _ready() -> void:
	create_log_file()


func create_log_file() -> void:
	file = FileAccess.open("user://%s.log" % [get_date_time_string()], FileAccess.WRITE)
	if file:
		file_open = true


func close_log_file() -> void:
	file_open = false
	file = null


func get_date_time_string() -> String:
	return Time.get_datetime_string_from_system(true, true)


func log_message(message: String) -> void:
	if not file_open:
		return
	file.store_line("%s - %s" % [get_date_time_string(), message])
	file.flush()


func log_packet(packet: InSimPacket) -> void:
	if not file_open:
		return
	var packet_string := packet.to_string()
	file.store_line("%s - %s" % [get_date_time_string(), packet_string])
	file.flush()
