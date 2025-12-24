# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!
class_name PlayerMovement
extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var shooting : bool = false
var grav_multiplier : float = 1.0
var hooked : bool = false
var pull_point : Vector3
var extra_jump : bool = false
var rope
var follow_object: Node3D

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var ray: RayCast3D = $Head/RayCast3D
@onready var head_marker: Marker3D = $Marker3D
@onready var gift_amount: RichTextLabel = $Head/Camera3D/RichTextLabel
@onready var rope_start: Marker3D = $RopeStart

@export_group("Extra")
@export var hook_ui: TextureRect
@export var ui_controls: CanvasLayer
@export var ui_extra_jump: TextureRect

var rope_pack = preload("res://Models/rope.tscn")

func _ready() -> void:
	Global.change_scene.connect(delete_rope)
	rope = rope_pack.instantiate()
	get_tree().root.add_child.call_deferred(rope)
	rope.visible = false
	ui_extra_jump.visible = false
	gift_amount.text = str(Global.gifts_amount)
	check_input_mappings()
	look_rotation.y = head_marker.rotation.y
	look_rotation.x = head_marker.rotation.x
	capture_mouse()

func delete_rope() -> void:
	hooked = false
	rope.queue_free()

func _process(delta: float) -> void:
	head.global_transform = head_marker.get_global_transform_interpolated()

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	if extra_jump && Input.is_action_just_pressed(input_jump):
		velocity.y = jump_velocity * 2
		extra_jump = false
		ui_extra_jump.visible = false
		return
	
	if hooked:
		if global_position.distance_to(pull_point) < 5 || ray.is_colliding():
			ui_extra_jump.visible = true
		else:
			ui_extra_jump.visible = false
		if Input.is_action_just_pressed(input_jump) && ui_extra_jump.visible:
			velocity.y = jump_velocity * 2
			shooting = false
			hooked = false
			rope.visible = false
			ray.target_position.z = -30
			ui_extra_jump.visible = false
		elif global_position.distance_to(pull_point) > -5:
			if follow_object != null:
				pull_point = follow_object.global_position
			rope.look_at(pull_point)
			rope.global_position = (pull_point + rope_start.global_position) / 2
			rope.get_child(0).height = rope_start.global_position.distance_to(pull_point)
			rope.visible = true
			var motion := (pull_point - head.global_position).normalized()
			motion *= freefly_speed * delta
			move_and_collide(motion)
		if Input.is_action_just_pressed("aim"):
			shooting = false
			hooked = false
			rope.visible = false
			extra_jump = true
			ui_extra_jump.visible = true
			velocity.y = jump_velocity
			ray.target_position.z = -30
		return
	
	# Shooting grappling hook
	if Input.is_action_just_pressed("shoot") && !shooting && mouse_captured:
		shooting = true
		if ray.is_colliding():
			pull_point = ray.get_collision_point()
			if ray.get_collider().name == "SantaSleigh":
				follow_object = ray.get_collider()
			else:
				follow_object = null
			hooked = true
			ray.target_position.z = -2
		else:
			hook_ui.modulate = Color.RED
			await wait(1.2)
			shooting = false
			hook_ui.modulate = Color.WHITE
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * grav_multiplier * delta

	# Apply jumping
	if can_jump:
		if is_on_floor():
			extra_jump = false
			ui_extra_jump.visible = false
			if Input.is_action_just_pressed(input_jump):
				velocity.y = jump_velocity

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
			move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
	
	# Use velocity to actually move
	move_and_slide()


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head_marker.transform.basis = Basis()
	head_marker.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
	ui_controls.visible = false


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
	ui_controls.visible = true


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
