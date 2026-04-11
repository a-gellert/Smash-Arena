local M = {}

-- Таблицы для хранения ID юнитов по командам
M.teams = { [1] = {}, [2] = {} }
-- Общий список для проверки физики (is_everyone_stopped)
M.all_units = {} 
-- Индексы текущего юнита для каждой команды (ДЛЯ ТВОЕЙ ОШИБКИ)
M.team_indices = { [1] = 1, [2] = 1 }
M.all_stoped = false
function M.reset()
	M.teams = { [1] = {}, [2] = {} }
	M.all_units = {}
	M.team_indices = { [1] = 1, [2] = 1 }
end

function M.register_unit(id, team)
	table.insert(M.teams[team], id)
	M.all_units[id] = true
	print("Unit registered: " .. tostring(id) .. " in team " .. team)
end

function M.remove_unit(id, team)
	local t = M.teams[team]
	for i, unit_id in ipairs(t) do
		if unit_id == id then
			table.remove(t, i)
			-- Если удалили юнита перед текущим индексом, нужно его скорректировать
			if i <= M.team_indices[team] and M.team_indices[team] > 1 then
				M.team_indices[team] = M.team_indices[team] - 1
			end
			break
		end
	end
	M.all_units[id] = nil
end

function M.is_everyone_stopped()
	for id, _ in pairs(M.all_units) do
		local ok, vel = pcall(go.get, msg.url(nil, id, "collisionobject"), "linear_velocity")
		if ok and vmath.length(vel) > 0.1 then 
			M.all_stoped = false
		end
	end
	M.all_stoped = true
	return M.all_stoped 
end

return M