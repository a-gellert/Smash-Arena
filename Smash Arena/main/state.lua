--state.lua
local M = {}

M.tutorial_step = 0
-- 0: Не начат, 1: Показ колод, 2: Бой начат, 3: Бой окончен, 4: Меню (сундук), 5: Инвентарь, 10: не показываем

M.has_unopened_chest = false
M.STRINGS = {
	step_1 = { en = "Pull and shoot at the enemies!",                              ru = "Натяни и пуляй во врагов!"                                    },
	step_2 = { en = "Each hero has a unique ability!",                             ru = "У каждого героя есть своя способность!"                       },
	step_3 = { en = "The Tank deals damage to nearby enemies after its turn.",     ru = "Танк наносит урон ближайшим врагам после окончания хода."     },
	step_4 = { en = "Players take turns sequentially. Good luck!",                 ru = "Игроки ходят по очереди. Удачи!"                              },
}

-- Константы экранов
M.SCREEN_MENU      = hash("main_menu")
M.SCREEN_LOBBY     = hash("lobby_screen")
M.SCREEN_BATTLE    = hash("main_game")
M.SCREEN_INVENTORY = hash("tab_inventory")

M.current_screen = M.SCREEN_MENU

local SAVE_PATH = sys.get_save_file("my_cool_game", "player_profile")

M.TEAM_PLAYER = 1
M.TEAM_ENEMY  = 2

-- ─────────────────────────────────────────────────────────────
--  ПЕРСИСТЕНТНЫЕ ДАННЫЕ
-- ─────────────────────────────────────────────────────────────
M.active_deck       = { 5, 4, 2, 5 }
M.enemy_deck        = { 1, 5, 7, 10 }
M.gold              = 100
M.almaz             = 10
M.prestige          = 0
M.available_heroes  = { 1, 2, 3, 4, 5 }

-- hero_cards[id] = сколько карточек у игрока
M.hero_cards  = { [1]=10, [2]=7, [3]=15, [4]=3,  [5]=1  }
-- hero_levels[id] = текущий уровень героя (минимум 1)
M.hero_levels = { [1]=1,  [2]=1,  [3]=1,  [4]=1,  [5]=1  }

M.award = {
	gold_win    = 20,
	prestige_win = 30,
}

-- ─────────────────────────────────────────────────────────────
--  СОСТОЯНИЕ СЕССИИ (не сохраняется)
-- ─────────────────────────────────────────────────────────────
M.current_team  = M.TEAM_PLAYER
M.is_simulation = false

-- ─────────────────────────────────────────────────────────────
--  ТРАНЗАКЦИИ
-- ─────────────────────────────────────────────────────────────
function M.add(prestige, gold, almaz)
	prestige = prestige or 0
	gold     = gold     or 0
	almaz    = almaz    or 0
	if prestige < 0 or gold < 0 or almaz < 0 then
		print("M.add: отрицательные значения запрещены")
		return
	end
	M.prestige = M.prestige + prestige
	M.gold     = M.gold     + gold
	M.almaz    = M.almaz    + almaz
	M.save()
end

function M.take(prestige, gold, almaz)
	prestige = prestige or 0
	gold     = gold     or 0
	almaz    = almaz    or 0

	if M.prestige >= prestige and M.gold >= gold and M.almaz >= almaz then
		M.prestige = M.prestige - prestige
		M.gold     = M.gold     - gold
		M.almaz    = M.almaz    - almaz
		M.save()
		return true
	end
	print("M.take: недостаточно ресурсов")
	return false
end

-- ─────────────────────────────────────────────────────────────
--  СОХРАНЕНИЕ / ЗАГРУЗКА
-- ─────────────────────────────────────────────────────────────
function M.save()
	local data_to_save = {
		active_deck      = M.active_deck,
		gold             = M.gold,
		almaz            = M.almaz,
		prestige         = M.prestige,
		available_heroes = M.available_heroes,
		hero_levels      = M.hero_levels,   -- ← сохраняем уровни
		hero_cards       = M.hero_cards,
	}
	local ok = sys.save(SAVE_PATH, data_to_save)
	if ok then
		print("Saved to: " .. SAVE_PATH)
	else
		print("ERROR: save failed")
	end
end

function M.load()
	local d = sys.load(SAVE_PATH)
	if not next(d) then
		print("No save file. Using defaults.")
		return
	end

	M.active_deck      = d.active_deck      or M.active_deck
	M.gold             = d.gold             or M.gold
	M.almaz            = d.almaz            or M.almaz
	M.prestige         = d.prestige         or M.prestige
	M.available_heroes = d.available_heroes or M.available_heroes
	M.hero_cards       = d.hero_cards       or M.hero_cards
	-- ИСПРАВЛЕНО: hero_levels тоже грузим из сохранения
	M.hero_levels      = d.hero_levels      or M.hero_levels

	print("Profile loaded.")
end

-- ─────────────────────────────────────────────────────────────
--  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
-- ─────────────────────────────────────────────────────────────
function M.add_cards(hero_id, amount)
	M.hero_cards[hero_id] = (M.hero_cards[hero_id] or 0) + amount
	-- Добавляем героя в available, если его там нет
	local found = false
	for _, id in ipairs(M.available_heroes) do
		if id == hero_id then found = true; break end
	end
	if not found then
		table.insert(M.available_heroes, hero_id)
		-- Инициализируем уровень 1, если его не было
		if not M.hero_levels[hero_id] then
			M.hero_levels[hero_id] = 1
		end
	end
end

function M.is_player_turn()
	return M.current_team == M.TEAM_PLAYER
end

function M.switch_turn()
	M.current_team = (M.current_team == M.TEAM_PLAYER) and M.TEAM_ENEMY or M.TEAM_PLAYER
end

return M