local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

return function(root, overrides)
	local cache = overrides or {}
	local function normalize(path)
		local parts = {}
		for part in path:gmatch("[^/]+") do
			if part == ".." then
				table.remove(parts)
			elseif part ~= "." then
				table.insert(parts, part)
			end
		end
		return table.concat(parts, "/")
	end
	local loadModule
	loadModule = function(path)
		path = normalize(path)
		if cache[path] ~= nil then
			return cache[path]
		end
		local env = table.clone(roblox)
		env.warn = warn
		env.game = {
			GetService = function()
				return {
					RenderStepped = {},
					IsClient = function()
						return true
					end,
				}
			end,
		}
		env.require = function(relative)
			assert(type(relative) == "string", "test loader expects relative requires")
			local directory = path:match("^(.*)/") or "."
			return loadModule(directory .. "/" .. relative)
		end
		local source = fs.readFile(root .. "/" .. path .. ".luau")
		local value = luau.load(source, { debugName = path, environment = env, injectGlobals = true })()
		cache[path] = value
		return value
	end
	return loadModule
end
