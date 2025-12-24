extends Node3D
class_name InteractableExterior

@export var id_house: int = 0
@export var spotlight: CSGCylinder3D
@export var spawn_point: Marker3D
@export var gifts_deserved: int = 0
@export var santa_sleigh: bool = false
@export var path_progress: PathFollow3D

var can_interact: bool = false
var interacted: bool = false
var completed: bool = false
var player

func _process(delta: float) -> void:
	if completed && spotlight != null:
		spotlight.visible = false
	elif spotlight != null:
		spotlight.visible = true

func _physics_process(delta: float) -> void:
	if santa_sleigh:
		path_progress.progress += 10 * delta

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact") && can_interact:
		if !completed && !santa_sleigh:
			Global.gifts_deserved = gifts_deserved
			Global.spawn_point = spawn_point.global_position
			Global.house_id = id_house
			Global.change_scene.emit()
		elif santa_sleigh:
			Global.gifts_amount += 5
			var auxscript: PlayerMovement = player
			auxscript.gift_amount.text = str(Global.gifts_amount)

func _on_body_entered(body: Node3D) -> void:
	if body.get_class() == "CharacterBody3D" && !completed:
		can_interact = true
		player = body
		if spotlight != null:
			spotlight.visible = false

func _on_body_exited(body: Node3D) -> void:
	if body.get_class() == "CharacterBody3D":
		can_interact = false
		player = null
		if gifts_deserved > 0 && spotlight != null:
			spotlight.visible = true
