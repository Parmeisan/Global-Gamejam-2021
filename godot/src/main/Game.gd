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
onready var monster_list := $MonsterCollection

export(Script) var game_save

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
	Data.setStartingWeights()
	local_map.connect("enemies_encountered", self, "enter_battle")
	music_player.play_field_theme()
	script_manager = DialogueAction.new()
	script_manager.initialize(local_map)
	debug.debugMessage(CAT.FILE, "Game load complete")

	# introTimer to clear splash screen and then load introduction scripts
	introTimer = Timer.new()
	introTimer.set_wait_time(4)
	introTimer.connect("timeout", self, "enter_game") 
	add_child(introTimer)
	introTimer.start()

func save_game():
	var save = game_save.new()

	save.flags = Data.flags
	save.disappeared = Data.disappeared
	save.character_position = local_map.grid.pawns.leader.position
	
	save.slimes = monster_list.slimes.duplicate(7)
	save.greys = monster_list.greys
	save.allowed_greys = monster_list.allowed_greys
	
	var error = ResourceSaver.save("res://src/saves/save01.tres", save)
	print("Attempting to save: " +  str(error))
	
func load_game() -> bool:
	print("attempting to load")
	var temp = Directory.new()
	if not temp.file_exists("res://src/saves/save01.tres"):
		print("It doesn't exist")
		return false
	var saved_game = load("res://src/saves/save01.tres")
	if not verify_save():
		return false
	Data.flags = saved_game.flags
	Data.disappeared = saved_game.disappeared
	
	monster_list.slimes = saved_game.slimes.duplicate(7)
	monster_list.greys = saved_game.greys
	monster_list.allowed_greys = saved_game.allowed_greys
	
	local_map.grid.pawns.leader.position = saved_game.character_position
	
	return true

func verify_save():
	return true

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

func flag_changed(fl, val):
	if (val):
		match fl:
			"SLIME0":
				unlock_slime(0)
				monster_list.show_overlay()
			"SLIME1":
				unlock_slime(1)
			"SLIME2":
				unlock_slime(2)
			"ARTIFACT0":
				unlock_artifact(0)
			"ARTIFACT0":
				unlock_artifact(1)
			"ARTIFACT0":
				unlock_artifact(2)

func create_slime(c):
	return Slime.new(c)

func unlock_slime(i):
	var slime = create_slime(i)
	slime.favourite = true
	monster_list.add_slime(slime)
	Data.addSlimeToRandom(i)
	# If there's room in the party for this Friend slime, add it
	var slot = monster_list.get_party_list().size()
	if (slot < party.PARTY_SIZE - 2): # Sky takes up a slot but we still start at 0
		slime.add_to_party(slot)

func unlock_artifact(i):
	monster_list.add_artifact(i)

#func enter_battle(formation: Formation):
func enter_battle(formation: Array, pawn : PawnInteractive = null):
	# Plays the combat transition animation and initializes the combat scene
	if transitioning:
		return

	gui.hide()
	monster_list.hide_overlay()
	music_player.play_battle_theme()

	transitioning = true
	yield(transition.fade_to_color(), "completed")

	remove_child(local_map)
	combat_arena = combat_arena_scene.instance()
	add_child(combat_arena)
	combat_arena.connect("victory", self, "_on_CombatArena_player_victory", [pawn])
	combat_arena.connect("defeat", self, "_on_CombatArena_player_defeat", [pawn])
	combat_arena.connect(
		"battle_completed", self, "_on_CombatArena_battle_completed", [combat_arena]
	)
	combat_arena.connect(
		"capture_reward", self, "_on_CombatArena_capture_reward", [combat_arena]
	)
	var active_party = party.get_active_members()
	for s in monster_list.get_party_list():
		active_party.append(s.clone(self))
	
	combat_arena.initialize(formation, active_party)

	yield(transition.fade_from_color(), "completed")
	transitioning = false

	combat_arena.battle_start()
	emit_signal("combat_started")


# Random encounters

func random_encounter():
	#print("Chance of encounter: %s%%" % curr_combat_chance)
	var rnd = Data.RNG.randf_range(0.0, 100.0)
	if rnd < Data.curr_combat_chance:
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

func get_random_enemy_group():
	var enemy_array = []
	var min_diff = floor(Data.map_difficulty * 2 / 3)
	var diff = Data.RNG.randi_range(min_diff, Data.map_difficulty)
	print("Random encounter of difficulty %s!" % diff)
	while diff > 0:
		var enc_type = 0
		var enc_rnd = Data.RNG.randf_range(0.0, Data.weight_total)
		var enc_check = 0.0
		for w in range(0, Data.combat_weights.size()):
			enc_check += Data.combat_weights[w]
			if enc_rnd > enc_check:
				enc_type += 1
		if Data.combat_diffs[enc_type] > diff:
			enc_type -= 1 # Can still go over the max, but not by too much
		#print("Enemy type %s name %s" % [enc_type, Data.generate_slime_name()])
		enemy_array.append($Enemies.get_child(enc_type))
		diff -= Data.combat_diffs[enc_type]
	return enemy_array

func _on_CombatArena_battle_completed(arena):
	# At the end of an encounter, fade the screen, remove the combat arena
	# and add the local map back
	gui.show()
	monster_list.show_overlay()

	transitioning = true
	yield(transition.fade_to_color(), "completed")
	combat_arena.queue_free()

	add_child(local_map)
	yield(transition.fade_from_color(), "completed")
	transitioning = false
	music_player.stop()


func _on_CombatArena_capture_reward():
	pass

func _on_CombatArena_player_victory(pawn : PawnInteractive):
	music_player.play_victory_fanfare()
	if pawn:
		pawn.update_state("Won")

func _on_CombatArena_player_defeat(pawn : PawnInteractive) -> void:
	# We don't want a complete game over
	combat_arena.rewards.on_defeated()
	if pawn:
		pawn.update_state("Lost")
	_on_CombatArena_battle_completed(combat_arena)
	# TODO: Set everyone's HP to 1
	
	
#	transitioning = true
#	yield(transition.fade_to_color(), "completed")
#	game_over_interface.display(GameOverInterface.Reason.PARTY_DEFEATED)
#	yield(transition.fade_from_color(), "completed")
#	transitioning = false


func _on_GameOverInterface_restart_requested():
	game_over_interface.hide()
	var formation = combat_arena.initial_formation
	combat_arena.queue_free()
	enter_battle(formation)


func _on_MonsterCollection_monster_collection_menu_summoned():
	var bg = monster_list.get_node("Background")
	var fg = monster_list.get_node("GameOverlay")
	bg.visible = !bg.visible
	fg.visible = !bg.visible
	if bg.visible:
		monster_list.reset()

func _on_toggle_encounters():
	Data.encounters_on = !Data.encounters_on

func _process(_delta):
	if(Input.is_action_just_released("ui_quicksave")):
		Data.saveCSV("saves/", "slimes", ".csv", monster_list.slimes)
	if(Input.is_action_just_pressed("save")):
		print("Pressed save")
		save_game()
	if(Input.is_action_just_pressed("load")):
		print("Pressed load")
		load_game()
