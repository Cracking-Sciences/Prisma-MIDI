class_name Key
extends ColorRect

@export var note = 60 # midi note code
@export var start_color = color
@export var piano: Piano = null
@export var active_color = Color.ORANGE # default active color

@export var default_z_index = 0

@onready
var light = $PointLight2D
# Called when the node enters the scene tree for the first time.
func _ready():
	z_index = default_z_index
	light.range_z_max = z_index
	light.enabled = false
	pass # Replace with function body.


var is_activate = false

func mouse_activate():
	var velocity = clamp(int(get_local_mouse_position().y * 140 / size.y), 1, 126)
	activate(velocity)

func mouse_deactivate():
	deactivate(100)


func activate(velocity, new_color = null):
	is_activate = true
	if piano != null:
		piano.note_on_off.emit(true, note, velocity)
	if new_color == null:
		new_color = active_color
	color = (new_color * (128 + velocity)) / 256
	color.a = 1
	light.color = new_color
	light.enabled = true

func deactivate(velocity):
	if is_activate:
		is_activate = false
		color = start_color
		if piano != null:
			piano.note_on_off.emit(false, note, velocity)
	
	light.enabled = false

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

# on resize
var light_base_size = 30 # px
func _on_resized():
	light.position.x = size.x / 2
	light.scale.x = size.x / light_base_size
	light.scale.y = size.y / light_base_size