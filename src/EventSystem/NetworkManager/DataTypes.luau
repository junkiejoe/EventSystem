--!strict
export type DataTypeNames =
	-- Lua data types
	"Number"       |
	"String"       |
	"Boolean"      |
	-- Luau data types
	"Vector"       |
	"Buffer"       |
	-- Roblox data types
	"Vector2"      |
	"Vector3"      |
	"Vector2int16" |
	"Vector3int16" |
	"CFrame"       |
	"EnumItem"     |
	-- Special data types
	"Array"        |
	"Record"       

export type ArrayMemoryLayout = {
	-- A reference to the DataTypeProperties object
	t: DataTypeProperties,
	-- The maximum size of the array.
	-- If s == 0, then the array is considered dynamic.
	s: number
}

export type RecordMemoryLayout = {
	-- The order of the fields.
	[number]: {
		-- The name of the field.
		k: string,
		-- A reference to the DataTypeProperties object
		v: DataTypeProperties,
	}
}

export type MemoryLayout = ArrayMemoryLayout | RecordMemoryLayout

export type DataTypeCodec = {
	Encode: (data: any, to: buffer, offset: number, layout: any?) -> (),
	Decode: (data: buffer, offset: number, layout: any?) -> any
}

export type DataTypeProperties = {
	name: string,
	-- The number ID of the data type.
	ID: number?,
	-- The size of the data type (in bytes).
	-- For dynamically sized data types, the value is -1.
	size: number,
	-- The typename of the data type returned from the type or typeof function.
	typeName: string,
	codec: DataTypeCodec,
}

return {
	FromID = {} :: {[number]: DataTypeProperties},
	FromName = {} :: {[DataTypeNames | string]: DataTypeProperties},
	AddDataType = function(self, info: DataTypeProperties)
		self.FromID[info.ID] = info
		self.FromName[info.name] = info
	end
}
