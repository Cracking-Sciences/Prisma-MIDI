extends Control

@onready
var midi_options = $MidiOptions
@onready
var piano = $PianoRoll/PianoRollContainer/Piano
@onready
var piano_roll = $PianoRoll

# Called when the node enters the scene tree for the first time.
func _ready():
	piano.note_on_off.connect(self.note_on_off)
	midi_options.get_midi_in_message.connect(self.on_midi_in_message)
	midi_options.generate_map.connect(self.on_generate_map)
	piano_roll.parent = self

func note_on_off(is_on, note, velocity):
	if is_on:
		midi_options.send_midi_message([Utils.NoteOn, note, velocity], midi_options.midi_out)
	else:
		midi_options.send_midi_message([Utils.NoteOff, note, velocity], midi_options.midi_out)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if piano_roll != null:
			piano_roll.custom_minimum_size = get_viewport_rect().size

func on_midi_in_message(_deltatime, message):
	if len(message) != 3:
		return
	var is_on
	match message[0]:
		Utils.NoteOn:
			is_on = true
		Utils.NoteOff:
			is_on = false
		_:
			if message[0] >= 176 and message[0] <= 191: # cc message from channel 1~16
				match message[1]:
					Utils.SustainPedal:
						# TODO: internal sustain pedal handle, since many audio resource didn't handle that
						midi_options.send_midi_message(message, midi_options.midi_out)
						# print(message)
						return
					_:
						# print(message)
						return
	var key = piano.get_key(message[1])
	if key == null:
		# trigger without the key
		note_on_off(is_on, message[1], message[2])
	else:
		# trigger from the key
		piano_roll.manual_note_on_off(is_on, message[1], message[2], key)

func on_generate_map():
	if midi_options.smf_result == null:
		return
	piano_roll.generate_map(midi_options.smf_result.data, midi_options.get_selected_tracks_number())
	piano_roll.get_prisma_tracks(midi_options.get_prisma_tracks_number())

var keyboard_position_map = {
	KEY_A: 1/11.0,
	KEY_S: 2/11.0,
	KEY_D: 3/11.0,
	KEY_F: 4/11.0,
	KEY_G: 5/11.0,
	KEY_H: 6/11.0,
	KEY_J: 7/11.0,
	KEY_K: 8/11.0,
	KEY_L: 9/11.0,
	KEY_SEMICOLON: 10/11.0
}
func _input(event):
	# keyboard input. unrecommended way as it doesn't express velocity emotion.
	# but I added this feature anyway... make it more like a game.
	if event is InputEventKey and not event.echo:
		if event.keycode in keyboard_position_map.keys():
			# linear map
			var note = int((piano.note_max - piano.note_min) * keyboard_position_map[event.keycode]) + piano.note_min
			var key = piano.get_key(note)
			var is_on = true
			if not event.pressed:
				is_on = false
			piano_roll.manual_note_on_off(is_on, note, 100, key, false)