-- main/facebook.lua
-- Wrapper module for Defold Facebook extension (https://github.com/defold/extension-facebook)
-- Safe mock fallback for non-supported or desktop environments.

local M = {}

M.initialized = false

local function log(...)
	print("[FACEBOOK]", ...)
end

local function has_native()
	return rawget(_G, "facebook") ~= nil
end

function M.is_supported()
	return has_native()
end

--- Initialize Facebook SDK
function M.init()
	if M.initialized then return end

	if has_native() then
		log("✅ Native Facebook extension detected")
		-- Facebook extension in Defold auto-initializes or provides facebook.init() depending on version
		if facebook.init then
			local ok, err = pcall(facebook.init)
			if ok then
				log("🚀 Facebook SDK initialized successfully")
			else
				log("⚠️ Facebook SDK init error:", tostring(err))
			end
		end
		M.initialized = true
	else
		log("💻 Native Facebook not present in current environment (Mock active)")
		M.initialized = true
	end
end

return M
