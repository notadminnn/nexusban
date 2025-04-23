-- [ SERVICES ]

local HttpService = game:GetService("HttpService")

-- [ NOTICE ]

--[[
 █████╗ ████████╗████████╗███████╗███╗   ██╗████████╗██╗ ██████╗ ███╗   ██╗
██╔══██╗╚══██╔══╝╚══██╔══╝██╔════╝████╗  ██║╚══██╔══╝██║██╔═══██╗████╗  ██║
███████║   ██║      ██║   █████╗  ██╔██╗ ██║   ██║   ██║██║   ██║██╔██╗ ██║
██╔══██║   ██║      ██║   ██╔══╝  ██║╚██╗██║   ██║   ██║██║   ██║██║╚██╗██║
██║  ██║   ██║      ██║   ███████╗██║ ╚████║   ██║   ██║╚██████╔╝██║ ╚████║
╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝

🔒 NexusBan System – API Usage Policy 🔒

ATTENTION: 
This module connects to NexusBan’s secured API endpoints. Calling any of our endpoints without valid authorization 
(i.e. a valid Game ID and Whitelist Key) will be logged, rejected, and may result in your IP and game being blacklisted.

✔️ Do not attempt to bypass, spoof, or tamper with authorization.
✔️ API traffic is monitored and abuse is permanently logged.

This module is provided under strict terms of use.

Unauthorized access is considered abuse of service.

--]]

-- [ DEFINING MODULE SCRIPT ]
local NexusBan = {}

-- [ INTERNAL VARIABLES ]
local API_URL = "https://nexusban.nexusdark.com"

local GAME_ID = game.GameId
local PLACE_ID = game.PlaceId
local TEST_MODE = false
local WHITELIST_KEY = nil
local CHECK_INTERVAL = -1
local CUSTOM_KICK_MESSAGE = "You are permanently banned.\nReason: {reason} This is powered by NexusBan"

local CurrentConfig = {}

-- [FUNCTION]
-- Modified at: 22.04.2025 19:54
-- Last Modified by: afgdgzdg73
--
-- Allows administrators to report people
-- 
--
-- ABUSE NOTICE:
-- ATTENTION. SENDING TOO MANY REQUESTS WILL RESULTIN YOUR KEY BEING BLACKLISTED TEMPORARILY FOR INVESTIGATION
-- IF WE DETECT YOU HAVE BEEN ABUSING OUR API YOU WILL BE PERMANENTLY BLACKLISTED FROM OUR SYSTEM.

function NexusBan.Report(targetUserId, reason, proof)
	if not WHITELIST_KEY then
		warn("[NexusBan] Cannot report without a whitelist key. Call Configure() first.")
		return
	end

	local reportData = {
		reportedUserId = tostring(targetUserId),
		reason = reason,
		proof = proof,
		reportingGame = tostring(game.GameId),
		whitelistKey = WHITELIST_KEY
	}

	local success, result = pcall(function()
		return HttpService:RequestAsync({
			Url = API_URL .. "/report",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = HttpService:JSONEncode(reportData)
		})
	end)

	if success and result.Success then
		print("[NexusBan] Report sent successfully!")
	else
		warn("[NexusBan] Failed to send report:", result and result.Body or "Unknown error")
	end
end

-- [FUNCTION]
-- Modified at: 22.04.2025 16:19
-- Last Modified by: afgdgzdg73
--
-- Description of latest changes:
-- Allow developers to configure the whitelistKey and customKickMessage
-- Added a isTestMode option that will add debug logs all around the code
-- Added a checkInterval that will run function(CheckPlayer) every x SECONDS

function NexusBan.Configure(config)
	config = config or {}
	
	if config.IsTestMode then
		if typeof(config.IsTestMode) ~= "boolean" then
			print("[NexusBan] [ConfigurationError] For the IsTestMode Property you can only use true or false")
		else
			TEST_MODE = config.IsTestMode
			if TEST_MODE then
				print("📀 [ConfigurationService] [NexusBan] isTestMode defined")
			end
		end
	end
	
	if config.whitelistKey then
		WHITELIST_KEY = config.whitelistKey
		if config.IsTestMode == true then print("📀 [ConfigurationService] [NexusBan] whitelistKey defined") end
	end

	if config.customKickMessage then
		CUSTOM_KICK_MESSAGE = config.customKickMessage
		if config.IsTestMode == true then print("📀 [ConfigurationService] [NexusBan] customKickMessage defined") end
	end
	
	if config.checkInterval then
		if typeof(config.checkInterval) == "number" then
			if CHECK_INTERVAL > 5 then
				-- You will be permanently blacklisted if we find out you changed this value
				warn("[NexusBan] [ProtectionService] Do not set the checkInterval number lower than 5 Seconds!")
				return
			end
			CHECK_INTERVAL = config.checkInterval
			if config.IsTestMode == true then print("📀 [ConfigurationService] [NexusBan] checkInterval defined") end
		else
			print("[NexusBan] [ConfigurationError] For the checkInterval Property you can only use NUMBERS")
		end
	end
	
	CurrentConfig = config
end

-- [FUNCTION]
-- Modified at: -
-- Last Modified by: afgdgzdg73
--
-- Checks if the 'player' argument is on the banned list

function NexusBan.CheckPlayer(player)
	if CurrentConfig.IsTestMode == true then print("💫 [CheckPlayerService] [NexusBan] Checking "..player.Name) end
	
	if CurrentConfig.IsTestMode == true then print("💫 [CheckPlayerService] [NexusBan] Contacting Web-Server to check "..player.Name) end
	local success, result = pcall(function()
		return HttpService:RequestAsync({
			Url = API_URL .. "/isFlagged/" .. player.UserId,
			Method = "GET",
			Headers = {
				["Game-ID"] = tostring(PLACE_ID),
				["Whitelist-Key"] = WHITELIST_KEY,
			}
		})
	end)

	if success and result.Success then
		local data = HttpService:JSONDecode(result.Body)
		local updated = CUSTOM_KICK_MESSAGE:gsub("{reason}", data.reason or "No reason given")
		if data.flagged then
			if TEST_MODE == true then
				print("[NexusBan] [TEST-MODE] Would kick "..player.Name.." for reason: "..updated)
			else
				player:Kick(updated)
			end
		end
	else
		warn("[NexusBan] API Error: ", result and result.Body or "Unknown")
	end
end


-- [FUNCTION]
-- Modified at: 21.04.2025 19:51
-- Last Modified by: afgdgzdg73
--
-- Checks if the 'player' argument is on the banned list

function NexusBan.Init()
	if CurrentConfig.IsTestMode == true then
		print("📙 [Init] [NexusBan] Init has been started!")
	end

	if not WHITELIST_KEY then
		warn("[NexusBan] Init aborted — missing whitelistKey. Call Configure() or ActivateWhitelistKey() first.")
		return
	end

	if CHECK_INTERVAL == -1 then
		if CurrentConfig.IsTestMode == true then print("📙 [Init] [NexusBan] Performing one-time check on all players...") end
		for _, player in ipairs(game.Players:GetPlayers()) do
			task.spawn(function()
				if CurrentConfig.IsTestMode == true then print("📙 [Init] [NexusBan] Checking "..player.Name.." once...") end
				NexusBan.CheckPlayer(player)
			end)
		end
	else
		if CurrentConfig.IsTestMode == true then print("📙 [Init] [NexusBan] Starting interval check every "..CHECK_INTERVAL.." seconds...") end
		task.spawn(function()
			while true do
				task.wait(CHECK_INTERVAL)
				for _, player in ipairs(game.Players:GetPlayers()) do
					task.spawn(function()
						if CurrentConfig.IsTestMode == true then print("📙 [Init] [NexusBan] Checking "..player.Name.." (interval)") end
						NexusBan.CheckPlayer(player)
					end)
				end
			end
		end)
	end

	-- Always check new players when they join
	game.Players.PlayerAdded:Connect(function(player)
		if CurrentConfig.IsTestMode == true then print("📙 [Init] [NexusBan] New player joined: "..player.Name) end
		NexusBan.CheckPlayer(player)
	end)
end



return NexusBan
