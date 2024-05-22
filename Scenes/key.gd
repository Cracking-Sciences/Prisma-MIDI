class_name Key
extends ColorRect

@export var note = 60 # midi note code
@export var start_color = color
@export var piano: Piano = null
@export var active_color = Color.ORANGE

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


var is_activate = false

func mouse_activate():
	is_activate = true
	color = active_color
	if piano != null:
		var velocity = clamp(int(get_local_mouse_position().y * 128 / size.y), 1, 126)
		piano.note_on_off.emit(true, note, velocity)
	# print(note)

func mouse_deactivate():
	if is_activate:
		is_activate = false
		color = start_color
		if piano != null:
			piano.note_on_off.emit(false, note, 100)

# slide:
func _on_mouse_entered():
	if piano != null and piano.get_mouse_pressed():
		mouse_activate()

func _on_mouse_exited():
	mouse_deactivate()

# click
func _gui_input(input_event):
	if input_event is InputEventMouseButton and input_event.pressed:
		if piano != null:
			piano.set_mouse_pressed(true)
		mouse_activate()
	if input_event is InputEventMouseButton and not input_event.pressed:
		if piano != null:
			piano.set_mouse_pressed(false)
		mouse_deactivate()

# slide release 
func _on_change_mouse_pressed():
	if not piano.get_mouse_pressed():
		mouse_deactivate()