extends CanvasLayer
class_name MonsterCollection

# Variables to be saved
var slimes = [] # Enhanced & Primaries
var greys = [0, 0, 0] # Number owned of each grey difficulty
var artifacts = [ null, null, null ]

# Calculated Variables
var game
var selected_1ST = NONE # Some actions require 2 choices, e.g. merging
var selected_2ND = NONE
var prev_result = NONE

# Constants
signal monster_collection_menu_summoned()
signal toggle_encounters()
const NONE = -1
var allowed_greys = range(0, 3)
onready var grpParty = $Background/Columns/Col1/Party
onready var grpCollection = $Background/Columns/Col2/Collection/GridContainer
onready var grpArtifacts = $Background/Columns/Col1/Artifacts
onready var grpActions = $Background/Columns/Actions
onready var grpGreys = $Background/Columns/Col3/Greys
onready var grpPrimaries = $Background/Columns/Col3/Primaries/PrimHeadings
onready var grpReds = $Background/Columns/Col3/Primaries/PrimCols/Reds
onready var grpBlues = $Background/Columns/Col3/Primaries/PrimCols/Blues
onready var grpYellows = $Background/Columns/Col3/Primaries/PrimCols/Yellows
var selected = Data.getTexture("assets/theme/button/", "selected", ".png")

# Artifact interface functions
func add_artifact(a):
	var artifact = Artifact.new(ARTIFACTS[a])
	artifacts[a] = artifact
func get_artifact_by_id(id):
	for a in range(artifacts.size()):
		if artifacts[a]:
			if artifacts[a].get_instance_id() == id:
				return artifacts[a]
	return null
# Slime Array interface functions
func add_slime(new_slime: Slime) -> void:
	slimes.resize(slimes.size() + 1)
	slimes[slimes.size() - 1] = new_slime
func remove_slime(target_pos: int) -> Slime:
	var rv = slimes[target_pos]
	slimes.remove(target_pos)
	return rv
func get_slime(target_pos: int) -> Slime:
	var rv = slimes[target_pos]
	return rv
# Greys
func add_grey(g: int) -> void:
	assert(g in allowed_greys)
	greys[g] += 1
func remove_grey(g: int) -> void:
	assert(g in allowed_greys)
	assert(greys[g] >= 1)
	greys[g] -= 1
# Filters
func get_primary_list(colour : int):
	return get_slimes_filtered(false, false, colour)
func get_enhanced_list():
	return get_slimes_filtered(false, true, -1)
func get_party_list():
	return get_slimes_filtered(true, true, -1)

func get_slimes_filtered(wants_party : bool, wants_enhanced : bool, wants_colour : int):
	var arr = []
	for s in slimes:
		if wants_party and s.is_in_party():
			arr.append(s) # We don't care in this case if primary or not
		elif not wants_party and not s.is_in_party():
			if wants_enhanced != s.is_primary() and wants_colour in [s.colour, -1]:
				arr.append(s)
	pass # gives me a chance to evaluate arr during debugging
	return arr
func get_slime_by_id(id):
	#for s in slimes:
	#	if s.get_instance_id() == id:
	#		return s
	for s in range(slimes.size()):
		if slimes[s].get_instance_id() == id:
			return slimes[s]
	return null

func is_slime(id):
	return true if get_slime_by_id(id) else false
func is_artifact(id):
	return true if get_artifact_by_id(id) else false

# Main functions
func _ready():
	game = Util.getParent(self, "Game")
	# FOR TESTING!
	#add_slime(game.create_slime(0))
	#add_slime(game.create_slime(0))
	#add_slime(game.create_slime(1))
	#add_slime(game.create_slime(2))

func _process(_delta):
	if(Input.is_action_just_released("ui_select")):
		emit_signal("monster_collection_menu_summoned")
	if(Input.is_action_just_released("ui_toggle_encs")):
		emit_signal("toggle_encounters")

const ARTIFACTS = [ "Fang", "Eye", "Scale" ]
var artifact_path = "assets/sprites/artifacts/"
var artifact_ext = "_128.png"

func reset():
	selected_1ST = NONE
	selected_2ND = NONE
	reload()

func reload():
	grpActions.get_node("AscendButton").visible = checkAscendPossible()
	grpActions.get_node("AscendLabel").visible = checkAscendPossible()
	grpActions.get_node("MergeButton").visible = checkMergePossible()
	grpActions.get_node("MergeLabel").visible = checkMergePossible()
	# Party ------------------------------------------------------------------------
	var add = grpParty.get_node("AddPartyMember").duplicate() # before it's removed
	Util.deleteExtraChildren(grpParty, 3)
	var sky = grpParty.get_node("PartyMember")
	for s in get_party_list():
		var b = sky.duplicate()
		handleButton(b, s)
		var t = b.get_node("PartyContainer")
		t.get_node("Icons/FavFavourite").visible = s.favourite
		t.get_node("Icons/FavNormal").visible = !s.favourite
		t.get_node("Image").texture = s.sprite_small
		var stats = t.get_node("Stats")
		labelCell(stats, 0, s.get_name())
		labelCell(stats, 1, "Level: %s, XP: %s" % [str(s.battler.get_level()), s.experience])
		labelCell(stats, 2, "Strength: " + str(s.battler.get_strength()))
		displayAbilityTracks(t.get_node("Abilities"), s, true)
		b.get_node("PartyContainer/Icons").visible = true
		t.get_node("Image").rect_position.x = 0 # Overlap with favourite
		grpParty.add_child(b)
	# Put back the AddPartyMember button, after everything else
	grpParty.add_child(add)
	add.visible = checkPartyPossible()
	# Artifacts --------------------------------------------------------------------
	Util.deleteExtraChildren(grpArtifacts, 3)
	for a in artifacts:
		if a:
			var b = grpArtifacts.get_node("ArtifactMember").duplicate()
			handleButton(b, a)
			var t = b.get_node("ArtifactContainer")
			t.get_child(0).texture = Data.getTexture(artifact_path, a.name, artifact_ext)
			labelCell(t, 1, a.name)
			var assgn = ""
			if a.is_assigned():
				assgn = a.slime.get_name()
			labelCell(t, 2, assgn)
			b.visible = true
			grpArtifacts.add_child(b)
	# Collection (enhanced) --------------------------------------------------------
	Util.deleteExtraChildren(grpCollection, 1)
	for s in get_enhanced_list():
		var b = grpCollection.get_node("CollMember").duplicate()
		handleButton(b, s)
		var t = b.get_node("CollContainer")
		t.get_node("Image").texture = s.sprite_small
		labelCell(t.get_node("Stats"), 0, s.get_name())
		displayAbilityTracks(t.get_node("Stats/Abilities"), s, false)
		b.visible = true
		grpCollection.add_child(b)
	# Primaries --------------------------------------------------------------------
	var grps = [ grpReds, grpBlues, grpYellows ]
	for g in range(0, grps.size()):
		if Data.hasSlime(g):
			grpPrimaries.get_child(g).modulate = Color(1,1,1,1)
		else:
			grpPrimaries.get_child(g).modulate = Color(1,1,1,0.125)
		var list = grps[g]
		Util.deleteExtraChildren(list, 1)
		for s in get_primary_list(g):
			var b = list.get_node("Button").duplicate()
			handleButton(b, s)
			var t = b.get_node("Member")
			labelCell(t, 0, s.get_name().substr(0, 8))
			labelCell(t, 1, s.current_xp)
			t.get_node("FavFavourite").visible = s.favourite
			t.get_node("FavNormal").visible = !s.favourite
			b.visible = true
			list.add_child(b)
	# Greys ------------------------------------------------------------------------
	var greyCont = grpGreys.get_node("GreyMember/GreyContainer")
	greyCont.get_node("ValGreySolo").text = str(greys[0])
	greyCont.get_node("ValGreyDuo").text = str(greys[1])
	greyCont.get_node("ValGreyTrio").text = str(greys[2])

func labelCell(t, posn, data):
	var lbl : Label = t.get_child(posn)
	lbl.text = str(data)

func displayAbilityTracks(abilities, slime, show_none):
	for a in range(0, slime.ABILITIES.size()):
		for tier in range(0, slime.NUM_TIERS):
			var has_abil = slime.ability_tiers[a] > tier
			if has_abil or show_none:
				var icon_name = "none"
				if has_abil:
					icon_name = "Track%sTier%s" % [a, tier]
				icon_name += "_Tiny"
				var ab_icon = Data.getTexture("assets/sprites/abilities/", icon_name, ".png")
				var ab_node = TextureRect.new()
				ab_node.set_texture(ab_icon)
				ab_node.set_size(Vector2(32,32))
				ab_node.visible = true
				abilities.add_child(ab_node)

func handleButton(button, obj):
	# Every button's first child is a label with instance ID of corresponding slime (or artifact)
	labelCell(button, 0, obj.get_instance_id())
	# If this slime is selected, the button should reflect that
	var sel = obj.get_instance_id() in [selected_1ST, selected_2ND]
	#button.texture_pressed = selected
	button.toggle_mode = sel
	button.pressed = sel

func clickButton(button):
	var inst = int(button.get_node("InstanceID").text)
	if selected_1ST == NONE:
		selected_1ST = inst
	elif selected_2ND == NONE:
		selected_2ND = inst
	else:
		selected_2ND = selected_1ST
		selected_1ST = inst
	if selected_1ST == selected_2ND:
		selected_2ND = NONE
	reload()

func doAction(action : String):#btn : TextureRect):
	var s1 = get_slime_by_id(selected_1ST)
	var s2 = get_slime_by_id(selected_2ND)
	var a1 = get_artifact_by_id(selected_1ST)
	match action:
		"AddPartyMember":
			if checkPartyPossible():
				s1.party_slot = get_party_list().size()
				reset()
			#else
			#	game.script_manager.load_and_run({})
		"De-Party":
			s1.party_slot = NONE
			reset()
		"Unassign":
			a1.unassign()
			reset()
		"Merge":
			if checkMergePossible():
				var m = s1.merge(game, s2)
				var posn = slimes.find(s1)
				slimes.erase(s1)
				slimes.insert(posn, m)
				slimes.erase(s2)
				selected_1ST = m.get_instance_id()
				selected_2ND = NONE
				reload()

func ascend(s, a):
	var slime = get_slime_by_id(selected_1ST)
	var artifact = get_artifact_by_id(selected_2ND)
	artifact.assign(slime)
	slime.ascend(artifact)
	#Data.setSlime(i, false)
	#Data.setArtifact(i, false)
	#Data.setMonster(i, true)
	reset()

func checkAscendPossible():
	var s = selected_1ST
	var a = selected_2ND
	if a == NONE or s == NONE:
		return false
	elif is_slime(s) and is_artifact(a):
		return not get_artifact_by_id(a).is_assigned()
	elif is_slime(a) and is_artifact(s):
		# Not the expected order, and things will be easier if we can assume the order
		selected_1ST = a
		selected_2ND = s
		return not get_artifact_by_id(s).is_assigned()
	return false
func checkMergePossible():
	var s1 = selected_1ST
	var s2 = selected_2ND
	if s1 == NONE or s2 == NONE:
		return false
	if not is_slime(s1) or not is_slime(s2):
		return false
	s1 = get_slime_by_id(s1)
	s2 = get_slime_by_id(s2)
	if not s1.merge(game, s2):
		return false
	return true
	
	
func checkPartyPossible():
	if get_party_list().size() < game.party.PARTY_SIZE:
		if selected_1ST != NONE and selected_2ND == NONE:
			var slime = get_slime_by_id(selected_1ST)
			if slime:
				return !slime.is_in_party()
	return false


func _on_AscendButton_button_down():
	#for i in range(0, 3):
	#	if Data.hasSlime(i) and Data.hasArtifact(i) and not Data.hasMonster(i):
	if checkAscendPossible():
		ascend(selected_1ST, selected_2ND)

#func merge():
#	if checkMergePossible():
#		# first collection item
#		var m : Slime = slimes.pop_front()
#		# merges into appropriate party member
#		var game = Util.getParent(self, "Game")
#		var member = game.party.get_party_member(0)
#		member.stats.level += 1
#		reload()

func _on_MergeButton_button_down():
	#merge()
	doAction("Merge")

func _on_OpenMenu_pressed():
	emit_signal("monster_collection_menu_summoned")
func _on_CloseCollection_pressed():
	emit_signal("monster_collection_menu_summoned")
func show_overlay():
	$GameOverlay.visible = true
func hide_overlay():
	$GameOverlay.visible = false

