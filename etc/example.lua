class'AnimationProvider'(function(def)
	------------------- constructor ---------------------
	function def:Create()
		self.Humanoid = nil
		self.AnimationNameSet = {}
		self.AnimSet = {}          --maps {anim name => animation track}
		self.AnimSet_UpToDate = false
		self.TrackSet = {}
		self.TrackSet_UpToDate = false
		self.DefaultFadeTime = 0.1
	end

	--------------------- public API --------------------
	function def:Play(animName, speed, fadeTime)
		local track = self.TrackSet[animName]
		if track then
			speed = speed or 1
			fadeTime = fadeTime or self.DefaultFadeTime
			track:Play(fadeTime, 1, speed)
		elseif not self.AnimationNameSet[animName] then
			error("Animation `"..animName.."` is not in my AnimationSet", 2)
		elseif not self.Humanoid then
			error("AnimationProvider has no humanoid", 2)
		else
			error("Unknown error: Animation could not be loaded", 2)
		end
	end
	function def:Stop(animName, speed, fadeTime)
		fadeTime = fadeTime or self.DefaultFadeTime
		local track = self.TrackSet[animName]
		if track then
			track:Stop(fadeTime)
		elseif not self.AnimationNameSet[animName] then
			error("Animation `"..animName.."` is not in my AnimationSet", 2)
		elseif not self.Humanoid then
			error("AnimationProvider has no humanoid", 2)
		else
			error("Unknown error: Animation could not be loaded", 2)
		end
	end
	function def:StopAll(fadeTime)
		fadeTime = fadeTime or self.DefaultFadeTime
		for _, track in pairs(self.TrackSet) do
			track:Stop()
		end
	end

	--property AnimationSet
	function def.set:AnimationSet(animSet)
		if type(animSet) ~= 'table' then

		end
		self.AnimationNameSet = animSet
		--invalidate and update
		self.AnimSet_UpToDate = false
		self.TrackSet_UpToDate = false
		self:RefreshAnimTrackInstances()
	end
	def.get.AnimationSet()

	--property humanoid
	function def.set:Humanoid(humanoid)
		self.Humanoid = humanoid
		--invalidate and update
		self.TrackSet_UpToDate = false
		self:RefreshAnimTrackInstances()
	end
	def.get.Humanoid()

	--property DefaultFadeTime
	def.getset.DefaultFadeTime()


	------------- private implementation --------------
	function def.private:RefreshAnimTrackInstances(refresh_type)
		if not self.AnimSet_UpToDate then
			--kill old RBX::Animation objects
			for name, anim in pairs(self.AnimSet) do
				anim:Destroy()
				self.AnimSet[name] = nil
			end
			--make new RBX::Animation objects
			for name, assetId in pairs(self.AnimationNameSet) do
				self.AnimSet[name] = Create'Animation'{
					Name = 'ANIM_'..name,
					AnimationId = assetId,
				}
			end
			self.AnimSet_UpToDate = true
		end

		if not self.TrackSet_UpToDate then
			--kill old tracks
			for name, track in pairs(self.TrackSet) do
				track:Destroy()
				self.TrackSet[name] = nil
			end
			--load new RBX::AnimationTrack objects from humanoid
			if self.Humanoid then
				for name, anim in pairs(self.AnimSet) do
					self.TrackSet[name] = self.Humanoid:LoadAnimation(anim)
				end
			end
			--set flags
			self.TrackSet_UpToDate = true
		end
	end
end)