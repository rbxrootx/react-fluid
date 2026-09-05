--!strict
local Easing = {}
export type Curve = (number) -> number

Easing.linear = function(t: number): number
	return t
end

function Easing.reverse(curve: Curve): Curve
	return function(t)
		return 1 - curve(1 - t)
	end
end

function Easing.inOut(curve: Curve): Curve
	return function(t)
		return if t < 0.5 then curve(t * 2) * 0.5 else 1 - curve((1 - t) * 2) * 0.5
	end
end

-- CSS-style cubic Bezier: solve x(u)=time, then evaluate y(u).
-- Y may exceed [0,1] for anticipation and overshoot; X must be monotone.
function Easing.bezier(x1: number, y1: number, x2: number, y2: number): Curve
	assert(x1 >= 0 and x1 <= 1 and x2 >= 0 and x2 <= 1, "Bezier x controls must be in [0,1]")
	assert(math.abs(y1) < math.huge and math.abs(y2) < math.huge, "Bezier y controls must be finite")
	local function sample(u, a, b)
		return 3 * (1 - u) ^ 2 * u * a + 3 * (1 - u) * u * u * b + u ^ 3
	end
	return function(t)
		if t <= 0 then
			return 0
		end
		if t >= 1 then
			return 1
		end
		local low, high, u = 0, 1, t
		for _ = 1, 24 do
			local x = sample(u, x1, x2)
			if math.abs(x - t) < 1e-7 then
				break
			end
			if x < t then
				low = u
			else
				high = u
			end
			u = (low + high) * 0.5
		end
		return sample(u, y1, y2)
	end
end

function Easing.steps(count: number, jumpStart: boolean?): Curve
	assert(count >= 1 and count % 1 == 0, "steps requires a positive integer")
	return function(t)
		return math.clamp((math.floor(t * count) + (if jumpStart then 1 else 0)) / count, 0, 1)
	end
end

local families = {
	quad = function(t: number)
		return t * t
	end,
	cubic = function(t: number)
		return t ^ 3
	end,
	quart = function(t: number)
		return t ^ 4
	end,
	quint = function(t: number)
		return t ^ 5
	end,
	sine = function(t: number)
		return 1 - math.cos(t * math.pi * 0.5)
	end,
	expo = function(t: number)
		return if t == 0 then 0 else 2 ^ (10 * t - 10)
	end,
	circ = function(t: number)
		return 1 - math.sqrt(math.max(0, 1 - t * t))
	end,
	back = function(t: number)
		return 2.70158 * t ^ 3 - 1.70158 * t * t
	end,
	elastic = function(t: number)
		if t == 0 or t == 1 then
			return t
		end
		return -(2 ^ (10 * t - 10)) * math.sin((10 * t - 10.75) * (2 * math.pi / 3))
	end,
}

local function bounceOut(t: number): number
	if t < 1 / 2.75 then
		return 7.5625 * t * t
	end
	if t < 2 / 2.75 then
		t -= 1.5 / 2.75
		return 7.5625 * t * t + 0.75
	end
	if t < 2.5 / 2.75 then
		t -= 2.25 / 2.75
		return 7.5625 * t * t + 0.9375
	end
	t -= 2.625 / 2.75
	return 7.5625 * t * t + 0.984375
end
families.bounce = Easing.reverse(bounceOut)

for name, curve in families do
	Easing[name .. "In"] = curve
	Easing[name .. "Out"] = Easing.reverse(curve)
	Easing[name .. "InOut"] = Easing.inOut(curve)
end

Easing.smoothstep = function(t: number): number
	return t * t * (3 - 2 * t)
end
Easing.smootherstep = function(t: number): number
	return t ^ 3 * (t * (t * 6 - 15) + 10)
end
Easing.standard = Easing.bezier(0.2, 0, 0, 1)

return table.freeze(Easing)
