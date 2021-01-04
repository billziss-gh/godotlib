# godotlib.gd
#
# Copyright 2021 Bill Zissimopoulos

tool
extends EditorPlugin

func _enter_tree():
    add_custom_type("InputController2D", "Node", preload("InputController2D.gd"), preload("InputController2D.svg"))

func _exit_tree():
    remove_custom_type("InputController2D")
