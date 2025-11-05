--< Module begin >--
local NetworkManager = {}

---- Dependecies ----

local ScriptableEvent = require(script.Parent.Parent.ScriptableEvent)
local DataTypes = require(script.Parent.DataTypes)

---- Types  ----

export type RecordCreateInfo = {
	{name: string, type: DataTypes.DataTypeNames}
}

export type PacketTypeCreateInfo = {
	name: string,
	-- The type of remote event instance to use for the packet.
	remoteType: "RemoteEvent" | "UnreliableRemoteEvent" | nil,
	-- The data type used by the packet.
	-- Passing a record create info implicitly creates the record type.
	-- If nil, the packet takes no data.
	dataType: DataTypes.DataTypeNames | RecordCreateInfo | nil,
}

export type PacketType = {
	---- Properties ----

	name: string,
	-- The ID used to reference the packet when called.
	-- The range of values an ID can be is (0, 255).
	ID: number,
	-- The size of the buffer used by the packetType.
	-- If the packet is an array, then the size represents of the value's data type.
	-- If the packet is a record, it represents the total size.
	packetSize: number,
	-- If the packet type is a record, describes the memory layout.
	layout: DataTypes.MemoryLayout?,
	-- The encoder used by the PacketType.
	codec: DataTypes.DataTypeCodec,
	-- Fires when the server calls PacketType:InvokeClient or PacketType:InvokeAllClients.  
	onClientInvoke: ScriptableEvent.ScriptableEvent<(data: any) -> ()>,
	-- Fires when the client calls PacketType:InvokeServer.
	onServerInvoke: ScriptableEvent.ScriptableEvent<(player: Player, data: any) -> ()>,
	---- Methods ----

	-- Encode and send data to the client.
	InvokeClient: (self: PacketType, client: Player, data: any) -> (),
	-- Encode and send data to the server.
	InvokeServer: (self: PacketType, data: any) -> (),
	InvokeAllClients: (self: PacketType, data: any) -> (),

	Destory: () -> ()
}

---- Const ----

local RunService = game:GetService("RunService")

local PacketCreationEvent = script.Parent.Events.PacketCreationEvent
local PacketReplicationEvent = script.Parent.Events.PacketReplicationEvent
local UnreliableReplicationEvent = script.Parent.Events.UnreliableReplicationEvent

local PacketTypeMethods = {}
-- Event that fires every time an error occurs.
NetworkManager.PacketError = ScriptableEvent.New() :: ScriptableEvent.ScriptableEvent<(result: number, id: number?) -> ()>
NetworkManager.ErrorCodes = {
	-- The PacketType with the ID given does not exist.
	UnknownPacketTypeID = -1,
	-- The size of the buffer does not match the type.
	SizeMismatch = -2,
	-- The argument type or count is incorrect.
	InvalidRemoteArg = -3,
}

---- Var ----

-- Tables for looking up packet types by from an ID.
local PacketTypeFromName = {} :: {[string]: PacketType}
local PacketTypeFromID = table.create(256) :: {[number]: PacketType}
local UnreliablePacketTypeFromName = {} :: {[string]: PacketType}
local UnreliablePacketTypeFromID = table.create(256) :: {[number]: PacketType}
-- Tables for looking up data types by from an ID
local DataTypeFromID = DataTypes.FromID
local DataTypeFromName = DataTypes.FromName
--> Record types
local RecordTypeFromID = {} :: {[string]: DataTypes.RecordMemoryLayout}
---- Module functions ----

@checked
function NetworkManager.NewRecordType(info: RecordCreateInfo): DataTypes.RecordMemoryLayout?
	local memory_layout = {}
	for index, field in pairs(info) do

		if type(field) ~= "table" then
			return nil
		end

		if field.name == nil then
			warn "Failed to create PacketType. Missing field \"dataType.layout.name\"."
			return nil
		end

		if field.type == nil then
			warn "Failed to create PacketType. Missing field \"dataType.layout.value\"."
			return nil
		end
		
		memory_layout[index] = {
			-- Key name
			k = field.name,
			-- Data type
			v = DataTypes[field.type]
		}
	end--loop
	return memory_layout
end--NewRecordType
	
-- [Server] Create a new packet type on the server and replicate it to the client.
@checked @native
function NetworkManager.NewPacketType(info: PacketTypeCreateInfo): PacketType?

	if info.name == nil then
		warn "Failed to create PacketType. Missing field \"name\""
		return nil
	end

	if PacketTypeFromName[info.name] then
		warn(`Failed to create PacketType. PacketType with name \"{info.name}\" already exists.`)
		return nil
	end
	
	-- Find an available packet ID.
	local id = 0
	while true do
		
		if id > 255 then
			warn "Cannot create new packet type. Hit packet type limit of 255."
			return nil
		end

		-- Enumerate
		if PacketTypeFromID[id] then
			id += 1
			continue
		end

		break -- Packet found
	end

	local data_type = info.dataType
	local data_type_properties: DataTypes.DataTypeProperties
	local type_of_data_type_field = type(info.dataType)

	if type_of_data_type_field == "string" then
		-- Get properties from type name.
		data_type_properties = DataTypeFromName[data_type ::``]

		if data_type_properties == nil then
			-- Possible struct name?
		end
	elseif type_of_data_type_field == "table" then
		
		
		if structure_type == nil then
			warn "Failed to create PacketType. Missing field \"dataType.structureType\"."
			return nil
		end

		data_type_properties = DataTypes[structure_type]	
		
		if structure_type == "Record" then
			-- Create the memory layout
			
		elseif structure_type == "Array" then
			
		end--if
		
		
	else
		warn(`Invalid value of type \"{type_of_data_type_field}\" given to field \"dataType\" where string or table was expected`)
	end--if

	-- Create the PacketType object.
	local packet_type = (setmetatable({
		name = info.name,
		ID = id,
		packetSize = data_type_properties.size,
		layout = memory_layout,
		codec = data_type_properties.codec,
		onClientInvoke = ScriptableEvent.New(),
		onServerInvoke = ScriptableEvent.New(),
	}, PacketTypeMethods) :: unknown) :: PacketType

	PacketTypeFromID[id] = packet_type
	PacketTypeFromName[info.name] = packet_type
	
	return packet_type
end--NewPacketType

function NetworkManager.GetPacketType(id: string | number): PacketType?
	if type(id) == "string" then
		return PacketTypeFromName[id]
	else
		return PacketTypeFromID[id]
	end
end

-- [Client] Wait for the packet type to be defined by the server, then return it.
function NetworkManager.WaitForPacketType(id: string | number, timeOut: number?): PacketType?
	timeOut = timeOut or 60
	local end_time = time() + (timeOut :: number)
	
	if type(id) == "string" then
		while PacketTypeFromName[id] == nil do
			if time() < end_time then
				task.wait()
			else
				
				return nil		
			end
		end
		return PacketTypeFromName[id]
	else
		return PacketTypeFromID[id]
	end
end

---- Metamethods ----
PacketTypeMethods.__index = PacketTypeMethods

local ErrorEvent = NetworkManager.PacketError
local ErrorCodes = NetworkManager.ErrorCodes

-- Send the data to the player and fire the onClientInvoke event.
function PacketTypeMethods.InvokeClient(self: PacketType, client: Player, data: any)
	local data_size = self.packetSize

	if data_size < 0 then
		-- Dynamic type
	end
	
	local out = buffer.create(self.packetSize + 1)
	buffer.writeu8(out, 0, self.ID)
	-- Write the data to the buffer.
	self.codec.Encode(data, out, 1, self.layout)
	PacketReplicationEvent:FireClient(client, data)
end

---- RemoteEvent handlers ----

-- Decode the buffer obtained from the remote event.
local function DecodeData(data: buffer): (any?, PacketType?)

	local buffer_size = buffer.len(data)

	if buffer_size < 1 then
		warn "Size of buffer received is smaller than expected."
		ErrorEvent:Invoke(ErrorCodes.SizeMismatch)
		return nil
	end
	
	local id = buffer.readu8(data, 0)
	local packet_type = PacketTypeFromID[id]

	if packet_type == nil then
		warn "Unknown packet requested."
		ErrorEvent:Invoke(ErrorCodes.UnknownPacketTypeID)
		return nil, nil
	end

	local packet_size = packet_type.packetSize + 1

	if buffer_size ~= packet_size then
		warn "Received packet size does not match the PacketType's size."
		ErrorEvent:Invoke(ErrorCodes.SizeMismatch, id)
		return nil, nil
	end

	
	return 
end

-- Handler for when the server sends data to the client
local function ClientHandler(...: number | buffer)
	
	local args = table.pack(...)

	if #args ~= 1 then
		warn "Argument count provided to the replication event is does not equal to 1."
		ErrorEvent:Invoke(ErrorCodes.InvalidRemoteArg)
		return
	end

	local data = args[1]
	local typeof_data = type(data)

	if typeof_data == "number" then
		
		local packet_type = PacketTypeFromID[data :: number]
		
		if packet_type == nil then
			warn "Unknown packet requested."
		end
		
		packet_type.onClientInvoke:Invoke()

	elseif typeof_data == "buffer" then
		
		local decoded_data = DecodeData(data :: buffer)
		
		if decoded_data == nil then
			-- Decoding failed. DecodeData already reported the error.
			return
		end
	else
		
		warn "Argument provided to replication event is not a valid type (number or buffer)."
		ErrorEvent:Invoke(ErrorCodes.InvalidRemoteArg)		
	
	end
end

local function ServerHandler(...: number | buffer | Player)
	local args = table.pack(...)

	if #args ~= 2 then
		warn "Argument count provided to the replication event is not equal to 2."
		ErrorEvent:Invoke()
	end

	local player = args[1] :: Player
	local data = args[2]
	local typeof_data = type(data)

	if typeof_data == "number" then
		local packet_type = PacketTypeFromID[data :: number]
		packet_type.onServerInvoke:Invoke()
	elseif typeof_data == "buffer" then
		local decoded_data = DecodeData(data :: buffer)
		
	else
		warn "Argument provided to replication event is not a valid type (number or buffer)."
		ErrorEvent:Invoke(ErrorCodes.InvalidRemoteArg)
	end
end

if RunService:IsServer() then
	PacketReplicationEvent:OnServerEvent(ServerHandler)
	UnreliableReplicationEvent:OnServerEvent(ServerHandler)
elseif RunService:IsClient() then
	PacketReplicationEvent:OnClientEvent(ClientHandler)	
	UnreliableReplicationEvent:OnClientEvent(ClientHandler)
end




---- Misc ----


-- Load all built-in data types.
for _, type_module in script.Parent.DataTypes:GetChildren() do
	-- Stupid hack to remove type errors :/
	local _ = require(type_module) :: any
end

--< Module end >--
return NetworkManager
