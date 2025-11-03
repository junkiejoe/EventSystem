--!strict
--< Module begin >--
local ScriptableEvent = {}

---- Types ----

-- There are two types of events, deferred and immediate.
-- Immediate runs all events as soon as possible,
-- and attempts to reuse threads inorder to prevent unneeded thread creations.
-- Deferred will queue all the events to run at the next execution point.
-- Deferred will not try to reuse threads. The benefit of using deferred over
-- immediate is... honestly, I don't know but roblox has them so lets keep them anyways.
type EventMode =  "Immediate" | "Deferred"

export type EventListener<fn_sig = () -> ()> = {
	-- If nil, the event is no longer connected.
	parent: unknown?,
	StopListening: (self : EventListener<fn_sig>) -> (),
}

export type ScriptableEvent<fn_sig = () -> ()> = {
	---- Properties ----
	
	-- Event mode cannot be changed once instantiated.
	mode: EventMode,
	-- WARNING:
	-- The implementation of this property may change at any time.
	-- This property may be removed at any time.
	-- This property may go private at any time.
	listeners: {[EventListener]: fn_sig},

	---- Methods ---

	AddListener: (self: ScriptableEvent<fn_sig>, func: fn_sig) -> EventListener,
	Invoke: (self: ScriptableEvent<fn_sig>, ...any) -> (),
	-- Invoke without any mode processing. 
	-- Equivalent of enumerating through the listener list and firing them all.
	CleanInvoke: (self: ScriptableEvent<fn_sig>, ...any) -> (),
	RemoveListener: (self: ScriptableEvent<fn_sig>, listener: EventListener) -> (),
	RemoveAllListeners: (self: ScriptableEvent<fn_sig>) -> (),
	Destroy: (self: ScriptableEvent<fn_sig>) -> ()
}


	---- Const ----
local DeferredMethods
local ImmediateMethods
local ListenerMethods = {
	StopListening = function(self : EventListener)
		(self.parent :: ScriptableEvent):RemoveListener(self)
	end
}

---- Var ----

-- The free coroutine to reuse to prevent creating new
local FreeThread : thread?


---- Module functions ----

function ScriptableEvent.New<T>(mode : EventMode?) : ScriptableEvent<T>?
	if mode == "Immediate"
		or mode == nil
	then
		return (setmetatable({
			mode = "Immediate",
			listeners = {}
		}, DeferredMethods) :: unknown) :: ScriptableEvent<T>
	elseif mode == "Deferred" then
		-- Deferred event
		return (setmetatable({
			mode = mode,
			listeners = {}
		}, DeferredMethods) :: unknown) :: ScriptableEvent<T>
	else
		if type(mode) ~= "string" then
			warn "Parameter mode is not of type \"string\""
		else
			warn (`Unknown mode {mode}`)
		end
		return nil
	end
end--New

---- Implementation ----

--> Functions shared between both

local function AddListener(self : ScriptableEvent, func : any)
	local listener = (setmetatable({
		parent = self
	}, ListenerMethods) :: unknown) :: EventListener
	
	self.listeners[listener] = func
end

local function RemoveListener(self : ScriptableEvent, listener : EventListener)
	local func = self.listeners[listener]

	if func == nil then
		warn "Tried to remove non existing event listener"
		return
	else
		self.listeners[listener] = nil
		listener.parent = nil
	end
end

local function RemoveAllListeners(self : ScriptableEvent)
	for listener, _ in pairs(self.listeners) do
		self.listeners[listener] = nil
		(listener :: EventListener).parent  = nil
	end
end

local function CleanInvoke(self : ScriptableEvent, ...: any)
	for _, callback in pairs(self.listeners) do
		callback(...)
	end
end

--> Immediate mode functions

-- This function is needed to unpack the arguments.
-- It's either this function, or we unpack arguments via a table.
local function CallListenerCallback(callback, ...)
	FreeThread = nil
	callback(...)
	FreeThread = coroutine.running()
end
-- Call listener for immediate event thread
local function CallListener()
	-- We repeat this so the next time the function is called, it will yield again.
	while true do
		-- Get the procedure and it's arguments from the yield.
		-- coroutine.yield's return values are the arguments passed to coroutine.resume.
		CallListenerCallback(coroutine.yield())
	end	
end

-- Method tables --

ImmediateMethods = {
	AddListener = AddListener,
	RemoveListener = RemoveListener,
	RemoveAllListeners = RemoveAllListeners,
	Invoke = function(self: ScriptableEvent, ...: any)
		for _, callback in pairs(self.listeners) do
			if FreeThread == nil then
				FreeThread = task.spawn(CallListener)
			end
			coroutine.resume(FreeThread :: thread, callback, ...)
		end
	end,--Invoke
	CleanInvoke = CleanInvoke
} ImmediateMethods.__index = ImmediateMethods;

DeferredMethods = {
	AddListener = AddListener,
	RemoveListener = RemoveListener,
	RemoveAllListeners = RemoveAllListeners,
	Invoke = function(self : ScriptableEvent, ...: any)
		-- IDK man I guess this is better according to Roblox?
		for _, callback in pairs(self.listeners) do
			task.defer(callback, ...)
		end
	end,--Invoke
	CleanInvoke = CleanInvoke
} DeferredMethods.__index = DeferredMethods;

return ScriptableEvent
