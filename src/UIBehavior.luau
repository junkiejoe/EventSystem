--!strict
--< Dependencies >--
local Typeforge = require "Packages/Typeforge"
local EvenSystem = require "EventSystem"
--< Module begin >--
local UIBehavior = {}

-- Types
type BehaviorNames =
	"UIBehavior" |
	"UIToggle"   |
	"UISlider"

type UIBehavior = {
	---- Properties ----
	
	-- The name of the UIBehavior subclass, or UIBehavior if none.
	read behaviorName : BehaviorNames,
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
	read guiObject : GuiObject,
	-- Fires when a UICursor object
	read StateChanged : EventSystem.Event<(context : EventSystem.UICallbackContext) -> ()>,

	---- Methods ----

	-- 
	SetState : (state : EventSystem.UIState, context :) -> ()
}

export type UIToggleBehavior = {
	Toggled : EventSystem.Event<(context : EventSystem.UICallbackContext, state : boolean) -> ()>,
} & UIBehavior

export type UISliderBehavior = {
	progressMin : number,
	progressMax : number,
	progressCurrent : number,
	-- The progressed normalized (from 0 to 1)
	progressNorm : number,
	ProgressChanged : EventSystem.Event<(context : EventSystem.UICallbackContext, progress : number) -> ()>,
	---- Methods ----
	SetProgress : (value : number) -> ()
} & UIBehavior
-- Private types --

-- Const
local BehaviorGetters : {[BehaviorNames] : (object : GuiObject) -> UIBehavior}
local StateHooks : {[EventSystem.]}
-- Var
local UIBehaviorList : {[GuiObject] : UIBehavior} = {}
-- Functions

local NewUIBehavior : (object : GuiObject) -> EventSystem.UIBehavior
local NewUIButton : () -> 

function UIBehavior.New(object: GuiObject, behaviorName : BehaviorNames)
	if object == nil then
		return
	end
end

function UIBehavior.GetBehaviorFromGuiObject(object : GuiObject) : UIBehavior?
	if typeof(object) ~= "GuiObject" then
		warn "object passed to UIBehavior.GetBehaviorFromGuiObject is not of subclass of GuiObject"
		return nil
	else
		return UIBehaviorList[object]
	end
end

function UIBehavior.GetUIBehaviors() : {[GuiObject] : UIBehavior}
	return 
end
---- Implementation ----
-- Constructors --
local function UIBase(object : UIBehavior)
	return {
		guiObject = object,
		navigationMode = "Automatic",
		state = "Idle",
		-- Events
		Selected = EventSystem.NewEvent(),
		Pressed = EventSystem.NewEvent(),
		Released = EventSystem.NewEvent()
	} :: UIBehavior
end

NewUIBehavior = function(object) : UIBehavior
	local new : UIBehavior = UIBase(object)
	new.behaviorName = "UIBehavior"
	return new
end

NewUIToggle = function(object) : UIToggleBehavior
	local new : UIToggle = UIBase(object) :: UIToggle

	new.behaviorName = "UIToggle"
	new.Toggled = EventSystem.New()

	return new
end

NewUISlider = function(object) : UISliderBehavior
	local new : UIToggle = UIBase(object) :: UIToggle
	
	new.behaviorName = "UIToggle"
	new.progressMin = 0
	new.progressMax = 1
	new.progressCurrent = 0
	
	new.ProgressChanged = EventSystem.New()

	
	return new
end

-- UIBehaviorX callbacks --
UIToggleCallback = function(behavior : UIToggleBehavior, context : EventSystem.UICallbackContext, )

	if behavior.state ~= "UIBehavior"
end

-- Misc

--> Behavior logic
BehaviorConstructors = {
	UIBehavior = NewUIBehavior,
	UIToggle = NewUIToggle,
	UISlider = NewUISlider
}

BehaviorStateCallbacks = {
	UIToggle = 
}
--< Module end >--
return UIBehavior
