-- main/sdk.lua
-- Unified SDK Wrapper: Playgama Bridge SDK (HTML5/Web & Desktop Mock) & Unity Ads (Android/iOS)

local unityads = require "main.unityads"

local M = {}
M.unityads = unityads
M.admob = unityads -- Backwards compatibility alias

----------------------------------------------------------
-- PLATFORM TYPES
----------------------------------------------------------
M.PLATFORM_PLAYGAMA = "playgama"
M.PLATFORM_ANDROID  = "android"
M.PLATFORM_MOCK     = "mock"

----------------------------------------------------------
-- STATE
----------------------------------------------------------
M.initialized = false
M.game_ready_sent = false
M.ad_showing = false
M.banner_showing = false
M.gameplay_active = false
M.current_round = 1
M.active_platform = M.PLATFORM_MOCK
M.platform_audio_enabled = true
M.platform_paused = false
M.tab_hidden = false

-- Bridge reference (Playgama)
local bridge = nil

-- Ad callbacks for Playgama
local current_interstitial_cb = nil
local current_reward_cb = nil
local current_reward_close_cb = nil
local reward_granted = false

----------------------------------------------------------
-- LOGGING
----------------------------------------------------------
local function log(...)
	print("[SDK WRAPPER]", ...)
end

----------------------------------------------------------
-- AUDIO / GAMEPLAY PAUSE HELPERS
----------------------------------------------------------
local function pause_audio()
	log("🔇 Pausing/muting game audio")
	pcall(sound.set_group_gain, hash("master"), 0)
	pcall(sound.set_group_gain, "master", 0)
	pcall(sound.set_group_gain, hash("music"), 0)
	pcall(sound.set_group_gain, "music", 0)
	pcall(sound.set_group_gain, hash("sfx"), 0)
	pcall(sound.set_group_gain, "sfx", 0)
end

local function resume_audio()
	if M.ad_showing or M.tab_hidden or M.platform_paused or (not M.platform_audio_enabled) then
		return
	end

	log("🔊 Restoring game audio")
	local state_ok, state = pcall(require, "main.state")
	local sfx_vol = (state_ok and state.sfx_volume) or 1.0
	local music_vol = (state_ok and state.music_volume) or 0.8

	pcall(sound.set_group_gain, hash("master"), 1)
	pcall(sound.set_group_gain, "master", 1)
	pcall(sound.set_group_gain, hash("music"), music_vol)
	pcall(sound.set_group_gain, "music", music_vol)
	pcall(sound.set_group_gain, hash("sfx"), sfx_vol)
	pcall(sound.set_group_gain, "sfx", sfx_vol)
end

----------------------------------------------------------
-- PLAYGAMA BRIDGE SETUP & AD/PLATFORM LISTENERS
----------------------------------------------------------
local function setup_playgama_listeners()
	if not bridge then return end

	-- 1. Advertisement Listeners
	if bridge.advertisement and bridge.advertisement.on then
		-- Interstitial listener
		bridge.advertisement.on("interstitial_state_changed", function(self, state)
			log("📺 Playgama interstitial_state_changed:", state)
			if state == "opened" or state == "loading" then
				if state == "opened" then
					M.ad_showing = true
					pause_audio()
				end
			elseif state == "closed" or state == "failed" then
				M.ad_showing = false
				resume_audio()
				if current_interstitial_cb then
					local cb = current_interstitial_cb
					current_interstitial_cb = nil
					cb()
				end
			end
		end)

		-- Rewarded listener
		bridge.advertisement.on("rewarded_state_changed", function(self, state)
			log("🎁 Playgama rewarded_state_changed:", state)
			if state == "opened" then
				M.ad_showing = true
				reward_granted = false
				pause_audio()
			elseif state == "rewarded" then
				reward_granted = true
				if current_reward_cb then
					current_reward_cb()
				end
			elseif state == "closed" or state == "failed" then
				M.ad_showing = false
				resume_audio()
				if current_reward_close_cb then
					local cb = current_reward_close_cb
					current_reward_close_cb = nil
					cb(reward_granted)
				end
				current_reward_cb = nil
			end
		end)

		-- Banner listener
		bridge.advertisement.on("banner_state_changed", function(self, state)
			log("🏷️ Playgama banner_state_changed:", state)
			M.banner_showing = (state == "shown")
		end)

		-- Advanced banners listener
		bridge.advertisement.on("advanced_banners_state_changed", function(self, state)
			log("🏷️ Playgama advanced_banners_state_changed:", state)
		end)
	end

	-- 2. Visibility / Focus Listener
	if bridge.game and bridge.game.on then
		bridge.game.on("visibility_state_changed", function(self, state)
			log("👁️ Playgama visibility_state_changed:", state)
			M.tab_hidden = (state == "hidden")
			if M.tab_hidden then
				pause_audio()
			else
				resume_audio()
			end
		end)
	end

	-- 3. Platform Audio & Pause Listeners (Playgama Bridge 2.x standard)
	if bridge.platform and bridge.platform.on then
		bridge.platform.on("audio_state_changed", function(self, is_enabled)
			log("🔊 Playgama audio_state_changed:", is_enabled)
			M.platform_audio_enabled = (is_enabled ~= false)
			if not M.platform_audio_enabled then
				pause_audio()
			else
				resume_audio()
			end
		end)

		bridge.platform.on("pause_state_changed", function(self, is_paused)
			log("⏸️ Playgama pause_state_changed:", is_paused)
			M.platform_paused = (is_paused == true)
			if M.platform_paused then
				pause_audio()
			else
				resume_audio()
			end
		end)
	end
end

----------------------------------------------------------
-- INITIALIZATION
----------------------------------------------------------
function M.init(custom_config)
	if M.initialized then return end
	M.initialized = true

	local sys_info = sys.get_sys_info()
	local is_android = (sys_info.system_name == "Android")
	local is_ios = (sys_info.system_name == "iPhone OS")

	-- 1. Mobile Native Build (Android / iOS) -> Unity Ads
	if is_android or is_ios then
		M.active_platform = M.PLATFORM_ANDROID
		log("📱 Mobile build detected (" .. sys_info.system_name .. ") — Initializing Unity Ads")
		unityads.init(custom_config)
		return
	end

	-- 2. Playgama Bridge (Web / HTML5 & Editor/Desktop Mock)
	-- bridge-defold dependency provides both real WASM bridge on HTML5 and mock on Desktop
	local ok, mod = pcall(require, "bridge.bridge")
	if ok and mod then
		bridge = mod
		M.active_platform = M.PLATFORM_PLAYGAMA
		local platform_id = "unknown"
		if bridge.platform and bridge.platform.id then
			pcall(function() platform_id = bridge.platform.id() end)
		end
		log("🌐 Playgama Bridge SDK initialized (Platform ID: " .. tostring(platform_id) .. ")")
		setup_playgama_listeners()
		return
	end

	-- 3. Fallback to Unity Ads Mock if bridge library is missing
	M.active_platform = M.PLATFORM_MOCK
	log("💻 Running in Editor / Desktop fallback mock")
	unityads.init(custom_config)
end

----------------------------------------------------------
-- DUAL-CHANNEL PLATFORM MESSAGE SENDER (LUA BINDING + HTML5 JS)
----------------------------------------------------------
local function send_platform_message(msg_name, options)
	options = options or {}
	if not M.initialized then M.init() end

	log("📤 send_platform_message: '" .. tostring(msg_name) .. "'")

	-- Channel 1: Defold Lua / C++ Bridge extension
	if bridge and bridge.platform then
		local send_fn = bridge.platform.send_message or bridge.platform.sendMessage
		if send_fn then
			pcall(send_fn, msg_name, options, function()
				log("✅ [Defold Bridge] Message delivered:", msg_name)
			end, function(err)
				log("⚠️ [Defold Bridge] Message error callback:", msg_name, tostring(err))
			end)
		else
			log("⚠️ bridge.platform.send_message function not found")
		end
	end

	-- Channel 2: Direct browser JavaScript call via html5.run (Web/HTML5 only)
	-- Guarantees the portal receives the message even if the WASM bridge binding had timing delays
	if html5 and html5.run then
		local opts_json = "{}"
		if options and next(options) then
			local parts = {}
			for k, v in pairs(options) do
				local val_str = type(v) == "number" and tostring(v) or string.format("%q", tostring(v))
				table.insert(parts, string.format("%q:%s", tostring(k), val_str))
			end
			opts_json = "{" .. table.concat(parts, ",") .. "}"
		end

		local js = string.format([[
			(function() {
				var msg = %q;
				var opts = %s;
				try {
					var b = window.bridge || window.playgamaBridge;
					if (b) {
						if (b.platform && typeof b.platform.sendMessage === 'function') {
							b.platform.sendMessage(msg, opts)
								.then(function() { console.log('[PLAYGAMA SDK] ✅ window.bridge.platform.sendMessage("' + msg + '") OK'); })
								.catch(function(e) { console.warn('[PLAYGAMA SDK] ⚠️ sendMessage error (' + msg + '):', e); });
						} else if (typeof b.sendMessage === 'function') {
							b.sendMessage(msg, opts);
							console.log('[PLAYGAMA SDK] ✅ window.bridge.sendMessage("' + msg + '") called');
						}
						if (msg === 'game_ready') {
							var el = document.getElementById('loading-overlay');
							if (el) el.remove();
						}
					} else {
						console.warn('[PLAYGAMA SDK] window.bridge not defined yet for message:', msg);
					}

					// Direct CrazyGames SDK support (v2/v3)
					try {
						var cg = (window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.game) || (window.crazygames && window.crazygames.game);
						if (cg) {
							if (msg === 'in_game_loading_started') {
								if (typeof cg.loadingStart === 'function') cg.loadingStart();
								console.log('[CrazyGames SDK] ⏳ loadingStart() called');
							} else if (msg === 'in_game_loading_stopped' || msg === 'game_ready') {
								if (typeof cg.loadingStop === 'function') cg.loadingStop();
								console.log('[CrazyGames SDK] ⌛ loadingStop() called');
							} else if (msg === 'gameplay_started') {
								if (typeof cg.gameplayStart === 'function') cg.gameplayStart();
								console.log('[CrazyGames SDK] ▶️ gameplayStart() called');
							} else if (msg === 'gameplay_stopped') {
								if (typeof cg.gameplayStop === 'function') cg.gameplayStop();
								console.log('[CrazyGames SDK] ⏹️ gameplayStop() called');
							} else if (msg === 'happy_time') {
								if (typeof cg.happytime === 'function') cg.happytime();
								console.log('[CrazyGames SDK] 🎉 happytime() called');
							}
						}
					} catch(cgErr) {
						console.warn('[CrazyGames SDK Direct] Error:', cgErr);
					}
				} catch(err) {
					console.error('[PLAYGAMA SDK] ❌ Exception in sendMessage (' + msg + '):', err);
				}
			})();
		]], msg_name, opts_json)

		pcall(html5.run, js)
	end
end

----------------------------------------------------------
-- LIFECYCLE: GAME READY
----------------------------------------------------------
--- Call when game assets and main menu are fully loaded & ready for player input
function M.send_game_ready()
	if M.game_ready_sent then
		log("ℹ️ send_game_ready() already dispatched previously, ignoring duplicate call")
		return
	end
	M.game_ready_sent = true

	log("📤 send_game_ready() triggered — dispatching game_ready event")
	send_platform_message("game_ready")
end

----------------------------------------------------------
-- LIFECYCLE: IN-GAME LOADING
----------------------------------------------------------
--- Call when loading match / arena / asset transition starts
function M.in_game_loading_started()
	send_platform_message("in_game_loading_started")
end

--- Call when loading match / arena / asset transition finishes
function M.in_game_loading_stopped()
	send_platform_message("in_game_loading_stopped")
end

----------------------------------------------------------
-- LIFECYCLE: GAMEPLAY START / STOP
----------------------------------------------------------
--- Call when battle / active interactive session begins
function M.gameplay_start(world, level)
	if M.gameplay_active then return end
	M.gameplay_active = true
	log("▶️ gameplay_start()", world, level)

	local opts = {}
	if world then opts.world = tostring(world) end
	if level then opts.level = tostring(level) end

	send_platform_message("gameplay_started", opts)
end

--- Call on battle end, pause, game over, victory, or return to menu
function M.gameplay_stop(world, level)
	if not M.gameplay_active then return end
	M.gameplay_active = false
	log("⏹️ gameplay_stop()", world, level)

	local opts = {}
	if world then opts.world = tostring(world) end
	if level then opts.level = tostring(level) end

	send_platform_message("gameplay_stopped", opts)
end

----------------------------------------------------------
-- ROUND & LEVEL PROGRESSION
----------------------------------------------------------
function M.round_start(round_or_level)
	M.current_round = round_or_level or M.current_round or 1
	log("🚩 round_start:", M.current_round)

	send_platform_message("level_started", { level = M.current_round })
end

function M.round_end(victory, round_or_level)
	local r = round_or_level or M.current_round or 1
	log("🏁 round_end:", victory and "VICTORY" or "DEFEAT", "Round/Level:", r)

	local event_name = victory and "level_completed" or "level_failed"
	send_platform_message(event_name, { level = r })
end

function M.level_paused()
	send_platform_message("level_paused")
end

function M.level_resumed()
	send_platform_message("level_resumed")
end

----------------------------------------------------------
-- ACHIEVEMENTS / CELEBRATION / HAPPY TIME
----------------------------------------------------------
function M.happy_time(intensity)
	intensity = intensity or 1.0
	log("🎉 happy_time (intensity: " .. tostring(intensity) .. ")")

	if intensity >= 1.0 then
		send_platform_message("player_got_achievement", { type = "victory" })
	end
end

function M.tutorial_started()
	log("📖 tutorial_started")
	send_platform_message("level_started", { level = "tutorial" })
end

function M.tutorial_completed()
	log("🎓 tutorial_completed")
	send_platform_message("level_completed", { level = "tutorial" })
end

function M.chest_opened(chest_id, chest_name)
	local name = tostring(chest_name or chest_id or "chest")
	log("📦 chest_opened:", name)
	send_platform_message("player_got_achievement", { type = "chest_opened", name = name })
end

function M.hero_upgraded(hero_id, new_level)
	local tag = tostring(hero_id) .. "_lvl" .. tostring(new_level)
	log("⭐ hero_upgraded:", tag)
	send_platform_message("player_got_achievement", { type = "hero_upgraded", id = tostring(hero_id), level = tonumber(new_level) or 1 })
end

function M.measure(category, what, action)
	log("📊 measure:", category, what, action)
	if not M.initialized then M.init() end

	if bridge and bridge.platform and bridge.platform.send_custom_message then
		bridge.platform.send_custom_message(tostring(category), { what = tostring(what), action = tostring(action) })
	end
end

----------------------------------------------------------
-- INTERSTITIAL ADS (COMMERCIAL BREAK)
----------------------------------------------------------
function M.commercial_break(callback, placement)
	if M.ad_showing then
		if callback then callback() end
		return
	end

	if not M.initialized then M.init() end

	local placement_str = tostring(placement or "interstitial")

	-- 1. Playgama Bridge (Web)
	if M.active_platform == M.PLATFORM_PLAYGAMA and bridge and bridge.advertisement and bridge.advertisement.show_interstitial then
		log("📺 Showing Playgama interstitial ad (placement: " .. placement_str .. ")...")
		current_interstitial_cb = callback
		local ok, err = pcall(function()
			bridge.advertisement.show_interstitial(placement_str)
		end)
		if not ok then
			log("❌ Playgama show_interstitial Lua error, trying JS direct:", err)
			local js_ok = false
			if html5 and html5.run then
				local js = string.format([[
					(function() {
						try {
							var b = window.bridge || window.playgamaBridge;
							if (b && b.advertisement && typeof b.advertisement.showInterstitial === 'function') {
								b.advertisement.showInterstitial(%q);
								return "1";
							}
						} catch(e) {}
						return "0";
					})();
				]], placement_str)
				local ok_call, res = pcall(html5.run, js)
				if ok_call and res == "1" then js_ok = true end
			end
			if not js_ok then
				M.ad_showing = false
				resume_audio()
				if callback then callback() end
			end
		end

	-- 2. Android / iOS (Unity Ads)
	elseif (M.active_platform == M.PLATFORM_ANDROID or unityads.is_supported()) then
		log("📺 Showing Unity Ads interstitial ad...")
		M.ad_showing = true
		pause_audio()
		unityads.show_interstitial(function()
			M.ad_showing = false
			resume_audio()
			if callback then callback() end
		end)

	-- 3. Mock
	else
		log("💻 Mock commercial_break")
		if callback then callback() end
	end
end

M.show_interstitial = M.commercial_break

function M.is_interstitial_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.advertisement and bridge.advertisement.is_interstitial_supported then
		return bridge.advertisement.is_interstitial_supported()
	elseif M.active_platform == M.PLATFORM_ANDROID then
		return true
	end
	return true
end

----------------------------------------------------------
-- REWARDED ADS (REWARDED BREAK)
----------------------------------------------------------
function M.rewarded_break(on_reward, on_close, placement_or_size)
	if M.ad_showing then
		if on_close then on_close(false) end
		return
	end

	if not M.initialized then M.init() end
	local placement = tostring(placement_or_size or "rewarded")

	-- 1. Playgama Bridge (Web)
	if M.active_platform == M.PLATFORM_PLAYGAMA and bridge and bridge.advertisement and bridge.advertisement.show_rewarded then
		log("🎁 Showing Playgama rewarded ad (placement: " .. placement .. ")...")
		current_reward_cb = on_reward
		current_reward_close_cb = on_close
		reward_granted = false

		local ok, err = pcall(function()
			bridge.advertisement.show_rewarded(placement)
		end)
		if not ok then
			log("❌ Playgama show_rewarded Lua error, trying JS direct:", err)
			local js_ok = false
			if html5 and html5.run then
				local js = string.format([[
					(function() {
						try {
							var b = window.bridge || window.playgamaBridge;
							if (b && b.advertisement && typeof b.advertisement.showRewarded === 'function') {
								b.advertisement.showRewarded(%q);
								return "1";
							}
						} catch(e) {}
						return "0";
					})();
				]], placement)
				local ok_call, res = pcall(html5.run, js)
				if ok_call and res == "1" then js_ok = true end
			end
			if not js_ok then
				M.ad_showing = false
				resume_audio()
				if on_close then on_close(false) end
			end
		end

	-- 2. Android / iOS (Unity Ads)
	elseif (M.active_platform == M.PLATFORM_ANDROID or unityads.is_supported()) then
		log("🎁 Showing Unity Ads rewarded ad...")
		M.ad_showing = true
		pause_audio()
		unityads.show_rewarded(function()
			if on_reward then on_reward() end
		end, function(reward_earned)
			M.ad_showing = false
			resume_audio()
			if on_close then on_close(reward_earned) end
		end)

	-- 3. Mock
	else
		log("💻 Mock rewarded_break (granting reward)")
		if on_reward then on_reward() end
		if on_close then on_close(true) end
	end
end

M.show_rewarded = M.rewarded_break

function M.is_rewarded_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.advertisement and bridge.advertisement.is_rewarded_supported then
		return bridge.advertisement.is_rewarded_supported()
	elseif M.active_platform == M.PLATFORM_ANDROID then
		return true
	end
	return true
end

----------------------------------------------------------
-- BANNER ADS
----------------------------------------------------------
function M.show_banner(position, placement)
	position = position or "bottom"
	log("🏷️ show_banner() requested (position: " .. tostring(position) .. ")")
	if not M.initialized then M.init() end

	if bridge and bridge.advertisement and bridge.advertisement.show_banner then
		pcall(function()
			bridge.advertisement.show_banner(position, placement)
		end)
	elseif (M.active_platform == M.PLATFORM_ANDROID or unityads.is_supported()) then
		unityads.show_banner(position)
	else
		log("💻 Mock show_banner")
	end
end

function M.hide_banner()
	log("🏷️ hide_banner() requested")
	if not M.initialized then M.init() end

	if bridge and bridge.advertisement and bridge.advertisement.hide_banner then
		pcall(function()
			bridge.advertisement.hide_banner()
		end)
	elseif (M.active_platform == M.PLATFORM_ANDROID or unityads.is_supported()) then
		unityads.hide_banner()
	else
		log("💻 Mock hide_banner")
	end
end

function M.is_banner_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.advertisement and bridge.advertisement.is_banner_supported then
		return bridge.advertisement.is_banner_supported()
	end
	return false
end

----------------------------------------------------------
-- LEADERBOARDS
----------------------------------------------------------
function M.set_leaderboard_score(id_or_score, score_or_cb, on_success_or_failure, on_failure)
	local board_id = "prestige"
	local score = 0
	local success_cb = nil
	local failure_cb = nil

	if type(id_or_score) == "number" then
		score = id_or_score
		success_cb = score_or_cb
		failure_cb = on_success_or_failure
	else
		board_id = tostring(id_or_score or "prestige")
		score = tonumber(score_or_cb) or 0
		success_cb = on_success_or_failure
		failure_cb = on_failure
	end

	log("🏆 set_leaderboard_score:", board_id, score)
	if not M.initialized then M.init() end

	if bridge and bridge.leaderboards and bridge.leaderboards.set_score then
		bridge.leaderboards.set_score(board_id, score, success_cb, failure_cb)
		return
	end

	if success_cb then success_cb() end
end

function M.get_leaderboard_entries(id, on_success, on_failure)
	local board_id = tostring(id or "prestige")
	log("🏆 get_leaderboard_entries:", board_id)
	if not M.initialized then M.init() end

	if bridge and bridge.leaderboards and bridge.leaderboards.get_entries then
		bridge.leaderboards.get_entries(board_id, on_success, on_failure)
		return
	end

	if on_failure then on_failure("Leaderboards not supported") end
end

function M.show_leaderboard_popup(id, on_success, on_failure)
	local board_id = tostring(id or "prestige")
	log("🏆 show_leaderboard_popup:", board_id)
	if not M.initialized then M.init() end

	if bridge and bridge.leaderboards and bridge.leaderboards.show_native_popup then
		bridge.leaderboards.show_native_popup(board_id, on_success, on_failure)
		return
	end

	if on_failure then on_failure("Native leaderboard popup not supported") end
end

function M.is_leaderboard_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.leaderboards and bridge.leaderboards.type then
		return bridge.leaderboards.type() ~= "not_available"
	end
	return false
end

----------------------------------------------------------
-- CLOUD STORAGE (PLAYGAMA STORAGE WITH LOCAL FALLBACK)
----------------------------------------------------------
function M.storage_get(keys, on_success, on_failure)
	if not M.initialized then M.init() end

	if bridge and bridge.storage and bridge.storage.get then
		local keys_list = keys
		if type(keys) == "string" then
			keys_list = { keys }
		end
		bridge.storage.get(keys_list, on_success, on_failure)
		return
	end

	if on_success then on_success(nil, nil) end
end

function M.storage_set(data_or_key, value_or_cb, on_success_or_failure, on_failure)
	if not M.initialized then M.init() end

	local data = {}
	local success_cb = nil
	local failure_cb = nil

	if type(data_or_key) == "table" and type(value_or_cb) == "table" then
		for i, k in ipairs(data_or_key) do
			data[k] = value_or_cb[i]
		end
		success_cb = on_success_or_failure
		failure_cb = on_failure
	elseif type(data_or_key) == "table" then
		data = data_or_key
		success_cb = value_or_cb
		failure_cb = on_success_or_failure
	elseif type(data_or_key) == "string" then
		data[data_or_key] = value_or_cb
		success_cb = on_success_or_failure
		failure_cb = on_failure
	end

	if bridge and bridge.storage and bridge.storage.set then
		bridge.storage.set(data, success_cb, failure_cb)
		return
	end

	if success_cb then success_cb() end
end

function M.storage_delete(keys, on_success, on_failure)
	if not M.initialized then M.init() end

	if bridge and bridge.storage and bridge.storage.delete then
		local keys_list = keys
		if type(keys) == "string" then
			keys_list = { keys }
		end
		bridge.storage.delete(keys_list, on_success, on_failure)
		return
	end

	if on_success then on_success() end
end

function M.is_storage_supported(storage_type)
	if not M.initialized then M.init() end
	if bridge and bridge.storage and bridge.storage.is_supported then
		return bridge.storage.is_supported(storage_type or "platform_internal")
	end
	return true
end

----------------------------------------------------------
-- PLAYER PROFILE & AUTHORIZATION
----------------------------------------------------------
function M.get_player_id()
	if not M.initialized then M.init() end
	if bridge and bridge.player and bridge.player.id then
		return bridge.player.id()
	end
	return nil
end

function M.get_player_name()
	if not M.initialized then M.init() end
	if bridge and bridge.player and bridge.player.name then
		return bridge.player.name()
	end
	return nil
end

function M.get_player_photos()
	if not M.initialized then M.init() end
	if bridge and bridge.player and bridge.player.photos then
		return bridge.player.photos()
	end
	return {}
end

function M.is_player_authorized()
	if not M.initialized then M.init() end
	if bridge and bridge.player and bridge.player.is_authorized then
		return bridge.player.is_authorized()
	end
	return false
end

function M.is_player_authorization_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.player and bridge.player.is_authorization_supported then
		return bridge.player.is_authorization_supported()
	end
	return false
end

function M.authorize_player(options, on_success, on_failure)
	if not M.initialized then M.init() end
	if bridge and bridge.player and bridge.player.authorize then
		bridge.player.authorize(options, on_success, on_failure)
		return
	end
	if on_failure then on_failure("Authorization not supported") end
end

----------------------------------------------------------
-- SOCIAL & SHARE & RATING
----------------------------------------------------------
function M.share(options, on_success, on_failure)
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.share then
		bridge.social.share(options, on_success, on_failure)
		return
	end
	if on_success then on_success() end
end

function M.is_share_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.is_share_supported then
		return bridge.social.is_share_supported()
	end
	return false
end

function M.rate(on_success, on_failure)
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.rate then
		bridge.social.rate(on_success, on_failure)
		return
	end
	if on_success then on_success() end
end

function M.is_rate_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.is_rate_supported then
		return bridge.social.is_rate_supported()
	end
	return false
end

function M.add_to_favorites(on_success, on_failure)
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.add_to_favorites then
		bridge.social.add_to_favorites(on_success, on_failure)
		return
	end
	if on_success then on_success() end
end

function M.is_add_to_favorites_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.is_add_to_favorites_supported then
		return bridge.social.is_add_to_favorites_supported()
	end
	return false
end

function M.add_to_home_screen(on_success, on_failure)
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.add_to_home_screen then
		bridge.social.add_to_home_screen(on_success, on_failure)
		return
	end
	if on_success then on_success() end
end

function M.is_add_to_home_screen_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.is_add_to_home_screen_supported then
		return bridge.social.is_add_to_home_screen_supported()
	end
	return false
end

function M.get_server_time(on_success, on_failure)
	if not M.initialized then M.init() end
	if bridge and bridge.platform and bridge.platform.get_server_time then
		bridge.platform.get_server_time(on_success, on_failure)
		return
	end
	if on_success then on_success(nil, os.time()) end
end

----------------------------------------------------------
-- DEVICE & PLATFORM INFO
----------------------------------------------------------
function M.get_device_info()
	if not M.initialized then M.init() end

	if bridge and bridge.device and bridge.device.type then
		local dev_type = bridge.device.type()
		return {
			is_mobile = (dev_type == "mobile"),
			is_tablet = (dev_type == "tablet"),
			is_desktop = (dev_type == "desktop" or dev_type == nil),
			type = dev_type or "desktop"
		}
	elseif M.active_platform == M.PLATFORM_ANDROID then
		return {
			is_mobile = true,
			is_tablet = false,
			is_desktop = false,
			type = "mobile"
		}
	else
		local sys_info = sys.get_sys_info()
		local is_mob = (sys_info.system_name == "Android" or sys_info.system_name == "iPhone OS")
		return {
			is_mobile = is_mob,
			is_tablet = false,
			is_desktop = not is_mob,
			type = is_mob and "mobile" or "desktop"
		}
	end
end

function M.get_platform()
	if not M.initialized then M.init() end

	if bridge and bridge.platform and bridge.platform.id then
		return bridge.platform.id()
	elseif M.active_platform == M.PLATFORM_ANDROID then
		return "android"
	end
	return "mock"
end

function M.get_language()
	if not M.initialized then M.init() end

	if bridge and bridge.platform and bridge.platform.language then
		local lang = bridge.platform.language()
		if lang and lang ~= "" then
			return lang
		end
	end
	local sys_info = sys.get_sys_info()
	return sys_info.device_language or "en"
end

--- Returns normalized 2-letter language code ('ru' or 'en')
function M.get_language_code()
	local raw = M.get_language()
	if raw then
		local lower = string.lower(tostring(raw))
		if lower:find("^ru") or lower:find("^be") or lower:find("^uk") or lower:find("^kk") then
			return "ru"
		end
	end
	return "en"
end

function M.is_adblock_detected(callback)
	if not M.initialized then M.init() end

	if bridge and bridge.advertisement and bridge.advertisement.check_ad_block then
		bridge.advertisement.check_ad_block(function(self, is_blocked)
			if callback then callback(is_blocked) end
		end)
		return
	end
	if callback then callback(false) end
end

return M
