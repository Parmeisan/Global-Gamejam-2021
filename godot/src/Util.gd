extends Node

# ===== String Manipulation =============================================

static func isnull(s):
	# The order is very important here, as some Null objects will throw errors on some of these tests
	if s == null: return true
	if len(s) == 0: return true
	if typeof(s) == TYPE_DICTIONARY: return false
	return typeof(s) == TYPE_NIL or s == "Null" or len(s) == 0

static func nvl(s, def):
	if isnull(s):
		return def
	else:
		return s

static func padNum(num : int, n : int):
	return Util.pad(str(num), '0', n, true)
static func pad(inString : String, c : String, n : int, before = false):
	var s = inString
	while len(s) < n:
		if before: s = c + s
		else: s = s + c
	return s
	
# ===== Dates ===========================================================

const MONTHS = [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ]
static func getStringDateUnix(dateUnix : int):
	var date = OS.get_datetime_from_unix_time(dateUnix)
	return getStringDate(date)
static func getStringDate(date : Dictionary):
	return str(date.year) + "-" + Util.MONTHS[date.month-1] + "-" + padNum(date.day, 2)

static func getStringTime(date : Dictionary):
	return str(date.hour) + ":" + str(date.minute) + ":" + padNum(date.second, 2)
	#year, month, day, weekday, dst (Daylight Savings Time), hour, minute, second.

# ===== Display =========================================================

static func getRect(sprite):
	var posTL = sprite.position + sprite.offset
	if sprite.centered: posTL -= (sprite.texture.size / 2)
	var size = Vector2(sprite.texture.size.x / sprite.hframes, sprite.texture.size.y)
	var rect = Rect2(posTL, size)
	return rect
static func clickSolid(sprite, posn):
	var d = sprite.texture.get_data()
	d.lock()
	var rect = getRect(sprite)
	if rect.has_point(posn):
		return (d.get_pixelv(posn - rect.position).a > 0.2)
	return false

static func getParent(me, pname):
	var limitter = 0
	var parent = me
	while pname != parent.get_name() and limitter < 15:
		parent = parent.get_parent()
	return parent

func deleteExtraChildren(grp, numToKeep : int):
	# First few children in every section are labels, templates, etc
	# So reloading lists means clearing everything else & recreating
	while grp.get_child_count() > numToKeep:
		grp.remove_child(grp.get_child(numToKeep))

# ===== File R/W ========================================================

static func parseGenericCSV(file):
	var props = []
	file.seek(0)
	var list = {}
	while !file.eof_reached(): 
		var line = file.get_csv_line()
		if len(props) == 0:
			props = line
		elif len(line) == len(props):
			var dict = {}
			for i in range(0, props.size()):
				dict[props[i]] = line[i]
				list[list.size()] = dict
	return list
