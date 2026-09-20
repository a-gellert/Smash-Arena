-- main/chest_loot.lua
local data = require "main.heroes_data"
local state = require "main.state"

local M = {}

-- Вероятности выпадения сундуков при победе в процентах
local CHEST_DROP_CHANCES = {
	{ id = 1, chance = 70 }, -- Common: 70%
	{ id = 2, chance = 22 }, -- Rare: 22%
	{ id = 3, chance = 7  }, -- Epic: 7%
	{ id = 4, chance = 1  }, -- Legendary: 1%
}

function M.get_random_chest_drop()
	local roll = math.random(1, 100)
	local acc = 0
	for _, item in ipairs(CHEST_DROP_CHANCES) do
		acc = acc + item.chance
		if roll <= acc then
			return item.id
		end
	end
	return 1
end

-- Расчет стоимости мгновенного открытия сундука в кристаллах
function M.get_speedup_cost(remaining_seconds)
	if remaining_seconds <= 0 then return 0 end
	-- 1 кристалл за каждые 10 минут (600 сек), округление вверх, минимум 1
	return math.max(1, math.ceil(remaining_seconds / 600))
end

-- Вспомогательная функция группировки героев по редкости
local function get_heroes_by_rarity()
	local by_rarity = { [1] = {}, [2] = {}, [3] = {} }
	for id, hero in pairs(data.heroes) do
		local r = hero.rarity or 1
		if not by_rarity[r] then by_rarity[r] = {} end
		table.insert(by_rarity[r], id)
	end
	return by_rarity
end

-- Генерация наград из сундука
function M.generate_chest_rewards(chest_id)
	local cfg = data.chest_config[chest_id]
	if not cfg then
		cfg = data.chest_config[1]
		chest_id = 1
	end

	-- 1. Золото
	local gold = math.random(cfg.gold_min, cfg.gold_max)

	-- 2. Кристаллы (алмазы)
	local diamonds = 0
	if chest_id == 2 then
		if math.random(1, 100) <= 50 then
			diamonds = math.random(1, 3)
		end
	elseif chest_id == 3 then
		diamonds = math.random(4, 10)
	elseif chest_id == 4 then
		diamonds = math.random(20, 50)
	end

	-- 3. Карточки героев
	local by_rarity = get_heroes_by_rarity()
	local total_cards = cfg.cards_count or 5
	local cards_map = {} -- [hero_id] = count

	-- Определение пула доступных редкостей для этого сундука
	local available_rarities = {}
	if cfg.rarity_chances then
		if (cfg.rarity_chances.legendary or 0) > 0 or (cfg.rarity_chances.epic or 0) >= 0.5 then
			table.insert(available_rarities, 3)
		end
		if (cfg.rarity_chances.rare or 0) > 0 then
			table.insert(available_rarities, 2)
		end
		if (cfg.rarity_chances.common or 0) > 0 then
			table.insert(available_rarities, 1)
		end
	end
	if #available_rarities == 0 then
		available_rarities = { 1 }
	end

	-- Распределяем карточки
	local remaining = total_cards
	while remaining > 0 do
		local rarity_choice = available_rarities[math.random(1, #available_rarities)]
		local pool = by_rarity[rarity_choice]
		if not pool or #pool == 0 then
			pool = by_rarity[1]
		end

		local chosen_hero_id = pool[math.random(1, #pool)]
		local count = math.min(remaining, math.random(1, math.max(1, math.ceil(total_cards / 2))))
		cards_map[chosen_hero_id] = (cards_map[chosen_hero_id] or 0) + count
		remaining = remaining - count
	end

	-- Формируем структурированный список наград
	local cards_list = {}
	for hero_id, amount in pairs(cards_map) do
		local hero = data.heroes[hero_id]
		table.insert(cards_list, {
			hero_id = hero_id,
			amount = amount,
			name = data.get_name(hero_id, "en"),
			icon = hero and hero.name_key or "paladin",
			rarity = hero and hero.rarity or 1
		})
	end

	return {
		chest_id = chest_id,
		chest_name = cfg.name,
		chest_color = cfg.color,
		gold = gold,
		diamonds = diamonds,
		cards = cards_list
	}
end

-- Применение наград к профилю игрока
function M.apply_rewards(rewards)
	if not rewards then return end

	if (rewards.gold and rewards.gold > 0) or (rewards.diamonds and rewards.diamonds > 0) then
		state.add(0, rewards.gold or 0, rewards.diamonds or 0)
	end

	if rewards.cards then
		for _, card in ipairs(rewards.cards) do
			state.add_cards(card.hero_id, card.amount)
		end
	end

	state.save()
end

return M
