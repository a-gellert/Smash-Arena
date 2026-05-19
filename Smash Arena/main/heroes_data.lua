--heroes_data.lua
local M = {}

-- Локализация имен и описаний
M.strings = {
	["paladin"]      = { ru = "Паладин",    en = "Paladin"   },
	["paladin_desc"] = { ru = "Стена: После остановки восстанавливает себе ability_value HP.",            en = "Wall: Heals ability_value HP after stopping."                           },

	["berserker"]      = { ru = "Берсерк",   en = "Berserker" },
	["berserker_desc"] = { ru = "Ярость: Если здоровье меньше ability_value% урон увеличивается в 2 раза.", en = "Rage: If health is below ability_value%, damage is doubled."            },

	["tank"]      = { ru = "Танк",      en = "Tank"      },
	["tank_desc"] = { ru = "Волна: В конце хода отталкивает всех, нанося врагам ability_value урона.",    en = "Wave: At the end of its turn pushes everyone, dealing ability_value damage to enemies." },

	["reaper"]      = { ru = "Жнец",     en = "Reaper"   },
	["reaper_desc"] = { ru = "Жатва: При убийстве восстанавливает ability_value Здоровья.",               en = "Harvest: Restores ability_value HP on kill."                            },

	["ice_mage"]      = { ru = "Маг Льда", en = "Ice Mage" },
	["ice_mage_desc"] = { ru = "Заморозка: Ударенный враг теряет ability_value скорости на след. ход.",    en = "Freeze: Hit enemy loses ability_value speed next turn."                },

	["bomber"]      = { ru = "Подрывник", en = "Bomber"   },
	["bomber_desc"] = { ru = "Детонация: При смерти наносит ability_value урона всем вокруг.",            en = "Detonation: Deals ability_value AOE damage on death."                  },

	["monk"]      = { ru = "Монах",   en = "Monk"      },
	["monk_desc"] = { ru = "Молитва: При столкновении с союзником восстанавливает ability_value HP.",      en = "Prayer: Restores ability_value HP when touching an ally."              },

	["vampire"]      = { ru = "Вампир",  en = "Vampire"  },
	["vampire_desc"] = { ru = "Связь: Крадет ability_value% нанесенного урона в свое здоровье.",          en = "Link: Steals ability_value% of dealt damage as HP."                    },

	["golem"]      = { ru = "Голем",   en = "Golem"     },
	["golem_desc"] = { ru = "Твердыня: Не подвержен заклятиям.",                                          en = "Stronghold: Not susceptible to spells."                                },

	["wraith"]      = { ru = "Призрак", en = "Wraith"   },
	["wraith_desc"] = { ru = "Эфир: ability_value% шанс полностью игнорировать урон.",                   en = "Ethereal: ability_value% chance to ignore any damage."                 },
}

-- ─────────────────────────────────────────────────────────────
--  БАЗОВЫЕ ХАРАКТЕРИСТИКИ ГЕРОЕВ (уровень 1)
-- ─────────────────────────────────────────────────────────────
M.heroes = {
	[1]  = { id=1,  rarity=1, name_key="paladin",    desc_key="paladin_desc",    hp=88,  damage=15, mass=2.5, speed_mult=1.1, ability_value=5,   ability_method="heal_on_stop"     },
	[2]  = { id=2,  rarity=1, name_key="berserker",  desc_key="berserker_desc",  hp=67,  damage=22, mass=1.2, speed_mult=1.3, ability_value=95,  ability_method="rage_damage"      },
	[3]  = { id=3,  rarity=1, name_key="tank",       desc_key="tank_desc",       hp=102, damage=12, mass=5.0, speed_mult=1.5, ability_value=10,  ability_method="heavy_impact"     },
	[4]  = { id=4,  rarity=2, name_key="reaper",     desc_key="reaper_desc",     hp=48,  damage=19, mass=0.8, speed_mult=1.4, ability_value=20,  ability_method="life_steal_kill"  },
	[5]  = { id=5,  rarity=2, name_key="ice_mage",   desc_key="ice_mage_desc",   hp=60,  damage=14, mass=1.1, speed_mult=1.0, ability_value=30,  ability_method="freeze_hit"       },
	[6]  = { id=6,  rarity=2, name_key="bomber",     desc_key="bomber_desc",     hp=59,  damage=22, mass=1.0, speed_mult=1.1, ability_value=50,  ability_method="death_explosion"  },
	[7]  = { id=7,  rarity=2, name_key="monk",       desc_key="monk_desc",       hp=75,  damage=17, mass=1.5, speed_mult=1.3, ability_value=10,  ability_method="touch_heal"       },
	[8]  = { id=8,  rarity=3, name_key="vampire",    desc_key="vampire_desc",    hp=93,  damage=19, mass=1.1, speed_mult=1.2, ability_value=30,  ability_method="life_leech"       },
	[9]  = { id=9,  rarity=3, name_key="golem",      desc_key="golem_desc",      hp=110, damage=14, mass=8.0, speed_mult=1.2, ability_value=100, ability_method="stationary_shield"},
	[10] = { id=10, rarity=3, name_key="wraith",     desc_key="wraith_desc",     hp=46,  damage=21, mass=0.5, speed_mult=1.5, ability_value=25,  ability_method="evasion"          },
}
-- Добавь это в heroes_data.lua или создай chest_data.lua
M.chest_config = {
	[1] = { -- Common
		name = "Common Chest",
		color = vmath.vector4(0.5, 0.5, 0.5, 1),
		time = 60, -- секунд
		gold_min = 20, gold_max = 50,
		cards_count = 5,
		rarity_chances = { common = 1.0, rare = 0.1, epic = 0.0 }
	},
	[2] = { -- Rare
		name = "Rare Chest",
		color = vmath.vector4(0.2, 0.6, 1, 1),
		time = 1800, -- 30 минут
		gold_min = 100, gold_max = 250,
		cards_count = 20,
		rarity_chances = { common = 1.0, rare = 1.0, epic = 0.05 }
	},
	[3] = { -- Epic
		name = "Epic Chest",
		color = vmath.vector4(0.7, 0.2, 1, 1),
		time = 21600, -- 6 часов
		gold_min = 500, gold_max = 800,
		cards_count = 50,
		rarity_chances = { common = 1.0, rare = 1.0, epic = 1.0 }
	},
	[4] = { -- Legendary
		name = "Legendary Chest",
		color = vmath.vector4(1, 0.8, 0, 1),
		time = 86400, -- 24 часа
		gold_min = 2000, gold_max = 3500,
		cards_count = 1,
		rarity_chances = { common = 0, rare = 0, epic = 0, legendary = 1.0 }
	}
}
-- ─────────────────────────────────────────────────────────────
--  ТАБЛИЦА УРОВНЕЙ (Clash Royale style)
--  Каждый уровень: { cards = карт для апгрейда, gold = стоимость }
--  Уровней всего 13 (как в CR), после 13-го — максимум.
-- ─────────────────────────────────────────────────────────────
M.MAX_LEVEL = 13

-- cards  = сколько карт нужно для подъёма НА этот уровень
-- gold   = сколько золота стоит апгрейд
M.upgrade_table = {
	-- lvl  cards  gold
	[1]  = { cards=2,    gold=50    },
	[2]  = { cards=4,    gold=100   },
	[3]  = { cards=10,   gold=200   },
	[4]  = { cards=20,   gold=400   },
	[5]  = { cards=50,   gold=800   },
	[6]  = { cards=100,  gold=1000  },
	[7]  = { cards=200,  gold=1500  },
	[8]  = { cards=400,  gold=2000  },
	[9]  = { cards=800,  gold=3000  },
	[10] = { cards=1000, gold=4000  },
	[11] = { cards=1500, gold=6000  },
	[12] = { cards=2000, gold=8000  },
	[13] = { cards=0,    gold=0     },  -- макс. уровень, апгрейд недоступен
}

-- ─────────────────────────────────────────────────────────────
--  МНОЖИТЕЛИ ПРОГРЕССИИ ПО УРОВНЯМ
--  hp_mult и dmg_mult — накопленные множители (не от предыдущего,
--  а от базы), чтобы балансировать точнее, как в CR.
-- ─────────────────────────────────────────────────────────────
M.level_multipliers = {
	-- lvl   hp      dmg
	[1]  = { hp=1.00, dmg=1.00 },
	[2]  = { hp=1.10, dmg=1.10 },
	[3]  = { hp=1.21, dmg=1.21 },
	[4]  = { hp=1.33, dmg=1.33 },
	[5]  = { hp=1.46, dmg=1.46 },
	[6]  = { hp=1.61, dmg=1.61 },
	[7]  = { hp=1.77, dmg=1.77 },
	[8]  = { hp=1.95, dmg=1.95 },
	[9]  = { hp=2.14, dmg=2.14 },
	[10] = { hp=2.35, dmg=2.35 },
	[11] = { hp=2.59, dmg=2.59 },
	[12] = { hp=2.85, dmg=2.85 },
	[13] = { hp=3.13, dmg=3.13 },
}

-- ─────────────────────────────────────────────────────────────
--  ПОЛУЧЕНИЕ СТАТОВ С УЧЁТОМ УРОВНЯ
-- ─────────────────────────────────────────────────────────────
function M.get_stats(hero_id, level)
	local base = M.heroes[hero_id]
	if not base then return nil end

	level = math.max(1, math.min(level or 1, M.MAX_LEVEL))
	local mult = M.level_multipliers[level]

	return {
		hp      = math.floor(base.hp     * mult.hp),
		damage  = math.floor(base.damage * mult.dmg),
		mass    = base.mass,
		speed   = base.speed_mult,
		-- Стоимость апгрейда с текущего level на следующий
		upgrade_cost  = M.upgrade_table[level] and M.upgrade_table[level].gold  or 0,
		cards_required = M.upgrade_table[level] and M.upgrade_table[level].cards or 0,
	}
end

-- ─────────────────────────────────────────────────────────────
--  ПРОВЕРКА ВОЗМОЖНОСТИ АПГРЕЙДА
--  Возвращает: can_up(bool), gold_cost, cards_req
-- ─────────────────────────────────────────────────────────────
function M.can_upgrade(hero_id, current_level, player_gold, player_cards)
	if current_level >= M.MAX_LEVEL then
		return false, 0, 0
	end

	local row = M.upgrade_table[current_level]
	if not row then return false, 0, 0 end

	local gold_cost  = row.gold
	local cards_req  = row.cards

	local can_up = (player_gold >= gold_cost) and (player_cards >= cards_req)
	return can_up, gold_cost, cards_req
end

-- ─────────────────────────────────────────────────────────────
--  ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ЛОКАЛИЗАЦИИ
-- ─────────────────────────────────────────────────────────────
local function format_text(text, value)
	if not text then return "" end
	return string.gsub(text, "ability_value", tostring(value))
end

function M.get_name(hero_id, lang)
	lang = lang or "en"
	local hero = M.heroes[hero_id]
	if hero and hero.name_key then
		local entry = M.strings[hero.name_key]
		return entry and entry[lang] or "Unknown"
	end
	return "Hero Not Found"
end

function M.get_description(hero_id, lang)
	lang = lang or "en"
	local hero = M.heroes[hero_id]
	if hero and M.strings[hero.desc_key] then
		local raw = M.strings[hero.desc_key][lang]
		return format_text(raw, hero.ability_value)
	end
	return "No description."
end

function M.get_name_key(hero_id)
	return M.heroes[hero_id]
end

return M