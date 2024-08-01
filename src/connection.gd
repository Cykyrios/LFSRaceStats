class_name Connection
extends RefCounted


var ucid := 0
var username := ""
var nickname := ""

var selected_car := ""
var plid := -1


func fill_info(packet: InSimNCNPacket) -> void:
	ucid = packet.ucid
	username = packet.user_name
	nickname = packet.player_name
