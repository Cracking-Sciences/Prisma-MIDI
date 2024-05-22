class_name Piano
extends Control

@export var octaves = 7

@export var is_mouse_pressed = false

var keys_octaves: Array
const keys_octave = preload("res://Scenes/keys_octave.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	set_octaves()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_octaves():
	for child in keys_octaves:
		remove_child(child)
	var middle = int(octaves / 2)
	for i in range(octaves):
		var new_octave = keys_octave.instantiate()
		add_child(new_octave)
		keys_octaves.append(new_octave)
		var j = 0
		for key in new_octave.keys:
			key.piano = self
			key.note = max(min((i - middle) * 12 + j + 60, 127), 0)
			j = j + 1

	resize_keys()

func resize_keys():
	var octave_width = size.x / octaves
	var octave_height = size.y
	for i in range(octaves):
		keys_octaves[i].height = octave_height
		keys_octaves[i].width = octave_width
		keys_octaves[i].resize()
		keys_octaves[i].set_position(Vector2(i*octave_width, 0))

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		resize_keys()
