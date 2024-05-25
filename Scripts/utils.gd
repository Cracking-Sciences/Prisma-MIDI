extends Node

# macros
const NoteOn = 144
const NoteOff = 128
const ProgramChange = 192
const ControlChange = 176


# ui
const horizontal_widgets_width = 20

# utils
func sleep(seconds):
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = seconds
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()


func shorten_text_with_ellipsis(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
		
	var ellipsis = "..."
	var part_length = int((max_length - ellipsis.length()) / 2)
		
	var first_part = text.substr(0, part_length)
	var last_part = text.substr(text.length() - part_length, part_length)
		
	return first_part + ellipsis + last_part

func get_track_name(track: SMF.MIDITrack)->String:
	var answer = str(track.track_number)
	for event in track.events:
		if event.event.type == SMF.MIDIEventType.system_event:
			var args = event.event.args
			if args["type"] == SMF.MIDISystemEventType.track_name:
				answer = answer  + " | " + args["text"]
			elif args["type"] == SMF.MIDISystemEventType.instrument_name:
				answer = answer  + " | " + args["text"]
	return answer

func print_smf_data_1(smf_data:SMF.SMFData):
	# for debug
	for track in smf_data.tracks:
		print("track number: ", track.track_number)
		for event in track.events:
			if event.event.type == SMF.MIDIEventType.system_event:
				print(event.time, ", ", event.event.args)
			elif event.event.type == SMF.MIDIEventType.note_on:
				print(event.time, ", ", "Note On, ", event.event.note, " ", event.event.velocity)
			elif event.event.type == SMF.MIDIEventType.note_off:
				print(event.time, ", ", "Note Off, ", event.event.note, " ", event.event.velocity)

# maybe not in use...
func parse_timebase(timebase: int):
	if (timebase & 0x8000) == 0:
		# TPQN 格式
		var tpqn = timebase
		print("TPQN:", tpqn)
	else:
		# SMPTE 格式
		var smpte = timebase
		var frames_per_second_raw = 0xFF - (smpte >> 8) + 1
		var frames_per_second = 30
		var ticks_per_frame = smpte & 0xFF
		match frames_per_second_raw:
			24:
				frames_per_second =24
			25:
				frames_per_second = 25
			29:
				frames_per_second = 29.97
			30:
				frames_per_second = 30
			_:
				pass
		print("SMPTE Frames per second:", frames_per_second)
		print("Ticks per frame:", ticks_per_frame)

class MIDIEventChunkPlus:
# we will mix all tracks to one track
# so we add the track_number to the MIDIEventChunk for later use
	var track_number: int
	var midi_event_chunk: SMF.MIDIEventChunk

	func _init(_midi_event_chunk: SMF.MIDIEventChunk, _track_number = 0):
		self.midi_event_chunk = _midi_event_chunk
		self.track_number = _track_number

class EventsAndStatus:
	# one mixed track
	var timebase
	var events: Array[MIDIEventChunkPlus] = []
	var event_pointer: int = 0 # event index
	
	var tempo
	var seconds_to_timebase
	var timebase_to_seconds

	var position = 0.0 # time
	var last_position: int = 0 # time

	func set_tempo(bpm: float) -> void:
		self.tempo = bpm
		self.seconds_to_timebase = self.tempo / 60.0
		self.timebase_to_seconds = 60.0 / self.tempo

	func seek(to_position: float) -> void:
		var pointer: int = 0
		self.position = to_position
		var new_position: int = int(floor(self.position))
		for event in self.events:
			if new_position <= event.midi_event_chunk.time:
				break
			process_control_event(event)
			pointer += 1
		self.event_pointer = pointer

	func process_control_event(event: MIDIEventChunkPlus)->String:
		# return something changed?
		if event.midi_event_chunk.event.type == SMF.MIDIEventType.system_event:
				match event.midi_event_chunk.event.args["type"]:
					SMF.MIDISystemEventType.set_tempo:
						self.set_tempo(60000000.0 / float( event.midi_event_chunk.event.args.bpm ))
						return "set tempo"
					_:
						return ""
		return ""

func get_events_and_status(smf_data:SMF.SMFData)->EventsAndStatus:
	# Mix multiple tracks to single track
	var tracks:Array[Dictionary] = []
	for track in smf_data.tracks:
		tracks.append({"track_id": track.track_number, "pointer":0, "events":track.events, "length": len( track.events )})

	var events_and_status = EventsAndStatus.new()
	var time:int = 0
	var finished:bool = false
	while not finished:
		finished = true
		var next_time:int = 0x7fffffff
		for track in tracks:
			var p = track.pointer
			if track.length <= p: 
				continue
			finished = false

			var e:SMF.MIDIEventChunk = track.events[p]
			var e_time:int = e.time
			if e_time == time:
				if is_need_map_info(e):
					events_and_status.events.append(MIDIEventChunkPlus.new(e, track.track_id))
				track.pointer += 1
				next_time = e_time
			elif e_time < next_time:
				next_time = e_time
		time = next_time

	events_and_status.last_position = events_and_status.events[-1].midi_event_chunk.time
	events_and_status.event_pointer = 0
	events_and_status.set_tempo(80)
	events_and_status.timebase = smf_data.timebase
	return events_and_status


func is_need_map_info(event: SMF.MIDIEventChunk)->bool:
# filter note_on, note_off, bpm_change only
	if not ((event.event.type == SMF.MIDIEventType.system_event and \
		event.event.args["type"] == SMF.MIDISystemEventType.set_tempo )\
		or event.event.type == SMF.MIDIEventType.note_on \
		or event.event.type == SMF.MIDIEventType.note_off):
			return false
	return true

func get_color_for_note(note, _velocity, track_number)->Color:
	var base_hue = 120.0  # 基础色相 (可以调整)
	var hue_step = 75  # 色相步长
	var saturation = 0.5  # 低饱和度
	var value = 0.8  # 不过于暗淡
	var color
	if (note % 12) in [1,3, 6, 8, 10]:
		# sharp note
		color = Color.from_hsv(fmod(base_hue + track_number * hue_step, 360) / 360, saturation, value * 0.78)
	else:
		color = Color.from_hsv(fmod(base_hue + track_number * hue_step, 360) / 360, saturation * 0.6, value)
	return color
	

