local React = require("../React")
local useMotion = require("./useMotion")
local Tokens = require("./MotionTokens")

-- Call inside each keyed child, never a variable-length loop in its parent.
-- delay can be Fluid.stagger(...)(index, count). Closing reverses from the
-- current progress with the same spring and velocity.
return function(open, options)
	options = options or {}
	local values, motion = useMotion({ progress = if options.initialOpen then 1 else 0 }, options)
	local spring = options.spring or Tokens.Spring.smooth
	local delay = if open then options.delay or 0 else options.exitDelay or 0
	React.useEffect(function()
		local config = table.clone(spring)
		config.delay = delay
		motion:spring({ progress = if open then 1 else 0 }, config)
	end, { open, delay, spring.speed, spring.damper })
	return values.progress, motion
end
