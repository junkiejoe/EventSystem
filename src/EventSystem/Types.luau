--!strict
--[[
	MIT License

	Copyright (c) [year] [fullname]

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]--

--< Dependencies >--
local ScriptableEvent = require(script.Parent.ScriptableEvent)

------------------------
---- Input Action System
------------------------

export type InputBinding = Enum.KeyCode | Enum.UserInputType

export type CompositeDirection =
	"Up"      |
	"Down"    |
	"Left"    |
	"Right"   |
	"Foward"  |
	"Backward"

export type CompositeInputBinding = {
	[CompositeDirection]: InputBinding
}

-- Context passed to InputStateChangedCallback callback procedures.
-- It's the same as InputObject, but it is creatable by us.
export type InputActionCallBackContext = {
	-- When InputAction enabled is set to false, this will be set to
	-- Enum.KeyCode.Unknown
	key: Enum.KeyCode,
	-- When InputAction enabled is set to false, this will be set to
	-- Enum.UserInputType.None
	inputType: Enum.UserInputType,
	-- When InputAction enabled is set to false, this will be set to
	-- Enum.UserInputState.Cancel
	state: Enum.UserInputState,
	-- When InputAction enabled is set to false, this will be set to
	-- Vector3.zero if the last value type was a vector, or
	-- 0 if the if the last value type was a number
	value: number | Vector3,
	valueDelta: number | Vector3
}

export type InputStateChangedCallback = (inputObject: InputActionCallBackContext) -> ()

export type InputActionCreateInfo = {
	bindings: InputBinding | {InputBinding | CompositeInputBinding},
	-- Callbacks that will be added to the StateChanged event.
	callbacks: {InputStateChangedCallback}?
}

export type InputActionMapCreateInfo = {
	name: string,
	-- The gamepad to restrict gamepad input to.
	gamepad: Enum.UserInputType?,
	actions: {[string]: InputActionCreateInfo}
}

export type InputAction = {
	---- Properties ----
	
	read name: string,
	parent: InputActionMap,
	-- If enabled is false, bindings associated with this action will not update it's state.
	enabled: boolean,
	-- Whether or not the action's state has changed this frame.
	read changedThisFrame: boolean,
	read value: number | Vector3,
	read valueOld: number | Vector3,
	read valueDelta: number | Vector3,
	
	StateChanged: ScriptableEvent.ScriptableEvent<InputStateChangedCallback>,

	---- Methods ----

	NewBinding: (binding: InputBinding | CompositeInputBinding) -> boolean,
	RemoveBinding: (binding: InputBinding | CompositeInputBinding) -> ()
}

export type InputActionMap = {
	---- Properties ----
	
	read name: string,
	enabled: boolean,
	-- The gamepad to restrict gamepad input to.
	-- If nil, accepts input from any binding.
	gamepad: Enum.UserInputType?,
	
	---- Methods ----

	NewAction: (self:InputActionMap, name: string, createInfo: InputActionCreateInfo) -> InputAction?,
	RemoveAction: (self:InputActionMap, name: string) -> (),
	GetAction: (self:InputActionMap, name : string) -> InputAction?,
	Destroy: (self:InputActionMap) -> ()
}

------------------------
---- UIBehavior types
------------------------
export type BehaviorName =
	"UIBehavior" |
	"UISwitch"   |
	"UISlider"

export type UIState =
	"Idle"     |
	"Selected" |
	"Pressed"  |
	"Released"

export type UICallbackContext = {
	-- The state of the current UI
	read state: UIState,
	-- When fired via a handler, is the UICursor that triggered it.
	read cursor: UICursor?,
	-- Whether or not the cursor was in the frame when the event was processed.
	read inFrame: boolean,
	--clickType: 
}

export type UIBehavior = {
	---- Properties ----
	
	-- The name of the UIBehavior subclass, or UIBehavior if none.
	read behaviorName: BehaviorName,
	-- The Roblox GuiObject that the UIBehavior instance will operate on.
	--
	-- The UIBehavior will use the following properties from the guiObject:
	--  • The various selection properties, including:
	--     • Selectable
	--     • NextSelectionX
	--     • Selection
	--  • The Active property, when false, the behavior will not be evaluated.
	--  • The Visible property, when false, the behavior will not be evaluated.
	--  • The ZIndex property, which when navigating, will give it a priority boost.
	read guiObject: GuiObject,
	read currentState: UIState,

	-- Events --
	-- These events should not be called manually, and are meant to be set by the handler methods.
	
	-- Depending on the mode of the UICursor, the value that position represents will change.
	-- When mode is "Cursor", it represents the 
	read StateChanged: ScriptableEvent.ScriptableEvent<(context: UICallbackContext) -> ()>,
	read CursorPositionChanged: ScriptableEvent.ScriptableEvent<(cursor: UICursor, deltaTime: number?) -> ()>,

	---- Methods ----

	-- Collision methods --
	
	-- Returns true if point is in the behavior's collision box.
	QueryPoint: (self: UIBehavior, point: Vector2) -> boolean,
	-- Set the current state of the UI
	SetState: (self: UIBehavior, state: UIState, context: UICallbackContext) -> (),
	-- Destroy and internally dereference the object and it's properties.
	-- Destroying the UIBehavior will not destroy any of the GuiObjects it references.
	Destroy : (self: UIBehavior) -> (), 
	
	--< Defined by subclasses of UIBehavior >--
	-- Although these are overidable, unless you are creating a new UIBehavior who's logic
	-- doesn't fit any of the existing ones, you should avoid overwriting these.

	-- Handles any transition logic and fires the StateChanged event.
	StateTransitionHandler: (self: UIBehavior, context: UICallbackContext) -> (),
	-- Handles any movement within the object.
	-- The meaning of the position value depends on the cursor’s mode:
	-- • In Cursor mode, it represents the cursor's absolute position.
	-- • In Navigation mode, it represents cursor's movement direction (normalized).
	-- | In navigation mode, the handler will be called every frame
	-- | deltaTime will not be passed unless the cursor's mode is in navigation. This can be used as a means to detect the cursor's mode.
	CursorPositionHandler: (self: UIBehavior, cursor: UICursor, deltaTime: number?) -> ()
}

export type UISwitchBehavior = {
	-- The current state of the switch.
	-- To change the switch state, use the method TurnSwitchOnOrOff.
	read isOn: boolean,
	Flipped: ScriptableEvent.ScriptableEvent<(isOn: boolean) -> ()>,
	-- Set the switch to be on or off.
	-- If state is nil, it will flip the switch from it's current state.
	TurnSwitchOnOrOff: (self: UISwitchBehavior, state: boolean?) -> ()
} & UIBehavior

-- This class is not creatable outside of UISliderBehavior.SetHandleFromObject
-- All input sent to the handle is then provided to the parent UISliderBehavior.
export type UISliderHandle = {
	parent: UISliderBehavior
} & UIBehavior

export type UISliderBehavior = {
	-- The GuiObject to use as a fill frame.
	fillObject: GuiObject?,
	-- The handle to use as a visual indicator for the slider.
	-- This property cannot be set directly, and UISliderHandle cannot be constructed
	-- outside the UISliderBehavior class
	read handleObject: UISliderHandle?,
	-- The axis the slider is aligned to.
	-- Only input from the axis is relevant.
	sliderAxis: Enum.Axis,
	-- The time it takes for the slider to go from the starting point to the end point.
	-- This property is used when recieving navigation input.
	sliderTime: number,
	
	progressMin: number,
	progressMax: number,
	read progressCurrent: number,
	-- The progressed normalized (from 0 to 1)
	read progressNorm: number,
	ProgressChanged: ScriptableEvent.ScriptableEvent<(progress: number) -> ()>,

	---- Methods ----

	SetProgress: (self: UISliderBehavior, value: number) -> (),
	-- Set the progress using a value from progressMin to progressMax.
	SetProgressAbsolute: (self: UISliderBehavior, value: number) -> (),
	SetHandleFromObject: (self: UISliderBehavior, object: GuiObject) -> UISliderHandle?,
	-- Remove the handleObject
	RemoveHandle: (self: UISliderBehavior) -> ()
} & UIBehavior

export type SharedButton = {

}
------------------------
---- UICursor types
------------------------
export type UICursorMode = "Cursor" | "Navigation" | "Disabled"

export type UICursor = {
	---- Properties ----
	-- The current mode of the cursor.
	-- [Cursor mode]
	-- Display a cursor which navigates with free movement.
	-- [Navigation mode]
	-- The cursor will navigate depending on the currently selected UIBehavior's navigation mode.
	-- [Disabled mode]
	-- The cursor will not be evaluated.
	mode: "Cursor" | "Navigation" | "Disabled",
	-- If true, signifies that the cursor is the primary cursor to be used for the devices input detection.
	read isPrimary: boolean,
	-- The currently selected UIBehavior.
	-- Attempting to select a UIBehavior who's GuiObject.Selectable property is false will
	-- throw an error.
	selected: UIBehavior?,
	-- This property is only relevant when the cursor mode is Navigation.
	-- When true, the cursor will not be able to navigate to any nearby UIBehavior objects,
	-- and will call CursorPositionHandler with the cursor's movement direction.
	focused: boolean,
	-- The sensitivity modifier for the gamepad when
	-- the current mode is "Cursor".
	-- Default is true.
	gamepadSensitivity: number,
	-- The position of the cursor in pixels.
	-- When mode in navigation mode,
	-- this will evaluate to the center of the currently selected object.
	-- When there is no selection, it will be the last recorded position.
	read position: Vector2,
	read positionDelta: Vector2,
	-- The ImageLabel representing the UICursor's Icon.
	-- The used images are determined by the cursors state
	-- and the UICursor.cursorIcons image strings,
	read imageLabel: ImageLabel,
	-- The icons used by the cursor's ImageLabel.
	-- Each member should be a valid rbxasset.
	cursorIcons: {
		idleIcon: string,
		hoverIcon: string
	},
	-- The action map to recieve and handle UI input controls
	actionMap: InputActionMap,

	---- Methods ----
	SetSelection: (self: UICursor, behavior: UIBehavior) -> ()
	
}

return nil
