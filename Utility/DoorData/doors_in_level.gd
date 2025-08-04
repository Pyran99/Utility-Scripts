extends Node

#-------------------------------------------------------------------------------#
#                               DETAILS
# Handles setting the player position when using a door_trigger scene
# This uses the name of the door_trigger node, set in door_transition_data by body entered, 
#   \to find a corresponding door_trigger in the new level to set the players position 
# If a same name door_trigger node is NOT found in the new level, the player position will be set to either,
#   1. a marker position set in the level script,
#   2. the default_pos used as optional arg in func
# You can place door_trigger scenes anywhere in the scene tree, as they are found from groups
# The door_trigger scene uses an autoload SceneManager to load the next level
#                                SETUP
# 1. Add this scene to each level it will be used in
# 2. Add door_trigger scenes to each level. 
#   \The node names of each door_trigger must be the same as its corresponding door in the new level to use it's spawn position
# 3. Check collision layers for door_trigger. It should mask the player layer. The signal uses body entered, you can change to area
# 4. Create a DoorTransitionData resource & set the path to the preload below
#-------------------------------------------------------------------------------#

const DOORS_GROUP_NAME: String = "door_trigger"

var level
var player
## The resource that holds the name of the triggered door area
var door_transition_data: DoorTransitionData = preload("res://Utility/DoorData/door_name.tres")

func _ready():
    level = owner
    assert(level, "level not found")
    player = get_tree().get_first_node_in_group("player")
    assert(player, "player not found in %s" % level)
    # whether a door was used to change scene
    if door_transition_data.door_used.length() != 0:
        set_player_pos()

func set_player_pos(default_pos: Vector2 = Vector2.ZERO) -> void:
    var player_pos: Vector2 = Vector2.ZERO
    var doors = get_tree().get_nodes_in_group(DOORS_GROUP_NAME)
    for i in range(doors.size()):
        if doors[i].name.length() != door_transition_data.door_used.length():
            continue
        if doors[i].name == door_transition_data.door_used:
            player_pos = doors[i].spawn_pos
            break

    if player_pos != Vector2.ZERO:
        player.global_position = player_pos
    else:
        if level.get("player_spawn"):
            player.global_position = level.player_spawn.global_position
        else:
            player.global_position = default_pos

    door_transition_data.door_used = ""
