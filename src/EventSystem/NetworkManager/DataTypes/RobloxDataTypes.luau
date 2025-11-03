--!strict
-- This file contains some of the data types defined by Roblox.
local DataTypes = require(script.Parent.Parent.DataTypes)

---- Vector types ----

DataTypes.Vector2 = {
	ID = 6,
	size = 8,
	typeName = "Vector2",
	codec = {
		Encode = function(data: Vector2): buffer
			local out = buffer.create(9)
			buffer.writef32(out, 1, data.X)
			buffer.writef32(out, 5, data.Y)
			return out
		end,

		Decode = function(data: buffer): Vector2
			return Vector2.new(
				buffer.readf32(data, 1, data.X),
				buffer.readf32(data, 5, data.Y))
		end
	}
}

DataTypes.Vector3 = {
	ID = 7,
	size = 12,
	typeName = "Vector3",
	codec = {
		Encode = function(data: Vector3): buffer
			local out = buffer.create(13)
			buffer.writef32(out, 1, data.X)
			buffer.writef32(out, 5, data.Y)
			buffer.writef32(out, 9, data.Z)
			return out
		end,

		Decode = function(data: buffer): Vector3
			return Vector3.new(
				buffer.readf32(data, 1, data.X),
				buffer.readf32(data, 5, data.Y)
				buffer.readf32(data, 9, data.Z))
		end
	}
}

DataTypes.Vector2int16 = {
	ID = 8,
	size = 4,
	typeName = "Vector2int16",
	codec = {
		Encode = function(data: Vector2): buffer
			local out = buffer.create(5)
			buffer.writei16(out, 1, data.X)
			buffer.writei16(out, 3, data.Y)
			return out
		end,

		Decode = function(data: buffer): Vector2
			return Vector2int16.new(
				buffer.readi16(data, 1, data.X),
				buffer.readi16(data, 3, data.Y))
		end
	}
}

DataTypes.Vector3int16 = {
	ID = 9,
	size = 6,
	typeName = "Vector3int16",
	codec = {
		Encode = function(data: Vector3): buffer
			local out = buffer.create(7)
			buffer.writei16(out, 1, data.X)
			buffer.writei16(out, 3, data.Y)
			buffer.writei16(out, 5, data.Z)
			return out
		end,

		Decode = function(data: buffer): Vector3
			return Vector3int16.new(
				buffer.readi16(data, 1, data.X),
				buffer.readi16(data, 3, data.Y),
				buffer.readi16(data, 5, data.Z))
		end
	}
}

DataTypes.CFrame = {
	ID = 10,
	size = 48,
	typeName = "CFrame",
	codec = {
		Encode = function(data: CFrame): buffer
			local out = buffer.create(49)

			-- Position
			local pos = data.Position
			buffer.writef32(out, 1, pos.X)
			buffer.writef32(out, 5, pos.Y)
			buffer.writef32(out, 9, pos.Z)

			-- Right Vector
			local right = data.RightVector
			buffer.writef32(out, 13, right.X)
			buffer.writef32(out, 17, right.Y)
			buffer.writef32(out, 21, right.Z)
			
			-- UpVector
			local up = data.UpVector
			buffer.writef32(out, 25, up.X)
			buffer.writef32(out, 29, up.Y)
			buffer.writef32(out, 33, up.Z)

			-- -LookVector
			-- Invert to get proper rotation for rotation matrix
			local look = -data.LookVector
			buffer.writef32(out, 37, look.X)
			buffer.writef32(out, 41, look.Y)
			buffer.writef32(out, 45, look.Z)
						
			return out
		end,

		Decode = function(data: buffer): Vector3
			return Vector3int16.new(
				buffer.readi16(data, 1, data.X),
				buffer.readi16(data, 3, data.Y),
				buffer.readi16(data, 5, data.Z))
		end
	}
}

DataTypes.EnumItem = {
	ID = 11,
	size = 6,
	typeName = "Vector3int16",
	codec = {
		Encode = function(data: Vector3): buffer
			local out = buffer.create(7)
			buffer.writei16(out, 1, data.X)
			buffer.writei16(out, 3, data.Y)
			buffer.writei16(out, 5, data.Z)
			return out
		end,

		Decode = function(data: buffer): Vector3
			return Vector3int16.new(
				buffer.readi16(data, 1, data.X),
				buffer.readi16(data, 3, data.Y),
				buffer.readi16(data, 5, data.Z))
		end
	}
}
