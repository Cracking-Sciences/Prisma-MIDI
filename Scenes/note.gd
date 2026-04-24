class_name Note
extends Panel

var note = 60
var velocity = 100
var track_number = 0
var send_to_output = true
var strict = false

var falling_speed = 1 # % area.y per second
var falling_ratio = 0
var length_ratio = 0.1


var is_falling = false
var fell_below = false # and should release
var tail_cut = false

var triggered = false
var released = false

var parent = null

var is_prisma = false


@onready var diamond_marker = $DiamondMarker
@onready var glow_light = $DiamondMarker/GlowLight

@onready
var base_energy = glow_light.energy

func _ready():
	if note % 12 in [1,3,6,8,10]:
		color_mul(1.0, 1.2)
	diamond_marker.visible = is_prisma
	
	# Make note body more transparent without affecting children
	self_modulate.a *= 0.7
	
	reshape_diamond()
	# Compensate parent modulate so diamond always renders in its own pure color
	var m = modulate
	var pure_color = Color(
		(1.0 / m.r) if m.r > 0.001 else 1.0,
		(1.0 / m.g) if m.g > 0.001 else 1.0,
		(1.0 / m.b) if m.b > 0.001 else 1.0,
		(1.0 / m.a) if m.a > 0.001 else 1.0
	)
	diamond_marker.modulate = pure_color
	
	if is_prisma:
		glow_light.modulate = pure_color
		glow_light.energy = base_energy * clamp(falling_ratio, 0.0, 1.0)


func _process(delta):
	if is_falling and not fell_below:
		var delta_ratio = falling_speed * delta
		falling_ratio += delta_ratio
		reposition_y()
		if length_ratio + 1 + delta_ratio < falling_ratio:
			fell_below = true
		
		# Blur and Light logic
		if is_prisma and not triggered:
			if is_instance_valid(diamond_marker):
				diamond_marker.scale.y = 1.0 + falling_speed * 0.2
			if is_instance_valid(glow_light):
				glow_light.energy = base_energy * clamp(falling_ratio, 0.0, 1.0)
	else:
		if is_prisma:
			if is_instance_valid(diamond_marker):
				diamond_marker.scale.y = 1.0


func reposition_y():
	if not tail_cut:
		# Before the note is released, prevent size.y from becoming huge (which breaks Godot's 2D lighting/culling)
		var bottom_y = parent.custom_minimum_size.y * falling_ratio
		var top_y = min(-50.0, bottom_y - 100.0)
		size.y = bottom_y - top_y
		position.y = top_y
	else:
		size.y = parent.custom_minimum_size.y * length_ratio
		position.y = parent.custom_minimum_size.y * falling_ratio - size.y
		
	if is_instance_valid(diamond_marker):
		diamond_marker.position.y = size.y

func reshape_diamond():
	if diamond_marker == null or not diamond_marker.visible:
		return
	var half = size.x / 2.0
	diamond_marker.position.x = half
	diamond_marker.position.y = size.y
		
	var shape = PackedVector2Array([
		Vector2(0.0,  -half), # Top
		Vector2(half,  0.0),  # Right
		Vector2(0.0,   half), # Bottom
		Vector2(-half, 0.0),  # Left
	])
	diamond_marker.polygon = shape

func cut_tail(latency_ratio = 0.0):
	if not tail_cut:
		length_ratio = max(falling_ratio - latency_ratio, 0.01) # lower bound, make it visible
		tail_cut= true
		reposition_y()
		reshape_diamond() # size.y changed, bottom anchor moved
		return true
	return false

func set_triggered():
	triggered = true
	if is_prisma:
		_play_diamond_exit()

func _play_diamond_exit():
	var marker = diamond_marker
	var light = glow_light
	
	diamond_marker = null  # Clear ref
	marker.reparent(parent, true)
	marker.color = Color.WHITE
	var duration = 0.1
	var tween = marker.create_tween()
	tween.set_parallel(true)
	tween.tween_property(marker, "scale", Vector2(8.0, 0.0), duration)
	tween.tween_property(marker, "modulate:a", 0.0, duration)
	
	if is_instance_valid(light):
		light.scale = light.scale * 2.0
		light.energy = light.energy * 2.0
		tween.tween_property(light, "scale", Vector2(3.0, 0.0), duration)
		tween.tween_property(light, "energy", 0.0, duration)
	
	tween.set_parallel(false)
	tween.tween_callback(marker.queue_free)

func set_released():
	if released:
		return
	triggered = true
	released = true
	color_mul(0.5, 0.75)

func color_mul(mul: float, a_mul: float = 1):
	var a_backup = modulate.a
	modulate = (modulate * mul).clamp(Color(0, 0, 0, 0), Color(1, 1, 1, 1))
	modulate.a = a_backup * a_mul
