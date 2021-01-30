extends CanvasLayer

class_name MonsterCollection

signal monster_collection_menu_summoned()

var slimes = []

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
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_party(0)

	pass # Replace with function body.

func _process(_delta):
	if(Input.is_action_just_released("ui_select")):
		emit_signal("monster_collection_menu_summoned")

	return

func add_to_party(target:int ) -> void:
	print("code 1")
	var party = get_node("../Party")
	var active = party.get_active_members()
	var active_count = active.size()
	#Don't go over max party size
	if(active_count >= party.PARTY_SIZE):
		return
	var partySlime: PartySlime = load("res://src/party/PartySlime.tscn").instance()
	var skin = partySlime.get_node("Battler/Skin")
	var anim = load("res://src/combat/animation/OrangeSlimeAnim.tscn").instance()
	skin.add_child(anim)
	
	var temp: BattlerAnim = anim
	
	skin.battler_anim = anim
	var pawn = partySlime.get_node("PawnAnim/Root")
	pawn.add_child(anim)
	
	partySlime.pawn_anim_path = "PawnAnim"
	partySlime.growth = load("res://src/combat/battlers/jobs/Redjob.tres")
	party.add_child(partySlime)
	print("code 2")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
