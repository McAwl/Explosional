extends Node


onready var _track_1 = $track_1
onready var _track_2 = $track_2
onready var _track_3 = $track_3

var last_track_played = 1
var timer = 0.0
var music = true
var current_track

func _ready():
	_track_1.volume_db = 0.0
	if music:
		_track_1.playing = true
		current_track = _track_1
	

func _process(delta):

	if Input.is_action_pressed("music_toggle"):
		if music == true:
			current_track.playing = false
			current_track.stream_paused = true
		else:
			current_track.playing = true
			current_track.stream_paused = false
		
	if music:
		
		var a=0

		if _track_1.playing==true:
			a+=1

		if _track_2.playing==true:
			a+=1

		if _track_3.playing==true:
			a+=1
		elif a == 0 and timer>5.0:
			#print("a="+str(a)+" last_track_played="+str(last_track_played))
			if last_track_played == 1:
				_track_2.playing = true
				_track_2.volume_db = 0.0
				last_track_played = 2
				current_track = _track_2
			elif last_track_played == 2:
				_track_3.playing = true
				_track_3.volume_db = 0.0
				last_track_played = 3
				current_track = _track_3
			else:
				_track_1.playing = true
				_track_3.volume_db = 0.0
				last_track_played = 1
				current_track = _track_1
			timer = 0.0
		elif a == 0 and timer<5.0:
			timer += delta

