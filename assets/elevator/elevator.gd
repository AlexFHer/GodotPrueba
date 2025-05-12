extends AnimatableBody3D

@export var elevatorPoints: Array[ElevatorPoint] = [];
@export var speed: float = 2.0;

var currentElevatorPoint: ElevatorPoint = null;

func _ready() -> void:
	if elevatorPoints.size() == 0 or elevatorPoints.size() == 1:
		print_debug("Elevator points not set")
		return;

	initialize();

func _physics_process(delta: float) -> void:
	if currentElevatorPoint == null:
		return;
	# Move the elevator towards the current elevator point
	var direction = (currentElevatorPoint.global_position - global_position).normalized()
	var distance = speed * delta
	global_position += direction * distance
		
  
func setCurrentElevatorPoint(elevatorPoint: ElevatorPoint) -> void:
	disconnectFromLastElevatorPoint()
	currentElevatorPoint = elevatorPoint
	if elevatorPoint != null:
		connectToElevatorPoint(elevatorPoint)

func disconnectFromLastElevatorPoint() -> void:
	if currentElevatorPoint != null:
		currentElevatorPoint.elevatorPointReached.disconnect(on_elevator_point_reached)

func connectToElevatorPoint(elevatorPoint: ElevatorPoint) -> void:
	currentElevatorPoint = elevatorPoint
	elevatorPoint.elevatorPointReached.connect(on_elevator_point_reached)

func initialize() -> void:
	translateToFirstPoint();
	var secondPoint = elevatorPoints[1];
	setCurrentElevatorPoint(secondPoint);

func translateToFirstPoint() -> void:
	# Move the elevator to the first point
	var firstPoint = elevatorPoints[0];
	global_position = firstPoint.global_position;

func on_elevator_point_reached(reachedPoint: ElevatorPoint) -> void:
	setCurrentElevatorPoint(null);
	await get_tree().create_timer(reachedPoint.waitTime).timeout;
	var nextPoint = get_next_elevator_point(reachedPoint);
	print(nextPoint);
	setCurrentElevatorPoint(nextPoint);

func get_next_elevator_point(currentPoint: ElevatorPoint) -> ElevatorPoint:
	# Check if the current point is the last one
	if currentPoint == elevatorPoints[elevatorPoints.size() - 1]:
		# If it is, reverse the order of the points
		elevatorPoints.reverse()
		return elevatorPoints[1]  # Return the first point after reversing
	else:
		# If not, move to the next point
		var nextPoint = elevatorPoints[elevatorPoints.find(currentPoint) + 1]
		return nextPoint  # Return the next point