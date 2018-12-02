local defaults = {}

defaults.perlin_cave = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=256, z=256},
	seed = -400000000089,
	octaves = 3,
	persist = 0.67
}

defaults.perlin_wave = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=256, z=512}, -- squashed 2:1
	seed = 59033,
	octaves = 6,
	persist = 0.63
}

defaults.perlin_warren_area = {
	offset = 0,
	scale = 1,
	spread = {x=1024, y=128, z=1024},
	seed = -12554445,
	octaves = 2,
	persist = 0.67
}

defaults.perlin_warrens = {
	offset = 0,
	scale = 1,
	spread = {x=32, y=12, z=32},
	seed = 600089,
	octaves = 3,
	persist = 0.67
}

local c_stone = minetest.get_content_id("default:stone")

defaults.column_def = {
	maximum_radius = 10,
	minimum_radius = 4,
	node = c_stone,
	weight = 0.25,
	maximum_count = 50,
	minimum_count = 0,
}

return defaults