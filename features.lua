local c_dry_stal_1 = minetest.get_content_id("subterrane:dry_stal_1") -- thinnest
local c_dry_stal_2 = minetest.get_content_id("subterrane:dry_stal_2")
local c_dry_stal_3 = minetest.get_content_id("subterrane:dry_stal_3")
local c_dry_stal_4 = minetest.get_content_id("subterrane:dry_stal_4") -- thickest

local c_wet_stal_1 = minetest.get_content_id("subterrane:wet_stal_1") -- thinnest
local c_wet_stal_2 = minetest.get_content_id("subterrane:wet_stal_2")
local c_wet_stal_3 = minetest.get_content_id("subterrane:wet_stal_3")
local c_wet_stal_4 = minetest.get_content_id("subterrane:wet_stal_4") -- thickest

local c_air = minetest.get_content_id("air")

local wet_stalagmite_id = {c_wet_stal_1, c_wet_stal_2, c_wet_stal_3, c_wet_stal_4}
local dry_stalagmite_id = {c_dry_stal_1, c_dry_stal_2, c_dry_stal_3, c_dry_stal_4}

-- use a negative height to turn this into a stalactite
function subterrane:stalagmite(vi, area, data, param2_data, param2, height, is_wet)
	local pos = area:position(vi)
	local x = pos.x
	local y = pos.y
	local z = pos.z
	
	if height == nil then height = math.random(1,4) end
	if param2 == nil then param2 = math.random(0,3) end
	
	local stalagmite_id = nil
	if is_wet then stalagmite_id = wet_stalagmite_id else stalagmite_id = dry_stalagmite_id end
	
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

--function to create giant 'shrooms. Cap radius works well from about 2-6
function subterrane:giant_shroom(vi, area, data, stem_material, cap_material, gill_material, stem_height, cap_radius)
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
	for j = -1, stem_height do
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