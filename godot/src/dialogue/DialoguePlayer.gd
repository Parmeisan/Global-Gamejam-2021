extends Node

class_name DialoguePlayer
signal started
signal finished

var title : String = ""
var text : String = ""
var expression : String

var _conversation : Array
var _index_current : int = 0

func _ready(): 
	#sfxPlayer.pause_mode = Node.PAUSE_MODE_PROCESS
	pass

func start(dialogue_dict):
	"""
	Takes a dictionary of conversation data returned by Dialogue.load()
	and stores it in an array
	"""
	emit_signal("started")
	_conversation = dialogue_dict.values()
	_index_current = 0
	_update()

func next():
	_index_current += 1
	if _conversation[_index_current].has("type"):
		var arg_1
		var arg_2
		var arg_3
		var type = _conversation[_index_current].type
		arg_1 = _conversation[_index_current].name
		if _conversation[_index_current].has("expression"):
			arg_2 = _conversation[_index_current].expression
		else:
			 arg_2 = ''
		if _conversation[_index_current].has('text'):
			arg_3 = _conversation[_index_current].text
		else: 
			arg_3 = ''
		if type == 'jump':
			_index_current = int(arg_1) - 1
		#if type == 'itemcheck':
		#	var item = arg_1
		#	var then = arg_2
		#	var el = arg_3
		#	if Gvars[item] == true: 
		#		_index_current = int(then) - 1
		#	else:
		#		_index_current = int(el) - 1
		#if type == 'raise':
		#	var item = arg_1
		#	Gvars[item] = true
		#	_index_current
			
	assert(_index_current <= _conversation.size())
	_update()

func _update():
	print(_index_current)
	if _conversation[_index_current].has("sfx") == true:
		var sfxID = _conversation[_index_current].sfx
		#sfxPlayer.diaMCspeech()
	if not _conversation[_index_current].has("type"):
		text = _conversation[_index_current].text
		title = _conversation[_index_current].name
		expression = _conversation[_index_current].expression
	if _index_current == _conversation.size() - 1:
		emit_signal("finished")
