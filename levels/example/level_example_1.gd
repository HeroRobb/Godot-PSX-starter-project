extends Level


enum CAMERA_IDS {
	SPINNING,
	SIDE,
	TOP,
}

const CAMERA_TRANSITION_DURATION_SECONDS = 2.0
const NEXT_SCENE = Global.LEVELS.TEST2

var active_camera_id: CAMERA_IDS = CAMERA_IDS.SPINNING
var finished: bool = false

var _transitioning_camera: bool = false
var _new_default_shaders: Array[int] = [
	Global.SHADERS.PSX_DITHER,
	Global.SHADERS.COLOR_PRECISION,
	Global.SHADERS.CRT,
	Global.SHADERS.GRAIN,
	Global.SHADERS.BLUR,
]

@onready var _camera_pivot: Node3D = %SpinningCameraPivot
@onready var _camera_spinning: Camera3D = _camera_pivot.get_child(0)
@onready var _camera_side: Camera3D = %CameraSide
@onready var _camera_top: Camera3D = %CameraTop
@onready var _cameras: Dictionary = {
	CAMERA_IDS.SPINNING: _camera_spinning,
	CAMERA_IDS.SIDE: _camera_side,
	CAMERA_IDS.TOP: _camera_top,
}


func _ready() -> void:
	super()
	SignalManager.camera_cut_requested.emit(_camera_spinning)
	SignalManager.pp_default_shaders_changed.emit(_new_default_shaders)
	SignalManager.pp_default_shaders_enabled_changed.emit(true)


func _input(event: InputEvent) -> void:
	if _transitioning_camera or finished:
		return
	
	if event.is_action_pressed("ui_accept"):
		cycle_cameras()
	elif event.is_action_pressed("change_scenes"):
		finished = true
		SignalManager.change_scene_requested.emit(NEXT_SCENE)
	elif event.is_action_pressed("ui_cancel"):
		finished = true
		get_tree().quit()


func _process(delta: float) -> void:
	_camera_pivot.rotate_y(delta)


func change_to_camera(camera_id: CAMERA_IDS) -> void:
	_transitioning_camera = true
	if _cameras[active_camera_id] == _camera_spinning:
		set_process(false)
	
	active_camera_id = camera_id
	var to_camera = _cameras[active_camera_id]
	
	SignalManager.camera_transition_requested.emit(to_camera, CAMERA_TRANSITION_DURATION_SECONDS)
	await SignalManager.camera_transition_finished
	
	_transitioning_camera = false
	set_process(to_camera == _camera_spinning)


func cycle_cameras() -> void:
	var next_camera_id: CAMERA_IDS = wrapi( active_camera_id + 1, 0, _cameras.size() )
	change_to_camera(next_camera_id)
