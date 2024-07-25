extends Node


func _ready() -> void:
	pass


func get_date_time_string() -> String:
	return Time.get_datetime_string_from_system(true, true)


func log_message(message: String) -> void:
	print("%s - %s" % [get_date_time_string(), message])


func log_packet(packet: InSimPacket) -> void:
	var packet_string := packet.to_string()
	print("%s - %s" % [get_date_time_string(), packet_string])
