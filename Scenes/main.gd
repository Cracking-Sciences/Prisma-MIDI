extends Control

@onready
var midi_options = $MidiOptions
@onready
var piano = $PianoRoll/PianoRollContainer/Piano

# Called when the node enters the scene tree for the first time.
func _ready():
	piano.note_on_off.connect(self.note_on_off)
	midi_options.midi_in_message.connect(self.handle_midi_in_message)

func note_on_off(is_on, note, velocity):
	if is_on:
		midi_options.send_midi_message([Utils.NoteOn, note, velocity], midi_options.midi_out)
	else:
		midi_options.send_midi_message([Utils.NoteOff, note, velocity], midi_options.midi_out)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		var piano_roll = $PianoRoll
		piano_roll.custom_minimum_size = get_viewport_rect().size

func handle_midi_in_message(event: InputEventMIDI):
	var is_on
	match event.message:
		MIDI_MESSAGE_NOTE_ON:
			is_on = true
		MIDI_MESSAGE_NOTE_OFF:
			is_on = false
		_:
			return
	var key = piano.get_key(event.pitch)
	if key == null:
		# trigger without the key
		note_on_off(is_on, event.pitch, event.velocity)
	else:
		# trigger from the key
		if is_on:
			key.activate(event.velocity)
		else:
			key.deactivate(event.velocity)