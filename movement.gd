extends CharacterBody3D


#@export var crouch_enabled = true
@export var slide_enabled = true

@export var base_speed = 12
@export var sprint_speed = 16
@export var jump_velocity = 6
@export var sensitivity = 0.1
@export var accel = 10
@export var crouch_speed = 3
@export var slide_speed = 0
@export var wall_run_tilt_angle : float = 45.0
@export var dash_dist = 10

signal significant_action

enum State {
	WALKING,
	JUMPING,
	SLIDING,
	WALL_RUNNING,
	WALL_JUMPING,
	SLAMMING,
	FALLING,
}

@export var state: State

var is_sigact = false
var speed = base_speed
#var sprinting = false
#var sliding = false
#var crouching = false
#var wall_running = false
var camera_fov_extents = [75.0, 85.0] #index 0 is normal, index 1 is sprinting
var base_player_y_scale = 1.0
var crouch_player_y_scale = 0.25
var wall_normal
var w_runnable = false

var slide_started = false  # New variable to track if slide has started

var jump_count = 0

@onready var parts = {
	"head": $Head,
	"camera": $Head/Camera3D,
	"body": $CollisionShape3D,
	"collision": $CollisionShape3D,
	"timer": $Timer,
}
#@onready var world = get_parent()
@onready var timer = $Timer

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var direction = Vector3()

var current_tilt_angle: float
var wallrun_angle = 15
var side = Vector3()

var iscaptured: bool

func show_glitch():
	pass
	#if is_sigact:
	#	parts.glitch_shader.visible = true
#		parts.bw_shader.visible = true
#	else:
#		parts.glitch_shader.visible = false
		#parts.bw_shader.visible = false

func wall_run(delta):
	if w_runnable and is_on_wall_only():
		parts.camera.rotation_degrees.y = lerp(parts.camera.rotation_degrees.y, float(parts.camera.rotation_degrees.y), 0.0)
		wall_normal = get_slide_collision(0).get_normal()
		velocity = Vector3(velocity.x ,0, velocity.z)
		side = wall_normal.cross(Vector3.UP)
		jump_count = 0
		direction = -wall_normal * speed
		#wall_running = true
		state = State.WALL_RUNNING
		#speed = sprint_speed
		speed *= 3
		parts.camera.fov = lerp(parts.camera.fov, camera_fov_extents[1], 10*delta)
		parts.camera.rotation_degrees.y = lerp(parts.camera.rotation_degrees.y, 0.0, 1)
		if Input.is_action_just_pressed("MOVE_JUMP"):
			if state == State.WALL_RUNNING:
				state = State.WALL_JUMPING
				significant_action.emit()
				velocity += wall_normal * base_speed
				w_runnable = true
				jump_count = 0
		if not is_on_floor():
			var to_rot
			if abs(fmod(parts.head.rotation_degrees.y, 360.0)) < 90.0:
				if side.dot(Vector3.RIGHT) > 0:
					to_rot = wallrun_angle
					#print("a", to_rot , " " , abs(fmod(parts.head.rotation_degrees.y, 360.0)), " ", side.dot(Vector3.RIGHT))
				else:
					to_rot = -wallrun_angle
					#rint("b", to_rot , " " , abs(fmod(parts.head.rotation_degrees.y, 360.0)), " ", side.dot(Vector3.RIGHT))
			else:
				if side.dot(Vector3.RIGHT) <= 0:
					to_rot = wallrun_angle
					#print("c", to_rot , " " , abs(fmod(parts.head.rotation_degrees.y, 360.0)), " ", side.dot(Vector3.RIGHT))
				else:
					to_rot = -wallrun_angle
					#print("d", to_rot , " " , abs(fmod(parts.head.rotation_degrees.y, 360.0)), " ", side.dot(Vector3.RIGHT))

		# Set the rotation directly
			parts.camera.rotation_degrees.z = lerp(parts.camera.rotation_degrees.z, float(to_rot), 0.1)

func _reset_camera_rotation():
	parts.camera.rotation_degrees.z = lerp(parts.camera.rotation_degrees.z, 0.0, 0.1)


func _ready():
	if not is_multiplayer_authority(): return
	parts.camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED




func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	await get_tree().create_timer(0.125).timeout
	parts.collision.disabled = false

func escape():
	if Input.is_action_pressed("ACTION_ESCAPE"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	if not is_multiplayer_authority(): return
	
	escape()
	show_glitch()
	if Input.is_action_pressed("MOVE_SLIDE") and not (state == State.WALL_RUNNING):
		var slide_direction = Vector3()
		if !slide_started:
			slide_direction = Vector3(direction.x, 0, direction.z).normalized()
			slide_started = true

		#sliding = true
		state = State.SLIDING
		speed = slide_speed

		parts.camera.fov = lerp(parts.camera.fov, camera_fov_extents[1], 10*delta)
		parts.body.scale.y = lerp(parts.body.scale.y, crouch_player_y_scale, 20*delta) #change this to starting a crouching animation or whatever
		parts.collision.scale.y = lerp(parts.collision.scale.y, crouch_player_y_scale, 20*delta)
		velocity.x += (slide_direction.x * slide_speed) / (10 * delta) 
		velocity.z += (slide_direction.z * slide_speed) / (10 * delta) 
		
	else:
		#sprinting = false
		#crouching = false
		#sliding = false
		state = State.WALKING
		speed = base_speed
		sensitivity = 0.1
		parts.body.scale.y = lerp(parts.body.scale.y, base_player_y_scale, 20*delta) #change this to starting a crouching animation or whatever


		if slide_enabled:
			parts.camera.fov = lerp(parts.camera.fov, camera_fov_extents[0], 10*delta)

func slam():
	if not is_multiplayer_authority(): return
	if not is_on_floor() and (state == State.SLAMMING):
		significant_action.emit()
		velocity = Vector3(velocity.x, -50, velocity.z)
		state = State.SLAMMING

func jump():
	if not is_multiplayer_authority(): return
	if (is_on_floor() or jump_count < 3 or is_on_wall()) and state == State.JUMPING:
		velocity.y += jump_velocity
		jump_count += 1
		#if jump_count == 3:
			#velocity *= Vector3(1, 1, 1)
		timer.start()

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	wall_run(delta)

	if not is_on_floor():
		velocity.y -= (gravity * 1.3) * delta
		w_runnable = true
		#velocity.x = lerp(velocity.x, direction.x * 2, accel * delta)
		#velocity.z = lerp(velocity.z, direction.z * 2, accel * delta)
		state = State.FALLING
	else:
		if not state == State.SLIDING:
			velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, accel * delta)
			jump_count = 0
		w_runnable = false
		jump_count = 0  # Reset jump count when the jump key is released
	
	if not is_on_wall():
		_reset_camera_rotation()

	if Input.is_action_just_pressed("MOVE_SLIDE"):
		if not is_on_floor() and not (state == State.WALL_RUNNING):
			state = State.SLAMMING
			slam()
			  # Reset camera rotation when on floor

	if Input.is_action_just_pressed("MOVE_JUMP"):
		state = State.JUMPING
		jump()

	var input_dir = Input.get_vector("MOVE_LEFT", "MOVE_RIGHT", "MOVE_FORWARD", "MOVE_BACKWARD")
	direction = input_dir.normalized().rotated(-parts.head.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)

	if state == State.WALL_RUNNING:
		velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
		velocity.z = lerp(velocity.z, direction.z * speed, accel * delta)


	# bob head
	#if input_dir and is_on_floor() and not state == State.SLIDING:
		#parts.camera_animation.play("head_bob", 0.5)
	#else:
		#parts.camera_animation.play("reset", 0.5)

	move_and_slide()


func _input(event):
	if not is_multiplayer_authority(): return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if not is_on_wall_only():
			parts.head.rotation_degrees.y -= event.relative.x * sensitivity
		parts.head.rotation_degrees.x -= event.relative.y * sensitivity
		parts.head.rotation.x = clamp(parts.head.rotation.x, deg_to_rad(-90), deg_to_rad(90))	

func _on_pause():
	pass

func _on_unpause():
	pass

func _on_timer_timeout():
	w_runnable = false # Replace with function body.


func _on_significant_action():
	is_sigact = true
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.1).timeout
	while Engine.time_scale < 1:
		Engine.time_scale = lerp(Engine.time_scale, 1.0, 0.5)

	is_sigact = false
