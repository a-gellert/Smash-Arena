local M = {}

M.tutorial_step = 0 
-- 0: Не начат, 1: Показ колод, 2: Бой начат, 3: Бой окончен, 4: Меню (сундук), 5: Инвентарь
M.has_unopened_chest = false

-- Константы экранов
M.SCREEN_MENU = hash("main_menu")
M.SCREEN_LOBBY = hash("lobby_screen")
M.SCREEN_BATTLE = hash("main_game")
M.SCREEN_INVENTORY = hash("tab_inventory")

M.current_screen = M.SCREEN_MENU

-- Путь к файлу сохранения (в папке приложения)
local SAVE_PATH = sys.get_save_file("my_cool_game", "player_profile")

-- Перечисления
M.TEAM_PLAYER = 1
M.TEAM_ENEMY = 2

-----------------------------------------
-- ПЕРСИСТЕНТНЫЕ ДАННЫЕ (Сохраняемые)
-----------------------------------------
M.active_deck = { 1, 2, 3, 4 } 
M.gold = 100
M.almaz = 10
M.prestige = 0
M.available_heroes = {1, 2, 3, 4, 5}
-- Формат: [ID] = количество_карт (так удобнее искать, чем вложенными таблицами)
M.hero_cards = { [1] = 10, [2] = 7, [3] = 15, [4] = 3, [5] = 1 }

-----------------------------------------
-- СОСТОЯНИЕ СЕССИИ (Не сохраняется)
-----------------------------------------
M.current_team = M.TEAM_PLAYER
M.is_simulation = false

-----------------------------------------
-- МЕТОДЫ РАБОТЫ С ДАННЫМИ (Transactions)
-----------------------------------------

-- Сохранение данных на диск (COMMIT)
function M.save()
	local data_to_save = {
		active_deck = M.active_deck,
		gold = M.gold,
		almaz = M.almaz,
		prestige = M.prestige,
		available_heroes = M.available_heroes,
		hero_cards = M.hero_cards
	}
	local success = sys.save(SAVE_PATH, data_to_save)
	if success then
		print("Data saved successfully to: " .. SAVE_PATH)
	else
		print("Error: Failed to save data")
	end
end

-- Загрузка данных с диска (RESTORE)
function M.load()
	local loaded_data = sys.load(SAVE_PATH)

	-- Если файл пустой (первый запуск), выходим и используем дефолтные значения
	if not next(loaded_data) then 
		print("No save file found. Using defaults.")
		return 
	end

	-- Перезаписываем поля
	M.active_deck = loaded_data.active_deck or M.active_deck
	M.gold = loaded_data.gold or M.gold
	M.almaz = loaded_data.almaz or M.almaz
	M.prestige = loaded_data.prestige or M.prestige
	M.available_heroes = loaded_data.available_heroes or M.available_heroes
	M.hero_cards = loaded_data.hero_cards or M.hero_cards

	print("Profile loaded successfully.")
end

-- Вспомогательный метод для добавления карт (UPDATE)
function M.add_cards(hero_id, amount)
	M.hero_cards[hero_id] = (M.hero_cards[hero_id] or 0) + amount
	-- Если у нас теперь есть карты, но героя не было в списке доступных - добавляем
	local found = false
	for _, id in ipairs(M.available_heroes) do
		if id == hero_id then found = true break end
	end
	if not found then table.insert(M.available_heroes, hero_id) end
end

function M.is_player_turn()
	return M.current_team == M.TEAM_PLAYER
end

function M.switch_turn()
	M.current_team = (M.current_team == M.TEAM_PLAYER) and M.TEAM_ENEMY or M.TEAM_PLAYER
end

return M