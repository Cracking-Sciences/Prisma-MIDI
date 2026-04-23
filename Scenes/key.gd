class_name Key
extends ColorRect

@export var note = 60 # midi note code
@export var start_color = color
@export var piano: Piano = null
@export var active_color = Color.ORANGE # default active color
@export var default_z_index = 0

var light_top: PointLight2D
var light_bottom: PointLight2D


func _make_light() -> PointLight2D:
	var l = PointLight2D.new()
	l.texture = load("res://assets/2d_lights_and_shadows_neutral_point_light.webp")
	l.energy = 0.8
	l.texture_scale = 1.5
	l.enabled = false
	l.range_z_min = -2
	l.range_z_max = default_z_index
	l.shadow_enabled = true
	l.shadow_color = Color(0, 0, 0, 0.77254903)
	l.shadow_filter = Light2D.SHADOW_FILTER_PCF13
	l.shadow_filter_smooth = 3.0
	return l


func _ready():
	z_index = default_z_index

	light_top = _make_light()
	add_child(light_top)

	light_bottom = _make_light()
	add_child(light_bottom)

	_on_resized()


var is_activate = false

func mouse_activate():
	var velocity = clamp(int(get_local_mouse_position().y * 140 / size.y), 1, 126)
	activate(velocity)

func mouse_deactivate():
	deactivate(100)


func activate(velocity, new_color = null, send_to_output = true):
	is_activate = true
	if piano != null and send_to_output:
		piano.note_on_off.emit(true, note, velocity)
	if new_color == null:
		new_color = active_color
	color = (new_color * (128 + velocity)) / 256
	color.a = 1
	light_top.color = new_color
	light_top.enabled = true
	light_bottom.color = new_color
	light_bottom.enabled = true

func deactivate(velocity, send_to_output = true):
	if is_activate:
		is_activate = false
		color = start_color
		if piano != null and send_to_output:
			piano.note_on_off.emit(false, note, velocity)
	light_top.enabled = false
	light_bottom.enabled = false


# slide
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


# on resize: top light at y=0, bottom light at y=size.y, both centered on x
var light_base_size = 30 # px
func _on_resized():
	if light_top == null or light_bottom == null:
		return
	var scale_x = size.x / light_base_size
	var scale_y = size.y / light_base_size

	light_top.position = Vector2(size.x / 2, 0)
	light_top.scale = Vector2(scale_x, scale_y)

	light_bottom.position = Vector2(size.x / 2, size.y)
	light_bottom.scale = Vector2(scale_x, scale_y)
