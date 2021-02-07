extends CanvasLayer

class_name MonsterCollection

signal monster_collection_menu_summoned()
signal toggle_encounters()

var slimes = [] # Enhanced & Primaries
var greys = [0, 0, 0] # Number owned of each grey difficulty
var allowed_greys = range(0, 2)
onready var grpParty = $Background/Columns/Col1/Party
onready var grpCollection = $Background/Columns/Col2/Collection
onready var grpArtifacts = $Background/Columns/Col1/Artifacts
onready var grpActions = $Background/Columns/Actions
onready var grpGreys = $Background/Columns/Col3/Greys

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

func add_grey(g: int) -> void:
	assert(g in allowed_greys)
	greys[g] += 1
func remove_grey(g: int) -> void:
	assert(g in allowed_greys)
	assert(greys[g] >= 1)
	greys[g] -= 1

func _ready():
	pass # Replace with function body.

func _process(_delta):
	if(Input.is_action_just_released("ui_select")):
		emit_signal("monster_collection_menu_summoned")
	if(Input.is_action_just_released("ui_toggle_encs")):
		emit_signal("toggle_encounters")

enum TEMPLATE { IMG = 0, NAME, LEVEL, XP }
const FLAVOURS = [ "Red", "Blue", "Yellow" ]
const NAME_BASIC = [ "Red", "Blue", "Yellow" ]
const NAME_EVOLVED = [ "Fang", "Eye", "Scale" ]
const ARTIFACTS = [ "Fang", "Eye", "Scale" ]
var battler_path = "assets/sprites/battlers/"
var battler_ext = ".png"
var artifact_path = "assets/sprites/artifacts/"
var artifact_ext = ".png"

func reload():
	grpActions.get_node("AscendButton").visible = checkAscendPossible()
	grpActions.get_node("AscendLabel").visible = checkAscendPossible()
	grpActions.get_node("MergeButton").visible = checkMergePossible()
	grpActions.get_node("MergeLabel").visible = checkMergePossible()
	# First few children are labels etc and the main character; clear everything else and then start copying it
	while grpParty.get_child_count() > 3:
		grpParty.remove_child(grpParty.get_child(3))
	var game = Util.getParent(self, "Game")
	# Party
	for i in range(0, game.party.get_size()):
		if Data.hasSlime(i) or Data.hasMonster(i):
			var t = grpParty.get_node("PartyMember/PartyContainer").duplicate()
			var member = game.party.get_party_member(i)
			var img_file = FLAVOURS[i] + "_Slime_128"
			if Data.hasMonster(i):
				img_file = NAME_EVOLVED[i] + "_Monster"
			t.get_child(TEMPLATE.IMG).texture = Data.getTexture(battler_path, img_file, battler_ext)
			labelCell(t.get_child(1), TEMPLATE.NAME - 1, NAME_BASIC[i])
			labelCell(t.get_child(1), TEMPLATE.LEVEL - 1, "Level: " + str(member.stats.level))
			labelCell(t.get_child(1), TEMPLATE.XP - 1, "Strength: " + str(member.stats.strength))
			t.visible = true
			grpParty.add_child(t)
	# Artifacts
	while grpArtifacts.get_child_count() > 3:
		grpArtifacts.remove_child(grpArtifacts.get_child(3))
	for i in range(0, 3):
		if Data.hasArtifact(i):
			var t = grpArtifacts.get_node("ArtifactMember/ArtifactContainer").duplicate()
			t.get_child(TEMPLATE.IMG).texture = Data.getTexture(artifact_path, ARTIFACTS[i], artifact_ext)
			labelCell(t, TEMPLATE.NAME, ARTIFACTS[i])
			t.visible = true
			grpArtifacts.add_child(t)
	# Collection (enhanced)
	while grpCollection.get_child_count() > 3:
		grpCollection.remove_child(grpCollection.get_child(3))
	for i in range(0, slimes.size()):
		var t = grpCollection.get_node("CollMember/CollContainer").duplicate()
		var name = "Red"#NAME_BASIC[i]
		var img_file = "Red" + "_Slime_128"#FLAVOURS[i]
		t.get_child(TEMPLATE.IMG).texture = Data.getTexture(battler_path, img_file, battler_ext)
		labelCell(t, TEMPLATE.NAME, name)
		t.visible = true
		grpCollection.add_child(t)
	# Primaries
	# Greys
	var greyCont = grpGreys.get_node("GreyMember/GreyContainer")
	greyCont.get_node("ValGreySolo").text = str(greys[0])
	greyCont.get_node("ValGreyDuo").text = str(greys[1])
	greyCont.get_node("ValGreyTrio").text = str(greys[2])

func labelCell(t, posn, data):
	var lbl : Label = t.get_child(posn)
	lbl.text = str(data)

func ascend(i):
	Data.setSlime(i, false)
	Data.setArtifact(i, false)
	Data.setMonster(i, true)

func checkAscendPossible():
	var poss = false
	for i in range(0, 3):
		if Data.hasSlime(i) and Data.hasArtifact(i) and not Data.hasMonster(i):
			poss = true
	return poss
func checkMergePossible():
	return (Data.hasSlime(0) or Data.hasMonster(0)) and slimes.size() > 0

func _on_AscendButton_button_down():
	for i in range(0, 3):
		if Data.hasSlime(i) and Data.hasArtifact(i) and not Data.hasMonster(i):
			ascend(i)
			reload()
			break

func merge():
	if checkMergePossible():
		# first collection item
		var m : Slime = slimes.pop_front()
		# merges into appropriate party member
		var game = Util.getParent(self, "Game")
		var member = game.party.get_party_member(0)
		member.stats.level += 1
		reload()

func _on_MergeButton_button_down():
	merge()
