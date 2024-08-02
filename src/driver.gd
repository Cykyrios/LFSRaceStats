class_name Driver
extends RefCounted


var username := ""
var nickname := ""
var rank := 0
var position := Vector3.ZERO
var heading := 0.0
var speed := 0.0
var in_pitlane := false

var front_tyres := InSim.Tyre.TYRE_NUM
var rear_tyres := InSim.Tyre.TYRE_NUM

var lap_data: Array[LapData] = []
var stints: Array[StintData] = []
