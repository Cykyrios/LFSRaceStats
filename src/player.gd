class_name Player
extends RefCounted


var plid := 0
var ucid := 0
var nickname := ""
var plate := ""
var car := ""
var skin := ""
var tyres: Array[InSim.Tyre]

var laps: Array[LapData] = []
var splits: Array[SectorData] = []


func add_lap(packet: InSimLAPPacket) -> void:
	var lap := get_lap_from_number(packet.laps_done)
	if not lap:
		lap = LapData.new()
	lap.lap_number = packet.laps_done
	lap.lap_time = packet.gis_lap_time
	lap.session_time = packet.gis_elapsed_time
	for sector in splits:
		lap.sectors.append(sector)
	splits.clear()


func add_split(packet: InSimSPXPacket) -> void:
	var sector := SectorData.new()
	sector.sector_number = packet.split
	sector.split_time = packet.gis_split_time
	sector.session_time = packet.gis_elapsed_time
	splits.append(sector)
	if splits.size() > 1:
		sector.sector_time = sector.split_time - splits[-2].split_time
	else:
		sector.sector_time = sector.split_time


func fill_info(packet: InSimNPLPacket) -> void:
	plid = packet.player_id
	ucid = packet.ucid
	nickname = packet.player_name
	plate = packet.plate
	car = packet.car_name
	skin = packet.skin_name
	tyres = packet.tyres


func get_lap_from_number(lap_number: int) -> LapData:
	for lap in laps:
		if lap.lap_number == lap_number:
			return lap
	return null
