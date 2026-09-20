-- main/poki.lua
-- Official Defold Poki SDK Extension Adapter with Editor/Native Fallback Mock

local M = {}

----------------------------------------------------------
-- CONSTANTS & FALLBACK STATUSES
----------------------------------------------------------
local COMMERCIAL_BREAK_START   = 1
local COMMERCIAL_BREAK_SUCCESS = 2
local COMMERCIAL_BREAK_ERROR   = 3

local REWARDED_BREAK_START     = 1
local REWARDED_BREAK_SUCCESS   = 2
local REWARDED_BREAK_ERROR     = 3

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
	print("[POKI SDK]", ...)
end

----------------------------------------------------------
-- AUDIO / GAMEPLAY PAUSE HELPERS
----------------------------------------------------------
local function pause_game()
	log("🎮 Game paused (commercial/rewarded break active)")
	-- If using master audio buses in Defold:
	-- pcall(function() sound.set_group_gain("master", 0) end)
end

local function resume_game()
	log("🎮 Game resumed")
	-- pcall(function() sound.set_group_gain("master", 1) end)
end

----------------------------------------------------------
-- SDK DETECTION HELPER
----------------------------------------------------------
local function get_poki_sdk()
	if rawget(_G, "poki_sdk") ~= nil then
		return _G.poki_sdk
	end
	return nil
end

----------------------------------------------------------
-- INITIALIZATION
----------------------------------------------------------
function M.init()
	if M.initialized then return end
	M.initialized = true

	local sdk = get_poki_sdk()
	if sdk then
		log("✅ Native Poki SDK extension detected in HTML5 build")
	else
		log("ℹ️ Running in Editor / Native build — Using Poki SDK Mock")
	end
end

-- Poki: gameLoadingFinished (called when game assets & main menu are ready)
function M.send_game_ready()
	local sdk = get_poki_sdk()
	if sdk then
		log("📤 PokiSDK: game_loading_finished()")
		if sdk.game_loading_finished then
			sdk.game_loading_finished()
		elseif sdk.gameLoadingFinished then
			sdk.gameLoadingFinished()
		end
	else
		log("Mock: game_loading_finished()")
	end
end

----------------------------------------------------------
-- GAMEPLAY START / STOP
----------------------------------------------------------
-- gameplay_start: Call when player starts interacting or battle begins
function M.gameplay_start(world, level)
	if M.gameplay_active then return end
	M.gameplay_active = true

	local sdk = get_poki_sdk()
	if sdk then
		log("📤 PokiSDK: gameplay_start()", world, level)
		if sdk.gameplay_start then
			sdk.gameplay_start()
		elseif sdk.gameplayStart then
			sdk.gameplayStart()
		end
	else
		log("Mock: gameplay_start()", world, level)
	end
end

-- gameplay_stop: Call on pause, game over, victory, or return to menu
function M.gameplay_stop(world, level)
	if not M.gameplay_active then return end
	M.gameplay_active = false

	local sdk = get_poki_sdk()
	if sdk then
		log("📤 PokiSDK: gameplay_stop()", world, level)
		if sdk.gameplay_stop then
			sdk.gameplay_stop()
		elseif sdk.gameplayStop then
			sdk.gameplayStop()
		end
	else
		log("Mock: gameplay_stop()", world, level)
	end
end

----------------------------------------------------------
-- CELEBRATION / HAPPY TIME
----------------------------------------------------------
-- intensity: 0.0 (subtle) to 1.0 (huge achievement/win)
function M.happy_time(intensity)
	intensity = intensity or 1.0
	local sdk = get_poki_sdk()
	if sdk then
		log("🎉 PokiSDK: happy_time(" .. tostring(intensity) .. ")")
		if sdk.happy_time then
			sdk.happy_time(intensity)
		elseif sdk.happyTime then
			sdk.happyTime(intensity)
		end
	else
		log("Mock: happy_time(" .. tostring(intensity) .. ")")
	end
end

----------------------------------------------------------
-- CUSTOM ANALYTICS (PokiSDK.measure)
----------------------------------------------------------
-- Poki specification: PokiSDK.measure(category, what, action)
-- category: broad group (e.g. 'round', 'tutorial', 'level', 'chest', 'hero')
-- what: specific identifier (e.g. '1', 'step_1', 'arena')
-- action: event outcome - must be strictly 'start', 'complete', or 'fail'
M.current_round = 1

function M.measure(category, what, action)
	local sdk = get_poki_sdk()
	if sdk and sdk.measure then
		log("📊 PokiSDK: measure('" .. tostring(category) .. "', '" .. tostring(what) .. "', '" .. tostring(action) .. "')")
		pcall(function() sdk.measure(tostring(category), tostring(what), tostring(action)) end)
	else
		log("Mock measure:", category, what, action)
	end
end

function M.round_start(round_num)
	M.current_round = tonumber(round_num) or M.current_round or 1
	M.measure("round", tostring(M.current_round), "start")
end

function M.round_end(victory, round_or_reason)
	local r = tonumber(round_or_reason) or M.current_round or 1
	local action = victory and "complete" or "fail"
	M.measure("round", tostring(r), action)
end

function M.tutorial_started()
	M.measure("tutorial", "step_1", "start")
end

function M.tutorial_completed()
	M.measure("tutorial", "step_1", "complete")
end

function M.chest_opened(chest_id, chest_name)
	local name = tostring(chest_name or chest_id or "chest")
	M.measure("chest", name, "complete")
end

function M.hero_upgraded(hero_id, new_level)
	local tag = tostring(hero_id) .. "_lvl" .. tostring(new_level)
	M.measure("hero", tag, "complete")
end

----------------------------------------------------------
-- COMMERCIAL BREAK (INTERSTITIAL ADS)
----------------------------------------------------------
function M.commercial_break(callback)
	if M.ad_showing then
		if callback then callback() end
		return
	end

	local sdk = get_poki_sdk()
	if not sdk or not sdk.commercial_break then
		log("📺 Mock commercial_break")
		if callback then callback() end
		return
	end

	M.ad_showing = true
	local status_start = sdk.COMMERCIAL_BREAK_START or COMMERCIAL_BREAK_START
	local status_success = sdk.COMMERCIAL_BREAK_SUCCESS or COMMERCIAL_BREAK_SUCCESS
	local status_error = sdk.COMMERCIAL_BREAK_ERROR or COMMERCIAL_BREAK_ERROR

	log("📺 Requesting Poki commercial_break...")
	sdk.commercial_break(function(self, status)
		log("🪧 Commercial break status:", status)
		if status == status_start then
			pause_game()
		elseif status == status_success or status == status_error then
			M.ad_showing = false
			resume_game()
			if callback then
				callback()
			end
		end
	end)
end

----------------------------------------------------------
-- REWARDED BREAK (REWARDED ADS)
----------------------------------------------------------
-- size: "small" (default), "medium", or "large"
function M.rewarded_break(on_reward, on_close, size)
	if M.ad_showing then
		if on_close then on_close() end
		return
	end

	local sdk = get_poki_sdk()
	if not sdk or not sdk.rewarded_break then
		log("🎁 Mock rewarded_break (granting reward)")
		if on_reward then on_reward() end
		if on_close then on_close() end
		return
	end

	M.ad_showing = true
	local status_start = sdk.REWARDED_BREAK_START or REWARDED_BREAK_START
	local status_success = sdk.REWARDED_BREAK_SUCCESS or REWARDED_BREAK_SUCCESS
	local status_error = sdk.REWARDED_BREAK_ERROR or REWARDED_BREAK_ERROR

	local reward_size = size or "small"
	log("🎁 Requesting Poki rewarded_break (" .. reward_size .. ")...")

	sdk.rewarded_break(reward_size, function(self, status)
		log("🎁 Rewarded break status:", status)
		if status == status_start then
			pause_game()
		elseif status == status_success then
			M.ad_showing = false
			resume_game()
			if on_reward then on_reward() end
			if on_close then on_close() end
		elseif status == status_error then
			M.ad_showing = false
			resume_game()
			if on_close then on_close() end
		end
	end)
end

----------------------------------------------------------
-- UTILITIES / DEVICE INFO
----------------------------------------------------------
function M.is_adblock_detected()
	local sdk = get_poki_sdk()
	if sdk then
		if sdk.is_ad_blocked then
			return sdk.is_ad_blocked()
		elseif sdk.is_adblock_detected then
			return sdk.is_adblock_detected()
		end
	end
	return false
end

function M.get_device_info()
	local sdk = get_poki_sdk()
	if sdk and sdk.get_device_info then
		return sdk.get_device_info()
	end
	return {
		is_mobile = false,
		is_tablet = false,
		is_desktop = true
	}
end

function M.get_shareable_url(params)
	local sdk = get_poki_sdk()
	if sdk and sdk.shareable_url then
		return sdk.shareable_url(params or {})
	end
	return nil
end

return M