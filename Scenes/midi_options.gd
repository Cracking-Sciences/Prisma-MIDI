extends Node2D


# Called when the node enters the scene tree for the first time.

var selected_midi_out_name = ""
var selected_midi_in_name = ""
var time = 0.0
var message_out: PackedByteArray

@onready
var midi_out = $MidiOut
@onready
var midi_in = $MidiIn

func _ready():
	refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta

func refresh():
# button refresh
# midi out
	var select_midi_out = $HBoxContainerWidgets/SelectMidiOut
	select_midi_out.clear()
	select_midi_out.text = "Select MIDI Output"
	var num_ports = MidiOut.get_port_count()
	for i in range(num_ports):
		var port_name = MidiOut.get_port_name(i)
		select_midi_out.add_item(port_name)
		if port_name == selected_midi_out_name:
			select_midi_out.selected = i

# midi in
	var select_midi_in = $HBoxContainerWidgets/SelectMidiIn
	select_midi_in.clear()
	select_midi_in.text = "Select MIDI Input"
	num_ports = MidiIn.get_port_count()
	for i in range(num_ports):
		var port_name = MidiIn.get_port_name(i)
		select_midi_in.add_item(port_name)
		if port_name == selected_midi_in_name:
			select_midi_in.selected = i

func on_select_midi_out(index):
	var select_midi_out = $HBoxContainerWidgets/SelectMidiOut
	selected_midi_out_name = select_midi_out.get_item_text(index)
	midi_out.close_port()
	midi_out.open_port(index)

func on_select_midi_in(index):
	var select_midi_in = $HBoxContainerWidgets/SelectMidiIn
	selected_midi_in_name = select_midi_in.get_item_text(index)
	midi_in.close_port()
	midi_in.open_port(index)

func send_midi_message(data: Array, target: MidiOut = null):
	if target == null:
# TODO: internal music instrument
		return
	message_out.clear()
	for item in data:
		message_out.push_back(item)
	midi_out.send_message(message_out)

# demo
func _on_button_pressed():
	# send_midi_message([Utils.ProgramChange,5], midi_out)
	# send_midi_message([Utils.ControlChange,7,100], midi_out)
	var note = randi_range(20,80)
	send_midi_message([Utils.NoteOn, note, 90], midi_out)
	await Utils.sleep(0.5)
	send_midi_message([Utils.NoteOff, note, 40], midi_out)


