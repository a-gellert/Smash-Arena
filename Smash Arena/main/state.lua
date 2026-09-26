--state.lua
local i18n = require "main.i18n"

local M = {}

M.tutorial_step = 0
-- 0: Не начат, 1: Показ колод, 2: Бой начат, 3: Бой окончен, 4: Меню (сундук), 5: Инвентарь, 10: не показываем

M.has_unopened_chest = false
M.STRINGS = i18n.DICTIONARY

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
M.active_deck       = { 3, 1, 2, 4 }
M.enemy_deck        = { 1, 5, 7, 10 }
M.gold              = 100
M.almaz             = 10
M.prestige          = 0
M.available_heroes  = { 1, 2, 3, 4, 5 }

-- hero_cards[id] = сколько карточек у игрока
M.hero_cards  = { [1]=10, [2]=7, [3]=15, [4]=3,  [5]=1  }
-- hero_levels[id] = текущий уровень героя (минимум 1)
M.hero_levels = { [1]=1,  [2]=1,  [3]=1,  [4]=1,  [5]=1  }

M.selected_world = 1

M.WORLDS = {
	{
		id = 1,
		name_en = "Training Arena",
		name_ru = "Тренировочная арена",
		required_prestige = 0,
		description_en = "Training grounds of champions.",
		description_ru = "Тренировочная арена чемпионов.",
		border_color = vmath.vector4(0.85, 0.75, 0.45, 1.0)
	},
	{
		id = 2,
		name_en = "Forest Grove",
		name_ru = "Лесная арена",
		required_prestige = 100,
		description_en = "Enchanted grove with ancient runes.",
		description_ru = "Древняя роща, полная магии и рун.",
		border_color = vmath.vector4(0.3, 0.8, 0.4, 1.0)
	},
	{
		id = 3,
		name_en = "Dungeon Crypt",
		name_ru = "Подземелье",
		required_prestige = 300,
		description_en = "Dark crypt with iron grates and skulls.",
		description_ru = "Мрачные катакомбы с цепями и факелами.",
		border_color = vmath.vector4(0.45, 0.5, 0.85, 1.0)
	},
	{
		id = 4,
		name_en = "Dragon's Lair",
		name_ru = "Драконье логово",
		required_prestige = 600,
		description_en = "Molten caldera with dragon bones.",
		description_ru = "Лавовая кальдера с костями драконов.",
		border_color = vmath.vector4(0.95, 0.35, 0.2, 1.0)
	}
}

function M.is_world_unlocked(world_id)
	local w = M.WORLDS[world_id]
	if not w then return false end
	return (M.prestige or 0) >= w.required_prestige
end

function M.select_world(world_id)
	if world_id < 1 or world_id > #M.WORLDS then return false end
	if not M.is_world_unlocked(world_id) then return false end
	M.selected_world = world_id
	M.save()
	return true
end

M.award = {
	gold_win    = 20,
	prestige_win = 30,
}

M.sfx_volume   = 1.0
M.music_volume = 0.8

-- state.lua
M.chests = {
	{ id = nil, unlock_start_time = 0, is_opening = false },
	{ id = nil, unlock_start_time = 0, is_opening = false },
	{ id = nil, unlock_start_time = 0, is_opening = false },
	{ id = nil, unlock_start_time = 0, is_opening = false },
}

-- Проверка, открывается ли сейчас какой-нибудь сундук
function M.is_any_chest_opening()
	for _, ch in ipairs(M.chests) do
		if ch.is_opening then return true end
	end
	return false
end
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
function M.apply_profile_data(d)
	if not d then return end
	M.active_deck      = d.active_deck      or M.active_deck
	M.gold             = d.gold             or M.gold
	M.almaz            = d.almaz            or M.almaz
	M.prestige         = d.prestige         or M.prestige
	M.available_heroes = d.available_heroes or M.available_heroes
	M.hero_cards       = d.hero_cards       or M.hero_cards
	M.hero_levels      = d.hero_levels      or M.hero_levels
	M.chests           = d.chests           or M.chests
	M.sfx_volume       = (d.sfx_volume ~= nil) and d.sfx_volume or M.sfx_volume
	M.music_volume     = (d.music_volume ~= nil) and d.music_volume or M.music_volume
	M.last_free_spin_date = d.last_free_spin_date or ""

	if d.selected_world and M.is_world_unlocked(d.selected_world) then
		M.selected_world = d.selected_world
	else
		M.selected_world = 1
	end

	local sound = require "main.sound"
	sound.set_sfx_volume(M.sfx_volume)
	sound.set_music_volume(M.music_volume)

	if d.tutorial_completed ~= nil then
		M.tutorial_completed = d.tutorial_completed
	elseif d.gold or d.prestige or d.active_deck then
		M.tutorial_completed = true
	else
		M.tutorial_completed = false
	end

	if M.tutorial_completed then
		M.tutorial_step = 10
	end
end

function M.complete_tutorial()
	M.tutorial_completed = true
	M.tutorial_step = 10
	local sdk_ok, sdk = pcall(require, "main.sdk")
	if sdk_ok and sdk and sdk.tutorial_completed then
		sdk.tutorial_completed()
	end
	M.save()
end

function M.save()
	local data_to_save = {
		active_deck        = M.active_deck,
		gold               = M.gold,
		almaz              = M.almaz,
		prestige           = M.prestige,
		available_heroes   = M.available_heroes,
		hero_levels        = M.hero_levels,
		hero_cards         = M.hero_cards,
		chests             = M.chests,
		tutorial_completed = M.tutorial_completed,
		sfx_volume         = M.sfx_volume,
		music_volume       = M.music_volume,
		selected_world     = M.selected_world,
		last_free_spin_date = M.last_free_spin_date
	}
	local ok = sys.save(SAVE_PATH, data_to_save)
	if ok then
		print("Saved to: " .. SAVE_PATH)
	else
		print("ERROR: save failed")
	end

	-- Cloud save via Playgama Bridge Storage
	local sdk_ok, sdk = pcall(require, "main.sdk")
	if sdk_ok and sdk and sdk.storage_set then
		sdk.storage_set({ player_profile = data_to_save })
	end
end

function M.load(callback)
	local d = sys.load(SAVE_PATH)
	if not next(d) then
		print("No local save file. Using defaults (first launch).")
		M.tutorial_completed = false
	else
		M.apply_profile_data(d)
		print("Local profile loaded. Tutorial completed: " .. tostring(M.tutorial_completed))
	end

	-- Async cloud load from Playgama Bridge Storage
	local sdk_ok, sdk = pcall(require, "main.sdk")
	if sdk_ok and sdk and sdk.storage_get then
		sdk.storage_get({ "player_profile" }, function(err, cloud_data)
			if cloud_data and cloud_data.player_profile then
				local cd = cloud_data.player_profile
				if (cd.prestige or 0) > (M.prestige or 0) or (cd.gold or 0) > (M.gold or 0) or (not next(d)) then
					print("Cloud save restored from Playgama Storage")
					M.apply_profile_data(cd)
					sys.save(SAVE_PATH, cd)
					if callback then callback() end
				end
			end
		end)
	end
end

-- ─────────────────────────────────────────────────────────────
--  КОЛЕСО ФОРТУНЫ (LUCKY WHEEL)
-- ─────────────────────────────────────────────────────────────
M.last_free_spin_date = ""

M.WHEEL_SECTORS = {
	{ type = "gold",  amount = 50,  label = "50 Gold",        weight = 25 },
	{ type = "cards", amount = 5,   label = "x5 Hero Cards",  weight = 25 },
	{ type = "gold",  amount = 150, label = "150 Gold",       weight = 15 },
	{ type = "gems",  amount = 5,   label = "5 Gems",         weight = 8  },
	{ type = "cards", amount = 10,  label = "x10 Hero Cards", weight = 15 },
	{ type = "gold",  amount = 250, label = "250 Gold",       weight = 5  },
	{ type = "cards", amount = 20,  label = "x20 Hero Cards", weight = 5  },
	{ type = "chest", amount = 1,   label = "Mystery Chest",  weight = 2  }
}

function M.is_free_spin_available()
	local today = os.date("%Y-%m-%d")
	return M.last_free_spin_date ~= today
end

function M.consume_free_spin()
	M.last_free_spin_date = os.date("%Y-%m-%d")
	M.save()
end

function M.pick_wheel_sector()
	local total_weight = 0
	for _, s in ipairs(M.WHEEL_SECTORS) do
		total_weight = total_weight + s.weight
	end
	local r = math.random(1, total_weight)
	local cur = 0
	for idx, s in ipairs(M.WHEEL_SECTORS) do
		cur = cur + s.weight
		if r <= cur then
			return idx, s
		end
	end
	return 1, M.WHEEL_SECTORS[1]
end

function M.grant_wheel_reward(sector_idx)
	local s = M.WHEEL_SECTORS[sector_idx]
	if not s then return nil end

	local reward_result = { type = s.type, amount = s.amount, label = s.label }

	if s.type == "gold" then
		M.add(0, s.amount, 0)
	elseif s.type == "gems" then
		M.add(0, 0, s.amount)
	elseif s.type == "cards" then
		local pool = (M.available_heroes and #M.available_heroes > 0) and M.available_heroes or { 1, 2, 3, 4 }
		local h_id = pool[math.random(1, #pool)]
		M.add_cards(h_id, s.amount)
		reward_result.hero_id = h_id
	elseif s.type == "chest" then
		local chest_chances = { 1, 1, 1, 2, 2, 3 }
		local dropped_chest_id = chest_chances[math.random(1, #chest_chances)]
		local placed_slot = nil
		for i = 1, 4 do
			if not M.chests[i].id then
				M.chests[i].id = dropped_chest_id
				M.chests[i].unlock_start_time = 0
				M.chests[i].is_opening = false
				placed_slot = i
				break
			end
		end
		if not placed_slot then
			M.add(0, 0, 10)
			reward_result.chest_id = dropped_chest_id
			reward_result.slots_full = true
			reward_result.compensation_gems = 10
		else
			reward_result.chest_id = dropped_chest_id
			reward_result.placed_slot = placed_slot
		end
	end

	M.save()
	return reward_result
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

-- Автоматически загружаем профиль при подключении модуля
M.load()

return M