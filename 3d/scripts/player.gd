extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 8
const SENSITIVITY = 0.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var target = $camera_control/camera_target
@onready var camera = $camera_control/camera_target/Camera3D
@onready var control = $camera_control
@onready var player = $"."

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		
		if -event.relative.y > 0 and control.rotation_degrees.x>-45:
			control.rotation_degrees.x -= abs(-event.relative.y) * SENSITIVITY
		if -event.relative.y<0 and control.rotation_degrees.x<45:
			control.rotation_degrees.x += abs(-event.relative.y) * SENSITIVITY
		if -event.relative.x>0:
			control.rotation_degrees.y -= abs(-event.relative.x) * SENSITIVITY
			player.rotation_degrees.y -= abs(-event.relative.x) * SENSITIVITY
		if -event.relative.x<0:
			control.rotation_degrees.y += abs(-event.relative.x) * SENSITIVITY
			player.rotation_degrees.y +=  abs(-event.relative.x) * SENSITIVITY

func _physics_process(delta: float) -> void:

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	
	#new vector 3 direction, 	using camera rotation
	var direction = ($camera_control.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#rotate mesh according to direction of movement

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	move_and_slide()

	# Make camera control match player position
	$camera_control.position = lerp($camera_control.position, position,  0.10)
