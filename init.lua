-- mods/plot_system/init.lua
-- =================
-- See README.txt for licensing and other information.

local plotposy = tonumber(minetest.setting_get("plot_system_plotposy")) or 10000
local plotwidth = tonumber(minetest.setting_get("plot_system_plotwidth")) or 32
local plotheight = tonumber(minetest.setting_get("plot_system_plotheight")) or 32
local plotairheight = tonumber(minetest.setting_get("plot_system_plotairheight")) or plotheight
local plotblock = minetest.setting_get("plot_system_plotblock") or "default:dirt"
local plotblocktop = minetest.setting_get("plot_system_plotblocktop") or "default:dirt_with_grass"
local plotborder = minetest.setting_get("plot_system_plotborder") or "stairs:slab_stonebrick"
local pathwidth = tonumber(minetest.setting_get("plot_system_pathwidth")) or 3
local pathblock = minetest.setting_get("plot_system_pathblock") or "default:wood"
local borderwidth = 1
local plotsperplayer = tonumber(minetest.setting_get("plot_system_plotsperplayer")) or 1

local function copy_node(name)
    local node = minetest.registered_nodes[name]
    local node2 = table.copy(node)
    return node2
  end

local corner = copy_node(plotborder)
local cornerplayer = {}

local function ownerformspec(meta)
  return "size[1.7,8.2]" ..
         "label[0.33,0;Plotsettings]" ..
         "label[0.25,0.6;Add Members]" ..
         "field[0.31,1.2;1.69,1;plot_system_corner_addfield;;]" ..
         "button[0.23,1.6;1.2,1;plot_system_corner_add;Add]" ..
         "label[0.2,2.5;Delete Members]" ..
         "table[0,2.85;1.5,1.3;plot_system_corner_list;".. meta:get_string("members") ..";1]" ..
         "button[0.23,4.13;1.2,1;plot_system_corner_delete;Delete]" ..
         "label[0.37,5.03;Clear Plot]" ..
         "button[0.23,5.3;1.2,1;plot_system_corner_clear;Clear]" ..
         "label[0.34,6.2;Delete Plot]" ..
         "button[0.23,6.47;1.2,1;plot_system_corner_remove;Delete]" ..
         "button_exit[0.23,7.45;1.2,1;plot_system_corner_exit;Exit]"
end

corner.on_rightclick = function(pos, node, player, itemstack, pointed_thing)
  local name = player:get_player_name()
  local meta = minetest.get_meta(pos)
  if meta:get_string("owner") == "" and tonumber(player:get_attribute("plot_system_ownercount")) < plotsperplayer then
    cornerplayer[name] = pos
    minetest.show_formspec(name, "plot_system:corner_free",
      "size[1.5,0.75]" ..
      "button_exit[0,0;1.5,1;plot_system_corner_free;Own this Plot]")
  elseif meta:get_string("owner") == "" then
    minetest.chat_send_player(name, "[Server]: You already have ".. plotsperplayer .." Plots and you arent allowed to own more")
  elseif meta:get_string("owner") == name then
    cornerplayer[name] = pos
    minetest.show_formspec(name, "plot_system:corner", ownerformspec(meta))
  else
    minetest.chat_send_player(name, "[Server]: Plotowner: ".. meta:get_string("owner") .." Plotmembers: ".. meta:get_string("members"))
  end
end

local function check_dir(pos, posbefore)
  local pos1 = {x = pos.x + (plotwidth + 1), y = pos.y, z = pos.z}
  local pos2 = {x = pos.x, y = pos.y, z = pos.z + (plotwidth + 1)}
  local pos3 = {x = pos.x - (plotwidth + 1), y = pos.y, z = pos.z}
  local pos4 = {x = pos.x, y = pos.y, z = pos.z - (plotwidth + 1)}
  local pos5 = {x = pos.x + plotwidth, y = pos.y, z = pos.z}
  local pos6 = {x = pos.x, y = pos.y, z = pos.z + plotwidth}
  local pos7 = {x = pos.x - plotwidth, y = pos.y, z = pos.z}
  local pos8 = {x = pos.x, y = pos.y, z = pos.z - plotwidth}
  if minetest.get_node(pos1).name == "plot_system:corner" and not vector.equals(posbefore, pos1) then
    return pos1
  elseif minetest.get_node(pos2).name == "plot_system:corner" and not vector.equals(posbefore, pos2) then
    return pos2
  elseif minetest.get_node(pos3).name == "plot_system:corner" and not vector.equals(posbefore, pos3) then
    return pos3
  elseif minetest.get_node(pos4).name == "plot_system:corner" and not vector.equals(posbefore, pos4) then
    return pos4
  elseif minetest.get_node(pos5).name == "plot_system:corner" and not vector.equals(posbefore, pos5) then
    return pos5
  elseif minetest.get_node(pos6).name == "plot_system:corner" and not vector.equals(posbefore, pos6) then
    return pos6
  elseif minetest.get_node(pos7).name == "plot_system:corner" and not vector.equals(posbefore, pos7) then
    return pos7
  elseif minetest.get_node(pos8).name == "plot_system:corner" and not vector.equals(posbefore, pos8) then
    return pos8
  end
end

local function get_cornerpos(pos)
  local poses = {pos}
  table.insert(poses, check_dir(poses[1], poses[1]))
  table.insert(poses, check_dir(poses[2], poses[1]))
  table.insert(poses, check_dir(poses[3], poses[2]))
  return poses
end

local function clearplot(pos)
  local air = minetest.get_content_id("air")
  local plotblockid = minetest.get_content_id(plotblock)
  local plotblocktopid = minetest.get_content_id(plotblocktop)
  local plotborderid = minetest.get_content_id(plotborder)
  local pos1 = {x = pos.x, y = pos.y - plotheight, z = pos.z}
  local pos2 = {x = pos.x + plotwidth, y = pos.y + plotairheight, z = pos.z + plotwidth}
  local vox = minetest.get_voxel_manip()
  local min, max = vox:read_from_map(pos1, pos2)
  local area = VoxelArea:new({MinEdge = min, MaxEdge = max})
  local data = vox:get_data()
  local minusx = 1
  local minusz = 1
  if data[area:index(pos.x + plotwidth - minusx, pos.y + 1, pos.z)] == plotborderid then
    minusx = 2
  end
  if data[area:index(pos.x, pos.y + 1, pos.z + plotwidth - minusz)] == plotborderid then
    minusz = 2
  end
  for pos in area:iter(pos.x, plotposy - plotheight + 1, pos.z, pos.x + plotwidth - minusx, plotposy - 1, pos.z + plotwidth - minusz) do
    data[pos] = plotblockid
  end
  for pos in area:iter(pos.x, plotposy, pos.z, pos.x + plotwidth - minusx, plotposy, pos.z + plotwidth - minusz) do
    data[pos] = plotblocktopid
  end
  for pos in area:iter(pos.x, plotposy + 1, pos.z, pos.x + plotwidth - minusx, plotposy + plotairheight, pos.z + plotwidth - minusz) do
    data[pos] = air
  end
  vox:set_data(data)
  vox:write_to_map()
  vox:update_map()
  vox:update_liquids()
end

local listselect = {}

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    if formname == "plot_system:corner_free" and fields.plot_system_corner_free then
      if minetest.get_meta(cornerplayer[name]):get_string("owner") ~= "" then
        return
      end
      player:set_attribute("plot_system_ownercount", tonumber(player:get_attribute("plot_system_ownercount")) + 1)
      local poses = get_cornerpos(cornerplayer[name])
      cornerplayer[name] = nil
      for key, value in ipairs(poses) do
        local meta = minetest.get_meta(value)
        meta:set_string("owner", name)
        meta:set_string("members", "")
      end
    elseif formname == "plot_system:corner" then
      if fields.plot_system_corner_add then
        local meta = minetest.get_meta(cornerplayer[name])
        local tbl = meta:get_string("members"):split(",")
        for key, value in pairs(tbl) do
          if value == fields.plot_system_corner_addfield then
            return
          end
        end
        if fields.plot_system_corner_addfield == "" or string.find(fields.plot_system_corner_addfield, ",") or meta:get_string("owner") == fields.plot_system_corner_addfield then
          return
        end
        table.insert(tbl, fields.plot_system_corner_addfield)
        for key, value in ipairs(get_cornerpos(cornerplayer[name])) do
          local meta = minetest.get_meta(value)
          meta:set_string("members", table.concat(tbl, ","))
        end
        minetest.show_formspec(name, "plot_system:corner", ownerformspec(meta))
      elseif fields.plot_system_corner_list and fields.plot_system_corner_list:sub(1, 3) == "CHG" then
        listselect[name] = tonumber(string.sub(fields.plot_system_corner_list, 5, -3))
      elseif fields.plot_system_corner_delete then
        if not listselect[name] or listselect[name] > 0 then
          listselect[name] = listselect[name] or 1
          local meta = minetest.get_meta(cornerplayer[name])
          local tbl = meta:get_string("members"):split(",")
          local playername = tbl[listselect[name]]
          listselect[name] = nil
          for key, value in pairs(tbl) do
            if value == playername then
              table.remove(tbl, key)
            end
          end
          for key, value in ipairs(get_cornerpos(cornerplayer[name])) do
            local meta = minetest.get_meta(value)
            meta:set_string("members", table.concat(tbl, ","))
          end
          minetest.show_formspec(name, "plot_system:corner", ownerformspec(meta))
        end
      elseif fields.plot_system_corner_clear then
        if listselect[name] == -100 then
          listselect[name] = nil
          local poses = get_cornerpos(cornerplayer[name])
          clearplot({x = math.min(poses[4].x, math.min(poses[3].x, math.min(poses[2].x, poses[1].x))) + 1, y = plotposy, z = math.min(poses[4].z, math.min(poses[3].z, math.min(poses[2].z, poses[1].z))) + 1})
        else
          listselect[name] = -100
        end
      elseif fields.plot_system_corner_remove then
        if listselect[name] == -1000 then
          listselect[name] = nil
          local poses = get_cornerpos(cornerplayer[name])
          for key, value in ipairs(poses) do
            local meta = minetest.get_meta(value)
            meta:set_string("owner", nil)
            meta:set_string("members", nil)
          end
          player:set_attribute("plot_system_ownercount", tonumber(player:get_attribute("plot_system_ownercount")) - 1)
          cornerplayer[name] = poses[1]
          minetest.show_formspec(name, "plot_system:corner_free",
            "size[1.5,0.75]" ..
            "button_exit[0,0;1.5,1;plot_system_corner_free;Own this Plot]")
          clearplot({x = math.min(poses[4].x, math.min(poses[3].x, math.min(poses[2].x, poses[1].x))) + 1, y = plotposy, z = math.min(poses[4].z, math.min(poses[3].z, math.min(poses[2].z, poses[1].z))) + 1})
        else
          listselect[name] = -1000
        end
      end
    end
end)

corner.tiles = {corner.tiles[1] .."^plot_system_setting.png", corner.tiles[1]}
corner.diggable = false
corner.on_blast = function() end
minetest.register_node("plot_system:corner", corner)

minetest.register_node("plot_system:invisible", { --Top Border
    description = "Invisible",
    drawtype = "airlike",
		paramtype = "light",
    groups = {not_in_creative_inventory = 1},
    pointable = false,
		diggable = false,
    sunlight_propagates = true,
    on_blast = function() end})

local invisible2 = copy_node("plot_system:invisible") --Wall Border
invisible2.walkable = false
minetest.register_node("plot_system:invisible2", invisible2)

local plotblock2 = copy_node("plot_system:invisible") --Bottom Border
plotblock2.drawtype = nil
plotblock2.tiles = {minetest.registered_nodes[plotblock].tiles[1]}
minetest.register_node("plot_system:invisible3", plotblock2)

minetest.register_on_joinplayer(function(player)
		if not player:get_attribute("plot_system_ownercount") then
      player:set_attribute("plot_system_ownercount", 0)
    end
end)

local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	local player = minetest.get_player_by_name(name)
	if not player or minetest.get_player_privs(name).privs then
		return old_is_protected(pos, name)
	end
	if pos.y < plotposy - plotheight or pos.y > plotposy + plotairheight then
		return old_is_protected(pos, name)
	end
	local cornerposes = minetest.find_nodes_in_area({x = pos.x - math.sqrt((plotwidth / 2) * (plotwidth / 2)), y = plotposy - plotheight, z = pos.z - math.sqrt((plotwidth / 2) * (plotwidth / 2))}, {x = pos.x + math.sqrt((plotwidth / 2) * (plotwidth / 2)), y = plotposy + plotairheight, z = pos.z + math.sqrt((plotwidth / 2) * (plotwidth / 2))}, "plot_system:corner")
	local cornerpos = cornerposes[1]
	for key, value in ipairs(cornerposes) do
		if vector.distance(pos, value) < vector.distance(pos, cornerpos) then
			cornerpos = value
		end
	end
	local poses = get_cornerpos(cornerpos)
	if pos.x > math.min(poses[4].x, math.min(poses[3].x, math.min(poses[2].x, poses[1].x))) and pos.x < math.max(poses[4].x, math.max(poses[3].x, math.max(poses[2].x, poses[1].x))) and pos.z > math.min(poses[4].z, math.min(poses[3].z, math.min(poses[2].z, poses[1].z))) and pos.z < math.max(poses[4].z, math.max(poses[3].z, math.max(poses[2].z, poses[1].z))) then
		local meta = minetest.get_meta(cornerpos)
		if meta:get_string("owner") == name then
			return old_is_protected(pos, name)
		end
		for key, value in pairs(meta:get_string("members"):split(",")) do
			if value == name then
				return old_is_protected(pos, name)
			end
		end
	end
	return true
end

local function inserts(min, max, y, y2)
  if (y >= min and y <= max) or (y2 >= min and y2 <= max) or (y < min and y2 > max) then
    return math.min(max, y)
  end
end

local function getblockpos(pos)
  local line = (plotwidth / 2) + 1 + pathwidth + 1 + (plotwidth / 2)
  local xdivide = math.floor(math.abs(pos.x) / line)
  local xdividerest = math.floor(math.abs(pos.x) - (xdivide * line))
  local zdivide = math.floor(math.abs(pos.z) / line)
  local zdividerest = math.floor(math.abs(pos.z) - (zdivide * line))
  
  if xdividerest < (plotwidth / 2) and zdividerest < (plotwidth / 2) then
    return 1 --Plot
  elseif xdividerest < (plotwidth / 2) and zdividerest < (plotwidth / 2) + borderwidth then
    return 2 --Border
  elseif xdividerest < (plotwidth / 2) and zdividerest < (plotwidth / 2) + borderwidth + pathwidth then
    return 3 --Path
  elseif xdividerest < (plotwidth / 2) and zdividerest < (plotwidth / 2) + borderwidth + pathwidth + borderwidth then
    return 2 --Border
  elseif xdividerest < (plotwidth / 2) then
    return 1 --Plot
    
  elseif xdividerest < (plotwidth / 2) + borderwidth and zdividerest == (plotwidth / 2) + borderwidth - 1 then
    return 4 --Corner
  elseif xdividerest < (plotwidth / 2) + borderwidth and zdividerest < (plotwidth / 2) + borderwidth then
    return 2 --Border
  elseif xdividerest < (plotwidth / 2) + borderwidth and zdividerest < (plotwidth / 2) + borderwidth + pathwidth then
    return 3 --Path
  elseif xdividerest < (plotwidth / 2) + borderwidth and zdividerest == (plotwidth / 2) + borderwidth + pathwidth + borderwidth - 1 then
    return 4 --Corner
  elseif xdividerest < (plotwidth / 2) + borderwidth then
    return 2 --Border
    
  elseif xdividerest < (plotwidth / 2) + borderwidth + pathwidth then
    return 3 --Path
    
  elseif xdividerest < (plotwidth / 2) + borderwidth + pathwidth + borderwidth and zdividerest == (plotwidth / 2) + borderwidth - 1 then
    return 4 --Corner
  elseif xdividerest < (plotwidth / 2) + borderwidth + pathwidth + borderwidth and zdividerest < (plotwidth / 2) + borderwidth then
    return 2 --Border
  elseif xdividerest < (plotwidth / 2) + borderwidth + pathwidth + borderwidth and zdividerest < (plotwidth / 2) + borderwidth + pathwidth then
    return 3 --Path
  elseif xdividerest < (plotwidth / 2) + borderwidth + pathwidth + borderwidth and zdividerest == (plotwidth / 2) + borderwidth + pathwidth + borderwidth - 1 then
    return 4 --Corner
  elseif xdividerest < (plotwidth / 2) + borderwidth + pathwidth + borderwidth then
    return 2 --Border
    
  elseif xdividerest < (plotwidth / 2) + borderwidth + pathwidth + borderwidth + (plotwidth / 2) and zdividerest < (plotwidth / 2) then
    return 1 --Plot
  elseif xdividerest < (plotwidth / 2) + borderwidth + pathwidth + borderwidth + (plotwidth / 2) and zdividerest < (plotwidth / 2) + borderwidth then
    return 2 --Border
  elseif xdividerest < (plotwidth / 2) + borderwidth + pathwidth + borderwidth + (plotwidth / 2) and zdividerest < (plotwidth / 2) + borderwidth + pathwidth then
    return 3 --Path
  elseif xdividerest < (plotwidth / 2) + borderwidth + pathwidth + borderwidth + (plotwidth / 2) and zdividerest < (plotwidth / 2) + borderwidth + pathwidth + borderwidth then
    return 2 --Border
  elseif xdividerest < (plotwidth / 2) + borderwidth + pathwidth + borderwidth + (plotwidth / 2) then
    return 1 --Plot
  end
end

minetest.register_on_generated(function(minp, maxp, seed)
    if not inserts(plotposy - plotheight, plotposy + plotairheight, minp.y, maxp.y) then
      return
    end
    local plotblockid = minetest.get_content_id(plotblock)
    local plotblocktopid = minetest.get_content_id(plotblocktop)
    local plotborderid = minetest.get_content_id(plotborder)
    local plotcornerid = minetest.get_content_id("plot_system:corner")
    local pathblockid = minetest.get_content_id(pathblock)
    local invisible = minetest.get_content_id("plot_system:invisible")
    local invisible2 = minetest.get_content_id("plot_system:invisible2")
    local invisible3 = minetest.get_content_id("plot_system:invisible3")
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local data = vm:get_data()
    local va = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    for x = minp.x, maxp.x do
      for z = minp.z, maxp.z do
        if getblockpos({x = x, y = plotposy, z = z}) == 1 then
          if inserts(plotposy - plotheight, plotposy - 1, minp.y, maxp.y)then
            for pos in va:iter(x, math.max(minp.y, plotposy - plotheight), z, x, plotposy - 1, z) do
              data[pos] = plotblockid
            end
          end
          if inserts(minp.y, maxp.y, plotposy, plotposy) then
            data[va:index(x, plotposy, z)] = plotblocktopid
          end
        elseif getblockpos({x = x, y = plotposy, z = z}) == 2 then
          if inserts(plotposy - plotheight, plotposy, minp.y, maxp.y) then
            for pos in va:iter(x, math.max(minp.y, plotposy - plotheight), z, x, plotposy, z) do
              data[pos] = plotblockid
            end
          end
          if inserts(plotposy + 1, plotposy + plotairheight, minp.y, maxp.y) then
            for pos in va:iter(x, plotposy + 1, z, x, plotposy + plotairheight, z) do
              data[pos] = invisible2
            end
          end
          if inserts(minp.y, maxp.y, plotposy + 1, plotposy + 1) then
            data[va:index(x, plotposy + 1, z)] = plotborderid
          end
        elseif getblockpos({x = x, y = plotposy, z = z}) == 3 then
          if inserts(plotposy - plotheight, plotposy - 1, minp.y, maxp.y) then
            for pos in va:iter(x, math.max(minp.y, plotposy - plotheight), z, x, plotposy - 1, z) do
              data[pos] = plotblockid
            end
          end
          if inserts(minp.y, maxp.y, plotposy, plotposy) then
            data[va:index(x, plotposy, z)] = pathblockid
          end
        elseif getblockpos({x = x, y = plotposy, z = z}) == 4 then
          if inserts(plotposy - plotheight, plotposy, minp.y, maxp.y) then
            for pos in va:iter(x, plotposy - plotheight, z, x, plotposy, z) do
              data[pos] = plotblockid
            end
          end
          if inserts(plotposy + 1, plotposy + plotairheight, minp.y, maxp.y) then
            for pos in va:iter(x, plotposy + 1, z, x, plotposy + plotairheight, z) do
              data[pos] = invisible2
            end
          end
          if inserts(minp.y, maxp.y, plotposy + 1, plotposy + 1) then
            data[va:index(x, plotposy + 1, z)] = plotcornerid
          end
        end
      end
    end
    if inserts(minp.y, maxp.y, plotposy - plotheight, plotposy - plotheight) then
      for pos in va:iter(minp.x, plotposy - plotheight, minp.z, maxp.x, plotposy - plotheight, maxp.z) do
        data[pos] = invisible3
      end
    end
    if inserts(minp.y, maxp.y, plotposy + plotairheight + 1, plotposy + plotheight + 1) then
      for pos in va:iter(minp.x, plotposy + plotairheight + 1, minp.z, maxp.x, plotposy + plotairheight + 1, maxp.z) do
        data[pos] = invisible
      end
    end
    vm:set_data(data)
    vm:calc_lighting(emin, emax)
    vm:update_liquids()
    vm:write_to_map()
  end)
