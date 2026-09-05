--!strict
-- Closed-form damped harmonic oscillator. Based on the Quenty integrator
-- credited in React Flow's Utility/SpringValue; MIT attribution is retained.
local SpringMath = {}

function SpringMath.coefficients(speed: number, damper: number, dt: number): (number, number, number, number)
	assert(speed > 0 and speed < math.huge, "spring speed must be finite and positive")
	assert(damper >= 0 and damper < math.huge, "spring damper must be finite and non-negative")
	local t = speed * dt
	local d2 = damper * damper
	local co, si
	if math.abs(d2 - 1) < 1e-8 then
		co = math.exp(-t)
		si = co * t
	elseif d2 < 1 then
		local h = math.sqrt(1 - d2)
		local decay = math.exp(-damper * t)
		co = decay * math.cos(h * t)
		si = decay * math.sin(h * t) / h
	else
		local h = math.sqrt(d2 - 1)
		-- -1/(d+h) avoids cancellation in -d+h for heavily damped springs.
		local a = math.exp(-t / (damper + h))
		local b = math.exp((-damper - h) * t)
		co = (a + b) * 0.5
		si = (a - b) / (2 * h)
	end
	return co + damper * si, si / speed, -speed * si, co - damper * si
end

function SpringMath.physical(stiffness: number, damping: number, mass: number?)
	local m = mass or 1
	assert(stiffness > 0 and damping >= 0 and m > 0, "invalid physical spring parameters")
	return { speed = math.sqrt(stiffness / m), damper = damping / (2 * math.sqrt(stiffness * m)) }
end

return table.freeze(SpringMath)
