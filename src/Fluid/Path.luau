--!strict
-- Continuous paths for numbers, Vector2, and Vector3. Control points are
-- geometry, not animation stops. Animate ONE progress value through the path.
local Path = {}

function Path.quadratic(a: any, b: any, c: any)
	return function(t: number)
		local u = 1 - t
		return a * (u * u) + b * (2 * u * t) + c * (t * t)
	end
end

function Path.cubic(a: any, b: any, c: any, d: any)
	return function(t: number)
		local u = 1 - t
		return a * (u ^ 3) + b * (3 * u * u * t) + c * (3 * u * t * t) + d * (t ^ 3)
	end
end

-- C1-continuous cardinal spline: adjacent segments share their tangent.
function Path.spline(points: { any }, tension: number?)
	assert(#points >= 2, "a spline needs at least two points")
	local values = table.clone(points)
	local scale = (1 - (tension or 0)) * 0.5
	return function(alpha: number)
		local t = math.clamp(alpha, 0, 1) * (#values - 1)
		local index = math.min(math.floor(t) + 1, #values - 1)
		t -= index - 1
		local a, b = values[index], values[index + 1]
		local m0 = (b - values[math.max(1, index - 1)]) * scale
		local m1 = (values[math.min(#values, index + 2)] - a) * scale
		return a * (2 * t ^ 3 - 3 * t * t + 1)
			+ m0 * (t ^ 3 - 2 * t * t + t)
			+ b * (-2 * t ^ 3 + 3 * t * t)
			+ m1 * (t ^ 3 - t * t)
	end
end

-- Precompute distance samples once; binary search per frame. This removes
-- unwanted speed changes caused by unevenly spaced path controls.
function Path.uniform(curve: (number) -> any, samples: number?)
	local count = samples or 96
	assert(count >= 2 and count % 1 == 0, "path samples must be an integer >= 2")
	local distances = table.create(count + 1, 0)
	local previous = curve(0)
	local total = 0
	for i = 1, count do
		local current = curve(i / count)
		local delta = current - previous
		total += if type(delta) == "number" then math.abs(delta) else delta.Magnitude
		distances[i + 1] = total
		previous = current
	end
	return function(alpha: number)
		if total == 0 then
			return curve(0)
		end
		local distance = math.clamp(alpha, 0, 1) * total
		local low, high = 1, count + 1
		while high - low > 1 do
			local middle = math.floor((low + high) / 2)
			if distances[middle] < distance then
				low = middle
			else
				high = middle
			end
		end
		local span = distances[high] - distances[low]
		local fraction = if span == 0 then 0 else (distance - distances[low]) / span
		return curve((low - 1 + fraction) / count)
	end
end

return table.freeze(Path)
