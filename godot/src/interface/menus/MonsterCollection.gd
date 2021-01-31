extends CanvasLayer

class_name MonsterCollection

signal monster_collection_menu_summoned()

var slimes = []
onready var party = $Background/Columns/Party
onready var collection = $Background/Columns/Collection
onready var artifacts = $Background/Columns/Artifacts

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

func _ready():
	pass # Replace with function body.

func _process(_delta):
	if(Input.is_action_just_released("ui_select")):
		emit_signal("monster_collection_menu_summoned")

enum TEMPLATE { IMG = 0, NAME, LEVEL, XP }
const FLAVOURS = [ "Red", "Blue", "Green" ]
const NAME_BASIC = [ "Red", "Blue", "Green" ]
const NAME_EVOLVED = [ "Fang", "Eye", "Scale" ]
const ARTIFACTS = [ "Fang", "Eye", "Scale" ]
var battler_path = "assets/sprites/battlers/"
var battler_ext = ".png"
var artifact_path = "assets/sprites/artifacts/"
var artifact_ext = ".png"

func reload():
	# First few children are labels etc and the main character; clear everything else and then start copying it
	while party.get_child_count() > 3:
		party.remove_child(party.get_child(3))
	var game = Util.getParent(self, "Game")
	for i in range(0, game.party.get_size() - 1):
		if Data.hasSlime(i) or Data.hasMonster(i):
			var t = party.get_node("PartyMember/PartyContainer").duplicate()
			var member = game.party.get_party_member(i)
			var img_file = FLAVOURS[i] + "_Slime_128"
			if Data.hasMonster(i):
				img_file = NAME_EVOLVED[i] + "_Monster"
			t.get_child(TEMPLATE.IMG).texture = Data.getTexture(battler_path, img_file, battler_ext)
			labelCell(t.get_child(1), TEMPLATE.NAME - 1, NAME_BASIC[i])
			labelCell(t.get_child(1), TEMPLATE.LEVEL - 1, "Level: " + str(member.stats.level))
			labelCell(t.get_child(1), TEMPLATE.XP - 1, "Strength: " + str(member.stats.strength))
			t.visible = true
			party.add_child(t)
	while collection.get_child_count() > 3:
		collection.remove_child(collection.get_child(3))
	for i in range(0, slimes.size()):
		var t = collection.get_node("CollMember/CollContainer").duplicate()
		var name = NAME_BASIC[i]
		var img_file = FLAVOURS[i] + "_Slime_128"
		if Data.hasMonster(i):
			name = NAME_EVOLVED[i]
			img_file = NAME_EVOLVED[i] + "_Monster"
		t.get_child(TEMPLATE.IMG).texture = Data.getTexture(battler_path, img_file, battler_ext)
		labelCell(t, TEMPLATE.NAME, name)
		t.visible = true
		collection.add_child(t)
	while artifacts.get_child_count() > 3:
		artifacts.remove_child(artifacts.get_child(3))
	for i in range(0, 3):
		if Data.hasArtifact(i):
			var t = artifacts.get_node("ArtifactMember/ArtifactContainer").duplicate()
			t.get_child(TEMPLATE.IMG).texture = Data.getTexture(artifact_path, ARTIFACTS[i], artifact_ext)
			labelCell(t, TEMPLATE.NAME, ARTIFACTS[i])
			t.visible = true
			artifacts.add_child(t)

func labelCell(t, posn, data):
	var lbl : Label = t.get_child(posn)
	lbl.text = str(data)

func ascend(i):
	Data.setSlime(i, false)
	Data.setArtifact(i, false)
	Data.setMonster(i, true)

func _on_AscendButton_button_down():
	for i in range(0, 3):
		if Data.hasSlime(i) and Data.hasArtifact(i) and not Data.hasMonster(i):
			ascend(i)
			reload()
			break

func merge():
	if slimes.size() > 0:
		# first collection item
		var m : Slime = slimes.pop_front()
		# determines type
		print("name? %s" % m.get_name())
		# merges into appropriate party member
		#var member = game.party.get_party_member(i)
	pass

func _on_MergeButton_button_down():
	merge()
