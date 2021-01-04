# InputController2D.gd
#
# Copyright 2021 Bill Zissimopoulos

# Handles input for its parent node.
#
# To use this node add it as a child of the node that must have its input handled.
# RigidBody2D, KinematicBody2D, generic Node2D and custom motion processing
# (via _process_motion) are supported.
#class_name InputController2D, "InputController2D.svg"
extends Node

# Emitted when the specified non-motion action is pressed.
signal action_pressed(action)

# Left motion action name.
export var motion_left: String = "ui_left"

# Right motion action name.
export var motion_right: String = "ui_right"

# Up motion action name.
export var motion_up: String = "ui_up"

# Down motion action name.
export var motion_down: String = "ui_down"

# Motion to apply when a motion action is pressed.
# The motion is interpretted as impulse for RigidBody2D and velocity for all other nodes.
export var motion: Vector2 = Vector2(100, 100)

# Non-motion actions that will emit action_pressed when pressed.
export var actions: Array = PoolStringArray()

var _parent: Node
var _process_motion_fn: FuncRef

func _notification(what):
    match what:
        NOTIFICATION_PARENTED:
            _parent = get_parent()
            if _parent.has_method("_process_motion"):
                _process_motion_fn = funcref(_parent, "_process_motion")
            elif _parent is RigidBody2D:
                _process_motion_fn = funcref(self, "_RigidBody2D_process_motion")
            elif _parent is KinematicBody2D:
                _process_motion_fn = funcref(self, "_KinematicBody2D_process_motion")
            elif _parent is Node2D:
                _process_motion_fn = funcref(self, "_Node2D_process_motion")
            else:
                _process_motion_fn = funcref(self, "_Node_process_motion")
        NOTIFICATION_UNPARENTED:
            _parent = null

func _RigidBody2D_process_motion(motion, _delta):
    _parent.apply_central_impulse(motion)

func _KinematicBody2D_process_motion(motion, _delta):
    _parent.move_and_slide(motion)

func _Node2D_process_motion(motion, delta):
    _parent.position.x += motion.x * delta
    _parent.position.y += motion.y * delta

func _Node_process_motion(motion, _delta):
    pass

func _physics_process(delta):
    var m: Vector2
    m.x = Input.get_action_strength(motion_right) - Input.get_action_strength(motion_left)
    m.y = Input.get_action_strength(motion_down) - Input.get_action_strength(motion_up)
    m = m.normalized()
    m.x *= motion.x
    m.y *= motion.y
    _process_motion_fn.call_func(m, delta)

func _unhandled_input(event):
    if not event.is_action_type():
        return
    for action in actions:
        if event.is_action_pressed(action):
            emit_signal("action_pressed", action)
