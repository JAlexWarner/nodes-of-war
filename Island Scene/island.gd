extends Control
class_name Island

var controlling_player: int = 0
var island_id: int
var current_resources: int = 1
var current_color 

@onready var selected = false

func _modify_selection_aspect(new_selection_value):
	selected = new_selection_value
	if(selected):
		%Sprite2D.material.set_shader_parameter("glow_bool", true)
	else:
		%Sprite2D.material.set_shader_parameter("glow_bool", false)
	
signal ownership_changed()
func change_owner(new_owner: int):
	controlling_player = new_owner
	ownership_changed.emit(island_id, new_owner)

signal resources_changed()
func increment_resources():
	if current_resources < 120:
		current_resources += 1
		resources_changed.emit(current_resources)
	
func halve_resources() -> int:
	var blob_resources = int(floor(float(current_resources)/2))
	current_resources -= blob_resources
	resources_changed.emit(current_resources)
	return blob_resources
	
func receive_resources(player_id: int, incoming_blob_resources):
	# If receiving from allied blob
	if player_id == controlling_player:
		current_resources = min(120, current_resources + incoming_blob_resources)
		resources_changed.emit(current_resources)
	
	# If receiving from enemy blob
	if player_id != controlling_player:
		current_resources -= incoming_blob_resources
		
		if current_resources == 0:
			# If already netral
			if controlling_player == 0:
				resources_changed.emit(current_resources)
				return
			# If changing from player owned to neutral
			change_owner(0)
			resources_changed.emit(current_resources)
			return
			
		elif current_resources < 0:
			current_resources = -1 * current_resources
			change_owner(player_id)
			resources_changed.emit(current_resources)
			return
		
		resources_changed.emit(current_resources)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#%Sprite2D.material.set_local_to_scene(true)
	
	resources_changed.connect(%Label._on_resources_label_update)
	%Label.text = str(current_resources)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func _create_resource_timer(wait) -> void:
	var timer := Timer.new()
	add_child(timer)
	timer.wait_time = wait	
	timer.timeout.connect(_resource_timer_timeout)
	timer.name = "ResourceTimer"
	timer.start()
	
func _resource_timer_timeout() -> void:
	increment_resources()

#TODO: Figure out how to make sprite glow then unglow after unclicked
func _on_button_pressed() -> void:
	%Sprite2D.set_modulate(Color8(62, 164, 140))
	pass
	
# _island_destination
func _spawn_outward_resource_blob(island_destination: Control) -> void:
	if current_resources < 2:
		# Early Propogate Error later
		# Figure out exception throwing
		return
		
	var blob_label: int = halve_resources()
	
	var new_blob_scene = load("res://Blob/Blob.tscn")
	var blob_instance = new_blob_scene.instantiate()
	
	blob_instance.originator = get_node("./")
	blob_instance.target_island = island_destination
	blob_instance.position = Vector2(get_node("./").position)
	blob_instance.resource_label = blob_label
	blob_instance.original_color = %Sprite2D.material.get_shader_parameter("color")
	
	get_parent().add_child(blob_instance)

func _incoming_resources() -> void:
	pass

signal added_to_potential_actions()
func _on_button_button_down() -> void:
	added_to_potential_actions.emit(1, island_id)
