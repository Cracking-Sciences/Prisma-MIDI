class_name Key
extends ColorRect

@export var note = 60 # midi note code
@export var start_color = color


@export var piano: Piano = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	mouse_filter = Control.MOUSE_FILTER_STOP

func mouse_activate():
	color = Color.ORANGE
	# print(note)


func mouse_deactivate():
	color = start_color


func _on_mouse_entered():
	if piano != null and piano.is_mouse_pressed:
		mouse_activate()

func _on_mouse_exited():
	mouse_deactivate()

func _gui_input(input_event):
	if input_event is InputEventMouseButton and not input_event.pressed:
		if piano != null:
			piano.is_mouse_pressed = false
		mouse_deactivate()
	elif input_event is InputEventMouseButton and input_event.pressed:
		if piano != null:
			piano.is_mouse_pressed = true
		mouse_activate()