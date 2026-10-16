-- main/gameanalytics.lua
-- Wrapper module for GameAnalytics Defold extension with local mock fallback

local M = {}

M.initialized = false

local function log(...)
	print("[GAMEANALYTICS]", ...)
end

local function has_native()
	return rawget(_G, "gameanalytics") ~= nil
end

function M.is_supported()
	return has_native()
end

--- Initialize GameAnalytics (Defold extension automatically initializes from game.project,
--- but we verify and provide manual init fallback if needed)
function M.init()
	if M.initialized then return end

	if has_native() then
		log("✅ Native GameAnalytics extension detected")
		M.initialized = true
	else
		log("💻 Native GameAnalytics not present in current environment (Desktop/Editor fallback mock active)")
		M.initialized = true
	end
end

--- Set custom user identifier
function M.set_user_id(user_id)
	if not user_id then return end
	if has_native() and gameanalytics.configureUserId then
		pcall(gameanalytics.configureUserId, tostring(user_id))
		log("👤 User ID configured:", user_id)
	else
		log("👤 [Mock] User ID configured:", user_id)
	end
end

--- Start progression (e.g., world, arena, level)
function M.start_progression(prog01, prog02, prog03)
	if not prog01 then return end
	local data = {
		progressionStatus = "Start",
		progression01 = tostring(prog01),
	}
	if prog02 then data.progression02 = tostring(prog02) end
	if prog03 then data.progression03 = tostring(prog03) end

	if has_native() and gameanalytics.addProgressionEvent then
		pcall(gameanalytics.addProgressionEvent, data)
		log("🚩 Progression Start:", prog01, prog02, prog03)
	else
		log("🚩 [Mock] Progression Start:", prog01, prog02, prog03)
	end
end

--- Complete progression
function M.complete_progression(prog01, prog02, prog03, score)
	if not prog01 then return end
	local data = {
		progressionStatus = "Complete",
		progression01 = tostring(prog01),
	}
	if prog02 then data.progression02 = tostring(prog02) end
	if prog03 then data.progression03 = tostring(prog03) end
	if score then data.score = tonumber(score) end

	if has_native() and gameanalytics.addProgressionEvent then
		pcall(gameanalytics.addProgressionEvent, data)
		log("🏁 Progression Complete:", prog01, prog02, prog03, "Score:", score)
	else
		log("🏁 [Mock] Progression Complete:", prog01, prog02, prog03, "Score:", score)
	end
end

--- Fail progression
function M.fail_progression(prog01, prog02, prog03, score)
	if not prog01 then return end
	local data = {
		progressionStatus = "Fail",
		progression01 = tostring(prog01),
	}
	if prog02 then data.progression02 = tostring(prog02) end
	if prog03 then data.progression03 = tostring(prog03) end
	if score then data.score = tonumber(score) end

	if has_native() and gameanalytics.addProgressionEvent then
		pcall(gameanalytics.addProgressionEvent, data)
		log("💀 Progression Fail:", prog01, prog02, prog03, "Score:", score)
	else
		log("💀 [Mock] Progression Fail:", prog01, prog02, prog03, "Score:", score)
	end
end

--- Send custom design event (e.g., "ui:click:shop", "chest:opened:rare")
function M.design_event(event_id, value)
	if not event_id then return end
	local data = {
		eventId = tostring(event_id)
	}
	if value ~= nil then data.value = tonumber(value) end

	if has_native() and gameanalytics.addDesignEvent then
		pcall(gameanalytics.addDesignEvent, data)
		log("📊 Design Event:", event_id, value)
	else
		log("📊 [Mock] Design Event:", event_id, value)
	end
end

--- Track resource flow (Source or Sink)
-- @param flow_type "Source" (earned/gained) or "Sink" (spent)
-- @param currency e.g. "gold", "gems"
-- @param amount numeric value
-- @param item_type e.g. "upgrade", "chest", "battle_reward"
-- @param item_id specific identifier e.g. "hero_level_2", "wooden_chest"
function M.resource_event(flow_type, currency, amount, item_type, item_id)
	local data = {
		flowType = flow_type or "Source",
		currency = tostring(currency or "gold"),
		amount = tonumber(amount) or 0,
		itemType = tostring(item_type or "item"),
		itemId = tostring(item_id or "default")
	}

	if has_native() and gameanalytics.addResourceEvent then
		pcall(gameanalytics.addResourceEvent, data)
		log("💰 Resource Event:", data.flowType, data.currency, data.amount, data.itemType, data.itemId)
	else
		log("💰 [Mock] Resource Event:", data.flowType, data.currency, data.amount, data.itemType, data.itemId)
	end
end

--- Track ad event (Show, Click, RewardReceived, FailedShow)
-- @param action "Clicked", "Show", "FailedShow", "RewardReceived"
-- @param ad_type "Video", "RewardedVideo", "Interstitial", "Banner"
-- @param sdk_name e.g. "unityads", "playgama"
-- @param placement placement identifier
function M.ad_event(action, ad_type, sdk_name, placement)
	local data = {
		adAction = tostring(action or "Show"),
		adType = tostring(ad_type or "Interstitial"),
		adSdkName = tostring(sdk_name or "unityads"),
		adPlacement = tostring(placement or "default")
	}

	if has_native() and gameanalytics.addAdEvent then
		pcall(gameanalytics.addAdEvent, data)
		log("📺 Ad Event:", data.adAction, data.adType, data.adSdkName, data.adPlacement)
	else
		log("📺 [Mock] Ad Event:", data.adAction, data.adType, data.adSdkName, data.adPlacement)
	end
end

--- Track error event
-- @param severity "Critical", "Debug", "Error", "Info", "Warning"
-- @param message error message string
function M.error_event(severity, message)
	local data = {
		severity = severity or "Error",
		message = tostring(message or "unknown error")
	}

	if has_native() and gameanalytics.addErrorEvent then
		pcall(gameanalytics.addErrorEvent, data)
		log("⚠️ Error Event:", data.severity, data.message)
	else
		log("⚠️ [Mock] Error Event:", data.severity, data.message)
	end
end

return M
