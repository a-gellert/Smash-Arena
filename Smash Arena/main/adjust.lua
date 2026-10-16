-- main/adjust.lua
-- Wrapper module for Adjust SDK (Defold extension) with local mock fallback

local M = {}

M.initialized = false

-- App token from game.project [adjust] section or hardcoded default
local APP_TOKEN = sys.get_config_string("adjust.app_token", "3fybji2hz728")
local ENVIRONMENT = sys.get_config_string("adjust.environment", "sandbox")
local LOG_LEVEL = sys.get_config_string("adjust.log_level", "info")

local function log(...)
	print("[ADJUST]", ...)
end

local function has_native()
	return rawget(_G, "adjust") ~= nil
end

function M.is_supported()
	return has_native()
end

--- Initialize Adjust SDK
--- On Android/iOS with the native extension present, initializes the real SDK.
--- On other platforms, provides a mock fallback.
function M.init()
	if M.initialized then return end

	if has_native() then
		log("✅ Native Adjust extension detected — initializing with app_token:", APP_TOKEN)
		local params = {
			app_token = APP_TOKEN,
			is_sandbox = (ENVIRONMENT == "sandbox"),
			log_level = LOG_LEVEL,
			listener = function(self, event)
				if event then
					log("📩 Event:", event.phase or "unknown",
						"| network:", event.network or "",
						"| campaign:", event.campaign or "",
						"| adgroup:", event.adgroup or "",
						"| creative:", event.creative or "",
						"| adid:", event.adid or "",
						"| is_error:", tostring(event.is_error or false))
				end
			end
		}
		local ok, err = pcall(adjust.init, params)
		if ok then
			log("🚀 Adjust SDK init called successfully")
			M.initialized = true
		else
			log("⚠️ Adjust SDK init error:", tostring(err))
			M.initialized = true -- mark as initialized to avoid retries
		end
	else
		log("💻 Native Adjust not present in current environment (Desktop/Editor/Web mock active)")
		M.initialized = true
	end
end

--- Track a custom event by event token
--- @param event_token string The Adjust event token (from Adjust dashboard)
--- @param revenue number|nil Optional revenue amount
--- @param currency string|nil Optional currency code (e.g. "USD")
function M.track_event(event_token, revenue, currency)
	if not event_token then return end
	if has_native() and adjust.track_event then
		local params = {
			token = event_token
		}
		if revenue and currency then
			params.revenue = tonumber(revenue)
			params.currency = tostring(currency)
		end
		local ok, err = pcall(adjust.track_event, params)
		if ok then
			log("📊 Event tracked:", event_token, revenue and ("revenue: " .. tostring(revenue) .. " " .. tostring(currency)) or "")
		else
			log("⚠️ Track event error:", tostring(err))
		end
	else
		log("📊 [Mock] Event tracked:", event_token, revenue and ("revenue: " .. tostring(revenue) .. " " .. tostring(currency)) or "")
	end
end

--- Track ad revenue (Adjust 5.x+ feature, may not be available in all extension versions)
--- @param source string Ad revenue source (e.g. "unity_ads", "admob")
--- @param revenue number Revenue amount
--- @param currency string Currency code (e.g. "USD")
function M.track_ad_revenue(source, revenue, currency)
	if has_native() and adjust.track_ad_revenue then
		local ok, err = pcall(adjust.track_ad_revenue, {
			source = tostring(source or "unknown"),
			revenue = tonumber(revenue) or 0,
			currency = tostring(currency or "USD")
		})
		if ok then
			log("💰 Ad revenue tracked:", source, revenue, currency)
		else
			log("⚠️ Track ad revenue error:", tostring(err))
		end
	else
		log("💰 [Mock] Ad revenue tracked:", source, revenue, currency)
	end
end

--- Set push token for Adjust (Android/iOS push notifications integration)
--- @param token string Push token string
function M.set_push_token(token)
	if not token then return end
	if has_native() and adjust.set_push_token then
		pcall(adjust.set_push_token, tostring(token))
		log("🔔 Push token set")
	else
		log("🔔 [Mock] Push token set")
	end
end

--- Enable/disable Adjust SDK tracking
--- @param enabled boolean
function M.set_enabled(enabled)
	if has_native() and adjust.set_enabled then
		pcall(adjust.set_enabled, enabled)
		log("⚙️ Adjust enabled:", tostring(enabled))
	else
		log("⚙️ [Mock] Adjust enabled:", tostring(enabled))
	end
end

--- Request IDFA tracking authorization (iOS 14+ ATT prompt)
function M.request_tracking_authorization()
	if has_native() and adjust.request_tracking_authorization_with_completion_handler then
		pcall(adjust.request_tracking_authorization_with_completion_handler)
		log("📱 Requested iOS tracking authorization (ATT)")
	else
		log("📱 [Mock] Requested iOS tracking authorization (ATT)")
	end
end

--- Send first packages (if delay_start was set)
function M.send_first_packages()
	if has_native() and adjust.send_first_packages then
		pcall(adjust.send_first_packages)
		log("📤 First packages sent")
	else
		log("📤 [Mock] First packages sent")
	end
end

return M
