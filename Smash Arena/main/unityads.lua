-- main/unityads.lua
-- Unity Ads Manager for Defold (iOS & Android) with local Mock fallback

local M = {}

----------------------------------------------------------
-- CONFIGURATION & DEFAULT IDs
----------------------------------------------------------
-- Default Unity Ads test Game IDs:
-- Android: 1401815
-- iOS: 1425385
-- Standard placement IDs:
-- Interstitial: "Interstitial_Android" or "video"
-- Rewarded: "Rewarded_Android" or "rewardedVideo"
-- Banner: "Banner_Android" or "banner"
local CONFIG = {
	game_id = {
		android = sys.get_config_string("unityads.game_id_android", "6194929"),
		ios     = sys.get_config_string("unityads.game_id_ios", "6194928"),
	},
	placements = {
		interstitial = sys.get_config_string("unityads.interstitial_placement", "Interstitial_Android"),
		rewarded     = sys.get_config_string("unityads.rewarded_placement", "Rewarded_Android"),
		banner       = sys.get_config_string("unityads.banner_placement", "Banner_Android"),
	},
	test_mode = sys.get_config_int("unityads.test_mode", 1) == 1,
}

----------------------------------------------------------
-- ERROR DESCRIPTIONS
----------------------------------------------------------
local ERROR_NAMES = {
	[1] = "INTERNAL_ERROR",
	[2] = "INVALID_ARGUMENT",
	[3] = "NOT_INITIALIZED",
	[4] = "NOT_READY (Ad still loading or not loaded yet)",
	[5] = "VIDEO_PLAYER_ERROR",
	[6] = "NO_CONNECTION (Check internet connectivity)",
	[7] = "ALREADY_SHOWING",
	[8] = "NO_FILL (No ads available - enable test_mode=1 in game.project for testing)",
	[9] = "TIMEOUT",
	[10] = "UNKNOWN",
	[11] = "NATIVE_ERROR",
	[12] = "WEBVIEW_ERROR",
	[13] = "AD_BLOCKER_DETECTED",
}

local function error_desc(code)
	if not code then return "UNKNOWN" end
	return ERROR_NAMES[code] or ("CODE_" .. tostring(code))
end

----------------------------------------------------------
-- STATE
----------------------------------------------------------
M.initialized = false
M.is_showing = false
M.interstitial_loaded = false
M.rewarded_loaded = false
M.banner_loaded = false
M.is_banner_showing = false

local current_interstitial_cb = nil
local current_reward_cb = nil
local current_reward_close_cb = nil
local reward_was_earned = false

local function safe_timer_delay(delay_sec, repeating, cb)
	local ok, handle = pcall(timer.delay, delay_sec, repeating, cb)
	if ok then return handle end
	return nil
end

----------------------------------------------------------
-- LOGGING
----------------------------------------------------------
local function log(...)
	print("[UNITY ADS]", ...)
end

----------------------------------------------------------
-- AUDIO HELPERS
----------------------------------------------------------
local function pause_audio()
	-- Audio pause is handled by sdk.lua wrapper (which calls us).
	log("🔇 [unityads] pause_audio (delegated to sdk.lua)")
end

local function resume_audio()
	-- Audio resume is handled by sdk.lua wrapper (which calls us).
	log("🔊 [unityads] resume_audio (delegated to sdk.lua)")
end

----------------------------------------------------------
-- PLATFORM DETECTION & HELPERS
----------------------------------------------------------
function M.is_supported()
	if rawget(_G, "unityads") ~= nil then
		if unityads.is_supported then
			local ok, sup = pcall(unityads.is_supported)
			if ok then return sup end
		end
		return true
	end
	return false
end

local function get_game_id()
	local sys_info = sys.get_sys_info()
	if sys_info.system_name == "iPhone OS" then
		return CONFIG.game_id.ios
	else
		return CONFIG.game_id.android
	end
end

local function get_placements()
	return CONFIG.placements
end

----------------------------------------------------------
-- UNITY ADS EVENT CALLBACK
----------------------------------------------------------
local function on_unityads_event(self, message_id, message)
	if not rawget(_G, "unityads") then return end

	-- 1. INITIALIZATION
	if message_id == unityads.MSG_INIT then
		if message.event == unityads.EVENT_COMPLETED then
			log("✅ Unity Ads initialized successfully!")
			M.initialized = true
			-- Preload ads right after initialization
			M.load_interstitial()
			M.load_rewarded()
		elseif message.event == unityads.EVENT_SDK_ERROR then
			log("❌ Unity Ads initialization error:", tostring(message.error), "code:", message.code, "[" .. error_desc(message.code) .. "]")
			if message.code == 8 or message.code == 2 then
				log("💡 HINT: Check Game ID and ensure test_mode=1 is enabled in game.project during development!")
			end
		elseif message.event == unityads.EVENT_JSON_ERROR then
			log("❌ Unity Ads initialization JSON error:", tostring(message.error))
		end

	-- 2. AD LOADING
	elseif message_id == unityads.MSG_LOAD then
		local placements = get_placements()
		if message.event == unityads.EVENT_LOADED then
			log("📥 Unity Ads loaded placement:", message.placement_id)
			if message.placement_id == placements.interstitial then
				M.interstitial_loaded = true
			elseif message.placement_id == placements.rewarded then
				M.rewarded_loaded = true
			else
				-- Match fallback in case of placement naming difference
				M.interstitial_loaded = true
				M.rewarded_loaded = true
			end
		elseif message.event == unityads.EVENT_SDK_ERROR then
			log("⚠️ Unity Ads failed to load placement:", message.placement_id, "error:", tostring(message.error), "code:", message.code, "[" .. error_desc(message.code) .. "]")
			if message.placement_id == placements.interstitial then
				M.interstitial_loaded = false
			elseif message.placement_id == placements.rewarded then
				M.rewarded_loaded = false
			end

			-- Retry loading after 12 seconds in background
			local failed_placement = message.placement_id
			safe_timer_delay(12, false, function()
				if failed_placement == placements.interstitial and not M.interstitial_loaded then
					log("🔄 Retrying loading interstitial ad...")
					M.load_interstitial()
				elseif failed_placement == placements.rewarded and not M.rewarded_loaded then
					log("🔄 Retrying loading rewarded ad...")
					M.load_rewarded()
				end
			end)
		end

	-- 3. AD SHOWING
	elseif message_id == unityads.MSG_SHOW then
		local placements = get_placements()

		if message.event == unityads.EVENT_START then
			log("📺 Unity Ads started showing placement:", message.placement_id)
			M.is_showing = true
			pause_audio()
			if message.placement_id == placements.interstitial then
				M.interstitial_loaded = false
			elseif message.placement_id == placements.rewarded then
				M.rewarded_loaded = false
				reward_was_earned = false
			end

		elseif message.event == unityads.EVENT_COMPLETED then
			log("🚪 Unity Ads completed placement:", message.placement_id)
			M.is_showing = false
			resume_audio()

			-- Check if rewarded ad was showing
			if current_reward_close_cb or message.placement_id == placements.rewarded then
				reward_was_earned = true
				if current_reward_cb then
					current_reward_cb()
				end
				if current_reward_close_cb then
					local cb = current_reward_close_cb
					current_reward_close_cb = nil
					current_reward_cb = nil
					cb(true)
				end
				M.load_rewarded()
			elseif current_interstitial_cb or message.placement_id == placements.interstitial then
				if current_interstitial_cb then
					local cb = current_interstitial_cb
					current_interstitial_cb = nil
					cb()
				end
				M.load_interstitial()
			else
				if current_interstitial_cb then
					local cb = current_interstitial_cb
					current_interstitial_cb = nil
					cb()
				end
			end

		elseif message.event == unityads.EVENT_SKIPPED then
			log("⏭️ Unity Ads skipped placement:", message.placement_id)
			M.is_showing = false
			resume_audio()

			if current_reward_close_cb or message.placement_id == placements.rewarded then
				if current_reward_close_cb then
					local cb = current_reward_close_cb
					current_reward_close_cb = nil
					current_reward_cb = nil
					cb(false)
				end
				M.load_rewarded()
			elseif current_interstitial_cb or message.placement_id == placements.interstitial then
				if current_interstitial_cb then
					local cb = current_interstitial_cb
					current_interstitial_cb = nil
					cb()
				end
				M.load_interstitial()
			else
				if current_interstitial_cb then
					local cb = current_interstitial_cb
					current_interstitial_cb = nil
					cb()
				end
			end

		elseif message.event == unityads.EVENT_SDK_ERROR or message.event == unityads.EVENT_JSON_ERROR then
			log("❌ Unity Ads show error:", tostring(message.error), "code:", message.code, "[" .. error_desc(message.code) .. "]")
			M.is_showing = false
			resume_audio()

			if current_interstitial_cb then
				local cb = current_interstitial_cb
				current_interstitial_cb = nil
				cb()
			end
			if current_reward_close_cb then
				local cb = current_reward_close_cb
				current_reward_close_cb = nil
				current_reward_cb = nil
				cb(false)
			end
			M.load_interstitial()
			M.load_rewarded()
		end

	-- 4. BANNER
	elseif message_id == unityads.MSG_BANNER then
		if message.event == unityads.EVENT_LOADED then
			log("📥 Unity Ads banner loaded:", message.placement_id, "size:", message.width, message.height)
			M.banner_loaded = true
			if M.is_banner_showing then
				unityads.show_banner()
			end
		elseif message.event == unityads.EVENT_SDK_ERROR then
			log("⚠️ Unity Ads banner error:", tostring(message.error), "code:", message.code, "[" .. error_desc(message.code) .. "]")
			M.banner_loaded = false
		end

	-- 5. IDFA (iOS)
	elseif message_id == unityads.MSG_IDFA then
		log("ℹ️ Unity Ads IDFA status event:", message.event)
	end
end

----------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------

--- Initialize Unity Ads SDK
function M.init(custom_config)
	if M.initialized then return end

	if custom_config then
		if custom_config.game_id then
			for k, v in pairs(custom_config.game_id) do CONFIG.game_id[k] = v end
		end
		if custom_config.placements then
			for k, v in pairs(custom_config.placements) do CONFIG.placements[k] = v end
		end
		if custom_config.test_mode ~= nil then
			CONFIG.test_mode = custom_config.test_mode
		end
	end

	if M.is_supported() then
		log("📱 Initializing Unity Ads native extension...")
		local ok_cb, err_cb = pcall(function()
			unityads.set_callback(on_unityads_event)
		end)
		if not ok_cb then
			log("⚠️ unityads.set_callback error:", err_cb)
		end

		-- Check if already initialized natively
		if unityads.is_initialized and unityads.is_initialized() then
			log("✅ Unity Ads is already initialized!")
			M.initialized = true
			M.load_interstitial()
			M.load_rewarded()
			return
		end

		-- iOS IDFA request before initialization
		local sys_info = sys.get_sys_info()
		if sys_info.system_name == "iPhone OS" and unityads.request_idfa then
			pcall(unityads.request_idfa)
		end

		local game_id = get_game_id()
		pcall(function()
			unityads.set_debug_mode(CONFIG.test_mode)
		end)
		log("📱 Initializing with Game ID: " .. tostring(game_id) .. ", test_mode: " .. tostring(CONFIG.test_mode))
		local ok_init, err_init = pcall(function()
			unityads.initialize(tostring(game_id), on_unityads_event, CONFIG.test_mode)
		end)
		if not ok_init then
			log("❌ unityads.initialize call failed:", err_init)
		end
	else
		log("💻 Native Unity Ads not present (Desktop/Editor/Web) — Mock active")
		M.initialized = true
	end
end

--- Load Interstitial
function M.load_interstitial()
	if M.is_supported() then
		local placements = get_placements()
		log("⏳ Loading interstitial:", placements.interstitial)
		local ok, err = pcall(function()
			unityads.load(placements.interstitial)
		end)
		if not ok then
			log("⚠️ unityads.load interstitial failed:", err)
		end
	else
		M.interstitial_loaded = true
	end
end

--- Check if interstitial is ready
function M.is_interstitial_ready()
	if M.is_supported() then
		return M.interstitial_loaded
	end
	return true
end

--- Show Interstitial
-- @param callback function called when ad closes or fails to show
function M.show_interstitial(callback)
	if M.is_showing then
		if callback then callback() end
		return
	end

	current_interstitial_cb = callback

	if M.is_supported() then
		local placements = get_placements()
		log("📺 Showing native interstitial ad (" .. placements.interstitial .. ")...")
		if not M.interstitial_loaded then
			log("⚠️ Interstitial not preloaded, attempting load first...")
			M.load_interstitial()
		end

		local ok, err = pcall(function()
			unityads.show(placements.interstitial)
		end)
		if not ok then
			log("⚠️ unityads.show failed:", err, "executing callback")
			M.is_showing = false
			if callback then
				current_interstitial_cb = nil
				callback()
			end
		end
	else
		log("💻 Mock show_interstitial")
		if callback then
			current_interstitial_cb = nil
			callback()
		end
	end
end

--- Load Rewarded Ad
function M.load_rewarded()
	if M.is_supported() then
		local placements = get_placements()
		log("⏳ Loading rewarded ad:", placements.rewarded)
		local ok, err = pcall(function()
			unityads.load(placements.rewarded)
		end)
		if not ok then
			log("⚠️ unityads.load rewarded failed:", err)
		end
	else
		M.rewarded_loaded = true
	end
end

--- Check if rewarded ad is ready
function M.is_rewarded_ready()
	if M.is_supported() then
		return M.rewarded_loaded
	end
	return true
end

--- Show Rewarded Ad
-- @param on_reward function called when reward is earned
-- @param on_close function called when ad is closed (receives boolean reward_earned)
function M.show_rewarded(on_reward, on_close)
	if M.is_showing then
		if on_close then on_close(false) end
		return
	end

	current_reward_cb = on_reward
	current_reward_close_cb = on_close
	reward_was_earned = false

	if M.is_supported() then
		local placements = get_placements()
		log("🎁 Showing native rewarded ad (" .. placements.rewarded .. ")...")
		if not M.rewarded_loaded then
			log("⚠️ Rewarded ad not preloaded, attempting load first...")
			M.load_rewarded()
		end

		local ok, err = pcall(function()
			unityads.show(placements.rewarded)
		end)
		if not ok then
			log("⚠️ unityads.show rewarded failed:", err, "granting reward fallback")
			if on_reward then on_reward() end
			if on_close then on_close(true) end
			current_reward_cb = nil
			current_reward_close_cb = nil
		end
	else
		log("💻 Mock show_rewarded (granting reward)")
		if on_reward then on_reward() end
		if on_close then on_close(true) end
		current_reward_cb = nil
		current_reward_close_cb = nil
	end
end

local function parse_banner_position(position)
	if type(position) == "number" then
		return position
	end
	if type(position) == "string" then
		local p = string.lower(position)
		if p == "top" or p == "top_center" or p == "top-center" or p == "topcenter" then
			return (rawget(_G, "unityads") and unityads.BANNER_POSITION_TOP_CENTER) or 1
		elseif p == "top_left" or p == "top-left" or p == "topleft" then
			return (rawget(_G, "unityads") and unityads.BANNER_POSITION_TOP_LEFT) or 0
		elseif p == "top_right" or p == "top-right" or p == "topright" then
			return (rawget(_G, "unityads") and unityads.BANNER_POSITION_TOP_RIGHT) or 2
		elseif p == "bottom_left" or p == "bottom-left" or p == "bottomleft" then
			return (rawget(_G, "unityads") and unityads.BANNER_POSITION_BOTTOM_LEFT) or 3
		elseif p == "bottom_right" or p == "bottom-right" or p == "bottomright" then
			return (rawget(_G, "unityads") and unityads.BANNER_POSITION_BOTTOM_RIGHT) or 5
		elseif p == "center" then
			return (rawget(_G, "unityads") and unityads.BANNER_POSITION_CENTER) or 6
		else
			return (rawget(_G, "unityads") and unityads.BANNER_POSITION_BOTTOM_CENTER) or 4
		end
	end
	return (rawget(_G, "unityads") and unityads.BANNER_POSITION_BOTTOM_CENTER) or 4
end

--- Show Banner
-- @param position optional position string ("bottom", "top", etc.) or number enum
function M.show_banner(position)
	if M.is_supported() then
		local placements = get_placements()
		local pos = parse_banner_position(position)
		pcall(function()
			unityads.set_banner_position(pos)
		end)
		M.is_banner_showing = true
		if not M.banner_loaded then
			pcall(function()
				unityads.load_banner(placements.banner)
			end)
		else
			pcall(function()
				unityads.show_banner()
			end)
		end
	else
		log("💻 Mock show_banner")
		M.is_banner_showing = true
	end
end

--- Hide Banner
function M.hide_banner()
	if M.is_supported() then
		pcall(function()
			unityads.hide_banner()
		end)
	end
	M.is_banner_showing = false
end

--- Destroy Banner
function M.destroy_banner()
	if M.is_supported() then
		pcall(function()
			unityads.unload_banner()
		end)
	end
	M.banner_loaded = false
	M.is_banner_showing = false
end

--- Configure Game IDs & Placements
function M.set_config(game_id_android, game_id_ios, test_mode)
	if game_id_android then CONFIG.game_id.android = tostring(game_id_android) end
	if game_id_ios then CONFIG.game_id.ios = tostring(game_id_ios) end
	if test_mode ~= nil then CONFIG.test_mode = test_mode end
end

return M
