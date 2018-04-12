-- internationalization boilerplate
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

local x_disp = 0.125
local z_disp = 0.125


local stal_on_place = function(itemstack, placer, pointed_thing, itemname)
	local pt = pointed_thing
	-- check if pointing at a node
	if not pt then
		return itemstack
	end
	if pt.type ~= "node" then
		return itemstack
	end

	local under = minetest.get_node(pt.under)
	local above = minetest.get_node(pt.above)

	if minetest.is_protected(pt.above, placer:get_player_name()) then
		minetest.record_protection_violation(pt.above, placer:get_player_name())
		return
	end

	-- return if any of the nodes is not registered
	if not minetest.registered_nodes[under.name] or not minetest.registered_nodes[above.name] then
		return itemstack
	end
	-- check if you can replace the node above the pointed node
	if not minetest.registered_nodes[above.name].buildable_to then
		return itemstack
	end

	local new_param2
	-- check if pointing at an existing stalactite
	if minetest.get_item_group(under.name, "subterrane_stal_align") ~= 0 then
		new_param2 = under.param2
	else
		new_param2 = math.random(0,3)
	end

	-- add the node and remove 1 item from the itemstack
	minetest.add_node(pt.above, {name = itemname, param2 = new_param2})
	if not minetest.setting_getbool("creative_mode") then
		itemstack:take_item()
	end
	return itemstack
end


minetest.register_node("subterrane:dry_stal_1", {
	description = S("Dry Dripstone"),
	tiles = {
		"default_stone.png^[brighten",
	},
	groups = {cracky = 3, stone = 2, subterrane_stal_align = 1, fall_damage_add_percent=100, flow_through=1,},
	sounds = default.node_sound_stone_defaults(),
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = true,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.0625+x_disp, -0.5, -0.0625+z_disp, 0.0625+x_disp, 0.5, 0.0625+z_disp},
		}
	},
	on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, "subterrane:dry_stal_1")
	end,
})

minetest.register_node("subterrane:dry_stal_2", {
	description = S("Dry Dripstone"),
	tiles = {
		"default_stone.png^[brighten",
	},
	groups = {cracky = 3, stone = 2, subterrane_stal_align = 1, fall_damage_add_percent=50, flow_through=1,},
	sounds = default.node_sound_stone_defaults(),
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = true,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125+x_disp, -0.5, -0.125+z_disp, 0.125+x_disp, 0.5, 0.125+z_disp},
		}
	},
	on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, "subterrane:dry_stal_2")
	end,
})

minetest.register_node("subterrane:dry_stal_3", {
	description = S("Dry Dripstone"),
	tiles = {
		"default_stone.png^[brighten",
	},
	groups = {cracky = 3, stone = 2, subterrane_stal_align = 1, flow_through=1,},
	sounds = default.node_sound_stone_defaults(),
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = true,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.25+x_disp, -0.5, -0.25+z_disp, 0.25+x_disp, 0.5, 0.25+z_disp}, 
		}
	},
	on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, "subterrane:dry_stal_3")
	end,
})

minetest.register_node("subterrane:dry_stal_4", {
	description = S("Dry Dripstone"),
	tiles = {
		"default_stone.png^[brighten",
	},
	groups = {cracky = 3, stone = 2, subterrane_stal_align = 1, flow_through=1,},
	sounds = default.node_sound_stone_defaults(),
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = true,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.375+x_disp, -0.5, -0.375+z_disp, 0.375+x_disp, 0.5, 0.375+z_disp}, 
		}
	},
	on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, "subterrane:dry_stal_4")
	end,
})

minetest.register_node("subterrane:dry_flowstone", {
	description = S("Dry Flowstone"),
	tiles = {"default_stone.png^[brighten"},
	groups = {cracky = 3, stone = 1},
	is_ground_content = true,
	drop = 'default:cobble',
	sounds = default.node_sound_stone_defaults(),
})


-----------------------------------------------


minetest.register_node("subterrane:wet_stal_1", {
	description = S("Wet Dripstone"),
	tiles = {
		"default_stone.png^[brighten^subterrane_dripstone_streaks.png",
	},
	groups = {cracky = 3, stone = 2, subterrane_stal_align = 1, fall_damage_add_percent=100, subterrane_wet_dripstone = 1, flow_through=1,},
	sounds = default.node_sound_stone_defaults(),
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = true,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.0625+x_disp, -0.5, -0.0625+z_disp, 0.0625+x_disp, 0.5, 0.0625+z_disp},
		}
	},
	drop = "subterrane:dry_stal_1",
	on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, "subterrane:wet_stal_1")
	end,
})

minetest.register_node("subterrane:wet_stal_2", {
	description = S("Wet Dripstone"),
	tiles = {
		"default_stone.png^[brighten^subterrane_dripstone_streaks.png",
	},
	groups = {cracky = 3, stone = 2, subterrane_stal_align = 1, fall_damage_add_percent=50, subterrane_wet_dripstone = 1, flow_through=1,},
	sounds = default.node_sound_stone_defaults(),
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = true,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125+x_disp, -0.5, -0.125+z_disp, 0.125+x_disp, 0.5, 0.125+z_disp},
		}
	},
	drop = "subterrane:dry_stal_2",
	on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, "subterrane:wet_stal_2")
	end,
})

minetest.register_node("subterrane:wet_stal_3", {
	description = S("Wet Dripstone"),
	tiles = {
		"default_stone.png^[brighten^subterrane_dripstone_streaks.png",
	},
	groups = {cracky = 3, stone = 2, subterrane_stal_align = 1, subterrane_wet_dripstone = 1, flow_through=1,},
	sounds = default.node_sound_stone_defaults(),
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = true,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.25+x_disp, -0.5, -0.25+z_disp, 0.25+x_disp, 0.5, 0.25+z_disp}, 
		}
	},
	drop = "subterrane:dry_stal_3",
	on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, "subterrane:wet_stal_3")
	end,
})

minetest.register_node("subterrane:wet_stal_4", {
	description = S("Wet Dripstone"),
	tiles = {
		"default_stone.png^[brighten^subterrane_dripstone_streaks.png",
	},
	groups = {cracky = 3, stone = 2, subterrane_stal_align = 1, subterrane_wet_dripstone = 1, flow_through=1,},
	sounds = default.node_sound_stone_defaults(),
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = true,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.375+x_disp, -0.5, -0.375+z_disp, 0.375+x_disp, 0.5, 0.375+z_disp}, 
		}
	},
	drop = "subterrane:dry_stal_4",
	on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, "subterrane:wet_stal_4")
	end,
})

minetest.register_node("subterrane:wet_flowstone", {
	description = S("Wet Flowstone"),
	tiles = {"default_stone.png^[brighten^subterrane_dripstone_streaks.png"},
	groups = {cracky = 3, stone = 1, subterrane_wet_dripstone = 1},
	is_ground_content = true,
	drop = 'default:cobble',
	sounds = default.node_sound_stone_defaults(),
})
