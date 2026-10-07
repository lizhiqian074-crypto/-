extends Node
func _ready() -> void:
	# Input actions are installed before Home; also usable when running Game alone.
	InputSetup.install()
	GameManager.go_to.call_deferred("Start")
