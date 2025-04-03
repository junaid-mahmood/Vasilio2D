extends TextureButton

signal shop_opened

func _ready():
	# Ensure we're using the correct signal connection format
	if not is_connected("pressed", Callable(self, "_on_shop_button_pressed")):
		connect("pressed", Callable(self, "_on_shop_button_pressed"))
	
	print("Shop button ready - click to open shop")

func _on_shop_button_pressed():
	print("Shop button pressed - opening shop")
	emit_signal("shop_opened") 
