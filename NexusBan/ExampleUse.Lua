local NexusBan = require(game.ServerScriptService.NexusBan.Core.MainModule) -- Most recommended keeping it in ServerScriptService

--[[
	HttpService is required
]]--


NexusBan.Configure({
	whitelistKey = "", -- Not needed for regular people
	IsTestMode = false,
	customKickMessage = "You have been permanently banned from this Game\n\n{reason}",
	customCodeOnFlagged = function(player, reason)
		print(player, reason)
	end,
	checkInterval = 6
})

NexusBan.Init()

-- NexusBan.Report("123456", "Test reason", "Test proof")