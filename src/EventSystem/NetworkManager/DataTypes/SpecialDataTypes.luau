--!nonstrict
-- Implements array and record data types.
-- Type
local DataTypes = require(script.Parent.Parent.DataTypes)

DataTypes:AddType {
	name = "Array",
	ID = 1,
	size = 0,
	typeName = "table",
	codec = {
		Encode = function(data, to, offset, subType)
			local element_size = subType.size
			local codec = subType.codec
			
			for i, v in ipairs(data) do
				-- Because arrays actually start at 0.
				local index = 
					(i - 1)
					* element_size
					+ offset
				
				codec.Encode(v, to, index,subType)
			end

			return false
		end,
		
		Decode = function(data, offset, size, subType): any?
			local element_size = subType.size
			-- Subtract PacketType ID
			local buffer_size = buffer.len(data) - 1
			local codec = subType.codec
			
			local element_count, remainder = math.modf(buffer_size/element_size)

			if remainder ~= 0 then
				-- The buffer size is not a value of n * element_size.
				return nil
			end
			
			if size ~= 0 and element_count > size then
				-- Array is larger than expected.
				return nil
			end

			local out = {} :: {[number]: any}
			-- Subtract one, because you know... Arrays start at 0.
			for i = 0, (element_count - 1) do
				local index = i * element_size + offset
				local decoded_value = codec.Decode(data, index, subType, size)

				if decoded_value == nil then
					return nil
				end

				table.insert(out, decoded_value)
			end

			return out
		end--Decode
	}
}

DataTypes:AddType {
	name = "Record",
	ID = 1,
	size = 0,
	typeName = "table",
	codec = {
		Encode = function(data, to, offset, subType)
			
			-- The offset in bytes needed to get to the next field
			local field_offset = 0
			for _, field in ipairs(subType.layout) do
				
				local value = data[field.k]
				
				if value == nil then
					-- Missing field
					return true
				end

				local field_type = field.v :: DataTypes.DataTypeProperties
				
				if field_type.ID == nil then
					-- Feld is an array.
					field_type = (field_type :: DataTypes.ArrayMemoryLayout).t
				end

				if typeof(value) ~= field_type.typeName then 
					-- Mismatch types
					return true
				end
				
				if field_type.codec.Encode(value, to, offset + field_offset, field_type.layout) == true then
					-- Encoding failed
					return true
				end

				field_offset += field_type.size
			end--loop

			return false
		end,
		
		Decode = function(data, offset, subType, size)
			local buffer_size = buffer.len(data) - 1
			local layout = subType.layout :: DataTypes.RecordMemoryLayout

			local field_offset = 0
			local out = {}

			for _, field in ipairs(layout) do
				
				local field_type = field.v :: DataTypes.DataTypeProperties
				if field_type.ID == nil then
					-- Feld is an array.
					field_type = (field_type :: DataTypes.ArrayMemoryLayout).t
				end

				if field_offset + field_type.size > buffer_size then
					-- Out of bounds
					return nil
				end

				local value = field_type.codec.Decode(buffer, offset + field_offset, field_type.layout)
				if value == nil then
					-- Decoding failed
					return nil
				end

				out[field.k] = value
				field_offset += field_type.size
			end--loop
			return out
		end--Decode
	}
}