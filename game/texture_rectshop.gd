extends TextureRect

func _ready():
	var shader_material = ShaderMaterial.new()
	
	shader_material.shader = load("res://rounded_corners.gdshader")
	
	shader_material.set_shader_parameter("corner_radius", 20.0)
	
	material = shader_material
