-- mods/plot_system/init.lua
-- =================
-- See README.md for licensing and other information.

local function get_mtconf(key)
	return type(minetest.settings) ~= "nil" and minetest.settings:get(key) or minetest.setting_get(key)
end

local config = {}
config.size = tonumber(get_mtconf("plot_system.size")) or 31
config.gen_height = tonumber(get_mtconf("plot_system.gen_height")) or 10000
config.height = tonumber(get_mtconf("plot_system.height")) or 32
config.surface = get_mtconf("plot_system.surface") or "default:dirt_with_grass"
config.depth = tonumber(get_mtconf("plot_system.depth")) or 32
config.ground = get_mtconf("plot_system.ground") or "default:stone"
config.path_width = tonumber(get_mtconf("plot_system.path_width")) or 5
config.path = get_mtconf("plot_system.path") or "default:wood"
config.boundary = get_mtconf("plot_system.boundary") or "stairs:slab_stonebrick"
config.border = get_mtconf("plot_system.border") or "default:glass"
config.id_size = config.size + 2 + config.path_width
config.sizep = math.ceil(config.size / 2)
config.sizem = math.floor(config.size / 2)
config.path_widthp = math.ceil(config.path_width / 2)
config.path_widthm = math.floor(config.path_width / 2)

--Start of edited external source code

--By: rnd
--License: GPLv3
--Taken: skyblock redo Mod for Minetest
--Link: https://github.com/ac-minetest/skyblock/blob/master/skyblock/world.lua

local function id2pos(id)
	local g = 3 / 8 + math.sqrt(1 / 4 * id + 9 / 64)
	local g0 = math.floor(g)
	local ssid = 4 * g0 ^ 2 - 3 * g0
	local sid = id - ssid
	local h = 2 * g0 + 1
	local d = (h - 1) / 2
	local dp
	if sid < d then
		dp = {0, sid}
	elseif sid < 3 * d then
		dp = {-(sid - d), d}
	elseif sid < 5 * d then
		dp = {-2 * d, d - (sid - 3 * d)}
	elseif sid <= 7 * d then
		dp = {-2 * d + (sid - 5 * d), -d}
	else
		dp = {1, -d + (sid - 7 * d) - 1}
	end
	return {x = (g0 + dp[1]) * config.id_size, y = config.gen_height, z = dp[2] * config.id_size}
end

local function pos2id(pos)
	pos.x = math.floor((pos.x / config.id_size) + 0.5)
	pos.z = math.floor((pos.z / config.id_size) + 0.5)
	local g = math.max(math.abs(pos.x), math.abs(pos.z))
	local id = 0
	local h = 2 * g + 1
	local d = (h - 1) / 2
	if pos.z < 0 and pos.x > 0 and math.abs(pos.x) > math.abs(pos.z) then
		g = g - 1
		h = h - 2
		d = d - 1
		id = (pos.z + d) + 1 + 7 * d
	elseif pos.z == -d then
		id = (pos.x + d) + 5 * d
	elseif pos.x == -d then
		id = d - pos.z + 3 * d
	elseif pos.z == d then
		id = d - pos.x + d
	else
		id = pos.z
	end
	return 4 * g ^ 2 - 3 * g + id
end

--End of edited external source code

local function register_node(name, def)
	local defs = {description = "Border ".. name:gsub("^%l", string.upper),
								paramtype = "light",
								groups = {not_in_creative_inventory = 1},
								pointable = false,
								diggable = false,
								sunlight_propagates = true,
								on_blast = function() end}
	for key, value in pairs(def or {}) do
		defs[key] = value
	end
	minetest.register_node("plot_system:border_".. name, defs)
	config["border_".. name] = "plot_system:border_".. name
end

register_node("top", {drawtype = "airlike"})
register_node("wall", {drawtype = "airlike", walkable = false})
register_node("bottom", {pointable = true, tiles = minetest.registered_nodes[config.ground].tiles})

local function inserts(y1, y2, y)
	return (y >= y1 and y <= y2)
end

local min = config.gen_height - config.depth - 1
local max = config.gen_height + config.height + 1
local id = {}
for k, v in pairs({config.surface, config.ground, config.path, config.boundary, config.border_top, config.border_wall, config.border_bottom}) do
	id[v] = minetest.get_content_id(v)
end

minetest.register_on_generated(function(minp, maxp, blockseed)
		if maxp.y < min or minp.y > max then
			return
		end
		
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
		local data = vm:get_data()
		
		local y1, y2 = math.max(min, minp.y), math.min(max, maxp.y)
		
		if inserts(y1, y2, min) then--Bottom border
			for pos in area:iter(minp.x, min, minp.z, maxp.x, min, maxp.z) do
				data[pos] = id[config.border_bottom]
			end
		end
		
		if inserts(y1, y2, max) then--Top border
			for pos in area:iter(minp.x, max, minp.z, maxp.x, max, maxp.z) do
				data[pos] = id[config.border_top]
			end
		end
		
		if inserts(y1, y2, min + 1) or inserts(y1, y2, config.gen_height - 1) then--Ground
			for pos in area:iter(minp.x, math.max(y1, min + 1), minp.z, maxp.x, math.min(y2, config.gen_height - 1), maxp.z) do
				data[pos] = id[config.ground]
			end
		end
		
		for x = minp.x, maxp.x do
			for z = minp.z, maxp.z do
				local middle = id2pos(pos2id({x = x, z = z}))
				
				if inserts(y1, y2, config.gen_height) and
					 x >= middle.x - config.sizem and
					 x < middle.x + config.sizep and
					 z >= middle.z - config.sizem and
					 z < middle.z + config.sizep then
					data[area:index(x, config.gen_height, z)] = id[config.surface]
				elseif (x == middle.x - config.sizem - 1 and z >= middle.z - config.sizem - 1 and z < middle.z + config.sizep + 1) or
							 (x == middle.x + config.sizep and z >= middle.z - config.sizem - 1 and z < middle.z + config.sizep + 1) or
							 (z == middle.z - config.sizem - 1 and x >= middle.x - config.sizem and x < middle.x + config.sizep) or
							 (z == middle.z + config.sizep and x >= middle.x - config.sizem and x < middle.x + config.sizep) then
					for y = math.max(config.gen_height, minp.y), math.min(config.gen_height + config.height, maxp.y) do
						if y == config.gen_height then
							data[area:index(x, y, z)] = id[config.path]
						elseif y == config.gen_height + 1 then
							data[area:index(x, y, z)] = id[config.boundary]
						else
							data[area:index(x, y, z)] = id[config.border_wall]
						end
					end
				elseif inserts(y1, y2, config.gen_height) then
					data[area:index(x, config.gen_height, z)] = id[config.path]
				end
			end
		end
		
		vm:set_data(data)
		vm:write_to_map()
end)

