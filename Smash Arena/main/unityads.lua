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
-- Interstitial: "video"
-- Rewarded: "rewardedVideo"
-- Banner: "banner"
local CONFIG = {
	game_id = {
		android = sys.get_config_string("unityads.game_id_android", "1401815"),
		ios     = sys.get_config_string("unityads.game_id_ios", "1425385"),
	},
	placements = {
		interstitial = sys.get_config_string("unityads.interstitial_placement", "video"),
		rewarded     = sys.get_config_string("unityads.rewarded_placement", "rewardedVideo"),
		banner       = sys.get_config_string("unityads.banner_placement", "banner"),
	},
	test_mode = sys.get_config_int("unityads.test_mode", 1) == 1,
}

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
	log("🔇 Muting audio for ad playback")
	pcall(function() sound.set_group_gain("master", 0) end)
end

local function resume_audio()
	log("🔊 Restoring audio after ad")
	pcall(function() sound.set_group_gain("master", 1) end)
end

----------------------------------------------------------
-- PLATFORM DETECTION & HELPERS
----------------------------------------------------------
function M.is_supported()
	if rawget(_G, "unityads") ~= nil then
		if unityads.is_supported then
			return unityads.is_supported()
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
			log("❌ Unity Ads initialization error:", message.error, "code:", message.code)
		elseif message.event == unityads.EVENT_JSON_ERROR then
			log("❌ Unity Ads initialization JSON error:", message.error)
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
			end
		elseif message.event == unityads.EVENT_SDK_ERROR then
			log("⚠️ Unity Ads failed to load placement:", message.placement_id, "error:", message.error, "code:", message.code)
			if message.placement_id == placements.interstitial then
				M.interstitial_loaded = false
			elseif message.placement_id == placements.rewarded then
				M.rewarded_loaded = false
			end
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

			if message.placement_id == placements.interstitial then
				if current_interstitial_cb then
					local cb = current_interstitial_cb
					current_interstitial_cb = nil
					cb()
				end
				M.load_interstitial()

			elseif message.placement_id == placements.rewarded then
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
			else
				-- Other placement completed
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

			if message.placement_id == placements.interstitial then
				if current_interstitial_cb then
					local cb = current_interstitial_cb
					current_interstitial_cb = nil
					cb()
				end
				M.load_interstitial()

			elseif message.placement_id == placements.rewarded then
				if current_reward_close_cb then
					local cb = current_reward_close_cb
					current_reward_close_cb = nil
					current_reward_cb = nil
					cb(false)
				end
				M.load_rewarded()
			else
				if current_interstitial_cb then
					local cb = current_interstitial_cb
					current_interstitial_cb = nil
					cb()
				end
			end

		elseif message.event == unityads.EVENT_SDK_ERROR or message.event == unityads.EVENT_JSON_ERROR then
			log("❌ Unity Ads show error:", message.error, "code:", message.code)
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
			log("⚠️ Unity Ads banner error:", message.error, "code:", message.code)
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
		unityads.set_callback(on_unityads_event)

		-- iOS IDFA request before initialization
		local sys_info = sys.get_sys_info()
		if sys_info.system_name == "iPhone OS" and unityads.request_idfa then
			unityads.request_idfa()
		end

		local game_id = get_game_id()
		unityads.set_debug_mode(CONFIG.test_mode)
		log("📱 Initializing with Game ID: " .. tostring(game_id) .. ", test_mode: " .. tostring(CONFIG.test_mode))
		unityads.initialize(tostring(game_id), on_unityads_event, CONFIG.test_mode)
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
		unityads.load(placements.interstitial)
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
		unityads.show(placements.interstitial)
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
		unityads.load(placements.rewarded)
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
		unityads.show(placements.rewarded)
	else
		log("💻 Mock show_rewarded (granting reward)")
		if on_reward then on_reward() end
		if on_close then on_close(true) end
		current_reward_cb = nil
		current_reward_close_cb = nil
	end
end

--- Show Banner
-- @param position optional position (e.g. unityads.BANNER_POSITION_BOTTOM_CENTER)
function M.show_banner(position)
	if M.is_supported() then
		local placements = get_placements()
		local pos = position or (unityads.BANNER_POSITION_BOTTOM_CENTER or 4)
		unityads.set_banner_position(pos)
		M.is_banner_showing = true
		if not M.banner_loaded then
			unityads.load_banner(placements.banner)
		else
			unityads.show_banner()
		end
	else
		log("💻 Mock show_banner")
		M.is_banner_showing = true
	end
end

--- Hide Banner
function M.hide_banner()
	if M.is_supported() then
		unityads.hide_banner()
	end
	M.is_banner_showing = false
end

--- Destroy Banner
function M.destroy_banner()
	if M.is_supported() then
		unityads.unload_banner()
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
