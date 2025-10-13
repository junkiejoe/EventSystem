--< Dependencies >--
local Types = require(script.Parent.Parent.Types)
local Typeforge = require(game:GetService("ReplicatedStorage").Packages.Typeforge)
local InputActionSystem = require(script.Parent.Parent.InputActionSystem)
local InputMaps = require(script.Parent.InputMap)
local Shared = require(script.Parent.Parent.Shared)
--< Module begin >--
local UICursor = {}
---- Types ----
type UICursor = Types.UICursor
type PrivateUICursor = Typeforge.ReadWrite<UICursor>;
---- Const ----
local UIBehaviorObjects = Shared.UIBehaviorObjects
local Methods
local RunService = game:GetService "RunService"
-- Screen Gui to hold all the UICursor image labels
local CursorScreenGUI: ScreenGui

local NewPrimaryCursor: () -> PrivateUICursor
local NewSecondaryCursor: () -> PrivateUICursor

-- Use new roblox cursor icons
local DefaultCursorIcons = {
	idleIcon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png",
	hoverIcon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
}
---- Var ----
local UICursorObjects = {} :: {UICursor}
local PrimaryActionMap = InputMaps.PrimaryMap
local SecondaryActionMap = InputMaps.SecondaryMap
---- Functions ----
local SetUpEventsForCursor: (cursor: PrivateUICursor) -> ()
local SetUpPrimaryEventsForCursor: (cursor: PrivateUICursor) -> ()
--< Module functions
function UICursor.New(forGamepad: Enum.UserInputType?): UICursor?
	local cursor = {
		mode = "Disabled",
		isPrimary = true,
		selected = nil,
		focused = false,
		gamepadSensitivity = 1,
		position = Vector2.zero,
		positionDelta = Vector2.zero,
		imageLabel = Instance.new("ImageLabel"),
		cursorIcons = {
			idleIcon = DefaultCursorIcons.idleIcon,
			hoverIcon = DefaultCursorIcons.hoverIcon
		},
	} :: PrivateUICursor
	
	if UICursor.GetPrimaryCursor() then
		cursor.isPrimary = false
		cursor.actionMap = InputActionSystem.NewInputActionMap(PrimaryActionMap) :: Types.InputActionMap
	else
		cursor.isPrimary = true
		-- Restrict input to the provided gamepad
		SecondaryActionMap.gamepad = forGamepad
		cursor.actionMap = InputActionSystem.NewInputActionMap(SecondaryActionMap) :: Types.InputActionMap
	end
	-- Some error from creating the action map occured.
	if cursor.actionMap == nil then
		return nil
	end
	
	return (setmetatable(cursor, Methods) :: unknown) :: UICursor
end

function UICursor.GetPrimaryCursor(): UICursor?
	for _, cursor in UICursorObjects do
		if cursor.isPrimary then
			return cursor
		end
	end
	return nil
end
---- Implementation ----

SetUpEventsForCursor = function(cursor: PrivateUICursor)
	local action_map = cursor.actionMap
	-- Actions
	local confirm_action = action_map:GetAction "Confirm"
	local navigate_action =  action_map:GetAction "Navigate"
	assert(confirm_action and navigate_action)
	
	confirm_action.StateChanged:AddListener(function(context: Types.InputActionCallBackContext)
		local selected = cursor.selected

		if selected == nil then
			return
		end
		
		if context.state == Enum.UserInputState.Begin then
			selected:StateTransitionHandler {
				state = "Pressed",
				cursor = cursor,
				inFrame = true,
			}
		else
			selected:StateTransitionHandler {
				state = "Pressed",
				cursor = cursor,
				inFrame = 
					cursor.selected 
					and cursor.selected:QueryPoint(cursor.position)
					or false,
			}
		end
	end)
	navigate_action.StateChanged:AddListener(function(context)
	
	end)
	-- Find a new selection from a collision
	RunService.Heartbeat:Connect(function(dt: number)

		if cursor.mode ~= "Cursor" then
			return
		end
		
		local selected = cursor.selected

		-- Don't try to find a new selection until the UI is released
		if selected and selected.currentState == "Pressed" then
			return
		end

		local new_selection: Types.UIBehavior
		local new_zindex = 0
		local cursor_position = cursor.position

		for object, behavior in pairs(UIBehaviorObjects) do
			if behavior:QueryPoint(cursor_position)
				and object.ZIndex > new_zindex
			then
				new_selection = behavior
				new_zindex = object.ZIndex
			end
		end

		if new_selection then
			cursor:SetSelection(new_selection)
		end
	end)--function

	navigate_action.StateChanged:AddListener(function(context)
		
	end)
end

SetUpPrimaryEventsForCursor = function(cursor: PrivateUICursor)
	local action_map = cursor.actionMap
	-- Actions

end

Methods = {
	SelectUI = function(self: PrivateUICursor, object: Types.UIBehavior)

	end
}
--< Module end >--
return 
