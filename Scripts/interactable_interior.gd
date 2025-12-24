extends Node3D

@export var exit : bool = false
@export var gift_list: Array[PackedScene]
@export var area_spawn: CollisionShape3D

var can_interact: bool = false
var player

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact") && can_interact:
		if exit:
			Global.change_scene.emit()
		elif Global.house_list[Global.house_id] > 0 && Global.gifts_amount > 0:
			var playerscript: PlayerMovement = player
			playerscript.gift_amount.text = str(playerscript.gift_amount.text.to_int() - 1)
			Global.gifts_amount -= 1
			Global.house_list[Global.house_id] -= 1
			var i = randi_range(0, gift_list.size() - 1)
			var gift = gift_list[i].instantiate()
			add_child(gift)
			gift.position = Vector3( randf_range( -area_spawn.shape.radius, area_spawn.shape.radius), -0.15, randf_range( -area_spawn.shape.radius, area_spawn.shape.radius))

func _on_body_entered(body: Node3D) -> void:
	if body.get_class() == "CharacterBody3D":
		can_interact = true
		player = body

func _on_body_exited(body: Node3D) -> void:
	if body.get_class() == "CharacterBody3D":
		can_interact = false
		player = null
