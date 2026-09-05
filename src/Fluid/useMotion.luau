local React = require("../React")
local Controller = require("./Controller")
local SharedRuntime = require("./SharedRuntime")
local Types = require("./Types")

-- Fixed hook count regardless of the number/order of properties. Bindings are
-- created once, and animated writes never trigger a React render.
return function(
	initial: Types.Goals,
	options: { reducedMotion: boolean? }?
): ({ [string]: React.Binding<any> }, Types.Motion)
	local state = React.useMemo(function()
		local bindings, setters = {}, {}
		for key, value in initial do
			bindings[key], setters[key] = React.createBinding(value)
		end
		local controller = Controller.new(initial, SharedRuntime, function(key, value)
			setters[key](value)
		end)
		return { bindings = bindings, controller = controller }
	end, {})
	React.useEffect(function()
		return function()
			-- stop is reusable for StrictMode's effect cleanup/remount cycle.
			state.controller:stop()
		end
	end, {})
	local reduced = options and options.reducedMotion == true or false
	React.useEffect(function()
		state.controller:setReducedMotion(reduced)
	end, { reduced })
	return state.bindings, state.controller
end
