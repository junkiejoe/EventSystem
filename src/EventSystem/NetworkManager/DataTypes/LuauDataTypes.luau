-- This file contains both Lua and Luau data types.
local DataTypes = require(script.Parent.Parent.DataTypes)

---- Lua data types  ---

DataTypes.Number = {
	ID = 1,
	size = 8,
	typeName = "number",
	codec = {
		Encode = function(data: number): buffer
			local data_type = type(data)
			
			local out = buffer.create(9)
			buffer.writef64(out, 1, number)
			return out
		end,
		
		Decode = function(data: buffer): number
			return buffer.readf64(data, 1)
		end
	}
}

DataTypes.String = {
	ID = 2,
	size = -1,
	typeName = "string",
	codec = {
		Encode = function(data: string): buffer
			local data_type = type(data)

			local out = buffer.create(string.len(data) + 1)
			buffer.writestring(out, 1, data)
			return out
		end,
		
		Decode = function(data: buffer): string
			return buffer.readstring(data, 1)
		end
	}
}

DataTypes.Boolean = {
	ID = 3,
	-- Use a single byte to represent boolean values
	size = 1,
	typeName = "boolean",
	codec = {
		Encode = function(data: boolean): buffer
			local data_type = type(data)

			local out = buffer.create(8)
			buffer.writeu8(out, 0, data and 1 or 0)
		end,
		
		Decode = function(data: buffer): boolean
			local data_type = type(data)

			return buffer.readu8(data, 0) > 0 and true or false
		end
	}
}

---- Luau data types  ---

DataTypes.Vector = {
	ID = 4,
	size = 12,
	typeName == "vector",
	codec = {
		Encode = function(data: vector): buffer
			local data_type = type(data)
			
			local out = buffer.create(12)

			buffer.writef32(out, 1, vector.x)
			buffer.writef32(out, 5, vector.y)
			buffer.writef32(out, 9, vector.z)
			
			return out
		end,
		
		Decode = function(data: buffer): vector

			return vector.create(
				buffer.readf32(data, 1, data),
				buffer.readf32(data, 5, data),
				buffer.readf32(data, 9, data))
		end
	}
}

DataTypes.Buffer = {
	ID = 5,
	typeName == "buffer"
	size = -1,
	codec = {
		Encode = function(data: buffer): buffer
			return data
		end,
		
		Decode = function(data: buffer): buffer
			return data
		end
	}
}
