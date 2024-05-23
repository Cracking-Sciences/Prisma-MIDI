class_name Piano
extends Control

@export var num_octaves: int = 8
var keys_octaves: Array
var note_to_key: Dictionary


var black_width_ratio = 0.65
var black_height_ratio = 0.70

const keys_octave = preload("res://Scenes/keys_octave.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	set_octaves()
	resize_keys()


func set_octaves():
	for child in keys_octaves:
		remove_child(child)
	keys_octaves.clear()
	note_to_key.clear()
	var middle = int(num_octaves / 2)
	for i in range(num_octaves):
		var new_octave = keys_octave.instantiate()
		add_child(new_octave)
		keys_octaves.append(new_octave)
		var j = 0
		for key in new_octave.keys:
			key.piano = self
			change_mouse_pressed.connect(key._on_change_mouse_pressed)
			var temp_note = (i - middle) * 12 + j + 60
			key.note = clamp(temp_note, 0, 127)
			if temp_note == key.note:
				# unclamped
				note_to_key[temp_note] = key
			j = j + 1

func resize_keys():
	if keys_octaves.size() == 0:
		return
	var octave_width = (size.x - Utils.vertical_progression_slider_width)/ num_octaves
	var octave_height = size.y
	for i in range(num_octaves):
		keys_octaves[i].height = octave_height
		keys_octaves[i].width = octave_width
		keys_octaves[i].black_width_ratio = black_width_ratio
		keys_octaves[i].black_height_ratio = black_height_ratio
		keys_octaves[i].resize()
		keys_octaves[i].set_position(Vector2(i*octave_width, 0))

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
