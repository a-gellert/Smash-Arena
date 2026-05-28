local M = {}

----------------------------------------------------------
-- BRIDGE LOADER
----------------------------------------------------------

local bridge =  nil

local function get_bridge()
	if bridge then return bridge end
	local result =  require "bridge.bridge"
--	local ok, result = pcall(require, "bridge.bridge")
	if result then
		bridge = result
		print("[PLAYGAMA] Bridge loaded")
		
		return bridge
	else
		print("[PLAYGAMA] ⚠️ Bridge NOT loaded:", result)
		return nil
	end
end

----------------------------------------------------------
-- STATE
----------------------------------------------------------

M.initialized = false
M.ad_showing = false
M.gameplay_active = false

----------------------------------------------------------
-- LOG
----------------------------------------------------------

local function log(...)
	print("[PLAYGAMA]", ...)
	
end

----------------------------------------------------------
-- INIT
----------------------------------------------------------

function M.init()
	if M.initialized then return end
	M.initialized = true

	local b = get_bridge()
	if not b then
		log("⚠️ SDK not available (editor/native build) — using mock")
		return
	end

	-- 🔥 ВАЖНО: Подписываемся на события ДО отправки game_ready
	b.platform.on("audio_state_changed", function(_, enabled)
		log("Audio:", enabled and "ON" or "OFF")
		-- Ваша логика mute
	end)

	b.platform.on("pause_state_changed", function(_, paused)
		log("Pause:", paused and "PAUSED" or "RESUMED")
		if paused then
		--	pause_game()
		else
		--	resume_game()
		end
	end)

	-- 🔥 Отправляем game_ready ТОЛЬКО когда игра действительно готова
	-- Не в init(), а когда закончилась загрузка ресурсов/меню
	log("✅ SDK initialized — call M.send_game_ready() when game is playable")
end

-- 🔥 НОВАЯ ФУНКЦИЯ: вызывайте явно, когда игра готова к взаимодействию
function M.send_game_ready()
	local b = get_bridge()
	if not b then 
		log("Mock: game_ready")
		return 
	end

	log("📤 Sending: game_ready")
	b.platform.send_message("game_ready")
end

----------------------------------------------------------
-- GAMEPLAY MESSAGES
----------------------------------------------------------

function M.gameplay_start(world, level)
	if M.gameplay_active then return end
	M.gameplay_active = true

	local b = get_bridge()
	if not b then 
		log("Mock: level_started")
		return 
	end

	local params = nil
	if world or level then
		params = { world = world, level = level }
	end

	log("📤 Sending: level_started", world, level)
	b.platform.send_message("level_started", params)
end

function M.gameplay_stop(world, level)
	if not M.gameplay_active then return end
	M.gameplay_active = false

	local b = get_bridge()
	if not b then 
		log("Mock: level_completed")
		return 
	end

	local params = nil
	if world or level then
		params = { world = world, level = level }
	end

	log("📤 Sending: level_completed", world, level)
	b.platform.send_message("level_completed", params)
end

----------------------------------------------------------
-- INTERNAL
----------------------------------------------------------

local function pause_game()
	-- Defold example:
--	msg.post("#gameproxy", "set_time_step", { factor = 0, mode = 0 })
	log("🎮 Game paused")
end

local function resume_game()
--	msg.post("#gameproxy", "set_time_step", { factor = 1, mode = 0 })
	log("🎮 Game resumed")
end

----------------------------------------------------------
-- REWARDED (сокращённо — см. предыдущий ответ)
----------------------------------------------------------

function M.rewarded_break(on_reward, on_close)
	if M.ad_showing then return end

	local b = get_bridge()
	if not b then
		-- Mock для редактора
		log("🎁 Mock rewarded")
		if on_reward then on_reward() end
		if on_close then on_close() end
		return
	end

	if not b.advertisement.is_rewarded_supported() then
		log("⚠️ Rewarded not supported")
		if on_close then on_close() end
		return
	end

	M.ad_showing = true
	pause_game()
	M._pending_reward = on_reward
	M._pending_close = on_close

	-- Подписка на состояние (если ещё не подписаны)
	if not M._rewarded_listener then
		M._rewarded_listener = true
		b.advertisement.on("rewarded_state_changed", function(_, state)
			log("🎁 Rewarded state:", state)
			if state == "rewarded" and M._pending_reward then
				M._pending_reward()
				M._pending_reward = nil
			elseif (state == "closed" or state == "failed") and M._pending_close then
				M.ad_showing = false
				resume_game()
				M._pending_close()
				M._pending_close = nil
			end
		end)
	end

	log("📺 Showing rewarded ad")
	b.advertisement.show_rewarded()
end

----------------------------------------------------------
-- INTERSTITIAL
----------------------------------------------------------
function M.commercial_break(callback)

	if M.ad_showing then
		return
	end

	local b = get_bridge()

	if not b then
		if callback then callback() end
		return
	end

	if not M._interstitial_listener then

		M._interstitial_listener = true

		b.advertisement.on("interstitial_state_changed", function(_, state)

			log("🪧 Interstitial state:", state)

			if state == "opened" then
				pause_game()
			end

			if state == "closed"
			or state == "failed"
			or state == "skipped" then

				M.ad_showing = false

				resume_game()

				if M._pending_close then
					M._pending_close()
					M._pending_close = nil
				end
			end
		end)
	end

	M.ad_showing = true
	M._pending_close = callback

	log("📺 Showing interstitial")

	b.advertisement.show_interstitial()
end

----------------------------------------------------------

return M