local RunService = game:GetService("RunService")
local Runtime = require("./Runtime")

return Runtime.new(function(step)
	local signal = if RunService:IsClient() then RunService.PreRender else RunService.Heartbeat
	return signal:Connect(step)
end)
