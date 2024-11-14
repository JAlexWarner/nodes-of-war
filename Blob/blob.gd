class_name Blob
extends Node2D

@onready var resource_label: int

var originator: Control
var original_color

var target_island: Control

@onready var distance_vector: Array = [target_island.position.x - originator.position.x,
target_island.position.y - originator.position.y]

@onready var distance_magnitude: float = sqrt((distance_vector[0])**2 + (distance_vector[1])**2)
@onready var unit_vector: Array = distance_vector.map(func(i): return i/distance_magnitude)

# Assumes max blob value of 60
@onready var speed_modifier: float = 1 - ((.5 * resource_label - 1)/(59)) 

# TODO: Make the following math less corny
# Remake calculation for .4 instead of .48
@onready var scale_value = .06 + (resource_label * .007)

@onready var refuse_blob_combination = false

signal blob_resources_changed()
func resource_fusion(added_resources, other_position):
	resource_label = min(80, resource_label + added_resources)

	position.x = (position.x + other_position.x)/2
	position.y = (position.y + other_position.y)/2
	
	scale_value = .06 + (min(80, resource_label) * .006)
	%Sprite2D.set_scale(Vector2(scale_value,scale_value))
	
	speed_modifier = 1 - (.5 * (min(80, resource_label) - 1)/(79))
	
	blob_resources_changed.emit(resource_label)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#%Sprite2D.material.set_local_to_scene(true)
	%Sprite2D.material.set_shader_parameter("color", original_color)
	# Orange: Color8(255,165,0)
	
	### Test scale size
	%Sprite2D.set_scale(Vector2(scale_value,scale_value))
	
	%Label.text = str(resource_label)
	
	blob_resources_changed.connect(%Label._on_blob_resource_update)
	# TODO: change above when signal figured out
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position.x += unit_vector[0] * speed_modifier
	position.y += unit_vector[1] * speed_modifier

func _on_area_2d_area_entered(area: Area2D) -> void:
	# Check if we're encountering a Blob
	var potential_blob_partner = area.get_parent().get_parent()
	if potential_blob_partner is Blob:
		if refuse_blob_combination == true:
			print("Begin self-immolation")
			queue_free()
			return
			
		print("This will be the resulting blob")
		
		var other_blob_position = potential_blob_partner.position
		var other_blob_resources = potential_blob_partner.resource_label
		
		potential_blob_partner.refuse_blob_combination = true
		potential_blob_partner.queue_free()
		
		resource_fusion(other_blob_resources, other_blob_position)
	
	# Check if we're encountering an Island
	var collision_partner = area.get_parent().get_parent()
	if collision_partner is Island:
		if collision_partner == originator:
			pass
		elif collision_partner == target_island:
			# TODO: Blob Completion Logic
			target_island.receive_resources(originator.controlling_player, resource_label)
			queue_free()
		else:
			print("Hit a wrong Island")
