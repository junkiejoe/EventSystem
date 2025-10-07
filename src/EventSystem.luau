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

--< Dependecies >--
local Typeforge = require "Packages/Typeforge"
------------------------
---- Types
------------------------

---- Input Action System ----
export type InputActionCreateInfo = {
	name : string,
	
}

export type InputActionMapCreateInfo = {
	name : string,
}
export type InputActionMap = {
	name : string,
	FindAction : (name : string) -> Action?
}

------------------------
---- UIBehavior types
------------------------
export type UIState =
	"Idle"     |
	"Selected" |
	"Pressed"  |
	"Released"

export type UIBehavior = {
	guiObject : GuiObject,
	navigationMode : string,
}

------------------------
---- UICursor types
------------------------


export type UICursor = {
	-- The current mode of the cursor.
	-- [Cursor mode]
	-- Display a cursor which navigates with free movement.
	-- [Navigation mode]
	-- The cursor will navigate depending on the currently selected UIBehavior's navigation mode.
	-- [Disabled mode]
	-- The cursor will not be evaluated.
	mode : string,
	-- The currently selected UIBehavior.
	-- When set, it will fire the UIBehavior.Selected event.
	-- Attempting to select a UIBehavior who's GuiObject.Select
	selected : UIBehavior?,
	-- The sensitivity modifier for the gamepad when
	-- the current mode is "Cursor".
	-- Default is true.
	gamepadSensitivity : number,
	-- [Default = true]
	visible : boolean,
	-- The position of the cursor in pixels.
	-- When mode in navigation mode,
	-- this will evaluate to the center of the currently selected object.
	-- When there is no selection, it will be the last recorded position.
	read position : Vector2,
	-- The ImageLabel representing the UICursor's Icon.
	-- 
	read imageLabel : ImageLabel,
	idleIcon : string,
	hoverIcon : string,
}
--< Module begin >--
local EventSystem = {}

return EventSystem
