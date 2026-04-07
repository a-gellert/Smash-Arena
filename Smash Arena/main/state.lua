local M = {}

-- Перечисления для удобства (чтобы не гадать, что такое 1 или 2)
M.TEAM_PLAYER = 1
M.TEAM_ENEMY = 2

-- Текущее состояние
M.current_team = M.TEAM_PLAYER -- Кто ходит сейчас
M.is_simulation = false        -- Летит ли сейчас кто-то по полю?

function M.is_player_turn()
	return M.current_team == M.TEAM_PLAYER
end

function M.switch_turn()
	if M.current_team == M.TEAM_PLAYER then
		M.current_team = M.TEAM_ENEMY
	else
		M.current_team = M.TEAM_PLAYER
	end
	print("Ход переключен на команду: " .. M.current_team)
end

return M