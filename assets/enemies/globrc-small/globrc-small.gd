class_name GlobrcSmall extends Enemy

@onready var _rig: Node3D = $Rig
@onready var _animation_tree: AnimationTree = $Rig/AnimationTree

@export var patrolPoints: Array[PatrolPoint] = [];

@export var speed: float = 100.0
@export var attackDamage: int = 1

var currentPatrolPoint: PatrolPoint = null;

var canPatrol := true

func _ready():
	if patrolPoints.size() == 0:
		show_no_patrol_message()
		return

	set_initial_patrol_point()
	attach_to_patrol_points()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		# Play the attack animation which is an one shot
		print("Attack")
		_animation_tree.set("parameters/mele_attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _physics_process(delta: float) -> void:
	if canPatrol:
		patrol(delta)
	else:
		# If the enemy is not patrolling, stop moving
		velocity = Vector3.ZERO
	look_at_current_direction()
	move_and_slide()

func patrol(delta: float):
	# Check if the enemy is within a certain distance of the patrol point

	if currentPatrolPoint != null:
		# Move towards the patrol point
		move_to_point(currentPatrolPoint, delta)

func attach_to_patrol_points():
	# Attach the enemy to the patrol points
	for point in patrolPoints:
		point.patrolPointReached.connect(patrol_point_reached)

func move_to_point(point: Area3D, delta: float):
	# Move towards the patrol point
	var direction = (point.global_position - global_transform.origin).normalized()
	velocity = direction * speed * delta
	
	# Check if the enemy has reached the patrol point
	if global_transform.origin.distance_to(point.global_position) < 0.2:
		velocity = Vector3.ZERO
		return

func set_initial_patrol_point():
	# Set the initial patrol point to the first one in the list
	if patrolPoints.size() > 0:
		currentPatrolPoint = patrolPoints[0]
	else:
		show_no_patrol_message()
		return

func show_no_patrol_message():
	print("No patrol points set for GlobrcSmall. Please set patrol points in the inspector. ", name)

func look_at_current_direction():
	if velocity.length() > 0:
		_rig.global_rotation.y = velocity.angle_to(Vector3.FORWARD)


func patrol_point_reached():
	canPatrol = false
	var random = randi() % 3 + 3
	await get_tree().create_timer(random).timeout
	get_next_patrol_point()
	canPatrol = true


func get_next_patrol_point():
	# Get the next patrol point in the list taking into account current patrolPoint
	var indexOfCurrentPatrolPoint := patrolPoints.find(currentPatrolPoint)
	if indexOfCurrentPatrolPoint != -1:
		if indexOfCurrentPatrolPoint < patrolPoints.size() - 1:
			currentPatrolPoint = patrolPoints[indexOfCurrentPatrolPoint + 1]
		else:
			currentPatrolPoint = patrolPoints[0]
	else:
		currentPatrolPoint = patrolPoints[0]
