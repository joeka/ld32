extends Node

var _current_scene = null
var _current_level_id = 0
var _current_path = null

var _replay_first = []
var _replay_events = []
var _replay = false

var _time = 0

var replay_delay = 3

var _levels = [
		"res://title.scn",
		"res://levels/level1.scn"
		]
var _credits_screen = "res://credits.scn"

var _enemies = []

var _bullets = []
var _bullet_counter = 0

func register_bullet( bullet ):
	_bullets.push_back( bullet )
func unregister_bullet( bullet ):
	_bullets.remove(_bullets.find( bullet ))
func get_bullets():
	return _bullets

func register_enemy( enemy ):
	_enemies.push_back(enemy)
func get_enemies():
	return _enemies

func get_current_level_id():
	return _current_level_id

func start():
	_time = 0
	for enemy in _enemies:
		enemy.start()

func bullet_caught( bullet ):
	_bullet_counter += 1
	if _bullet_counter == _bullets.size():
		next_scene() #TODO something fancier

func reset_replay():
	_replay_first = []
	_replay_events = []
	_time = 0
	
func get_current_level():
	return _current_level_id

func replay():
	_replay = true
	if _current_scene and _current_scene.get_node("ReplayCamera"):
		_current_scene.get_node("ReplayCamera").make_current()

func register_replay( node, type, opt1=null, opt2=null ):
	if type == "player":
		_replay_first.push_back( {"node": node, "type": type})
	elif type == "animation":
		_replay_events.push_back( {"time": _time + opt2, "node": node, "type": type, "opt1": opt1} )
	else:
		_replay_events.push_back( {"time": _time, "node": node, "type": type} )

var _once = true
var _replay_start_time = null
func _fixed_process( delta ):
	if _replay:
		if _once:
			_replay_start_time = _time
			_time += replay_delay
			_once = false
		if _time < _replay_start_time:
			for entry in _replay_first:
				entry["node"].replay()	
			_replay_first = []
			_replay_start_time = -666
		
		
		_time -= delta
		while _replay_events.size() > 0 and _replay_events[_replay_events.size() - 1]["time"] > _time:
			var entry = _replay_events[_replay_events.size() - 1]
			if entry.size() < 4:
				entry["node"].replay() 
			elif entry.size() < 5:
				entry["node"].replay(entry["opt1"])
			else:
				entry["node"].replay(entry["opt1"], entry["opt2"])
				
			_replay_events.remove(_replay_events.size() - 1)
		if _time <= 0:
			_replay = false
			_once = true
			#TODO do something. End event?
			reload_scene()
	else:
		_time += delta

func _ready():
	var root = get_tree().get_root()
	_current_scene = root.get_child( root.get_child_count() - 1 )
	if not _current_path and _levels.size() > 0:
		_current_path = _levels[0]
	
	set_process_input(true)
	set_fixed_process(true)
	reset_replay()

func _input(event):
	if event.is_action("reload_scene"):
		reload_scene()

func reload_scene():
	if _current_path != null:
		goto_scene( _current_path )

func goto_scene( path ):
	reset_replay()
	_bullets = []
	_enemies = []
	_bullet_counter = 0
	_current_path = path
	call_deferred( "_deferred_goto_scene", path )

func next_scene():
	_current_level_id += 1
	if _current_level_id == _levels.size():
		goto_scene(_credits_screen)
	else:
		goto_scene(_levels[_current_level_id])

func _deferred_goto_scene( path ):
	_current_scene.free()
	var s = ResourceLoader.load( path )
	_current_scene = s.instance()
	get_tree().get_root().add_child(_current_scene)
