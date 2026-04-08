-- main/utils/unit_manager.lua
local M = {}

M.teams = { [1] = {}, [2] = {} }
M.team_indices = { [1] = 1, [2] = 1 }

function M.reset()
	M.teams = { [1] = {}, [2] = {} }
	M.team_indices = { [1] = 1, [2] = 1 }
end

function M.register_unit(id, team)
	table.insert(M.teams[team], id)
end

function M.remove_unit(id, team)
	local t = M.teams[team]
	for i, unit_id in ipairs(t) do
		if unit_id == id then
			table.remove(t, i)
			break
		end
	end
end

return M