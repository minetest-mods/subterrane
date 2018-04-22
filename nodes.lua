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

local stal_box_1 = {{-0.0625+x_disp, -0.5, -0.0625+z_disp, 0.0625+x_disp, 0.5, 0.0625+z_disp}}
local stal_box_2 = {{-0.125+x_disp, -0.5, -0.125+z_disp, 0.125+x_disp, 0.5, 0.125+z_disp}}
local stal_box_3 = {{-0.25+x_disp, -0.5, -0.25+z_disp, 0.25+x_disp, 0.5, 0.25+z_disp}}
local stal_box_4 = {{-0.375+x_disp, -0.5, -0.375+z_disp, 0.375+x_disp, 0.5, 0.375+z_disp}}

subterrane.register_stalagmite_nodes = function(base_name, base_node_def, drop_base_name)
	base_node_def.groups = base_node_def.groups or {}
	base_node_def.groups.subterrane_stal_align = 1
	base_node_def.groups.flow_through = 1
	base_node_def.drawtype = "nodebox"
	base_node_def.paramtype = "light"
	base_node_def.paramtype2 = "facedir"
	base_node_def.is_ground_content = true
	base_node_def.node_box = {type = "fixed"}
	
	base_node_def.groups.fall_damage_add_percent = 100
	base_node_def.node_box.fixed = stal_box_1
	base_node_def.on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, base_name.."_1")
	end
	if drop_base_name then
		base_node_def.drop = drop_base_name.."_1"
	end
	minetest.register_node(base_name.."_1", base_node_def)
	
	base_node_def.groups.fall_damage_add_percent = 50
	base_node_def.node_box.fixed = stal_box_2
	base_node_def.on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, base_name.."_2")
	end
	if drop_base_name then
		base_node_def.drop = drop_base_name.."_2"
	end
	minetest.register_node(base_name.."_2", base_node_def)

	base_node_def.groups.fall_damage_add_percent = nil
	base_node_def.node_box.fixed = stal_box_3
	base_node_def.on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, base_name.."_3")
	end
	if drop_base_name then
		base_node_def.drop = drop_base_name.."_3"
	end
	minetest.register_node(base_name.."_3", base_node_def)

	base_node_def.node_box.fixed = stal_box_4
	base_node_def.on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, base_name.."_4")
	end
	if drop_base_name then
		base_node_def.drop = drop_base_name.."_4"
	end
	minetest.register_node(base_name.."_4", base_node_def)
end

-----------------------------------------------

subterrane.register_stalagmite_nodes("subterrane:dry_stal", {
	description = S("Dry Dripstone"),
	tiles = {
		"default_stone.png^[brighten",
	},
	groups = {cracky = 3, stone = 2},
	sounds = default.node_sound_stone_defaults(),
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

subterrane.register_stalagmite_nodes("subterrane:wet_stal", {
	description = S("Dry Dripstone"),
	tiles = {
		"default_stone.png^[brighten^subterrane_dripstone_streaks.png",
	},
	groups = {cracky = 3, stone = 2, subterrane_wet_dripstone = 1},
	sounds = default.node_sound_stone_defaults(),
}, "subterrane:dry_stal")


minetest.register_node("subterrane:wet_flowstone", {
	description = S("Wet Flowstone"),
	tiles = {"default_stone.png^[brighten^subterrane_dripstone_streaks.png"},
	groups = {cracky = 3, stone = 1, subterrane_wet_dripstone = 1},
	is_ground_content = true,
	drop = 'default:cobble',
	sounds = default.node_sound_stone_defaults(),
})

-----------------------------------------------

subterrane.register_stalagmite_nodes("subterrane:icicle", {
	description = S("Icicle"),
	tiles = {
		"default_ice.png",
	},
	groups = {cracky = 3, puts_out_fire = 1, cools_lava = 1, slippery = 3},
	sounds = default.node_sound_glass_defaults(),
})
