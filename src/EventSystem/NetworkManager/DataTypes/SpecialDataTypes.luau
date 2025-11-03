
-- Implements array and record data types.
local DataTypes = require(script.Parent.Parent.DataTypes)

DataTypes:AddDataType {
	name = "Array",
	ID = 1,
	size = 0,
	-- Technically thats what lua "arrays" are.
	typeName = "table",
	codec = {
		Encode = function(data: {any}, to: buffer, offset: number, layout: DataTypes.RecordMemoryLayout)
			local element_size = layout.t.size
			local codec = layout.t.codec
			
			for i, v in pairs(data) do
				-- Index into buffer
				local index = (i - 1) * element_size
				codec.Encode(data, to, index + offset)
			end
		end,
		
		Decode = function(data: buffer, offset: number, layout: DataTypes.RecordMemoryLayout): {any}?
			local element_size = layout.t.size
			local array_size = layout.t.s
			local buffer_size = buffer.len() - 1
			local codec = layout.t.codec
			
			local element_count, remainder = math.modf(buffer_size/element_size)

			if remainder ~= 0 then
				-- The buffer size is not a value of n * element_size.
				return nil
			end
			
			if array_size ~= 0 and element_count > array_size then
				-- Array is larger than expected.
				return nil
			end

			local out = {} :: {[number]: any}
			for i = 0, (element_count - 1) do

				local decoded_value = codec.Decode(data,i * element_size + offset)

				if decoded_value == nil then
					-- Unknown error
					return nil
				end

				table.insert(out, decoded_value)
			end
			return out
		end
	}
}


