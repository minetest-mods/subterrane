local c_air = minetest.get_content_id("air")

---------------------------------------------------------------------------
-- For registering a set of stalactite/stalagmite nodes to use with the small stalactite placement function below

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

local simple_copy = function(t)
	local r = {}
	for k, v in pairs(t) do
		r[k] = v
	end
	return r
end

subterrane.register_stalagmite_nodes = function(base_name, base_node_def, drop_base_name)
	base_node_def.groups = base_node_def.groups or {}
	base_node_def.groups.subterrane_stal_align = 1
	base_node_def.groups.flow_through = 1
	base_node_def.drawtype = "nodebox"
	base_node_def.paramtype = "light"
	base_node_def.paramtype2 = "facedir"
	base_node_def.is_ground_content = true
	base_node_def.node_box = {type = "fixed"}
	
	local def1 = simple_copy(base_node_def)
	def1.groups.fall_damage_add_percent = 100
	def1.node_box.fixed = stal_box_1
	def1.on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, base_name.."_1")
	end
	if drop_base_name then
		def1.drop = drop_base_name.."_1"
	end
	minetest.register_node(base_name.."_1", def1)

	local def2 = simple_copy(base_node_def)
	def2.groups.fall_damage_add_percent = 50
	def2.node_box.fixed = stal_box_2
	def2.on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, base_name.."_2")
	end
	if drop_base_name then
		def2.drop = drop_base_name.."_2"
	end
	minetest.register_node(base_name.."_2", def2)

	local def3 = simple_copy(base_node_def)
	def3.node_box.fixed = stal_box_3
	def3.on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, base_name.."_3")
	end
	if drop_base_name then
		def3.drop = drop_base_name.."_3"
	end
	minetest.register_node(base_name.."_3", def3)

	local def4 = simple_copy(base_node_def)
	def4.node_box.fixed = stal_box_4
	def4.on_place = function(itemstack, placer, pointed_thing)
		return stal_on_place(itemstack, placer, pointed_thing, base_name.."_4")
	end
	if drop_base_name then
		def4.drop = drop_base_name.."_4"
	end
	minetest.register_node(base_name.."_4", def4)
	
	return {
		minetest.get_content_id(base_name.."_1"),
		minetest.get_content_id(base_name.."_2"),
		minetest.get_content_id(base_name.."_3"),
		minetest.get_content_id(base_name.."_4"),
	}
end

-------------------------------------------------------------------------------------------------
-- Use with stalactite nodes defined above

-- use a negative height to turn this into a stalactite
-- stalagmite_id is a table of the content ids of the four stalagmite sections, from _1 to _4.
function subterrane:small_stalagmite(vi, area, data, param2_data, param2, height, stalagmite_id)
	local pos = area:position(vi)
	
	local x = pos.x
	local y = pos.y
	local z = pos.z
	
	if height == nil then height = math.random(1,4) end
	if param2 == nil then param2 = math.random(0,3) end
	
	local sign, id_modifier
	if height > 0 then
		sign = 1
		id_modifier = 1 -- stalagmites are blunter than stalactites
	else
		sign = -1
		id_modifier = 0
	end
	
	data[vi] = c_air -- force the first node to be viable. It's assumed some testing was done before calling this function.
	for i = 1, math.abs(height) do
		vi = area:index(x, y + height - i * sign, z)
		if data[vi] == c_air then
			data[vi] = stalagmite_id[math.min(i+id_modifier,4)]
			param2_data[vi] = param2
		end
	end	
end

-------------------------------------------------------------------------------------------------
-- Builds very large stalactites and stalagmites

--giant stalagmite spawner
function subterrane:giant_stalagmite(vi, area, data, min_height, max_height, base_material, root_material, shaft_material)
	local pos = area:position(vi)
	local x = pos.x
	local y = pos.y
	local z = pos.z

	local top = math.random(min_height,max_height)
	for j = -2, top do --y
		for k = -3, 3 do
			for l = -3, 3 do
				if j <= 0 then
					if k*k + l*l <= 9 then
						local vi = area:index(x+k, y+j, z+l)
						if data[vi] == c_air then data[vi] = base_material end
					end
				elseif j <= top/5 then
					if k*k + l*l <= 4 then
						local vi = area:index(x+k, y+j, z+l)
						data[vi] = root_material
					end
				elseif j <= top/5 * 3 then
					if k*k + l*l <= 1 then
						local vi = area:index(x+k, y+j, z+l)
						data[vi] = shaft_material
					end
				else
					local vi = area:index(x, y+j, z)
					data[vi] = shaft_material
				end
			end
		end
	end
end

--giant stalactite spawner
function subterrane:giant_stalactite(vi, area, data, min_height, max_height, base_material, root_material, shaft_material)
	local pos = area:position(vi)
	local x = pos.x
	local y = pos.y
	local z = pos.z

	local bot = math.random(-max_height, -min_height) --grab a random height for the stalagmite
	for j = bot, 2 do --y
		for k = -3, 3 do
			for l = -3, 3 do
				if j >= -1 then
					if k*k + l*l <= 9 then
						local vi = area:index(x+k, y+j, z+l)
						if data[vi] == c_air then data[vi] = base_material end
					end
				elseif j >= bot/5 then
					if k*k + l*l <= 4 then
						local vi = area:index(x+k, y+j, z+l)
						data[vi] = root_material
					end
				elseif j >= bot/5 * 3 then
					if k*k + l*l <= 1 then
						local vi = area:index(x+k, y+j, z+l)
						data[vi] = shaft_material
					end
				else
					local vi = area:index(x, y+j, z)
					data[vi] = shaft_material
				end
			end
		end
	end
end

----------------------------------------------------------------------------------------
-- Giant mushrooms

--function to create giant 'shrooms. Cap radius works well from about 2-6
--if ignore_bounds is true this function will place the mushroom even if it overlaps the edge of the voxel area.
function subterrane:giant_shroom(vi, area, data, stem_material, cap_material, gill_material, stem_height, cap_radius, ignore_bounds)

	if not ignore_bounds and 
		not (area:containsi(vi - cap_radius - area.zstride*cap_radius) and 
		area:containsi(vi + cap_radius + stem_height*area.ystride + area.zstride*cap_radius)) then
			return -- mushroom overlaps the bounds of the voxel area, abort.
	end

	local pos = area:position(vi)
	local x = pos.x
	local y = pos.y
	local z = pos.z

	--cap
	for k = -cap_radius, cap_radius do
	for l = -cap_radius, cap_radius do
		if k*k + l*l <= cap_radius*cap_radius then
			local vi = area:index(x+k, y+stem_height, z+l)
			if data[vi] == c_air then data[vi] = cap_material end
		end
		if k*k + l*l <= (cap_radius-1)*(cap_radius-1) and (cap_radius-1) > 0 then
			local vi = area:index(x+k, y+stem_height+1, z+l)
			data[vi] = cap_material
			vi = area:index(x+k, y+stem_height, z+l)
			if data[vi] == cap_material then data[vi] = gill_material end
		end
		if k*k + l*l <= (cap_radius-2)*(cap_radius-2) and (cap_radius-2) > 0 then
			local vi = area:index(x+k, y+stem_height+2, z+l)
			if data[vi] == c_air then data[vi] = cap_material end
		end
		if k*k + l*l <= (cap_radius-3)*(cap_radius-3) and (cap_radius-3) > 0 then
			local vi = area:index(x+k, y+stem_height+3, z+l)
			if data[vi] == c_air then data[vi] = cap_material end
		end
	end
	end
	--stem
	for j = 0, stem_height do
		local vi = area:index(x, y+j, z)
		data[vi] = stem_material
		if cap_radius > 3 then
			local ai = area:index(x, y+j, z+1)
			if data[ai] == c_air or data[ai] == gill_material then data[ai] = stem_material end
			ai = area:index(x, y+j, z-1)
			if data[ai] == c_air or data[ai] == gill_material then data[ai] = stem_material end
			ai = area:index(x+1, y+j, z)
			if data[ai] == c_air or data[ai] == gill_material then data[ai] = stem_material end
			ai = area:index(x-1, y+j, z)
			if data[ai] == c_air or data[ai] == gill_material then data[ai] = stem_material end
		end
	end
end