extends Node3D

var townLevel = preload("res://Scenes/world.tscn")
var houseLevel = preload("res://Scenes/house_interior.tscn")

var auxscene

func _ready() -> void:
	Global.gifts_amount = 10
	Global.gifts_deserved = -1
	Global.change_scene.connect(_change_scene)
	auxscene = townLevel.instantiate()
	add_child.call_deferred(auxscene)

func _change_scene() -> void:
	var old_scene: Node = auxscene
	if auxscene.name != "World":
		auxscene = townLevel.instantiate()
	else:
		auxscene = houseLevel.instantiate()
	remove_child(old_scene)
	if get_tree().root.get_node("ProtoController") != null:
		get_tree().root.get_node("ProtoController").queue_free()
	add_child(auxscene)
	old_scene.queue_free()
