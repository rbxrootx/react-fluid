--!nonstrict
-- Dense active list, swap removal, no work while idle. A manual runtime is
-- useful for tests, deterministic replay, or an existing world renderer.
local Runtime = {}
Runtime.__index = Runtime

function Runtime.new(connect, onError)
	return setmetatable(
		{ active = {}, pending = {}, stepping = false, connection = nil, connect = connect, onError = onError or warn },
		Runtime
	)
end

function Runtime:add(job)
	job._removed = nil
	if job._runtimeIndex or job._pending then
		return
	end
	if self.stepping then
		job._pending = true
		table.insert(self.pending, job)
	else
		table.insert(self.active, job)
		job._runtimeIndex = #self.active
	end
	if not self.connection and self.connect then
		self.connection = self.connect(function(dt)
			self:step(dt)
		end)
	end
end

function Runtime:remove(job)
	job._pending = nil
	if self.stepping then
		job._removed = true
		return
	end
	local index = job._runtimeIndex
	if index then
		local last = table.remove(self.active)
		if last ~= job then
			self.active[index] = last
			last._runtimeIndex = index
		end
		job._runtimeIndex = nil
	end
	if not self.stepping and #self.active == 0 and #self.pending == 0 and self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
end

function Runtime:step(dt)
	assert(not self.stepping, "runtime step cannot be re-entered")
	assert(dt >= 0 and dt < math.huge, "dt must be finite and non-negative")
	if dt == 0 then
		return
	end
	self.stepping = true
	local index = 1
	-- Structural changes are deferred during callbacks, so stopping another
	-- job cannot move an unvisited item behind the iteration cursor.
	while index <= #self.active do
		local job = self.active[index]
		if not job._removed then
			local ok, active = pcall(job._step, job, dt)
			if not ok or not active then
				self:remove(job)
			end
			if not ok then
				local reported, reportError = pcall(self.onError, active)
				if not reported then
					warn(reportError)
				end
			end
		end
		index += 1
	end
	self.stepping = false
	for i = #self.active, 1, -1 do
		local job = self.active[i]
		if job._removed then
			self:remove(job)
		end
	end
	for _, job in self.pending do
		if job._pending then
			job._pending = nil
			self:add(job)
		end
	end
	table.clear(self.pending)
	if #self.active == 0 and self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
end

function Runtime:count()
	return #self.active
end

return Runtime
