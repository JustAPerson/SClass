local CurrentTest = ""
local CurrentSubTest = ""
local TestOver = false
local Failed = false
Spawn(function()
	wait(1)
	if not TestOver and not Failed then
		error("TEST "..CurrentTest.."::"..CurrentSubTest.."> STALLED", 0)
	end
end)
function Test(s)
	CurrentTest = s
end
function SubTest(s)
	CurrentSubTest = s
end
function Check(st)
	if not st then
		Failed = true
		error("TEST "..CurrentTest.."::"..CurrentSubTest.."> FAILED", 2)
	end
end
function Fail(f)
	local st, err = pcall(f)
	if st then
		error("TEST "..CurrentTest.."::"..CurrentSubTest.."> FAILED", 2)
	end
end
function Pass()
	print("TEST "..CurrentTest.."> Passed")
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

Test'class'

SubTest'BasicInstantiation' do
	class'Test1'(function(def) end)
	local obj = CreateTest1()
	Check(obj)
end

SubTest'Constructors' do
	local constructed = 0
	class'Test2'(function(def)
		function def:Create()
			constructed = constructed + 1
		end
	end)
	--
	local obj = CreateTest2()
	Check(constructed == 1)
end

SubTest'Methods' do
	local calls = 0
	class'Test3'(function(def)
		function def:Test()
			calls = calls + 1
		end
	end)
	--
	local obj = CreateTest3()
	obj:Test()
	Check(calls == 1)
end

SubTest'MethodArguments' do
	class'Test4'(function(def)
		function def:Test(a, b)
			Check((a == 'a') and (b == 42))
		end
	end)
	--
	local obj = CreateTest4()
	obj:Test('a', 42)
end

SubTest'StoringData' do
	class'Test5'(function(def)
		function def:Create()
			self.Member = 1337
		end
		function def:Test()
			Check(self.Member == 1337)
		end
	end)
	--
	local obj = CreateTest5()
	obj:Test()
end

SubTest'DefaultGetter' do
	class'Test6'(function(def)
		function def:Create()
			self.Member = 1337
		end
		def.get.Member()
	end)
	--
	local obj = CreateTest6()
	Check(obj.Member == 1337)
end

SubTest'DefaultSetter' do
	class'Test7'(function(def)
		function def:Test(n)
			Check(n and (self.Member == n))
		end
		def.set.Member()
	end)
	--
	local obj = CreateTest7()
	obj.Member = 1337
	obj:Test(1337)
end

SubTest'DefaultGetterSetter' do
	class'Test8'(function(def)
		def.getset.Member()
	end)
	--
	local obj = CreateTest8()
	obj.Member = 4
	Check(obj.Member == 4)
end

SubTest'UserDefinedGetter' do
	class'Test9'(function(def)
		function def.get:Member()
			return 1337
		end
	end)
	--
	local obj = CreateTest9()
	Check(obj.Member == 1337)
end

SubTest'UserDefinedSetter' do
	class'Test10'(function(def)
		function def.set:Member(val)
			self.Member = val*2
		end
		def.get.Member()
	end)
	--
	local obj = CreateTest10()
	obj.Member = 21
	Check(obj.Member == 42)
end

SubTest'PrivateMember' do
	class'Test11'(function(def)
		function def.private:PrivMethod(n)
			return 2*n
		end
		function def:Test()
			Check(self:PrivMethod(4) == 8)
		end
	end)
	--
	local obj = CreateTest11()
	obj:Test()
	Fail(function()
		obj:PrivMethod(5)
	end)
end

SubTest'StaticData' do
	class'Test12'(function(def)
		def.static.ClassName = 'Test12'
		function def:Method()
			Check(Test12.ClassName == 'Test12')
		end
	end)
	--
	local obj = CreateTest12()
	obj:Method()
	Check(Test12.ClassName == 'Test12')
	Fail(function()
		local a = obj.ClassName..""
	end)
end

SubTest'Events' do
	class'Test13'(function(def)
		def.event.ThingChanged()
		function def.set:Thing(val)
			self.Thing = val
			self.ThingChanged:fire(val)
		end
		def.get.Thing()
	end)
	--
	local obj = CreateTest13()
	local calls = 0
	obj.ThingChanged:connect(function(v)
		calls = calls + 1
		Check(v == obj.Thing)
	end)
	obj.Thing = 42
	wait()
	Check(calls == 1)
end

Pass()



------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
TestOver = true