--!strict
-- This file contains some of the data types defined by Roblox.
local DataTypes = require(script.Parent.Parent.DataTypes)

---- Vector types ----

DataTypes:AddType {
	name = "Vector2",
	ID = 6,
	size = 8,
	typeName = "Vector2",
	codec = {
		Encode = function(data, to, offset, subType)
			
			buffer.writef32(to, offset, data.X)
			buffer.writef32(to, offset + 4, data.Y)
			return false
		end,

		Decode = function(data, offset, subType, size)
			return Vector2.new(
				buffer.readf32(data, offset),
				buffer.readf32(data, offset + 4))
		end
	}
}

DataTypes:AddType {
	name = "Vector3",
	ID = 7,
	size = 12,
	typeName = "Vector3",
	codec = {
		Encode = function(data, to, offset)
			local out = buffer.create(13)
			buffer.writef32(out, 1, data.X)
			buffer.writef32(out, 5, data.Y)
			buffer.writef32(out, 9, data.Z)
			return false
		end,

		Decode = function(data, offset)
			return Vector3.new(
				buffer.readf32(data, offset),
				buffer.readf32(data, offset + 4),
				buffer.readf32(data, offset + 8))
		end
	}
}

DataTypes:AddType {
	name = "Vector2int16",
	ID = 8,
	size = 4,
	typeName = "Vector2int16",
	codec = {
		Encode = function(data, to, offset)
			buffer.writei16(data, offset, data.X)
			buffer.writei16(data, offset + 2, data.Y)
			return false
		end,

		Decode = function(data, offset)
			return Vector2int16.new(
				buffer.readi16(data, offset),
				buffer.readi16(data, offset + 2))
		end
	}
}

DataTypes:AddType {
	name = "Vector3int16",
	ID = 9,
	size = 6,
	typeName = "Vector3int16",
	codec = {
		Encode = function(data, to, offset)
			local out = buffer.create(7)
			buffer.writei16(out, 1, data.X)
			buffer.writei16(out, 3, data.Y)
			buffer.writei16(out, 5, data.Z)
			return false
		end,

		Decode = function(data, offset)
			return Vector3int16.new(
				buffer.readi16(data, 1),
				buffer.readi16(data, 3),
				buffer.readi16(data, 5))
		end
	}
}

DataTypes:AddType {
	name = "CFrame",
	ID = 10,
	size = 24,
	typeName = "CFrame",
	codec = {
		Encode = function(data, to, offset)
			local rx, ry, rz = (data ::  CFrame):ToEulerAnglesXYZ()
			local pos = data.Position :: Vector3
			-- Position
			buffer.writef32(to, offset, pos.X)
			buffer.writef32(to, offset + 4, pos.Y)
			buffer.writef32(to, offset + 8, pos.Z)
			-- Euler angles
			buffer.writef32(to, offset + 12, rx)
			buffer.writef32(to, offset + 16, ry)
			buffer.writef32(to, offset + 20, rz)
			return false
		end,

		Decode = function(data, offset)
	local px = buffer.readf32(data, offset)
	local py = buffer.readf32(data, offset + 4)
	local pz = buffer.readf32(data, offset + 8)

	local rx = buffer.readf32(data, offset + 12)
	local ry = buffer.readf32(data, offset + 16)
	local rz = buffer.readf32(data, offset + 20)

	return CFrame.new(px, py, pz) * CFrame.Angles(rx, ry, rz)
end
	}
}