-- state.lua
local M = {}

-- Перечисления для удобства
M.TEAM_PLAYER = 1
M.TEAM_ENEMY = 2

-- Данные игрока
-- Массив из 4 элементов (ID героев из data.lua)
M.active_deck = { 1, 2, 3, 4 } 

-- Текущее состояние боя
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

-- Вспомогательный метод для обновления колоды (аналог UPDATE в БД)
function M.set_deck_slot(slot_index, hero_id)
	if slot_index >= 1 and slot_index <= 4 then
		M.active_deck[slot_index] = hero_id
	end
end

return M