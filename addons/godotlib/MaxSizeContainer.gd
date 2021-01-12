tool
extends Container

export var max_size: Vector2 setget set_max_size

func set_max_size(value):
    if max_size == value:
        return
    max_size = value
    queue_sort()

func _get_minimum_size():
    var min_size: Vector2
    for c in get_children():
        if not c.has_method("get_combined_minimum_size"):
            continue
        if c.is_set_as_toplevel():
            continue
        if not c.is_visible():
            continue
        var size: Vector2 = c.get_combined_minimum_size()
        if min_size.x < size.x:
            min_size.x = size.x
        if min_size.y < size.y:
            min_size.y = size.y
    return min_size

func _notification(what):
    match what:
        NOTIFICATION_SORT_CHILDREN:
            var size: Vector2 = get_size()
            var w: int = max_size.x if 0 != max_size.x and size.x > max_size.x else size.x
            var h: int = max_size.y if 0 != max_size.y and size.y > max_size.y else size.y
            var l: int = (size.x - w) / 2
            var t: int = (size.y - h) / 2
            for c in get_children():
                if not c.has_method("get_combined_minimum_size"):
                    continue
                if c.is_set_as_toplevel():
                    continue
                fit_child_in_rect(c, Rect2(l, t, w, h))
        NOTIFICATION_THEME_CHANGED:
            minimum_size_changed()
