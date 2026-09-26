-- main/i18n.lua
-- Localization module for Smash Arena (Russian and English)
-- Detects platform language using the SDK (Playgama / mobile sys_info fallback)

local sdk = require "main.sdk"

local M = {}

M.LANG_RU = "ru"
M.LANG_EN = "en"

local current_lang = nil

----------------------------------------------------------
-- LOCALIZATION DICTIONARY
----------------------------------------------------------
M.DICTIONARY = {
	-- Tutorial
	step_1 = {
		en = "Pull and shoot at the enemies!",
		ru = "Натяни и пуляй во врагов!",
	},
	step_2 = {
		en = "Each hero has a unique ability!",
		ru = "У каждого героя есть своя способность!",
	},
	step_3 = {
		en = "The Tank deals damage to nearby enemies after its turn.",
		ru = "Танк наносит урон ближайшим врагам после окончания хода.",
	},
	step_4 = {
		en = "Players take turns sequentially. Good luck!",
		ru = "Игроки ходят по очереди. Удачи!",
	},
	tutorial_team = {
		en = "This is your team. Time to battle!",
		ru = "Это твоя команда. Пора в бой!",
	},
	tutorial_trophy = {
		en = "Look, you earned a trophy!",
		ru = "Смотри, ты заработал трофей!",
	},

	-- Main Menu & Navigation
	play = {
		en = "Play",
		ru = "В бой",
	},
	your_gang = {
		en = "Your Gang",
		ru = "Твоя банда",
	},
	enemy = {
		en = "Enemy",
		ru = "Враг",
	},
	the_enemy_team = {
		en = "The Enemy\nTeam",
		ru = "Вражеская\nкоманда",
	},
	your_team = {
		en = "Your\nTeam",
		ru = "Твоя\nкоманда",
	},
	my_deck = {
		en = "My Deck",
		ru = "Моя колода",
	},
	all_cards = {
		en = "All Cards",
		ru = "Все карты",
	},
	use = {
		en = "USE",
		ru = "ВЫБРАТЬ",
	},
	choose_place = {
		en = "Choose Place",
		ru = "Выбери слот",
	},
	ok = {
		en = "OK",
		ru = "ОК",
	},
	claim = {
		en = "CLAIM",
		ru = "ЗАБРАТЬ",
	},
	continue_btn = {
		en = "CONTINUE",
		ru = "ДАЛЕЕ",
	},
	open = {
		en = "OPEN",
		ru = "ОТКРЫТЬ",
	},
	wait = {
		en = "WAIT",
		ru = "ЖДАТЬ",
	},
	max = {
		en = "MAX",
		ru = "МАКС",
	},
	lvl = {
		en = "Lvl %s",
		ru = "Ур. %s",
	},
	gold_suffix = {
		en = "gold",
		ru = "золота",
	},
	gems_suffix = {
		en = "Gems",
		ru = "Алмазов",
	},

	-- Battle & End Game
	your_turn = {
		en = "Your turn",
		ru = "Твой ход",
	},
	enemys_turn = {
		en = "Enemy's turn",
		ru = "Ход противника",
	},
	victory = {
		en = "VICTORY",
		ru = "ПОБЕДА",
	},
	defeat = {
		en = "DEFEAT",
		ru = "ПОРАЖЕНИЕ",
	},

	-- Settings
	settings = {
		en = "SETTINGS",
		ru = "НАСТРОЙКИ",
	},
	sound_off = {
		en = "SOUND: OFF",
		ru = "ЗВУКИ: ВЫКЛ",
	},
	sound_pct = {
		en = "SOUND: %d%%",
		ru = "ЗВУКИ: %d%%",
	},
	music_off = {
		en = "MUSIC: OFF",
		ru = "МУЗЫКА: ВЫКЛ",
	},
	music_pct = {
		en = "MUSIC: %d%%",
		ru = "МУЗЫКА: %d%%",
	},

	-- Arenas / Worlds
	arena_prefix = {
		en = "ARENA %s",
		ru = "АРЕНА %s",
	},
	locked = {
		en = "LOCKED",
		ru = "ЗАКРЫТО",
	},
	active = {
		en = "ACTIVE",
		ru = "ВЫБРАНО",
	},
	select_btn = {
		en = "SELECT",
		ru = "ВЫБРАТЬ",
	},
	prestige_req = {
		en = "Requires %d Prestige (have: %d)",
		ru = "Нужно %d престижа (у вас: %d)",
	},

	-- Wheel of Fortune
	wheel_title = {
		en = "LUCKY WHEEL",
		ru = "КОЛЕСО УДАЧИ",
	},
	wheel_status_ready = {
		en = "Daily Free Spin Ready!",
		ru = "Бесплатный спин дня готов!",
	},
	wheel_status_watch_ad = {
		en = "Watch AD for new spin!",
		ru = "Смотри рекламу для нового спина!",
	},
	wheel_spinning = {
		en = "Spinning...",
		ru = "Вращаем колесо...",
	},
	free_spin = {
		en = "FREE SPIN",
		ru = "БЕСПЛАТНО",
	},
	spin_ad = {
		en = "SPIN (AD)",
		ru = "СПИН (РЕКЛАМА)",
	},
	free_badge = {
		en = "FREE",
		ru = "БЕСПЛ.",
	},
	you_won = {
		en = "🎉 YOU WON! 🎉",
		ru = "🎉 ВЫИГРЫШ! 🎉",
	},
	won_gold_title = {
		en = "+%d GOLD",
		ru = "+%d ЗОЛОТА",
	},
	won_gems_title = {
		en = "+%d GEMS",
		ru = "+%d АЛМАЗОВ",
	},
	won_label_gold = {
		en = "+%d Gold",
		ru = "+%d Золота",
	},
	won_label_gems = {
		en = "+%d Gems",
		ru = "+%d Алмазов",
	},
	won_chest = {
		en = "Chest",
		ru = "Сундук",
	},
	won_prefix = {
		en = "Won: %s! ",
		ru = "Выигрыш: %s! ",
	},
	won_status = {
		en = "Won: %s!",
		ru = "Выигрыш: %s!",
	},
	added_to_balance = {
		en = "Added to your balance!",
		ru = "Начислено на ваш счет!",
	},
	hero_upgrade_cards = {
		en = "Hero upgrade cards!",
		ru = "Карты для улучшения героя!",
	},
	slots_full_comp = {
		en = "Slots full! Compensation granted.",
		ru = "Слоты полны! Даны алмазы.",
	},
	mystery_chest = {
		en = "MYSTERY CHEST!",
		ru = "ТАИНСТВЕННЫЙ СУНДУК!",
	},
	added_to_chest_slots = {
		en = "Added to chest slots!",
		ru = "Добавлен в слот сундуков!",
	},

	-- Chests & Rewards
	tap_to_open = {
		en = "Tap to open rewards!",
		ru = "Нажми, чтобы открыть!",
	},
	chest_unlocked = {
		en = "CHEST UNLOCKED",
		ru = "СУНДУК ОТКРЫТ",
	},
	gold_reward = {
		en = "GOLD REWARD",
		ru = "НАГРАДА ЗОЛОТОМ",
	},
	gems_reward = {
		en = "GEMS REWARD",
		ru = "НАГРАДА АЛМАЗАМИ",
	},
	cards_reward = {
		en = "Cards Reward",
		ru = "Награда картами",
	},
	reward_gold = {
		en = "+%s Gold",
		ru = "+%s Золота",
	},
	reward_diamonds = {
		en = "+%s Diamonds!",
		ru = "+%s Алмазов!",
	},
	all_rewards_collected = {
		en = "ALL REWARDS COLLECTED!",
		ru = "ВСЕ НАГРАДЫ СОБРАНЫ!",
	},
	all_rewards_added = {
		en = "All rewards added to inventory",
		ru = "Все награды добавлены в инвентарь",
	},
	unlock_instantly = {
		en = "Unlock Instantly?",
		ru = "Открыть сейчас?",
	},
	open_immediately = {
		en = "Open %s immediately?",
		ru = "Открыть %s немедленно?",
	},
	time_left = {
		en = "Time left: %s",
		ru = "Осталось: %s",
	},
	open_cost = {
		en = "OPEN (%s)",
		ru = "ОТКРЫТЬ (%s)",
	},
	not_enough_diamonds = {
		en = "Not enough diamonds!\nYou need %d diamonds.",
		ru = "Недостаточно кристаллов!\nНужно %d шт.",
	},

	-- Unit stats
	hp = {
		en = "HP",
		ru = "ОЗ",
	},
	dmg = {
		en = "DMG",
		ru = "УРОН",
	},
	spd = {
		en = "SPD",
		ru = "СКОР",
	},
	dead_tag = {
		en = " (Dead)",
		ru = " (Мёртв)",
	},
}

----------------------------------------------------------
-- LANGUAGE RESOLUTION
----------------------------------------------------------
function M.resolve_language()
	local raw = sdk.get_language()
	if raw then
		local lower = string.lower(tostring(raw))
		if lower:find("^ru") or lower:find("^be") or lower:find("^uk") or lower:find("^kk") then
			return M.LANG_RU
		end
	end
	return M.LANG_EN
end

function M.get_language()
	if not current_lang then
		current_lang = M.resolve_language()
	end
	return current_lang
end

function M.set_language(lang)
	if lang == M.LANG_RU or lang == M.LANG_EN then
		current_lang = lang
	else
		current_lang = M.resolve_language()
	end
end

function M.is_ru()
	return M.get_language() == M.LANG_RU
end

----------------------------------------------------------
-- TRANSLATION API
----------------------------------------------------------
function M.t(key, ...)
	local lang = M.get_language()
	local entry = M.DICTIONARY[key]
	local str = (entry and entry[lang]) or (entry and entry[M.LANG_EN]) or key
	if ... ~= nil then
		local ok, res = pcall(string.format, str, ...)
		if ok then return res end
	end
	return str
end

return M
