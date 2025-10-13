--< Dependecies >--
local Types = require(script.Parent.Types)
local Typeforge = require (game:GetService("ReplicatedStorage").Packages.Typeforge)
local Shared = require(script.Parent.Shared)
--< Module begin >--
local UICursor = {}

---- Types ----
type PrivateUICursor = {
} & Typeforge.ReadWrite<Types.UICursor>

---- Const ----

local Player = game:GetService("Players").LocalPlayer :: Player	
local PlayerGUI = Player:WaitForChild("PlayerGuu")
local PreRenderEvent = game:GetService("RunService").PreRender
local UIBehaviorObjects = Shared.UIBehaviorObjects
-- Use new roblox cursor icons
local DefaultCursorIcons = {
	idleIcon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png",
	hoverIcon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
}
-- Map used by primary cursor
local PrimaryActionMapCreateInfo : Types.InputActionMapCreateInfo
-- Map used by secondary (gamepad only) cursors
local SecondaryActionMapCreateInfo : Types.InputActionMapCreateInfo

local Methods : {[string] : (self : PrivateUICursor, ...any) -> ()} = {}
--> Look up tables
local InputModeLUT : {[Enum.PreferredInput] : string} = {
	[Enum.PreferredInput.KeyboardAndMouse] = "Cursor",
	[Enum.PreferredInput.Touch] = "Cursor",
	[Enum.PreferredInput.Gamepad] = "Selection"
}
---- Var ----

local CursorScreenGUI : ScreenGui
local RealScreenSize : Vector2
local UICursorObjects : {PrivateUICursor} = {}



---- Functions ----

local SetUpPrimaryCursor : (cursor : PrivateUICursor) -> PrivateUICursor?
local SetUpSecondaryCursor : (cursor : PrivateUICursor) -> PrivateUICursor?

---- Module functions ----

function UICursor.New(forGamepad : Enum.UserInputType?) : Types.UICursor?
	-- Const
	-- Var
	local cursor : PrivateUICursor
	local cursor_meta : any
	local action_map : Types.InputActionMap
	-- Initial properties --
	
	--> Image label representing the 
	local cursor_image = Instance.new("ImageLabel")
	cursor_image.Parent = CursorScreenGUI
	cursor_image.Size = UDim2.fromOffset(48,48)

	cursor_meta = {
		__index = Methods,
		__newindex = function(self : PrivateUICursor, key : string, value : any)
			local setter = ComputedProperties[key]

			if not setter then
				error(`Attempt to set unknown property \"{key}\" on UICursor`)
				return
			end
			setter(cursor_meta, key, value)
		end,
		-- Default properties
		imageLabel = cursor_image,
		idleIcon = DefaultCursorIcons.Idle,
		hoverIcon = DefaultCursorIcons.Hover,
	}

	if UICursor.GetPrimaryCursor() then
		-- Create a primary cursor
		if forGamepad == nil then
			error "Missing argument \"forGamepad\" for UICursor constructor, which is required for a non-primary cursor."
			return nil
		end
		cursor = SetUpPrimaryCursor(cursor_meta :: PrivateUICursor)
	else
		-- Create a secondary cursor
		-- A secondary cursor is different from a primary one in the following ways:
		-- • It uses the secondary action map, which only supports gamepad input
		-- • It doesn't hide when hovering over CoreGui elements
		-- • It doesn't hide when the Roblox Menu is active
		cursor = SetUpPrimaryCursor(cursor_meta :: PrivateUICursor)
	end
	
	table.insert(UICursorObjects, cursor)
	return cursor :: Types.UICursor
end

function UICursor.GetPrimaryCursor(): Types.UICursor?
	for _, cursor in pairs(UICursorObjects) do
		if cursor.isPrimary then
			return cursor
		end
	end
	return nil
end

---- Implementation ----
-- Helper functions --

-- (Cursor mode) Set the cursor at position and check for interactable UI at point 
local SetCursorPosition : (cursor: PrivateUICursor, position: Vector2) -> ()
local ActivateBehavior : (cursor: PrivateUICursor, position: Vector2) -> ()
local PointIsInFrame : (point: Vector2, frame: GuiObject) -> boolean
local NavigateCursorFromSelection : (cursor: PrivateUICursor) -> ()

SetUpPrimaryCursor = function(cursor : PrivateUICursor) : PrivateUICursor
	local action_map  = cursor.actionMap
	-- Actions --
	local navigation_action = action_map:GetAction("Navigation") :: Types.InputAction
	local touch_action = action_map:GetAction("Touch input") :: Types.InputAction
	local confirm_action = action_map:GetAction("Confirm") :: Types.InputAction
	local cancel_action = action_map:GetAction("Cancel") :: Types.InputAction
	
	-- Action implementations --
	navigation_action.StateChanged:AddListener(function(input : InputObject)

		local state = input.UserInputState
		local input_type = input.UserInputType
		
		if cursor.mode == "Cursor" then
			local action_val = navigation_action.value :: Vector3
			local val = Vector2.new(action_val.X, action_val.Y)

			-- Check for cursor mode input
			if input_type == Enum.UserInputType.MouseMovement then
				SetCursorPosition(cursor, val)
			elseif input_type == action_map.gamepad then
				-- Add to position
				SetCursorPosition(
					cursor, 
					cursor.position + (val * cursor.gamepadSensitivity))
			end
		elseif cursor.mode == "Navigation" then
			if input_type ~= action_map.gamepad then
				NavigateCursorFromSelection(cursor)
			end
		end
	end)
	
	touch_action.InputChanged:AddListener(function(input : InputObject)
		local state = input.UserInputState
		
		if state == Enum.UserInputState.End then
			local selected = cursor.selected
			if selected then
				-- Check if mouse is in selected frame
				local context = {
					state = "Released",
					cursor = cursor,
					inFrame = PointIsInFrame(cursor.position, selected.guiObject)
				} :: Types.UICallbackContext
				
				selected:SetState("Released", context)
				return
			end
			
		elseif state == Enum.UserInputState.Change and cursor.mode == "Cursor" then
			local input_pos = input.Position
			local position = Vector2.new(input_pos.X, input_pos.Y)
			SetCursorPosition(cursor, position)
		end
	end)

	confirm_action.InputChanged:AddListener(function(input : InputObject)
		
	end)
	return cursor
end

local NavigateCursorManual = function(
	cursor : PrivateUICursor,
	direction : Vector2)
-- begin
	-- Var
	local new_selection : Types.UIBehavior
	local new_object : GuiObject 
	-- Const
	local object = (cursor.selected :: Types.UIBehavior).guiObject
	local x = direction.X
	local y = direction.Y
	local xabs = math.abs(direction.X)
	local yabs = math.abs(direction.Y)
	
	-- GuiObject direction names
	local direction :
		"NextSelectionUp"   |
		"NextSelectionDown" |
		"NextSelectionLeft" |
		"NextSelectionRight"
	-- Detect the primary axis of the direction input
	if xabs > yabs then
		-- Primary axis is X
		if x < 0 then
			new_object = object.NextSelectionLeft
		else
			new_object = object.NextSelectionRight
		end
	else
		-- Primary axis is Y
		if y > 0 then
			new_object = object.NextSelectionUp
		else
			new_object = object.NextSelectionDown
		end
	end
	
	if new_object == nil then 
		-- Selection not found
		return
	end

	--new_selection = Shared.UIBehaviorObjects[]

	if new_selection == nil then
		-- Object found, but has no UIBehavior
		return
	end
	ComputedProperties.selection(cursor, new_selection)
end

--[[
	Cursor navigation comes in two forms:
	Automatic, which uses an algorithm.
	Manual, which uses the NextSelection(...) property of the behavior's GuiObject

	Manual navigation uses a weight algorithm to determine the best selection choice.

	where:
	• S = selected gui
	• C = current gui
	• P = previous gui
	• W = weight
	• w = component of weight
	
	The following properties go into choosing the selection:
	• The dot product of the movement direction and C.position
	  w₁ = S.origin:Dot(C.position)
	• The magnitude relative to the screen's magnitude.
	  w₂ = ((S.origin - C.position).Magnitude)/ScreenSize.Magnitude
	• The current object having a higher ZIndex
	  w₃ = C.ZIndex > P.ZIndex and 0.115 or 0
]]--
NavigateCursorAutomatic = function(cursor : PrivateUICursor)
	--Prefix:
	-- o = output
	-- s = selected
	
	-- Const
	local selected = cursor.selected
	local s_gui = selected.guiObject
	local s_origin =
		(s_gui.AbsoluteSize * 0.5):Floor() + s_gui.AbsolutePosition
	local screen_magnitude = ScreenSize.Magnitude
	-- Var
	local o_behavior : EventSystem.UIBehavior
	local o_gui : GuiObject
	local o_weight : number = 0
	-- Lua = poo performance :^(
	for gui, behavior in pairs(Shared.UIBehaviorObjects) do
		if
			gui.Active == false
			or gui.Selectable == false
			or behavior == selected
		then
			continue
		end
		
		local pos = gui.AbsolutePosition

		local w1 = s_origin:Dot(pos)
		if w1 < 0 then
			--Gui is of detection range
			continue
		end
		
		local w2 =
			((s_origin - pos).Magnitude)
			/screen_magnitude
		local w3 = gui.ZIndex > o_gui.ZIndex and 0.115 or 0
		local weight = w1 + w2 + w3

		if weight > o_weight then
			o_behavior = behavior
			o_gui = gui
			o_weight = weight
		end
	end

	ComputedProperties.selection(cursor, o_behavior)
end

-- Implementation [Helper functions]
SetCursorPosition = function(cursor : PrivateUICursor, position : Vector2)
	position = Vector2.New(
		math.clamp(position.X, 0, RealScreenSize.X),
		math.clamp(position.Y, 0, RealScreenSize.Y)
	)
	
	cursor.imageLabel.Position = UDim2.fromOffset(position : Vector2)
end


-- You don't really have to care about this, it's basically the same thing.
SetUpSecondaryCursor = function(cursor : PrivateUICursor) : PrivateUICursor
	local action_map  = cursor.actionMap
	-- Actions --
	local navigation_action = action_map:GetAction("Navigation")
	local touch_action = action_map:GetAction("Touch input")
	local confirm_action = action_map:GetAction("Confirm")
	local cancel_action = action_map:GetAction("Cancel")

	navigation_action.InputChanged:Connect(function(input : InputObject)

		local state = input.UserInputState
		local input_type = input.UserInputType
		local key_code = input.KeyCode
		
		if cursor.mode == "Cursor" then
			if input_type == action_map.gamepadID then
				SetCursorPosition(
					cursor.Position + (action.value * cursor.gamepadSensitivity)
				)
			end
		elseif
			cursor.mode == "Navigation"
			and input_type ~= action_map.gamepadID
		then
			NavigateCursorFromSelection(cursor)
		end
	end)
end


---- Methods ----


-- Misc

--< Reorder cursors upon disconnecting a gamepad >--

--< Create ScreenGui object to hold all cursor icons >--
CursorScreenGUI = Instance.new "ScreenGui"
-- Properties
CursorScreenGUI.Parent = PlayerGUI

-- We don't want the cursor going byebye after we go into safe areas
CursorScreenGUI.ClipToDeviceSafeArea = false
CursorScreenGUI.IgnoreGuiInset = true
-- Obviously, we want this to render over everything
CursorScreenGUI.DisplayOrder = 64
-- Update the RealScreenSize variable
CursorScreenGUI:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
	RealScreenSize = CursorScreenGUI.AbsolutePosition
end)

--> Action maps create info
type ActionList = {Types.InputActionCreateInfo}
	
-- Primary action for the main controller, keyboard, and gamepad.
local PrimaryActions : ActionList = {
	-- Cursor navigation
	{
		name = "Navigate",
		bindings = {
			Enum.UserInputType.MouseMovement,
			Enum.KeyCode.Thumbstick1,
			{
				Up = Enum.KeyCode.DPadUp,
				Down = Enum.KeyCode.DPadDown,
				Left = Enum.KeyCode.DPadLeft,
				Right = Enum.KeyCode.DPadRight
			}
		}
	},
	-- Cancel / go back
	-- Because roblox uses the ESC key, we have to use something else.
	{
		name = "Cancel",
		bindings = {
			Enum.KeyCode.Backspace,
			Enum.KeyCode.ButtonB
		}
	},
	{
		name = "Confirm",
		bindings = {
			Enum.KeyCode.Return,
			Enum.KeyCode.ButtonA,
		}
	},
	-- Touch input will:
	-- (When touch released)
	-- • Activate GUI at tap position, if any.
	--  (When UICursor.mode == "Cursor")
	-- • Set the cursor to tap position
	{
		name = "Touch input",
		bindings = Enum.UserInputType.Touch
	}
}

-- Same thing minus keyboard and touch input.
local SecondaryActions : ActionList = {
	{
		name = "Navigate",
		bindings = {
			Enum.KeyCode.Thumbstick1,
			{
				Up = Enum.KeyCode.DPadUp,
				Down = Enum.KeyCode.DPadDown,
				Left = Enum.KeyCode.DPadLeft,
				Right = Enum.KeyCode.DPadRight
			}
		}
	},
	{
		name = "Cancel",
		bindings = {Enum.KeyCode.ButtonB}
	},
	{
		name = "Confirm",
		bindings = {Enum.KeyCode.ButtonA}
	}
}


PrimaryActionMapCreateInfo = {
	actions = PrimaryActions
}

SecondaryActionMapCreateInfo = InputActionSystem.new {
	actions = SecondaryActions
}
--< Module end >--
return UICursor
