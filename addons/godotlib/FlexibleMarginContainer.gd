tool
extends MarginContainer

export var content_max_size: Vector2 setget set_content_max_size

func set_content_max_size(value):
    if content_max_size == value:
        return
    content_max_size = value
    queue_sort()

func _notification(what):
    match what:
        NOTIFICATION_SORT_CHILDREN:
            var ml = get_constant("margin_left")
            var mt = get_constant("margin_top")
            var mr = get_constant("margin_right")
            var mb = get_constant("margin_bottom")
            var size: Vector2 = get_size()
            size.x -= ml + mr
            size.y -= mt + mb
            var w: float = min(size.x, content_max_size.x)
            var h: float = min(size.y, content_max_size.y)
            var l: float = ml + (size.x - w) / 2
            var t: float = mt + (size.y - h) / 2
            for c in get_children():
                if not c.has_method("get_combined_minimum_size"):
                    continue
                if c.is_set_as_toplevel():
                    continue
                fit_child_in_rect(c, Rect2(l, t, w, h))
        NOTIFICATION_THEME_CHANGED:
            minimum_size_changed()
