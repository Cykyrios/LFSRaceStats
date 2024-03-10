class_name LapData
extends RefCounted


var lap_number := 0
var lap_time := 0.0
var session_time := 0.0
var sectors: Array[SectorData] = []
var inlap := false
var outlap := false
