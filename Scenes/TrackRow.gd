extends HBoxContainer
class_name TrackRow
@export var track_number: int
@onready var label_track_name     = $LabelTrackName
@onready var check_enabled        = $CheckBoxEnabled
@onready var check_prisma         = $CheckBoxPrisma
@onready var check_to_output      = $CheckBoxToOutput
var is_enabled: bool:
	get: return check_enabled.button_pressed
	set(v): check_enabled.button_pressed = v
var is_prisma: bool:
	get: return check_prisma.button_pressed
	set(v): check_prisma.button_pressed = v
var send_to_output: bool:
	get: return check_to_output.button_pressed
	set(v): check_to_output.button_pressed = v
