--!strict
--< Dependencies >--
local Packages = game:GetService("ReplicatedStorage").Packages
local Typeforge = require(Packages.Typeforge)
local ScriptableEvent = require(script.Parent.ScriptableEvent)
local Types = require(script.Parent.Types)
local Shared = require(script.Parent.Shared)
--< Module begin >--
local UIBehavior = {}

---- Types ----
--> Alias
type UIBehavior = Types.UIBehavior
type BehaviorName = Types.BehaviorName
type UICursor = Types.UICursor

type PrivateUIBehavior = Typeforge.ReadWrite<UIBehavior>
type PrivateUISwitch = Typeforge.ReadWrite<Types.UISwitchBehavior>
type PrivateUISlider = Typeforge.ReadWrite<Types.UISliderBehavior>
-- Const
local BehaviorConstructors: {[BehaviorName] : (object : GuiObject) -> UIBehavior}

---- Var ----
local UIBehaviorObjects: {[GuiObject] : UIBehavior} = require(script.Parent.UIBehaviorObjects)

---- Functions ----

local NewUIBehavior: (object : GuiObject) -> UIBehavior
local NewUISwitch:   (object : GuiObject) -> UIBehavior
local NewUISlider:   (object : GuiObject) -> UIBehavior

---- Module functions ----

function UIBehavior.New(object: GuiObject, behaviorName : BehaviorName?): 
	UIBehavior | Types.UISwitchBehavior | Types.UISliderBehavior | nil
-- begin
	if not object then
		warn "Invalid or nil GuiObject"
		return nil
	end
	
	if behaviorName == nil then
		behaviorName = "UISwitch"
	end

	local constructor = BehaviorConstructors[behaviorName :: BehaviorName]
	if constructor == nil then
		warn(`Invalid behavior name \"{behaviorName}\"`)
		return nil
	end
	return constructor(object)
end--New

function UIBehavior.GetBehaviorFromGuiObject(object : GuiObject) : UIBehavior?
	if typeof(object) ~= "GuiObject" then
		warn "object passed to UIBehavior.GetBehaviorFromGuiObject is not a subclass of GuiObject"
		return nil
	else
		return UIBehaviorObjects[object]
	end
end

---- Implementation ----

-- Constructors --
local function UIBase(object: GuiObject)
	return {
		guiObject = object,
		navigationMode = "Automatic",
		state = "Idle",
		-- Events
		Selected = ScriptableEvent.New "Immediate",
		Pressed  =  ScriptableEvent.New "Immediate",
		Released = ScriptableEvent.New "Immediate"
	} :: PrivateUIBehavior
end

NewUIBehavior = function(object) : UIBehavior
	local new: PrivateUIBehavior = UIBase(object)
	new.behaviorName = "UIBehavior"
	return new :: UIBehavior
end

NewUISwitch = function(object): Types.UISwitchBehavior
	local new = UIBase(object) :: PrivateUISwitch

	new.behaviorName = "UISwitch"
	new.Flipped = ScriptableEvent.New "Immediate" :: any
	return new
end

NewUISlider = function(object) : Types.UISliderBehavior
	local new = UIBase(object) :: PrivateUISlider
	
	new.behaviorName = "UISlider"
	new.progressMin  = 0
	new.progressMax  = 1
	new.progressCurrent = 0
	new.ProgressChanged = ScriptableEvent.New "Immediate" :: any
	
	return new
end

-- UIBehavior(...) methods --

-- Base methods

local function BaseCursorPositionHandler(self: UIBehavior, cursor: UICursor)
	self.CursorPositionChanged:Invoke(cursor)
end


local function BaseDestroy(self: PrivateUIBehavior)
	self.StateChanged:Destroy()
	self.CursorPositionChanged:Destroy()
	UIBehaviorObjects[self.guiObject] = nil
end

local UISwitchMethods = {

	TurnSwitchOnOrOff = function(self: PrivateUISwitch, cursor: UICursor?, isOn: boolean?)
		isOn = isOn or not self.isOn
		self.Flipped:Invoke(isOn)
	end,
	
	StateTransitionHandler = function(self: PrivateUISwitch, context: Types.UICallbackContext)
		local state = context.state

		if state == "Released" then
			self:TurnSwitchOnOrOff()
			self.StateChanged:Invoke(context)
		end	
	end,

	CursorPositionHandler = BaseCursorPositionHandler,

	Destroy = function(self: PrivateUISwitch)
		BaseDestroy(self)
		self.Flipped:Destroy()
	end
}


local UISliderMethods = {
	SetProgress = function(self: PrivateUISlider, progress: number)
		local min = self.progressMin
		local max = self.progressMax
		if (progress > 1 or progress < 0) then
			warn "Tried to set progress out of bounds"
			progress = math.clamp(progress, min, max)
		end
		
		local calculated_progress = min + ((max - min) * progress)
		local slider_axis = self.sliderAxis
		self.progressCurrent = calculated_progress
		self.progressNorm = progress
		self.ProgressChanged:Invoke(calculated_progress)

		-- Set the objects position
		local fill_object = self.fillObject
		local handle_object = self.handleObject and self.handleObject.guiObject or nil

		
		if slider_axis == Enum.Axis.X then
			if fill_object then
				fill_object.Size = UDim2.fromScale(progress, 1)
			end
			
			if handle_object then
				handle_object.Position = UDim2.fromScale(progress,0)
			end
		elseif slider_axis == Enum.Axis.Y then
			if fill_object then
				fill_object.Size = UDim2.fromScale(progress, 1)
			end
			
			if handle_object then
				handle_object.Position = UDim2.fromScale(progress,0)
			end
		end
	end,
	
	StateTransitionHandler = function(self: PrivateUISlider, context: Types.UICallbackContext)
		self.StateChanged:Invoke(context)
	end,

	CursorPositionHandler = function(self: PrivateUISlider, cursor: UICursor)
	
		if self.currentState ~= "Pressed" then
			BaseCursorPositionHandler(self, cursor)
		end

		local cursor_position = cursor.position
		local ui_object = self.guiObject
		local slider_axis = self.sliderAxis

		if cursor.mode == "Cursor" then
			-- Calculate the progress using the cursor's position
			local begin_point: number
			local end_point: number

			if slider_axis == Enum.Axis.X then
				begin_point = ui_object.AbsolutePosition.X
				end_point = begin_point + ui_object.AbsoluteSize.X
				
				self:SetProgress(math.clamp(cursor_position.X, begin_point, end_point)/end_point)
			else
				begin_point = ui_object.AbsolutePosition.Y
				end_point = begin_point + ui_object.AbsoluteSize.Y
				
				self:SetProgress(math.clamp(cursor_position.Y, begin_point, end_point)/end_point)
			end
		else
			
			if cursor.focused == false then
				cursor.focused = true
			end
			
			-- Calculate the progress using the cursor's direction
			-- and factor in the sliderTime variable.
			local slider_time = self.sliderTime
			local progress: number
						
			if slider_time < 0.1 then
				-- Make the slider instantly go from A to B.
				slider_time = 1
			end

			local slider_velocity = Shared.DeltaTime/slider_time

			local scale =
				self.sliderAxis == Enum.Axis.X
				and cursor_position.X
				or cursor_position.Y
						
			self:SetProgress(math.clamp(
				slider_velocity * scale,
				0,1
			))
		end
	end,

	Destroy = function(self: PrivateUISwitch)
		BaseDestroy(self)
		self.Flipped:Destroy()
	end
}

-- Misc

--> Behavior logic
BehaviorConstructors = {
	UIBehavior = NewUIBehavior,
	UISwitch = NewUISwitch,
	UISlider = NewUISlider
}

--< Module end >--
return UIBehavior
