-- This file contains both Lua and Luau data types.
local DataTypes = require(script.Parent.Parent.DataTypes)

---- Lua data types  ---

DataTypes:AddType {
	name = "Number",
	ID = 1,
	size = 8,
	typeName = "number",
	codec = {
		Encode = function(data, to, offset)
			buffer.writef64(to, offset, data)
			return false
		end,
		
		Decode = function(data, offset)
			return buffer.readf64(data, offset)
		end
	}
}

DataTypes:AddType {
	name = "String",
	ID = 2,
	size = 0,
	typeName = "string",
	codec = {
		Encode = function(data, to, offset)
			buffer.writestring(to, offset, data)
			return false
		end,
		
		Decode = function(data, offset, _, size)
			return buffer.readstring(data, offset, size :: number)
		end
	}
}

DataTypes:AddType {
	name = "Boolean",
	ID = 3,
	-- Use a single byte to represent boolean values
	size = 1,
	typeName = "boolean",
	codec = {
		Encode = function(data, to, offset)
			buffer.writeu8(to, offset, data and 1 or 0)
			return false
		end,
		
		Decode = function(data, offset)
			return buffer.readu8(data, offset) > 0 and true or false
		end
	}
}

---- Luau data types  ---

DataTypes:AddType {
	name = "Vector",
	ID = 4,
	size = 12,
	typeName = "vector",
	codec = {
		Encode = function(data, to, offset)
			local data_type = type(data)

			buffer.writef32(to, offset, data.x)
			buffer.writef32(to, offset + 4, data.y)
			buffer.writef32(to, offset + 8, data.z)
			
			return false
		end,
		
		Decode = function(data, offset)

			return vector.create(
				buffer.readf32(data, offset),
				buffer.readf32(data, offset + 4),
				buffer.readf32(data, offset + 8))
		end
	}
}

-- lol
DataTypes:AddType {
	name = "Buffer",
	ID = 5,
	typeName = "buffer",
	size = 0,
	codec = {
		Encode = function(data)
			return false
		end,
		
		Decode = function(data)
			return data
		end
	}
}
