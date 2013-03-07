---
-- Stravantian Classes
-- A Class system by Stravant.
--
--@module SClass

---
-- Class System
-- The primary function for defining a class
-- @function [parent=#sclass] class

function class(classname)
	local classDef = {}
	
	--methods, maps method names to functions
	local mPublicMethods = {}
	local mAllMethods = {}

	--getters and setters map to either "true" for simply allowed members, or
	--a setter function for members with special implementation.
	local mGetters = {__ClassName = true}
	local mSetters = {}

	--table of events to automatically create
	local mEvents = {}

	--
	--if key is a string, return '.'..key, otherwise return '['..tostring(key)..']''
	--this is used for nice error formatting in handling of index/newindex
	local function fmtKey(key)
		if type(key) == 'string' then
			return '.'..key
		else
			return '['..tostring(key)..']'
		end
	end
	--
	return function(implementer)
		--only accept function implementers
		if type(implementer) ~= 'function' then
			error("Only functions ay be used as a class body definition, got a "..type(implementer), 2)
		end

		--the proxy-object returned by `def.set`
		local setProxy = setmetatable({}, {
			__index = function(tb, key)
				--return another proxy to handle the:
				--classdef.get.MemberName()
				--syntax for default get behavior
				return setmetatable({}, {
					__call = function(tb, ...)
						if #{...} > 0 then
							error('Passing arguments to classdef.set'..fmtKey(key)..'() has no meaning, \
							       see documentation for correct usage.', 2)
						end
						if mSetters[key] then
							error('Redefinition of setter for '..tostring(key), 2)
						end
						mSetters[key] = true
					end;
				})
			end;
			__newindex = function(tb, key, val)
				if type(key) == 'string' and type(val) == 'function' then
					if mSetters[key] then
						error('Redefinition of setter for '..tostring(key), 2)
					end
					mSetters[key] = val
				else
					error('Can\'t set classdef.set'..fmtKey(key)..' = '..tostring(val), 2)
				end
			end;
		})

		--the proxy object returned by `def.get`
		local getProxy = setmetatable({}, {
			__index = function(tb, key)
				--return another proxy to handle the:
				--classdef.set.MemberName()
				--syntax for default get behavior
				return setmetatable({}, {
					__call = function(tb, ...)
						if #{...} > 0 then
							error('Passing arguments to classdef.get'..fmtKey(key)..'() has no meaning, \
							       see documentation for correct usage.', 2)
						end
						if mGetters[key] then
							error('Redefinition of getter for '..tostring(key), 2)
						end
						mGetters[key] = true
					end;
				})
			end;
			__newindex = function(tb, key, val)
				if type(key) == 'string' and type(val) == 'function' then
					if mGetters[key] then
						error('Redefinition of getter for '..tostring(key), 2)
					end
					mGetters[key] = val
				else
					error('Can\'t set classdef.get'..fmtKey(key)..' = '..tostring(val), 2)
				end
			end;
		})

		--the proxy object returned by `def.getset`
		local getsetProxy = setmetatable({}, {
			__index = function(tb, key)
				--return another proxy to handle the:
				--classdef.getset.MemberName()
				--syntax for default get behavior
				return setmetatable({}, {
					__call = function(tb, ...)
						if #{...} > 0 then
							error('Passing arguments to classdef.getset'..fmtKey(key)..'() has no meaning, \
							       see documentation for correct usage.', 2)
						end
						if mSetters[key] then
							error('Redefinition of setter for '..tostring(key), 2)
						end
						if mGetters[key] then
							error('Redefinition of getter for '..tostring(key), 2)
						end
						mSetters[key] = true
						mGetters[key] = true
					end;
				})
			end;
			__newindex = function(tb, key, val)
				--assigning to getset is meaningless
				error('Can\'t set classdef.set'..fmtKey(key)..' = '..tostring(val), 2)
			end;
		})

		--the proxy object returned by `def.event`
		local eventProxy = setmetatable({}, {
			__index = function(tb, key)
				return setmetatable({}, {
					__call = function(tb, ...)
						if #{...} > 0 then
							error("Passing arguments to clasdef.event"..fmtKey(key).."() has no meaning, \
							       see documentation for correct usage.", 2)
						end
						if type(key) ~= 'string' then
							error("Can't create event `"..tostring(key).."` event names must be strings", 2)
						end
						if mEvents[key] then
							error("Redefinition of event `"..key.."`", 2)
						end
						mEvents[key] = true
						mGetters[key] = true
					end;
					__index = function()
						error("classdef.event"..fmtKey(key).." can only be called, not indexed", 2)
					end;
					__newindex = function()
						error("classdef.event"..fmtKey(key).." can only be called, not assigned to", 2)
					end;
				})
			end;
			__newindex = function(tb, key, val)
				error("Can't set classdef.event"..fmtKey(key).." = "..tostring(val), 2)
			end;
		})

		--the proxy object returned by `classdef.static`
		local staticProxy = setmetatable({}, {
			__index = classDef,
			__newindex = classDef,
		})

		--the private proxy, returned by `classdef.private`
		local privateProxy = setmetatable({}, {
			__newindex = function(tb, key, val)
				if type(key) == 'string' and type(val) == 'function' then
					mAllMethods[key] = val
				else
					error("Can't set classdef.private"..fmtKey(key).." = "..tostring(val), 2)
				end
			end;
			__index = function(tb, key)
				error("Can't get classdef.private"..fmtKey(key), 2)
			end;
		})

		--the main proxy, `def` itself
		local mainImplProxy = {}
		mainImplProxy.get = getProxy
		mainImplProxy.set = setProxy
		mainImplProxy.getset = getsetProxy
		mainImplProxy.event = eventProxy
		mainImplProxy.private = privateProxy
		mainImplProxy.static = staticProxy
		setmetatable(mainImplProxy, {
			__index = function(tb, key)
				--note, we do not have to check for and return the other keys such as get/set/getset here, since
				--the __index metamethod will only fire for missing keys, any keys such as get/set/getset will have
				--already been returned before this code is ever reached.
				error('Can\'t get classdef'..fmtKey(key), 2)
			end; 
			__newindex = function(tb, key, val)
				--it's a method's declaration
				if type(key) == 'string' and type(val) == 'function' then
					--note, the method still must be wrapped, but that will be done later
					--for clarity of the code.
					mPublicMethods[key] = val
					mAllMethods[key] = val
					mGetters[key] = true

				--error, did not succeed for any set
				else
					error('Can\'t set classdef'..fmtKey(key)..' = '..tostring(val), 2)
				end
			end;
		})

		--Main call of the constructor on the class body
		implementer(mainImplProxy)

		--now, replace the methods with wrappers to get the internal object
		for k, f in pairs(mAllMethods) do
			if k ~= 'Create' then
				mAllMethods[k] = function(self, ...)
					if type(self) ~= 'table' or self.__ClassName ~= classname then
						error("Methods must be called with a ':', not a '.'")
					end
					return f(rawget(self, '__internal'), ...)
				end
				if mPublicMethods[k] then
					mPublicMethods[k] = mAllMethods[k]
				end
			end
		end
		--also replace getters and setters
		for k, f in pairs(mGetters) do
			if type(f) == 'function' then
				mGetters[k] = function(self, ...)
					return f(rawget(self, '__internal'), ...)
				end
			end
		end
		for k, f in pairs(mSetters) do
			if type(f) == 'function' then
				mSetters[k] = function(self, ...)
					return f(rawget(self, '__internal'), ...)
				end
			end
		end

		--the metatable for the internal objects of instances
		local internalMT = {
			__index = mAllMethods;
		}

		local rawget = rawget 
		--the metatable for the external object if the instance
		local externalMT = {
			__index = function(obj, key)
				local method = mPublicMethods[key]
				if method then
					return method
				elseif mGetters[key] == true then
					return rawget(obj, '__internal')[key]
				elseif mGetters[key] then
					return mGetters[key](obj)
				else
					error("Can't get "..classname.."::"..key, 2)
				end
			end;
			__newindex = function(obj, key, val)
				if mSetters[key] == true then
					rawget(obj, '__internal')[key] = val
				elseif mSetters[key] then
					mSetters[key](obj, val)
				else
					error("Can't set "..classname.."::"..key, 2)
				end
			end;
		}

		--now, generate the constructor function
		local constructor = function(...)
			--first, make the internal instance state table
			local internalThis = {__ClassName = classname}
			
			--make the internal table still make method requests go to the methods table
			setmetatable(internalThis, internalMT)

			--and make the external table
			local externalThis = {__internal = internalThis}
			setmetatable(externalThis, externalMT)

			--and add signals to the internal object
			for eventName, _ in pairs(mEvents) do
				internalThis[eventName] = CreateSignal()
			end

			--call the user-constructor
			if mAllMethods.Create then
				mAllMethods.Create(internalThis, ...)
			end
 
			--and return the object
			return externalThis
		end

		--put the static class stuff into the global env:
		classDef.Create = constructor
		setmetatable(classDef, {__call = constructor})
		getfenv(0)[classname] = classDef
	end
end