extends Control

@onready
var midi_options = $MidiOptions
@onready
var piano = $PianoRoll/PianoRollContainer/Piano

# Called when the node enters the scene tree for the first time.
func _ready():
	piano.note_on_off.connect(self.note_on_off)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func note_on_off(is_on, note, velocity):
	if is_on:
		midi_options.send_midi_message([Utils.NoteOn, note, velocity], midi_options.midi_out)
	else:
		midi_options.send_midi_message([Utils.NoteOff, note, velocity], midi_options.midi_out)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		var piano_roll = $PianoRoll
		piano_roll.custom_minimum_size = get_viewport_rect().size