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
var script_manager

# Debugging
var debug : Debugger
enum CAT { MAP = 0, FILE, BATTLE, DEBUG }

func _ready():
	debug = Debugger.new()
	debug.debugMessage(CAT.FILE, "Loading")
	QuestSystem.initialize(self, party)
	local_map.spawn_party(party)
	local_map.visible = true
	Data.map_difficulty = $LocalMap.map_difficulty
	local_map.connect("enemies_encountered", self, "enter_battle")
	music_player.play_field_theme()
	script_manager = DialogueAction.new()
	script_manager.initialize(local_map)
	prep_random()
	debug.debugMessage(CAT.FILE, "Game load complete")

	# introTimer to clear splash screen and then load introduction scripts
	introTimer = Timer.new()
	introTimer.set_wait_time(4)
	introTimer.connect("timeout", self, "enter_game") 
	add_child(introTimer)
	introTimer.start()

func switch_maps(new_map):
	local_map = new_map
	local_map.connect("enemies_encountered", self, "enter_battle")
	

var introTimer
func enter_game():
	get_node("IntroScreen/TextureRect").visible = false
	introTimer.stop()
	script_manager.load_and_run("res://src/dialogue/data/game_intro_01.json")
	## TODO Not actually yielding, but I guess it's all right for this scene
	yield(script_manager, "finished")
	local_map.get_node("GameBoard/Pawns/Usir-purple").visible = false


func set_party():
	var first_slime = get_node("Party/Robi")
	var second_slime = get_node("Party/Robi2")
	var third_slime = get_node("Party/Robi3")
	var first_monster = get_node("Party/Robi4")
	var second_monster = get_node("Party/Robi5")
	var third_monster = get_node("Party/Robi6")	
	#for testing puroses, definitely delete these flag sets if you see them:
	#Data.setSlime(0, true)
	#Data.setSlime(1, true)
	#Data.setSlime(2, true)
	#Data.setMonster(0, true)
	#Data.setMonster(1, true)
	#Data.setMonster(2, true)	
	first_slime.visible = Data.hasSlime(0) && !Data.hasMonster(0)
	second_slime.visible = Data.hasSlime(1) && !Data.hasMonster(1)
	third_slime.visible = Data.hasSlime(2) && !Data.hasMonster(2)	
	first_monster.visible = Data.hasMonster(0)
	second_monster.visible = Data.hasMonster(1)
	third_monster.visible = Data.hasMonster(2)

#func enter_battle(formation: Formation):
func enter_battle(formation: Array):
	# Plays the combat transition animation and initializes the combat scene
	if transitioning:
		return

	set_party()
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


# Random encounters
var RNG = RandomNumberGenerator.new()
var weight_total
func prep_random():
	weight_total = 0.0
	for w in range(0, Data.combat_weights.size()):
		weight_total += Data.combat_weights[w]
	RNG.randomize()

func random_encounter():
	#print("Chance of encounter: %s%%" % curr_combat_chance)
	var rnd = RNG.randf_range(0.0, 100.0)
	if rnd < Data.curr_combat_chance:
		var enc_rnd = RNG.randf_range(0.0, weight_total)
		var enc_check = 0.0
		Data.curr_combat_chance = 0.0
		#var enc = map.get_node("GameBoard/Pawns/" + Data.combat_types[enc_type])
		var enc = get_random_enemy_group()
		if Data.encounters_on and enc:
			local_map.start_encounter(enc)
	else:
		if Data.curr_combat_chance < Data.max_combat_chance:
			Data.curr_combat_chance += Data.combat_chance_inc

#func create_encounter(i):
#	var formation = Formation.new()
#	var enemy : Battler = $Enemies/RedSlime
#	formation.add_child(enemy)
#	enemy.owner = formation
#	var ps = PackedScene.new()
#	var result = ps.pack(formation)
#	if result == OK:
#		#var enc = MapAction.new()
#		#enc.formation = ps
#		return ps
#	else:
#		return null

#		var enc_type = 0
#		for w in range(0, Data.combat_weights.size()):
#			enc_check += Data.combat_weights[w]
#			if enc_rnd > enc_check:
#				enc_type += 1
func get_random_enemy_group():
	var enemy_array = []
	var diff = RNG.randi_range(1, Data.map_difficulty)
	print("Random encounter of difficulty %s!" % diff)
	while diff > 0:
		var e = RNG.randi_range(1, 3)
		if e > diff:
			e = diff
		#print("Enemy ", e)
		enemy_array.append($Enemies.get_child(e - 1))
		diff -= e
	#var node_arr = [$Enemies/RedSlime, $Enemies/RedSlime, $Enemies/RedSlime, $Enemies/RedSlime]
	return enemy_array

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

func _on_toggle_encounters():
	Data.encounters_on = !Data.encounters_on

func _process(_delta):
	if(Input.is_action_just_released("ui_quicksave")):
		Data.saveCSV("saves/", "slimes", ".csv", monster_collection_interface.slimes)
