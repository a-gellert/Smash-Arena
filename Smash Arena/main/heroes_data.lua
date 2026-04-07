local M = {}

-- Таблица текстов (легко вынести в JSON для локализации)
M.strings = {
	["knight_name"] = { ru = "Рыцарь", en = "Knight" },
	["knight_desc"] = { ru = "Крепкий боец ближнего боя", en = "Sturdy melee warrior" },
	["mage_name"] = { ru = "Маг", en = "Mage" },
	["mage_desc"] = { ru = "Наносит урон по площади", en = "Deals area damage" }
}

-- Основные характеристики героев
M.heroes = {
	[1] = {
		id = 1,
		name_key = "knight_name",
		desc_key = "knight_desc",
		hp = 120,
		damage = 25,
		ability_value = 10,
		ability_method = "shield_bash", -- Имя метода в скрипте
	},
	[2] = {
		id = 2,
		name_key = "mage_name",
		desc_key = "mage_desc",
		hp = 80,
		damage = 40,
		ability_value = 50,
		ability_method = "fireball",
	}
}

-- Таблица прогрессии и улучшений
M.progression = {
	[1] = { -- Ссылка по ID персонажа
		upgrade_cost_base = 100, -- Базовая стоимость
		cost_multiplier = 1.5,   -- На сколько умножаем стоимость с каждым уровнем
		hp_multiplier = 1.2,     -- Прирост здоровья за уровень
		dmg_multiplier = 1.15,    -- Прирост урона за уровень
	},
	[2] = {
		upgrade_cost_base = 150,
		cost_multiplier = 1.8,
		hp_multiplier = 1.1,
		dmg_multiplier = 1.3,
	}
}

-- Функция-помощник для получения данных с учетом уровня
function M.get_stats(hero_id, level)
	local base = M.heroes[hero_id]
	local prog = M.progression[hero_id]

	if not base or not prog then return nil end

	local lvl_factor = level - 1
	return {
		hp = math.floor(base.hp * (prog.hp_multiplier ^ lvl_factor)),
		damage = math.floor(base.damage * (prog.dmg_multiplier ^ lvl_factor)),
		upgrade_cost = math.floor(prog.upgrade_cost_base * (prog.cost_multiplier ^ lvl_factor))
	}
end

return M