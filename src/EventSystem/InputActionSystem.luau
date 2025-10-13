--!strict
--< Dependencies >--
local Types = require(script.Parent.Types)
local Typeforge = require(game:GetService("ReplicatedStorage").Packages.Typeforge)
local ScriptableEvent = require(script.Parent.ScriptableEvent)

--< Module begin >--
local InputActionSystem = {}
---- Types ----


type InputBindingDescription = {
	action: PrivateInputAction,
}

type CompositeInputBindingDescription = {
	action: PrivateInputAction,
	direction: Types.CompositeDirection,
	directionVector: Vector3, 
}

type BindingMap = {[Types.InputBinding]: InputBindingDescription | CompositeInputBindingDescription}

type PrivateInputAction = Typeforge.ReadWrite<Types.InputAction>

type PrivateInputActionMap = {
	actions: { [string] : PrivateInputAction},
	-- Look-up table to match input bindings with their associated properties
	bindings: BindingMap
} & Typeforge.ReadWrite<Types.InputActionMap>
---- Functions ----

--> Constructors
local NewInputAction: (map: PrivateInputActionMap, name: string, createInfo: Types.InputActionCreateInfo) -> PrivateInputAction?
-- Add a input binding to the InputActionMap affiliated with the InputAction.
local AddInputBindingDescription: (action: PrivateInputAction, binding: Types.InputBinding | Types.CompositeInputBinding) -> boolean

---- Const ----
local UIS = game:GetService("UserInputService")

local ActionMethods
local ActionMapMethods
--> Lookup tables
-- Determine if a Enum.UserInputType member is a gamepad
local IsAGamepadLUT = {
	[Enum.UserInputType.Gamepad1] = true,
	[Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true,
	[Enum.UserInputType.Gamepad4] = true,
	[Enum.UserInputType.Gamepad5] = true,
	[Enum.UserInputType.Gamepad6] = true,
	[Enum.UserInputType.Gamepad7] = true,
	[Enum.UserInputType.Gamepad8] = true,
}
-- Get a vector from a composite direction
local DirectionVectorLUT : {[Types.CompositeDirection] : Vector3} = {
	["Up"] = Vector3.new(0, 1, 0),
	["Down"] = Vector3.new(0, -1, 0),
	["Left"] = Vector3.new(-1, 0, 0),
	["Right"] = Vector3.new(1, 0, 0),
	["Foward"] = Vector3.new(0, 0, 1),
	["Backward"] = Vector3.new(0, 0, -1),
}
-- Whether or not the position value is relevant from a InputObject
local IsPositionRelevantLUT = {
	[Enum.KeyCode.Thumbstick1] = true,
	[Enum.KeyCode.Thumbstick2] = true,
	[Enum.UserInputType.Touch] = true,
	[Enum.UserInputType.MouseMovement] = true
}

---- Var ----
local InputActionMapObjects = {} :: { [string] : PrivateInputActionMap }

---- Module functions ----
function InputActionSystem.NewInputActionMap(createInfo: Types.InputActionMapCreateInfo): Types.InputActionMap?
	local map = (setmetatable({
		name = createInfo.name,
		enabled = true,
		-- Take input from all gamepads
		gamepad = createInfo.gamepad,
		actions = {},
		bindings = {}
	}:: PrivateInputActionMap,  ActionMapMethods) :: unknown) :: PrivateInputActionMap 
	
	local actions = map.actions
	
	for action_name, action_create_info in pairs(createInfo.actions) do
		local new_action = NewInputAction(map, action_name, action_create_info)
		
		if new_action == nil then
			return nil
		else
			actions[new_action.name] = new_action
		end
	end

	InputActionMapObjects[createInfo.name] = map
	return map :: Types.InputActionMap
end

function InputActionSystem.GetMap(name: string): Types.InputActionMap?
	return InputActionMapObjects[name]
end


function InputActionSystem.InputTypeIsGamepad(type: Enum.UserInputType): boolean
	return IsAGamepadLUT[type] or false
end

---- Implementation ----

-- Constructors --
AddInputBindingDescription = function(
	action: PrivateInputAction,
	binding: Types.InputBinding | Types.CompositeInputBinding): boolean
	-- begin
	local parent = action.parent:: PrivateInputActionMap
	local bindings = parent.bindings
	
	if type(binding) == "table" then
		for composite_direction, composite_binding in binding do
			local existing_binding = bindings[composite_binding]
			
			if existing_binding then
				warn(`Attempt to redifine binding {composite_binding.Name} in ActionMap {parent.name}`)
				return false
			end
			
			-- Create composite binding
			bindings[composite_binding] = {
				action = action,
				direction = composite_direction,
				directionVector = DirectionVectorLUT[composite_direction]
			}
		end--loop

	else

		local existing_binding = bindings[binding]
		
		if existing_binding then
			warn(`Attempt to redifine binding {binding.Name} in ActionMap {parent.name}`)
			return false
		end

		bindings[binding] = {action = action}
	end--if
	return true
end

NewInputAction = function(
	map: PrivateInputActionMap,
	actionName: string, 
	createInfo: Types.InputActionCreateInfo): PrivateInputAction?
-- begin
	if map.actions[actionName] then
		local actions = map.actions
		local new_name: string
		local name_dupe_count = 0
		-- Get a new name
		repeat
			name_dupe_count += 1
			new_name = actionName.. ` {name_dupe_count}`
		until actions[new_name] == nil
		warn(`Attempt to create an action with the same name "{actionName}" in InputActionMap {map.name}`)
	end
	
	local action = {
		parent = map,
		name = actionName,
		enabled = true,
		value = 0,
		valueOld = 0,
		valueDelta = 0,
		StateChanged = ScriptableEvent.New()
	} :: PrivateInputAction

	for _, binding in createInfo.bindings do
		local success = AddInputBindingDescription(action, binding)
		if success == false then
			return nil
		end
	end

	return setmetatable(action, ActionMethods)
end

-- Methods --
ActionMethods = {
	NewBinding = function(self: PrivateInputAction, binding: Types.InputBinding | Types.CompositeInputBinding)
		return AddInputBindingDescription(self, binding)
	end,

	RemoveBinding = function(self: PrivateInputAction, binding: Types.InputBinding)
		local bindings = (self.parent :: PrivateInputActionMap).bindings
		if bindings[binding] then
			bindings[binding] = nil
		end
	end,

	ChangeBinding = function(self: PrivateInputAction, oldBinding: Types.InputBinding, newBinding: Types.InputBinding)
		self:RemoveBinding(oldBinding)
		self:NewBinding(newBinding)
	end
}

ActionMapMethods = {
	NewAction = function(self: PrivateInputActionMap, name: string, createInfo: Types.InputActionCreateInfo): PrivateInputAction?
		local action = NewInputAction(self, name, createInfo)
		if action == nil then 
			return nil
		end
		self.actions[action.name] = action
		return action
	end,
	
	RemoveAction = function(self: PrivateInputActionMap, name: string)
		local action = self.actions[name]
		local bindings = self.bindings 

		if action == nil then
			return
		end

		for binding, binding_desc in pairs(bindings) do
			if binding_desc.action == action then
				bindings[binding] = nil
			end
		end
		-- Destroy events
		action.StateChanged:Destroy()

		self.actions[name] = nil
	end,
	
	GetAction = function(self: PrivateInputActionMap, name: string): PrivateInputAction?
		return self.actions[name]
	end,
	
	Destroy = function(self: PrivateInputActionMap)
		for name, action in pairs(self.actions) do
			self:RemoveAction(name)
		end
		
		InputActionMapObjects[self.name] = nil
	end
}

---- Input handler  ----


local function ProcessBinding(
	binding: Types.InputBinding,
	binding_desc: CompositeInputBindingDescription | InputBindingDescription,
	input: InputObject)
	-- begin
	local action = binding_desc.action
	local input_state = input.UserInputState
	
	if 
		action.enabled == false
		or action.firedThisFrame == true -- Avoid duplicate events per frame
	then
		return
	end
	
	--> Set action value
	if IsPositionRelevantLUT[binding] then
		-- It's a special input type (such as mouse), use the input object properties instead.
		action.valueOld = action.value
		action.value = input.Position
		action.valueDelta = input.Delta
	elseif (binding_desc :: CompositeInputBindingDescription).directionVector then
		-- Process the value as a directional value
		local direction = binding_desc.directionVector

		if typeof (action.value) ~= "Vector3" then
			-- The old value is not the same, so we need to set a default
			-- Set the values to the negated value to get a zero'd delta this frame.
			action.value =
				input_state == Enum.UserInputState.Begin
				and action.value or Vector3.zero
		else
			local new_value = 
				input_state == Enum.UserInputState.Begin 
				and (action.value + direction).Unit
				or input_state == Enum.UserInputState.End
				and -(action.value + direction).Unit
				or action.value
			action.valueOld = action.value
			action.value = new_value
		end
	else
		-- Process the value as a number representing truthy/falsy
		local new_value = 
			input_state == Enum.UserInputState.Begin 
			and 1
			or input_state == Enum.UserInputState.End
			and 0
			or action.value
		action.valueOld = action.value
		action.value = new_value
	end
	action.firedThisFrame = true
	action.StateChanged:Invoke(input)
end

local function ProcessActionMaps(input: InputObject, gameProcessedEvent: boolean)
	-- Const
	for _, map in pairs(InputActionMapObjects) do
		if map.enabled == false then
			continue
		end
		
		local bindings = map.bindings
		
		local key_code = input.KeyCode
		local input_type = input.UserInputType

		local kc_binding = bindings[input.KeyCode]
		local it_binding = bindings[input.UserInputType]
		
		if kc_binding then
			ProcessBinding(key_code, kc_binding, input)
		end

		if it_binding then
			ProcessBinding(input_type, it_binding, input)
		end	
	end
end

UIS.InputBegan:Connect(ProcessActionMaps)
UIS.InputEnded:Connect(ProcessActionMaps)
UIS.InputChanged:Connect(ProcessActionMaps)
game:GetService("RunService"):BindToRenderStep("InputDelta", 101, function(delta: number)  
	for _, map in InputActionMapObjects do
		if map.enabled == false then
			continue
		end
		for _, action in map.actions do
			if typeof(action.value) ~= typeof(action.valueOld) then
				-- Avoid mismatch type subtractions
				continue
			end
			action.valueDelta = action.value :: any - action.valueOld
			action.valueOld = action.value
		end
	end
end)

---- Misc ----

return InputActionSystem
