extends Control

@onready
var piano_roll_container = $PianoRollContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	# piano_roll_container.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
	set_all()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if piano_roll_container == null:
			return
		set_all()

func set_all():
	piano_roll_container.custom_minimum_size = get_viewport_rect().size
	var height_slider = $PianoRollContainer/HBoxContainerWidgets/HSliderHeight
	change_piano_height(height_slider.value)
	var octaves_slider= $PianoRollContainer/HBoxContainerWidgets/HSliderOctaves
	change_piano_octaves(octaves_slider.value)
	var black_width_slider= $PianoRollContainer/HBoxContainerWidgets/HSliderBlackWidth
	change_piano_black_width(black_width_slider.value)
	var black_height_slider= $PianoRollContainer/HBoxContainerWidgets/HSliderBlackHeight
	change_piano_black_height(black_height_slider.value)



func change_piano_height(ratio):
	var height = get_viewport_rect().size.y * ratio
	var piano = $PianoRollContainer/Piano
	var falling_notes = $PianoRollContainer/FallingNotes
	var widgets = $PianoRollContainer/HBoxContainerWidgets
	piano.custom_minimum_size.y = height
	falling_notes.custom_minimum_size.y = get_viewport_rect().size.y * \
		(1 - ratio) - widgets.size.y

func change_piano_octaves(num):
	var piano = piano_roll_container.get_node("Piano")
	piano.num_octaves = num
	piano.set_octaves()
	piano.resize_keys()

func change_piano_black_width(ratio):
	var piano = $PianoRollContainer/Piano
	piano.black_width_ratio = ratio
	piano.resize_keys()

func change_piano_black_height(ratio):
	var piano = $PianoRollContainer/Piano
	piano.black_height_ratio = ratio
	piano.resize_keys()