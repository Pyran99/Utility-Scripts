extends RefCounted
class_name Utils


static func create_timer(timeout: float, one_shot: bool = true) -> Timer:
    var timer = Timer.new()
    timer.wait_time = timeout
    timer.one_shot = one_shot
    timer.autostart = true
    return timer


static func create_timer_with_callback(timeout: float, callback: Callable, one_shot: bool = true) -> Timer:
    var timer = create_timer(timeout, one_shot)
    timer.timeout.connect(callback)
    return timer


static func create_timer_with_deferred_callback(timeout: float, callback: Callable, one_shot: bool = true) -> Timer:
    var timer = create_timer(timeout, one_shot)
    timer.timeout.connect(func() -> void:
        callback.call_deferred()
    )
    return timer


static func create_timer_with_args(timeout: float, callback: Callable, args: Array, one_shot: bool = true) -> Timer:
    var timer = create_timer(timeout, one_shot)
    timer.timeout.connect(func() -> void:
        callback.callv(args)
    )
    return timer