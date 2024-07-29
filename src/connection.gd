class_name Connection
extends RefCounted


var ucid := 0
var username := ""
var nickname := ""

var selected_car := ""


func fill_info(packet: InSimNCNPacket) -> void:
	ucid = packet.ucid
	username = packet.user_name
	nickname = packet.player_name
