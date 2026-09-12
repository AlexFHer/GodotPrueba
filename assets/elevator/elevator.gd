extends AnimatableBody3D

@export var elevatorPoints: Array[ElevatorPoint] = [];
@export var speed: float = 2.0;
@export var arriveDistance: float = 0.03;

var currentElevatorPoint: ElevatorPoint = null;
var currentElevatorPointIndex: int = 0;
var elevatorDirection: int = 1;

func _ready() -> void:
	if elevatorPoints.size() == 0 or elevatorPoints.size() == 1:
		print_debug("Elevator points not set")
		return;

	initialize();

func _physics_process(delta: float) -> void:
	if currentElevatorPoint == null:
		return;

	# Move the elevator towards the current elevator point
	var offset = currentElevatorPoint.global_position - global_position
	var maxDistance = speed * delta
	if offset.length() <= max(maxDistance, arriveDistance):
		_arrive_at_current_elevator_point()
		return

	global_position += offset.normalized() * maxDistance

  
func setCurrentElevatorPoint(elevatorPoint: ElevatorPoint) -> void:
	currentElevatorPoint = elevatorPoint

func initialize() -> void:
	translateToFirstPoint();
	currentElevatorPointIndex = 0
	elevatorDirection = 1
	setCurrentElevatorPoint(get_next_elevator_point(elevatorPoints[currentElevatorPointIndex]));

func translateToFirstPoint() -> void:
	# Move the elevator to the first point
	var firstPoint = elevatorPoints[0];
	global_position = firstPoint.global_position;

func _arrive_at_current_elevator_point() -> void:
	var reachedPoint = currentElevatorPoint
	global_position = reachedPoint.global_position
	currentElevatorPointIndex = elevatorPoints.find(reachedPoint)
	setCurrentElevatorPoint(null);
	await get_tree().create_timer(reachedPoint.waitTime, false).timeout;
	if not is_inside_tree():
		return

	var nextPoint = get_next_elevator_point(reachedPoint);
	GameLog.debug("Elevator moving to next point: %s" % nextPoint.name)
	setCurrentElevatorPoint(nextPoint);

func get_next_elevator_point(currentPoint: ElevatorPoint) -> ElevatorPoint:
	var pointIndex = elevatorPoints.find(currentPoint)
	if pointIndex == -1:
		pointIndex = currentElevatorPointIndex

	if pointIndex == elevatorPoints.size() - 1:
		elevatorDirection = -1
	elif pointIndex == 0:
		elevatorDirection = 1

	currentElevatorPointIndex = clampi(pointIndex + elevatorDirection, 0, elevatorPoints.size() - 1)
	return elevatorPoints[currentElevatorPointIndex]
