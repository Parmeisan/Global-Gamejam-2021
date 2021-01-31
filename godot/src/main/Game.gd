# Responsible for transitions between the main game screens:
# combat, game over, and the map
extends Node

signal combat_started

const combat_arena_scene = preload("res://src/combat/CombatArena.tscn")
onready var transition = $Overlays/TransitionColor
onready var local_map = $LocalMap
onready var party = $Party as Party
onready var music_player = $MusicPlayer
onready var game_over_interface := $GameOverInterface
onready var gui := $GUI
onready var monster_collection_interface := $MonsterCollection

var transitioning = false
var combat_arena: CombatArena

# Debugging
var debug : Debugger
enum CAT { MAP = 0, FILE, BATTLE, DEBUG }

func _ready():
	debug = Debugger.new()
	debug.debugMessage(CAT.FILE, "Loading")
	QuestSystem.initialize(self, party)
	local_map.spawn_party(party)
	local_map.visible = true
	local_map.connect("enemies_encountered", self, "enter_battle")
	music_player.play_field_theme()
	debug.debugMessage(CAT.FILE, "Game load complete")

	# introTimer to clear intro screen
	introTimer = Timer.new()
	introTimer.set_wait_time(4)
	introTimer.connect("timeout", self, "enter_game") 
	add_child(introTimer)
	introTimer.start()

var introTimer
func enter_game():
	get_node("IntroScreen/TextureRect").visible = false
	introTimer.stop()


func enter_battle(formation: Formation):
	# Plays the combat transition animation and initializes the combat scene
	if transitioning:
		return

	gui.hide()
	music_player.play_battle_theme()

	transitioning = true
	yield(transition.fade_to_color(), "completed")

	remove_child(local_map)
	combat_arena = combat_arena_scene.instance()
	add_child(combat_arena)
	combat_arena.connect("victory", self, "_on_CombatArena_player_victory")
	combat_arena.connect("game_over", self, "_on_CombatArena_game_over")
	combat_arena.connect(
		"battle_completed", self, "_on_CombatArena_battle_completed", [combat_arena]
	)
	combat_arena.connect(
		"capture_reward", self, "_on_CombatArena_capture_reward", [combat_arena]
	)
	combat_arena.initialize(formation, party.get_active_members())

	yield(transition.fade_from_color(), "completed")
	transitioning = false

	combat_arena.battle_start()
	emit_signal("combat_started")


func _on_CombatArena_battle_completed(arena):
	# At the end of an encounter, fade the screen, remove the combat arena
	# and add the local map back
	gui.show()

	transitioning = true
	yield(transition.fade_to_color(), "completed")
	combat_arena.queue_free()

	add_child(local_map)
	yield(transition.fade_from_color(), "completed")
	transitioning = false
	music_player.stop()


func _on_CombatArena_player_victory():
	music_player.play_victory_fanfare()

func _on_CombatArena_capture_reward():
	pass

func _on_CombatArena_game_over() -> void:
	transitioning = true
	yield(transition.fade_to_color(), "completed")
	game_over_interface.display(GameOverInterface.Reason.PARTY_DEFEATED)
	yield(transition.fade_from_color(), "completed")
	transitioning = false



func _on_GameOverInterface_restart_requested():
	game_over_interface.hide()
	var formation = combat_arena.initial_formation
	combat_arena.queue_free()
	enter_battle(formation)


func _on_MonsterCollection_monster_collection_menu_summoned():
	var bg = monster_collection_interface.get_node("Background")
	monster_collection_interface.reload()
	bg.visible = !bg.visible

func _process(_delta):
	if(Input.is_action_just_released("ui_quicksave")):
		Data.saveCSV("saves/", "slimes", ".csv", monster_collection_interface.slimes)

