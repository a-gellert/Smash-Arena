-- sound.lua
-- Central sound manager helper module for Smash Arena
local M = {}

M.music_loaded = false
M.music_playing = false
M.wants_music = true
M.in_battle = false
M.current_music_volume = 0.8
M.current_sfx_volume = 1.0

local SOUND_MANAGER_URL = "main:/sound_manager"
local last_play_time = {}

-- SoundGate: предотвращает наслоение одинаковых звуков в один и тот же кадр
local function can_play(sound_type, min_interval)
	local now = os.clock()
	local last = last_play_time[sound_type] or 0
	if (now - last) < (min_interval or 0.06) then
		return false
	end
	last_play_time[sound_type] = now
	return true
end

function M.play_hit(extra_gain)
	if not can_play("hit", 0.05) then return end
	local sfx_vol = M.current_sfx_volume or 1.0
	if sfx_vol <= 0.001 then return end
	local gain = (0.9 + math.random() * 0.2) * sfx_vol
	if extra_gain then
		gain = gain * extra_gain
	end
	local hit_id = math.random() > 0.5 and "#hit_1" or "#hit_2"
	pcall(msg.post, SOUND_MANAGER_URL, "play_sound", { id = hit_id, gain = gain })
end

function M.play_bounce(is_heavy)
	if not can_play("bounce", 0.06) then return end
	local sfx_vol = M.current_sfx_volume or 1.0
	if sfx_vol <= 0.001 then return end
	local gain = (0.85 + math.random() * 0.25) * sfx_vol
	local bounce_id = is_heavy and "#bounce_heavy" or "#bounce"
	pcall(msg.post, SOUND_MANAGER_URL, "play_sound", { id = bounce_id, gain = gain })
end

function M.play_sound(sound_id, gain)
	local sfx_vol = M.current_sfx_volume or 1.0
	if sfx_vol <= 0.001 then return end
	if sound_id == "bounce" then
		M.play_bounce(false)
		return
	elseif sound_id == "bounce_heavy" then
		M.play_bounce(true)
		return
	elseif sound_id == "hit" then
		M.play_hit(gain)
		return
	end
	local id = sound_id
	if type(id) == "string" and not id:find("#") then
		id = "#" .. id
	end
	pcall(msg.post, SOUND_MANAGER_URL, "play_sound", { id = id, gain = (gain or 1.0) * sfx_vol })
end

function M.play_music()
	M.in_battle = false
	if (M.current_music_volume or 0) <= 0.001 then
		M.wants_music = false
		if M.music_playing then
			pcall(msg.post, SOUND_MANAGER_URL, "stop_music")
		end
		return
	end

	M.wants_music = true
	if M.music_loaded and not M.music_playing then
		pcall(msg.post, SOUND_MANAGER_URL, "play_music")
	end
end

function M.stop_music()
	M.in_battle = true
	M.wants_music = false
	if M.music_playing then
		pcall(msg.post, SOUND_MANAGER_URL, "stop_music")
	end
end

function M.set_sfx_volume(gain)
	local val = math.max(0, math.min(1, gain))
	M.current_sfx_volume = val
	local ok = pcall(sound.set_group_gain, hash("sfx"), val)
	if not ok then
		pcall(sound.set_group_gain, "sfx", val)
	end
end

function M.set_music_volume(gain)
	local val = math.max(0, math.min(1, gain))
	M.current_music_volume = val
	local ok = pcall(sound.set_group_gain, hash("music"), val)
	if not ok then
		pcall(sound.set_group_gain, "music", val)
	end

	if val <= 0.001 then
		M.wants_music = false
		if M.music_playing then
			pcall(msg.post, SOUND_MANAGER_URL, "stop_music")
		end
	else
		if not M.in_battle then
			M.wants_music = true
			if M.music_loaded then
				if not M.music_playing then
					pcall(msg.post, SOUND_MANAGER_URL, "play_music")
				else
					pcall(msg.post, SOUND_MANAGER_URL, "set_music_gain", { gain = val })
				end
			end
		end
	end
end

return M
