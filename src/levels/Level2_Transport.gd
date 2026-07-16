extends BaseLevel

@onready var basket_area: Area2D = $BasketArea
@onready var spikes_area: Area2D = $SpikesArea

func _ready() -> void:
	super._ready()
	basket_area.body_entered.connect(_on_basket_body_entered)
	spikes_area.body_entered.connect(_on_spikes_body_entered)

func _on_basket_body_entered(body: Node2D) -> void:
	if body is PhysicalBall:
		# Succes! Nivel completat
		complete_level()

func _on_spikes_body_entered(body: Node2D) -> void:
	if body is BasePlayer:
		body.trigger_respawn()
