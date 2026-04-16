local M = {}

-- Локализация имен и описаний
M.strings = {
	["paladin_name"] = { ru = "Паладин", en = "Paladin" },
	["paladin_desc"] = { ru = "Стена: После остановки восстанавливает себе ability_value HP.", en = "Wall: Heals ability_value HP after stopping." },

	["berserker_name"] = { ru = "Берсерк", en = "Berserker" },
	["berserker_desc"] = { ru = "Ярость: Если здоровье меньше ability_value% урон увеличивается в 2 раза.", en = "Rage: If health is below ability_value%, damage is doubled." },

	["tank_name"] = { ru = "Танк", en = "Tank" },
	["tank_desc"] = { ru = "Волна: В конце хода отталкивает от себя всех, нанося врагам ability_value урона", en = "Wave: At the end of its turn, it pushes everyone away, dealing ability_value damage to enemies" },

	["reaper_name"] = { ru = "Жнец", en = "Reaper" },
	["reaper_desc"] = { ru = "Жатва: При убийстве восстанавливает ability_value Здоровья.", en = "Harvest: Restores ability_value HP on kill." },

	["ice_mage_name"] = { ru = "Маг Льда", en = "Ice Mage" },
	["ice_mage_desc"] = { ru = "Заморозка: Ударенный враг теряет ability_value скорости на след. ход.", en = "Freeze: Hit enemy loses ability_value speed next turn." },

	["bomber_name"] = { ru = "Подрывник", en = "Bomber" },
	["bomber_desc"] = { ru = "Детонация: При смерти наносит ability_value урона всем вокруг.", en = "Detonation: Deals ability_value AOE damage on death." },

	["monk_name"] = { ru = "Монах", en = "Monk" },
	["monk_desc"] = { ru = "Молитва: При столкновении с дружественным воином восстанавливает ability_value HP.", en = "Prayer: Restores ability_value HP when encountering an ally" },

	["vampire_name"] = { ru = "Вампир", en = "Vampire" },
	["vampire_desc"] = { ru = "Связь: Крадет ability_value% нанесенного урона в свое здоровье.", en = "Link: Steals ability_value% of dealt damage as HP." },

	["golem_name"] = { ru = "Голем", en = "Golem" },
	["golem_desc"] = { ru = "Твердыня: Не подвержен заклятиям", en = "Stronghold: Not susceptible to spells" },

	["wraith_name"] = { ru = "Призрак", en = "Wraith" },
	["wraith_desc"] = { ru = "Эфир: ability_value% шанс полностью игнорировать урон.", en = "Ethereal: ability_value% chance to ignore any damage." }
}

-- Характеристики героев
-- Масса и Скорость - это множители для физики Defold
M.heroes = {
	[1] = { id = 1, rarity = 1 , name_key = "paladin_name", desc_key = "paladin_desc", hp = 110, damage = 15, mass = 2.5, speed_mult = 1.1,ability_value = 5, ability_method  = "heal_on_stop" },
	[2] = { id = 2, rarity = 1 , name_key = "berserker_name", desc_key = "berserker_desc", hp = 84, damage = 22, mass = 1.2, speed_mult = 1.3,ability_value = 25, ability_method  = "rage_damage" },
	[3] = { id = 3, rarity = 1 , name_key = "tank_name", desc_key = "tank_desc", hp = 128, damage = 12, mass = 5.0, speed_mult = 1.0 ,ability_value = 10, ability_method  = "heavy_impact" },
	[4] = { id = 4, rarity = 2 , name_key = "reaper_name", desc_key = "reaper_desc", hp = 60, damage = 19, mass = 0.8, speed_mult = 1.4,ability_value = 20, ability_method  = "life_steal_kill" },
	[5] = { id = 5, rarity = 2 , name_key = "ice_mage_name", desc_key = "ice_mage_desc", hp = 75, damage = 14, mass = 1.1, speed_mult = 1.0,ability_value = 30, ability_method  = "freeze_hit" },
	[6] = { id = 6, rarity = 2 , name_key = "bomber_name", desc_key = "bomber_desc", hp = 74, damage = 22, mass = 1.0, speed_mult = 1.1,ability_value = 50, ability_method  = "death_explosion" },
	[7] = { id = 7, rarity = 2 , name_key = "monk_name", desc_key = "monk_desc", hp = 94, damage = 17, mass = 1.5, speed_mult = 1.3,ability_value = 10, ability_method  = "touch_heal" },
	[8] = { id = 8, rarity = 3 , name_key = "vampire_name", desc_key = "vampire_desc", hp = 116, damage = 19, mass = 1.1, speed_mult = 1.2,ability_value = 30, ability_method  = "life_leech" },
	[9] = { id = 9, rarity = 3 , name_key = "golem_name", desc_key = "golem_desc", hp = 138, damage = 14, mass = 8.0, speed_mult = 1.2,ability_value = 100, ability_method  = "stationary_shield" },
	[10] = { id = 10, rarity = 3 , name_key = "wraith_name", desc_key = "wraith_desc", hp = 57, damage = 21, mass = 0.5, speed_mult = 1.5,ability_value = 25, ability_method  = "evasion" }
}

-- Прогрессия (универсальные множители для всех для начала)
M.progression_default = {
	upgrade_cost_base = 100,
	cost_multiplier = 1.4,
	hp_multiplier = 1.15,
	dmg_multiplier = 1.12
}

-- Получение данных с расчетом уровня
function M.get_stats(hero_id, level)
	local base = M.heroes[hero_id]
	local prog = M.progression_default -- Можно сделать кастомным для каждого позже

	if not base then return nil end

	local lvl_factor = level - 1
	return {
		hp = math.floor(base.hp * (prog.hp_multiplier ^ lvl_factor)),
		damage = math.floor(base.damage * (prog.dmg_multiplier ^ lvl_factor)),
		mass = base.mass, -- Массу обычно не меняем, чтобы не ломать физику
		speed = base.speed_mult,
		upgrade_cost = math.floor(prog.upgrade_cost_base * (prog.cost_multiplier ^ lvl_factor))
	}
end

-- Получение имени
function M.get_name(hero_id, lang)
	lang = lang or "ru" -- По умолчанию русский, если не указан
	local hero = M.heroes[hero_id]

	if hero and hero.name_key then
		local string_entry = M.strings[hero.name_key]
		return string_entry and string_entry[lang] or "Unknown"
	end

	return "Hero Not Found"
end

return M