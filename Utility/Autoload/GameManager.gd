@icon("res://Assets/Packs/Kenney/Game Icons/gear.png")
extends Node
#AUTOLOAD

#const PAUSE_SCENE: PackedScene = preload("res://Scenes/UI/Options/pause_menu.tscn")
#const DEBUG_CONSOLE_PATH: String = "res://_Debug/debug_console.tscn"

signal toggle_game_paused(is_paused: bool)
signal game_state_changed(_game_state: GameStates)
signal level_state_changed(_level_state: LevelStates)
signal level_loaded(_level: Node2D)
signal level_unloaded(_level: Node2D)

enum GameStates {
    MENU,
    LOADING,
    PLAYING,
    PAUSED,
}
enum LevelStates {
    MENU,
    LOADING,
    GAME,
}
var game_state: GameStates = GameStates.MENU
var level_state: LevelStates = LevelStates.MENU

#var level: Level
var array_of_upgrades: Array[Resource]
var is_slowed: bool = false
var is_game_paused: bool = false: set = _set_game_paused
var debug_console: CanvasLayer = null
#var console_manager: DebugConsoleManager
var pause_menu: CanvasLayer


func _set_game_paused(value: bool) -> void:
    is_game_paused = value
    get_tree().paused = is_game_paused
    toggle_game_paused.emit(is_game_paused)


func _enter_tree() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    is_game_paused = false
    # EventBus.enemy_hit.connect(freeze_engine)
    #_create_debug_console()


#func _exit_tree() -> void:
    #_remove_cs_commands()
    #if console_manager != null:
        #console_manager._exit()


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        if level_state == LevelStates.MENU or level_state == LevelStates.LOADING: return
        pause_game()
        show_pause_menu()
        get_viewport().set_input_as_handled()
    #if event.is_action_pressed("translation_toggle_test"): # DEBUG
        #_cycle_translation()
    #if event.is_action_pressed("debug_console"):
        #_toggle_debug_console()
    #if event.is_action_pressed("DEBUG1"):
        #get_viewport().set_input_as_handled()
        #finish_level()


func show_pause_menu() -> void:
    if pause_menu != null: return
    var _ui = get_tree().get_first_node_in_group("ui")
    if _ui == null: return
    #pause_menu = PAUSE_SCENE.instantiate()
    _ui.add_child(pause_menu)
    # _level.add_child(pause_menu)


func finish_level() -> void:
    if level_state == LevelStates.MENU or level_state == LevelStates.LOADING: return
    var _ui = get_tree().get_first_node_in_group("ui")
    if _ui == null: return
    var _menu = load("res://Scenes/UI/Game/level_end_screen.tscn").instantiate()
    if pause_menu != null: pause_menu.queue_free()
    _ui.add_child(_menu)


func pause_game():
    is_game_paused = true
    change_game_state(GameStates.PAUSED)


func resume_game():
    is_game_paused = false
    change_game_state(GameStates.PLAYING)


func quit_game() -> void:
    get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
    get_tree().quit()


func change_game_state(_game_state: GameStates) -> void:
    if game_state == _game_state:
        return
    game_state = _game_state
    game_state_changed.emit(game_state)


func change_level_state(_level_state: LevelStates) -> void:
    if level_state == _level_state:
        return
    level_state = _level_state
    level_state_changed.emit(level_state)


func get_game_state() -> GameStates:
    return game_state

## slowdown game time when an enemy is hit -- from https://www.youtube.com/watch?v=_qxl7CalhDM 9:20.
## this could be used when defeating boss, with higher slow time
func freeze_engine() -> void:
    if is_slowed:
        return

    is_slowed = true
    # increasing the time can display effect from defeating boss or dealing crit
    Engine.time_scale = 0.07
    await get_tree().create_timer(0.3 * 0.07).timeout # time * slow
    Engine.time_scale = 1
    is_slowed = false


func _cycle_translation() -> void:
    if !OS.is_debug_build(): return
    var index = (SettingsManager.get_language_index_by_locale(TranslationServer.get_locale()) + 1) % SettingsManager.locale_list.size()
    SettingsManager.set_language(index)
    print("locale: ", TranslationServer.get_locale())


func _level_loaded(_level: Node2D = null) -> void:
    #level = _level
    #level_loaded.emit(level)
    pass


func _level_unloaded():
    #level_unloaded.emit(level)
    #Globals.player = null
    #level = null
    pass


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        #_exit_tree()
        pass


#region console
#
#func print_to_console(text: String, print_godot := false) -> void:
    #if debug_console == null: return
    #debug_console.print_line(text, print_godot)
#
#
#func _toggle_debug_console():
    #if !OS.is_debug_build(): return
    #if debug_console != null:
        #debug_console.visible = !debug_console.visible
        #return
    ##debug_console = load(DEBUG_CONSOLE_PATH).instantiate()
    #get_tree().root.add_child(debug_console)
#
#
#func _create_debug_console() -> void:
    ##if DebugConsoleManager.instance != null: return
    ##console_manager = DebugConsoleManager.new()
    #_add_cs_commands()
#
#
#func _add_cs_commands() -> void:
    #console_manager.add_command("quit", quit_game, [], 0, "quits the game")
    #console_manager.add_command("toggle_debug_collisions", _cs_debug_collisions, ["on/off"], 0, "Toggle debug collisions")
    #console_manager.add_command("toggle_debug_paths", _cs_debug_paths, ["on/off"], 0, "Toggle debug paths")
    #console_manager.add_command("toggle_debug_navigation", _cs_debug_navigation, ["on/off"], 0, "Toggle debug navigation")
    #console_manager.add_command("load_level", _cs_load_level, ["level", "arg1", "arg2"], 1, "Load a level. Call 'help' for a list of available levels. Args can be used to skip underscore")
    #console_manager.add_command("pause", pause_game, [], 0, "pause the game")
    #console_manager.add_command("resume", resume_game, [], 0, "resume the game")
    #console_manager.add_command("set_time_scale", _cs_set_time_scale, ["time scale"], 1, "set time scale")
    #console_manager.add_command("reset_time_scale", _cs_reset_time_scale, [], 0, "reset time scale to 1")
    #console_manager.add_command("language", _cs_set_language, ["locale"], 1, "set language using locale code")
#
#
#func _remove_cs_commands() -> void:
    #console_manager.remove_command("quit")
    #console_manager.remove_command("toggle_debug_collisions")
    #console_manager.remove_command("toggle_debug_paths")
    #console_manager.remove_command("toggle_debug_navigation")
    #console_manager.remove_command("load_level")
    #console_manager.remove_command("pause")
    #console_manager.remove_command("resume")
    #console_manager.remove_command("set_time_scale")
    #console_manager.remove_command("reset_time_scale")
#
#
#func _print_all_levels() -> void:
    #for _level in Levels.LevelNames.keys():
        #print_to_console(">> " + _level)
#
#
#func _print_all_languages() -> void:
    #for language in SettingsManager.locale_list:
        #print_to_console(">> " + language[Strings.LOCALE] + " | " + language["language"])
#
#
#func _cs_debug_collisions(value: String) -> void:
    #var tree := get_tree()
    #if value == "":
        #tree.debug_collisions_hint = !tree.debug_collisions_hint
        #return
    #var _value = console_manager.convert_string_arg_to_bool(value)
    #tree.debug_collisions_hint = _value
    #print_to_console(">> debug collisions: %s" % tree.debug_collisions_hint)
#
#
#func _cs_debug_paths(value: String) -> void:
    #var tree := get_tree()
    #if value == "":
        #tree.debug_paths_hint = !tree.debug_paths_hint
        #return
    #var _value = console_manager.convert_string_arg_to_bool(value)
    #tree.debug_paths_hint = _value
    #print_to_console(">> debug paths: %s" % tree.debug_paths_hint)
#
#
#func _cs_debug_navigation(value: String) -> void:
    #var tree := get_tree()
    #if value == "":
        #tree.debug_navigation_hint = !tree.debug_navigation_hint
        #return
    #var _value = console_manager.convert_string_arg_to_bool(value)
    #tree.debug_navigation_hint = _value
    #print_to_console(">> debug navigation: %s" % tree.debug_navigation_hint)
#
#
#func _cs_load_level(_level: String, arg1: String = "", arg2: String = "") -> void:
    #if _level.to_lower().match("help"):
        #_print_all_levels()
        #return
    #if arg1 != "":
        #_level += "_" + arg1
        #if arg2 != "":
            #_level += "_" + arg2
    #if _level.ends_with(" "):
        #_level = _level.trim_suffix(" ")
    #var _lvl = Levels.get_level_path(_level)
    #if _lvl == "":
        #print_to_console("invalid level: %s" % _level)
        #return
    #print_to_console(">> loading level: %s {%s}" % [_level, _lvl])
    #SceneManager.load_level(_lvl, false)
#
#
#func _cs_set_time_scale(value: String) -> void:
    #if value == "":
        #value = "1"
    #Engine.time_scale = value.to_float()
    #print_to_console(">> time scale set to %s" % Engine.time_scale)
#
#
#func _cs_reset_time_scale() -> void:
    #Engine.time_scale = 1
    #print_to_console(">> time scale reset to 1")
#
#
#func _cs_set_language(locale: String) -> void:
    #if locale.to_lower().match("help"):
        #_print_all_languages()
        #return
    #if locale.to_lower().match("reset"):
        #SettingsManager.set_language(0)
        #print_to_console(">> language set to %s" % locale)
        #return
    #var idx: int = -1
    #for _locale in SettingsManager.locale_list:
        #if _locale[Strings.LOCALE] == locale:
            #idx = SettingsManager.locale_list.find(_locale)
            #break
    #if idx == -1:
        #print_to_console("invalid locale: %s" % locale)
        #return
    #SettingsManager.set_language(idx)
    #print_to_console(">> language set to %s" % locale)


#endregion
