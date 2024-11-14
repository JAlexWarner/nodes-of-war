extends Control

# TODO: Switch to Array or Dictionary based on future roadmap
enum Timer_Designation {PLAYER = 1, NEUTRAL = 4}
# Originally 3 & 12

var connections = [[0,6],
[0,9],
[1,2],
[1,3],
[2,8],
[3,11],
[3,8],
[4,9],
[4,7],
[5,0],
[7,5],
[8,2],
[8,6],
[8,5],
[9,5],
[10,8],
[10,11]]

var island_locations = [[926, 111], [108, 84], [371, 110], [213, 295], [1105, 600], [734, 317], \
[668, 101], [830, 536], [468, 285], [1023, 333], [516, 523], [123, 545]]

@onready var controllers: Array[int]

@onready var island_grid = []

@onready var potential_actions = []

@onready var num_players = 1

var color_array: Array = [Color8(255,255,255), #White
Color8(0, 71, 171), #Cobalt Blue
Color8(60, 40, 80), #Amethyst
]

func new_potential_action_alternative(player_id, queued_island):
	if len(potential_actions[player_id]) == 1:
		var first_island = potential_actions[player_id][0]
		potential_actions[player_id].clear()
		print(potential_actions)
		if controllers[first_island] != player_id:
			print("TODO: Error for player not controlling the first island")
			return
		if first_island == queued_island:
			print("TODO: Error for same island picked twice")
			return
		if island_grid[first_island][queued_island] == 0:
			print("TODO: Error for islands not being connected")
			return
		# Only other option is that this is a valid action, RIGHT!?
		get_node(str(first_island))._spawn_outward_resource_blob(get_node(str(queued_island)))
		return
		
	potential_actions[player_id].append(queued_island)
	print(potential_actions)
	
func new_potential_action(player_id, queued_island):
	if len(potential_actions[player_id]) == 0:
		if controllers[queued_island] != player_id:
			print("TODO: Error for player not controlling the first island")
			return
		potential_actions[player_id].append(queued_island)
		get_node(str(queued_island))._modify_selection_aspect(true)
		return
	if len(potential_actions[player_id]) == 1:
		var first_island = potential_actions[player_id][0]
		if first_island == queued_island:
			get_node(str(queued_island))._modify_selection_aspect(false)
			potential_actions[player_id].clear()
			return
		if island_grid[first_island][queued_island] == 0:
			print("TODO: Error for islands not being connected")
			return
		get_node(str(first_island))._spawn_outward_resource_blob(get_node(str(queued_island)))
		return
	print("Something went wrong in new_potential_action()")
	get_tree().quit()

func color_change(island_id: int, new_owner: int):
	# Figure out new name and color for island
	var island_name = str(island_id)
	var new_color = color_array[new_owner]
	controllers[island_id] = new_owner
	
	# Make necessary updates to island
	get_node(island_name).get_node("Sprite2D").material.set_shader_parameter("color", new_color)
	
	for island_x in controllers:
		if island_x != island_id:
			return
	
	# All islands have the same owner
	print("Player " + str(new_owner) + " wins!")	
	
func resource_timer_change(island_id: int, new_owner_id: int):
	var timer_to_change = get_node(str(island_id)).get_node("ResourceTimer")
	if new_owner_id == 0:
		timer_to_change.stop()
		timer_to_change.wait_time = Timer_Designation.NEUTRAL
		timer_to_change.start()
		#get_node(str(island_id))._create_resource_timer(Timer_Designation.NEUTRAL)
	else:
		timer_to_change.stop()
		timer_to_change.wait_time = Timer_Designation.PLAYER
		timer_to_change.start()
 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func create_map_lines(connections_grid):
	for pair in connections_grid:
		island_grid[pair[0]][pair[1]] = 1
		island_grid[pair[1]][pair[0]] = 1
		
		var first_island = get_node(str(pair[0]))
		var second_island = get_node(str(pair[1]))
		
		var line := Line2D.new()
		line.points = [Vector2(first_island.position.x,first_island.position.y), Vector2(second_island.position.x,second_island.position.y)]
		line.width = 4
		line.set_z_index(-5)
		#line.antialiased = true
		line.set_default_color(Color(1,0,0))
		add_child(line)

func _ready():
	#####
	# TODO: Instantiate Island Map
	
	for island_index in range(len(island_locations)):
		var new_island_scene = load("res://Island Scene/Island.tscn")
		var island_instance = new_island_scene.instantiate()
		
		var new_pos = island_locations[island_index]
		island_instance.position = Vector2(new_pos[0], new_pos[1])
		island_instance.name = str(island_index)
		island_instance.island_id = island_index
		island_instance.current_resources = 1
	
		add_child(island_instance)
	
	#####
	
	potential_actions.resize(num_players + 1)
	for index in range(num_players + 1):
		potential_actions[index] = []
		
	var num_islands = 0

	for item in get_children():
		if item is Island:
			num_islands += 1
			
	var grid_width = num_islands
	
	# Controllers_i describes which player controls i-th Island
	controllers.resize(num_islands)
	controllers.fill(0)
	
	# Choose islands for players
	# Give Island 8 to Player 1
	controllers[8] = 1
	
	#var island_id_to_name = [] # If we change from the ith island being named i
	
	for i in range(num_islands):
		island_grid.append([])
		
		# Inform island of what its unique ID is
		get_node(str(i)).island_id = i
		
		# Setup Signals per island
		get_node(str(i)).added_to_potential_actions.connect(new_potential_action)
		get_node(str(i)).ownership_changed.connect(color_change)
		get_node(str(i)).ownership_changed.connect(resource_timer_change)
		get_node(str(i)).get_node("Sprite2D").material.set_shader_parameter("color", color_array[controllers[i]])

		# Attach Timers to each island's scene
		if controllers[i] == 0:
			get_node(str(i))._create_resource_timer(Timer_Designation.NEUTRAL)
		else:
			get_node(str(i))._create_resource_timer(Timer_Designation.PLAYER)
			get_node(str(i)).controlling_player = controllers[i]
				
		for j in range(num_islands):
			island_grid[i].append(0)
				
	create_map_lines(connections)
	pass

func update_size():
	#var size = get_viewport_rect().size
	#rect
	#set_size(size)
	pass
	
### Multiplayer Authority
#If we ever need to instantiate islands, use below code
#get_node(str(i)).get_node("Sprite2D").material.set_local_to_scene(true)
