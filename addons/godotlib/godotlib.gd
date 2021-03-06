# godotlib.gd
#
# Copyright 2021 Bill Zissimopoulos

tool
extends EditorPlugin

func _enter_tree():
    add_custom_type("FlexibleMarginContainer", "MarginContainer", preload("FlexibleMarginContainer.gd"), null)
    add_custom_type("InputController2D", "Node", preload("InputController2D.gd"), null)
    add_custom_type("MultiplayerGame", "Node", preload("MultiplayerGame.gd"), null)

func _exit_tree():
    remove_custom_type("MultiplayerGame")
    remove_custom_type("InputController2D")
    remove_custom_type("FlexibleMarginContainer")
