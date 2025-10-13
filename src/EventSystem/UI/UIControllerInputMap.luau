local Types = require(script.Parent.Parent.Types)


local PrimaryMap: Types.InputActionMapCreateInfo = {
	name = "EventSystem UI Input",
	actions = {
		Confirm = {
			bindings = {
				Enum.UserInputType.MouseButton1,
				Enum.KeyCode.Return,
				Enum.KeyCode.ButtonA,
			}
		},
		Cancel = {
			bindings = {Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB}
		},
		MouseMovement = {
			bindings = Enum.UserInputType.MouseMovement
		},
		TouchInput = {
			bindings = Enum.UserInputType.Touch
		},
		-- For gamepad navigation
		Navigation = {
			bindings = {
				Enum.KeyCode.Thumbstick1,
				{
					Up = Enum.KeyCode.Up,
					Down = Enum.KeyCode.Down,
					Left = Enum.KeyCode.Left,
					Right = Enum.KeyCode.Right
				},
				{
					Up = Enum.KeyCode.DPadUp,
					Down = Enum.KeyCode.DPadDown,
					Left = Enum.KeyCode.DPadLeft,
					Right = Enum.KeyCode.DPadRight
				}
			}
		},
		-- Scroll to top/bottom of scrolling list
		ScrollToTop = {
			bindings = Enum.KeyCode.Home
		},
		ScrollToBottom = {
			bindings = Enum.KeyCode.End
		}
	}
}

local SecondaryMap: Types.InputActionMapCreateInfo = {
	name = "EventSystem UI Input",
	actions = {
		Confirm = {
			bindings = Enum.KeyCode.ButtonA,
		},
		Cancel = {bindings = Enum.KeyCode.ButtonB},
		-- For gamepad navigation
		Navigation = {
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
	}
}

return {
	PrimaryMap = PrimaryMapInfo,
	SecondaryMap = SecondaryMapInfo
}
