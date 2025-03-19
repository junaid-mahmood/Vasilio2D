extends Label

func _ready():
	update_text()

func _process(delta):
	update_text()

func update_text():
	text = str(Global.coins_collected) + "/" + str(Global.get_required_coins()) + " Coins"
