extends Control
class_name DialogueBox

signal dialogue_ended

onready var dialogue_player: DialoguePlayer = get_node("DialoguePlayer")

onready var name_label := get_node("Panel/Columns/Name") as Label
onready var text_label := get_node("Panel/Columns/Text") as Label

onready var button_next := get_node("Panel/Columns/ButtonNext") as Button
onready var button_finished := get_node("Panel/Columns/ButtonFinished") as Button

onready var portrait := $Portrait as TextureRect

var acting_pawn
var legit_children # Add & delete from here if options are encountered

func start(dialogue: Dictionary, pawn : PawnInteractive) -> void:
	# Reinitializes the UI and asks the DialoguePlayer to 
	# play the dialogue
	button_finished.hide()
	button_next.show()
	button_next.grab_focus()
	button_next.text = "Next"
	acting_pawn = pawn
	legit_children = $Panel/Columns.get_child_count()
	dialogue_player.start(dialogue)
	update_content()
	show()

func set_options(options : Array):
	for o in options:
		var btn = button_next.duplicate()
		btn.text = o
		$Panel/Columns.add_child(btn)
		# Disconnect "next" - I tried duplicating Finished instead since we do
		# need to end this convo, but then on_finish went 2nd & hid the dialogue
		btn.disconnect("pressed", self, "_on_ButtonNext_pressed")
		btn.connect("pressed", self, "_on_Option_pressed", [o])
	button_next.visible = false
	button_finished.visible = false

func _on_Option_pressed(option) -> void:
	Util.deleteExtraChildren($Panel/Columns, legit_children)
	_on_DialoguePlayer_finished()
	acting_pawn.actions = acting_pawn.get_node(option)
	acting_pawn.start_interaction()

func _on_ButtonNext_pressed() -> void:
	dialogue_player.next()
	update_content()


func _on_DialoguePlayer_finished() -> void:
	button_next.hide()
	# Check if this final dialogue is a choice or not
	var btns = $Panel/Columns.get_child_count()
	if btns <= legit_children:
		# If not, display the Done button
		button_finished.grab_focus()
		button_finished.show()


func _on_ButtonFinished_pressed() -> void:
	emit_signal("dialogue_ended")
	hide()


func update_content() -> void:
	var dialogue_player_name = dialogue_player.title
	name_label.text = dialogue_player_name
	text_label.text = dialogue_player.text
	portrait.texture = DialogueDatabase.get_texture(
		dialogue_player_name, dialogue_player.expression
	)
