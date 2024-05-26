class_name Piano
extends Control

@export var num_octaves: int = 8
var keys_octaves: Array
var note_to_key: Dictionary
var middle_octave: int = 0

var white_gap_ratio = 0.10
var black_width_ratio = 0.65
var black_height_ratio = 0.70

const keys_octave = preload("res://Scenes/keys_octave.tscn")


var note_width = 0.0
var note_width_shrink = 0.0

var note_min = 0
var note_max = 0

var referece_xs = []

# Called when the node enters the scene tree for the first time.
func _ready():
	set_octaves()
	resize_keys()

func set_octaves():
	for child in keys_octaves:
		remove_child(child)
	keys_octaves.clear()
	note_to_key.clear()
	for i in range(num_octaves):
		var new_octave = keys_octave.instantiate()
		add_child(new_octave)
		keys_octaves.append(new_octave)
		var j = 0
		for key in new_octave.keys:
			key.piano = self
			change_mouse_pressed.connect(key._on_change_mouse_pressed)
			var temp_note = (i + middle_octave - num_octaves / 2) * 12 + j + 60
			key.note = clamp(temp_note, 0, 127)
			if temp_note == key.note:
				# unclamped
				note_to_key[temp_note] = key
			j = j + 1

	note_min = keys_octaves[0].keys[0].note
	note_max = keys_octaves[-1].keys[-1].note


func resize_keys():
	if keys_octaves.size() == 0:
		return
	var margin_key_gap = (size.x) / (num_octaves * 12 + 2)
	var octave_width = (size.x - margin_key_gap * 2)/ num_octaves
	var octave_height = size.y
	for i in range(num_octaves):
		keys_octaves[i].white_gap_ratio = white_gap_ratio
		keys_octaves[i].height = octave_height
		keys_octaves[i].width = octave_width
		keys_octaves[i].black_width_ratio = black_width_ratio
		keys_octaves[i].black_height_ratio = black_height_ratio
		keys_octaves[i].resize()
		keys_octaves[i].set_position(Vector2(i*octave_width + margin_key_gap, 0))
	
	note_width = (size.x) / (num_octaves * 12 + 2)
	var white_gap = octave_width / 7 * white_gap_ratio
	# note_width_shrink = white_gap
	note_width_shrink = 0
	referece_xs.clear()
	for i in range(num_octaves):
		referece_xs.append(margin_key_gap + octave_width * i - white_gap / 2)
		referece_xs.append(margin_key_gap + octave_width * i + octave_width * 5 / 12 - white_gap / 2)
	referece_xs.append(size.x - margin_key_gap)


func _notification(what):
	if what == NOTIFICATION_RESIZED:
		resize_keys()

signal note_on_off(is_on, note, velocity)

# for mouse clicks and slides on keys
var is_mouse_pressed = false
signal change_mouse_pressed

func set_mouse_pressed(value):
	is_mouse_pressed = value
	change_mouse_pressed.emit()

func get_mouse_pressed() -> bool:
	return is_mouse_pressed

func _gui_input(input_event):
	if input_event is InputEventMouseButton and not input_event.pressed:
		set_mouse_pressed(false)
	if input_event is InputEventMouseButton and input_event.pressed:
		set_mouse_pressed(true)

func get_key(note) -> Key:
	# return the key or null
	if note in note_to_key:
		return note_to_key[note]
	return null

func get_note_width():
	return note_width - note_width_shrink

func get_note_x(note) -> float:
	if note >= note_min and note <= note_max:
		return (note - note_min + 1) * note_width + note_width_shrink / 2
	if note < note_min:
		return note_width_shrink / 2
	elif note > note_max:
		return (size.x) - note_width + note_width_shrink / 2
	else:
		# impossible
		return -100

func get_reference_xs() -> Array:
	return referece_xs
