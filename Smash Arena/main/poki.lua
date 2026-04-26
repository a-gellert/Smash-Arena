local M = {}

-- Проверяем, существует ли нативное расширение (доступно только в HTML5)
local has_sdk = (poki_sdk ~= nil)

-- Внутренняя функция для логирования (чтобы ты видел в консоли, что сработало)
local function log(message)
	print("[POKI WRAPPER]: " .. message)
end

function M.init()
	if has_sdk then
		poki_sdk.init()
		log("Initialized Native SDK")
	else
		log("Mock Init (Not on Web)")
	end
end

function M.gameplay_start()
	if has_sdk then
		poki_sdk.gameplay_start()
	else
		log("Mock Gameplay Start")
	end
end

function M.gameplay_stop()
	if has_sdk then
		poki_sdk.gameplay_stop()
	else
		log("Mock Gameplay Stop")
	end
end

-- Реклама за вознаграждение (Золото/Апгрейд)
-- callback - это функция, которая выполнится, если игрок досмотрел рекламу
function M.rewarded_break(callback)
	if has_sdk then
		poki_sdk.show_rewarded_break(function(self, success)
			if success and callback then
				callback()
			end
		end)
	else
		log("Mock Rewarded Break (Giving reward instantly)")
		if callback then callback() end
	end
end

-- Обычная реклама между уровнями
function M.commercial_break(callback)
	if has_sdk then
		poki_sdk.show_commercial_break(function(self)
			if callback then callback() end
		end)
	else
		log("Mock Commercial Break")
		if callback then callback() end
	end
end

return M