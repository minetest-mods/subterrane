--These nodes used to be defined by subterrane but were pulled due to not wanting to force all mods that use it to create these nodes.
--For backwards compatibility they can still be defined here, however.

if minetest.setting_getbool("subterrane_enable_legacy_dripstone") then

subterrane.register_stalagmite_nodes("subterrane:dry_stal", {
	description = "Dry Dripstone",
	tiles = {
		"default_stone.png^[brighten",
	},
	groups = {cracky = 3, stone = 2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("subterrane:dry_flowstone", {
	description = "Dry Flowstone",
	tiles = {"default_stone.png^[brighten"},
	groups = {cracky = 3, stone = 1},
	is_ground_content = true,
	drop = 'default:cobble',
	sounds = default.node_sound_stone_defaults(),
})

-----------------------------------------------

subterrane.register_stalagmite_nodes("subterrane:wet_stal", {
	description = "Wet Dripstone",
	tiles = {
		"default_stone.png^[brighten^subterrane_dripstone_streaks.png",
	},
	groups = {cracky = 3, stone = 2, subterrane_wet_dripstone = 1},
	sounds = default.node_sound_stone_defaults(),
}, "subterrane:dry_stal")

minetest.register_node("subterrane:wet_flowstone", {
	description = "Wet Flowstone",
	tiles = {"default_stone.png^[brighten^subterrane_dripstone_streaks.png"},
	groups = {cracky = 3, stone = 1, subterrane_wet_dripstone = 1},
	is_ground_content = true,
	drop = 'default:cobble',
	sounds = default.node_sound_stone_defaults(),
})

end