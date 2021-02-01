extends AudioStreamPlayer

const battle_theme = preload("res://assets/audio/bgm/battle_theme.ogg")
const field_theme = preload("res://assets/audio/bgm/field_theme.ogg")
const victory_fanfare = preload("res://assets/audio/bgm/victory_fanfare.ogg")

func play_battle_theme():
	volume_db = -16
	stream = battle_theme
	stop()
	play()

func play_field_theme():
	volume_db = -12
	stream = field_theme
	stop()
	play()

var victoryTimer
func play_victory_fanfare():
	#play_field_theme()
	volume_db = -8
	stream = victory_fanfare
	stop()
	play()
	# Timer to switch to field theme
	victoryTimer = Timer.new()
	victoryTimer.set_wait_time(4)
	victoryTimer.connect("timeout", self, "_on_victory_complete") 
	add_child(victoryTimer)
	victoryTimer.start()

func _on_victory_complete():
	play_field_theme()
	victoryTimer.stop()
