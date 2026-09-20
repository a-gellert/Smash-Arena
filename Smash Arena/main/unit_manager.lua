local M = {}

-- Таблицы для хранения ID ЖИВЫХ юнитов по командам (для очереди ходов)
M.teams = { [1] = {}, [2] = {} }
-- Индексы текущего юнита для каждой команды
M.team_indices = { [1] = 1, [2] = 1 }

-- Фиксированные слоты (1..4 для команды игрока, 1..4 для команды врага) для UI панели
M.slots = { [1] = {}, [2] = {} }
M.unit_to_slot = {}

-- Общий список живых юнитов для проверки физики (is_everyone_stopped)
M.all_units = {} 
M.unit_data = {}
M.active_unit_id = nil

function M.reset()
	M.teams = { [1] = {}, [2] = {} }
	M.team_indices = { [1] = 1, [2] = 1 }
	M.slots = { [1] = {}, [2] = {} }
	M.unit_to_slot = {}
	M.all_units = {}
	M.unit_data = {}
	M.active_unit_id = nil
end

function M.register_unit(id, team, hero_id, level, hp)
	table.insert(M.teams[team], id)
	M.all_units[id] = true

	local info = {
		id = id,
		team = team,
		hero_id = hero_id,
		level = level,
		hp = hp,
		max_hp = hp,
		is_dead = false
	}

	table.insert(M.slots[team], info)
	local slot_idx = #M.slots[team]
	M.unit_to_slot[id] = { team = team, slot_idx = slot_idx }
	M.unit_data[id] = info
end

function M.update_hp(id, current_hp)
	if M.unit_data[id] then
		M.unit_data[id].hp = math.max(0, current_hp)
		if current_hp <= 0 then
			M.unit_data[id].is_dead = true
		end
	end
end

function M.remove_unit(id, team)
	if M.unit_data[id] then
		M.unit_data[id].hp = 0
		M.unit_data[id].is_dead = true
	end

	-- Удаляем только из очереди ходов живых бойцов
	local t = M.teams[team]
	for i, unit_id in ipairs(t) do
		if unit_id == id then
			table.remove(t, i)
			if i <= M.team_indices[team] and M.team_indices[team] > 1 then
				M.team_indices[team] = M.team_indices[team] - 1
			end
			break
		end 
	end
	M.all_units[id] = nil
	if M.active_unit_id == id then
		M.active_unit_id = nil
	end
end

-- Получить данные фиксированного слота для UI (1..4 - игрок, 5..8 - враг)
function M.get_slot_data(index)
	local team = (index <= 4) and 1 or 2
	local slot_idx = (index <= 4) and index or (index - 4)
	return M.slots[team] and M.slots[team][slot_idx] or nil
end

function M.get_id_by_index(index)
	local slot = M.get_slot_data(index)
	return slot and slot.id or nil
end

-- Получить индекс активного слота для UI (1..8)
function M.get_active_slot_index()
	if not M.active_unit_id then return nil end
	local info = M.unit_to_slot[M.active_unit_id]
	if not info then return nil end
	return (info.team == 1) and info.slot_idx or (info.slot_idx + 4)
end

function M.is_everyone_stopped()
	for id, _ in pairs(M.all_units) do
		local ok, vel = pcall(go.get, msg.url(nil, id, "collisionobject"), "linear_velocity")
		if ok and vmath.length(vel) > 0.1 then 
			return false
		end
	end
	return true
end

return M