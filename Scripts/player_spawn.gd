extends Node3D

@export var is_inside: bool = false

var player = preload("res://addons/proto_controller/proto_controller.tscn")

func _ready() -> void:
	var auxplayer : CharacterBody3D = player.instantiate()
	if !is_inside && Global.spawn_point != Vector3.ZERO:
		get_tree().root.add_child.call_deferred(auxplayer)
		auxplayer.global_position = Global.spawn_point
	else:
		add_child.call_deferred(auxplayer)
