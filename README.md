# Prisma MIDI (Prototype)


## What's it
If you want to play a piano score but don't know how to or don't want to practice, Prisma MIDI is what you are looking for.


Prisma MIDI maps a wrong keystroke to the nearest right key position, given by the score midi file. With a midi input device and a midi audio source, player can focus on the speed and velocity expression, without paying attention to key-locating and fingering.

## Details
### MIDI Input
Prisma MIDI get midi signals from a MIDI source.   
If you have no such a device, `ASDFGHJKL;` on computer keyboard can be used as input, those keys are mapped linearly across the keyboard. However, you will lose velocity expression.

### MIDI Output
Prisma MIDI will send the final processed MIDI signals to an output. On windows, the default output is Microsoft GS Wavetable Synth, which is laggy and crappy, don't use it unless no other choice.

### Select Tracks
A midi file has one or several tracks, select the tracks you want to auto / manual play.

### Manual-Prisma Tracks
Select the tracks you want to play manually. Other tracks will autoplay. 

We call notes from a manual-prisma track "prisma notes".

If an un-triggered prisma note reaches the end (top of the piano keys), the whole score's progress will pause. 

You can speed down the playing by utilizing this feature.


### TolerateLine
A keystroke can trigger the nearest prisma note that falls below the tolerate line. Horizontal and vertical distances are both considered. The triggered note will extends its buttom to the end.

You can play strums for chords under the tolerate line.

### AcceptLine

If there is no prisma note that falls below the tolerate line, but some fall below the accept line, the lowest(vertically) prisma note can be triggered by a keystroke. The whole score's progress will fast-forward until the prisma note reaches the tolerate line, and the note will be triggered the same way as for tolerate line part.

You can speed up the playing by utilizing this feature.

Accept line is always above the tolerate line.



### Ignore Free Note
Whether you can trigger a key without a valid prisma note. Enable it to prevent hitting extra wrong keys.

### Auto Follow

For notes from a autoplay track, the defaut setting is letting them reach the end and trigger them with the velocity in the midi file.

If velocity auto follow is enabled, the velocity to use will be the same as the last triggered prisma note.

If timing auto follow is enabled, the trigger position will be the same as the last triggered prisma note (above the end and below the tolerate line).

You can enable velocity and timing auto follow to get a more natural playing if some tracks are autoplaying.


### Alter Notes
Some people prefer the see wide white notes and thin black notes, enable it.


## Windows Tips
Currently it is hard to emulate Prisma MIDI as a midi output device on windows (a shocking truth. I cannot find a free open source impl). Therefore, you cannot directly set Prisma MIDI as your audio source's midi input. 

Please install [LoopMIDI](https://www.tobias-erichsen.de/software/loopmidi.html). Set Prisma MIDI's MIDI Output to a LoopMIDI input port.

Then for the audio source, set a LoopMIDI output port as midi input.

All done. The Prisma MIDI's final midi output signals will go to LoopMIDI. And LoopMIDI will forward those signals to your audio source.


## MacOS Tips
No macos build at the moment.

## Linux Tips
No linux build at the moment.


## Some Free Piano Audio Source
If you are not into the music / audio industry, you probably don't have any audio source installed. Here are some free piano source for you to begin with:


[LABS Soft Piano](https://labs.spitfireaudio.com/soft-piano)

[Studiologic Numa Player](https://www.studiologic-music.com/products/numaplayer/)

[99Sounds Upright Piano](https://99sounds.sellfy.store/p/8vh6xs/)

[Audiolatry Grand Piano](https://audiolatry.com/products/grand-piano)


You should install the stand-alone version. Plugin version (VST, AU, etc) can only be run within a [DAW](https://en.wikipedia.org/wiki/Digital_audio_workstation).







## Credits
Design and Program by [csric](https://csric.github.io/blog/)@[Cracking Sciences](https://cracking-sciences.github.io/)
Powered by [Godot Engine](https://godotengine.org/)
This project uses the following open source libraries:
- [rtmidi](https://github.com/thestk/rtmidi)
- [godot-rtmidi](https://github.com/NullMember/godot-rtmidi)