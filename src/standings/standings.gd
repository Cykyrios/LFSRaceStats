class_name Standings
extends VBoxContainer


enum TyreCompound { R1, R2, R3, R4, SUPER, NORMAL, HYBRID, KNOBBLY }

var tyre_colors: Array[Color] = []

var lines: Array[StandingsLine] = []

@onready var drivers: VBoxContainer = %Drivers


func _ready() -> void:
	var _discard := tyre_colors.resize(TyreCompound.size())
	tyre_colors[TyreCompound.R1] = Color(1.0, 0.706, 0.784)
	tyre_colors[TyreCompound.R2] = Color(0.871, 0.0, 0.0)
	tyre_colors[TyreCompound.R3] = Color(0.941, 0.863, 0.0)
	tyre_colors[TyreCompound.R4] = Color(0.941, 0.941, 0.941)
	tyre_colors[TyreCompound.SUPER] = Color(0.0, 0.784, 0.0)
	tyre_colors[TyreCompound.NORMAL] = Color(0.157, 0.294, 0.902)
	tyre_colors[TyreCompound.HYBRID] = Color(0.667, 0.0, 0.863)
	tyre_colors[TyreCompound.KNOBBLY] = Color(0.392, 0.275, 0.0)
