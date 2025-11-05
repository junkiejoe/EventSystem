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
		v: DataTypeProperties | ArrayMemoryLayout,
	}
}

export type MemoryLayout = ArrayMemoryLayout | RecordMemoryLayout

export type DataTypeCodec = {
	Encode: (data: any, to: buffer, offset: number, subType: DataTypeProperties?) -> boolean,
	Decode: (data: buffer, offset: number, subType: DataTypeProperties?, size: number?) -> any
}

export type DataTypeProperties = {
	name: string,
	-- The number ID of the data type.
	ID: number,
	-- The user defined layout of the DataType.
	layout: RecordMemoryLayout?,
	-- The size of the data type (in bytes).
	-- For dynamically sized data types, the value is -1.
	size: number,
	-- The typename of the data type returned from the type or typeof function.
	typeName: string,
	-- Defined by the built in data type.
	-- For user defined data types, this is just the Record encoder. 
	codec: DataTypeCodec,
}

return {
	FromID = {} :: {[number]: DataTypeProperties},
	FromName = {} :: {[ string]: DataTypeProperties},
	-- A list of user defined record memory layouts.
	Records = {} :: {[string]: RecordMemoryLayout},
	AddType = function(self, info: DataTypeProperties): boolean
		if self.FromID[info.ID] then
			warn(`Attempt to redefine {self.FromID[info.ID].name} using same ID.`)
			return false
		end
		if self.FromName[info.name] then
			warn(`Attempt to redefine {self.FromName[info.name].name} using same name.`)
		end
		self.FromID[info.ID] = info
		self.FromName[info.name] = info
		return true
	end
}