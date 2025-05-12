class_name ElevatorPoint extends Area3D

#Time the elevator will wait at this point
@export var waitTime: float = 5.0;

signal elevatorPointReached(currentPoint: ElevatorPoint);

func _on_body_entered(body:Node3D) -> void:
  if body.is_in_group("Elevator"):
    print_debug("Elevator point reached")
    elevatorPointReached.emit(self)
