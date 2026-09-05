local RS = game:GetService("ReplicatedStorage")
local StudioTestService = game:GetService("StudioTestService")
local completed = false
RS.ReactFluidValidation.Report.OnServerEvent:Connect(function(_, result)
	if completed then
		return
	end
	completed = true
	print("ReactFluidValidation", game:GetService("HttpService"):JSONEncode(result))
	pcall(function()
		StudioTestService:EndTest(result)
	end)
end)
task.delay(35, function()
	if not completed then
		local result = { ok = false, error = "client validation timed out" }
		warn(result.error)
		pcall(function()
			StudioTestService:EndTest(result)
		end)
	end
end)
