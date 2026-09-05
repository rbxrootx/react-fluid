--!strict
-- A delay function, not a timer per child. Total spread can be capped so a
-- long list does not take seconds to open. Indexes are one-based.
return function(interval: number, options: { from: any?, maxDelay: number?, ease: ((number) -> number)? }?)
	assert(interval >= 0 and interval < math.huge, "stagger interval must be finite and non-negative")
	local config = options or {}
	local origin = config.from or "first"
	assert(
		origin == "first" or origin == "last" or origin == "center" or type(origin) == "number",
		"invalid stagger origin"
	)
	assert(config.maxDelay == nil or config.maxDelay >= 0, "maxDelay must be non-negative")
	return function(index: number, count: number): number
		assert(
			count >= 1 and count % 1 == 0 and index >= 1 and index <= count and index % 1 == 0,
			"invalid stagger index/count"
		)
		local center = if origin == "center"
			then (count + 1) / 2
			elseif origin == "last" then count
			elseif type(origin) == "number" then origin
			else 1
		assert(center >= 1 and center <= count, "stagger origin is outside the list")
		local nearest = math.abs(center - math.floor(center + 0.5))
		local farthest = math.max(center - 1, count - center) - nearest
		if farthest == 0 then
			return 0
		end
		local fraction = (math.abs(index - center) - nearest) / farthest
		local spread = math.min(farthest * interval, config.maxDelay or math.huge)
		return spread * (if config.ease then config.ease(fraction) else fraction)
	end
end
