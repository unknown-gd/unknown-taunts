local _G = _G
local string, tonumber, istable, isnumber, isvector, isangle, FindMetaTable, CreateConVar, CurTime, CLIENT, SERVER = _G.string, _G.tonumber, _G.istable, _G.isnumber, _G.isvector, _G.isangle, _G.FindMetaTable, _G.CreateConVar, _G.CurTime, _G.CLIENT, _G.SERVER
local sub, lower, find, match, Trim = string.sub, string.lower, string.find, string.match, string.Trim
local PLAYER, ENTITY = FindMetaTable("Player"), FindMetaTable("Entity")
local LookupBone, GetBonePosition, GetCollisionGroup = ENTITY.LookupBone, ENTITY.GetBonePosition, ENTITY.GetCollisionGroup
local Exists = file.Exists
local bor = bit.bor
if Exists("ulib/shared/hook.lua", "LUA") then
	include("ulib/shared/hook.lua")
end
local PRE_HOOK = _G.PRE_HOOK or _G.HOOK_MONITOR_HIGH
local addonName = "Unknown Taunts"
local lib = _G.uTaunt
if not istable(lib) then
	lib = {
		Name = addonName
	}
	uTaunt = lib
end
local webSounds = list.GetForEdit("uTaunt - WebSounds", false)
local coopDances = list.GetForEdit("uTaunt - Coop", false)
timer.Simple(0.5, function()
	for sequenceName, value in pairs(coopDances) do
		if not isnumber(value) or value < 1 then
			goto _continue_0
		end
		local name, danceID = match(sequenceName, "^([%a_]+_?)(%d+)$")
		if name == nil or danceID == nil then
			goto _continue_0
		end
		danceID = tonumber(danceID)
		if danceID == nil then
			goto _continue_0
		end
		for index = 1, value do
			coopDances[name .. (danceID + index)] = 0
		end
		::_continue_0::
	end
end)
local IsValid, GetNW2Var, SetNW2Var, LookupSequence, SequenceDuration, GetSequenceList, IsDormant = ENTITY.IsValid, ENTITY.GetNW2Var, ENTITY.SetNW2Var, ENTITY.LookupSequence, ENTITY.SequenceDuration, ENTITY.GetSequenceList, ENTITY.IsDormant
local ACT_GMOD_TAUNT_DANCE, GESTURE_SLOT_CUSTOM = _G.ACT_GMOD_TAUNT_DANCE, _G.GESTURE_SLOT_CUSTOM
local Alive, Crouching = PLAYER.Alive, PLAYER.Crouching
local Add, Run = hook.Add, hook.Run
local isPlayingCTaunt = PLAYER.IsPlayingCTaunt
if not isPlayingCTaunt then
	isPlayingCTaunt = PLAYER.IsPlayingTaunt
	PLAYER.IsPlayingCTaunt = isPlayingCTaunt
end
lib.GetSequenceName = function(ply)
	return GetNW2Var(ply, "uTaunt-Name", "")
end
local getRenderAngles
do
	local EyeAngles = ENTITY.EyeAngles
	getRenderAngles = function(ply)
		local angles = EyeAngles(ply)
		angles[1], angles[3] = 0, 0
		return GetNW2Var(ply, "uTaunt-Angles", angles)
	end
	lib.GetRenderAngles = getRenderAngles
end
local isPlayingTaunt
isPlayingTaunt = function(ply)
	return GetNW2Var(ply, "uTaunt-Name") ~= nil
end
lib.IsPlayingTaunt = isPlayingTaunt
local getStartTime
getStartTime = function(ply)
	return GetNW2Var(ply, "uTaunt-Start") or CurTime()
end
lib.GetStartTime = getStartTime
lib.GetWebSound = function(sequenceName)
	return webSounds[sequenceName]
end
lib.HasWebSound = function(sequenceName)
	return webSounds[sequenceName] ~= nil
end
local findSound
do
	local GetTable = sound.GetTable
	local sounds = list.GetForEdit("uTaunt - Sounds", false)
	local supportedExtensions = {
		"mp3",
		"wav",
		"ogg"
	}
	local soundExists
	soundExists = function(sequenceName)
		if Exists("sound/unknown-taunts/" .. sequenceName, "GAME") then
			return true
		end
		return false
	end
	lib.SoundExists = soundExists
	findSound = function(sequenceName)
		if sounds[sequenceName] then
			return sounds[sequenceName]
		end
		for _index_0 = 1, #supportedExtensions do
			local extension = supportedExtensions[_index_0]
			if soundExists(sequenceName .. "." .. extension) then
				return "unknown-taunts/" .. sequenceName .. "." .. extension
			end
		end
		sequenceName = "uTaunt." .. sequenceName
		local _list_0 = GetTable()
		for _index_0 = 1, #_list_0 do
			local soundName = _list_0[_index_0]
			if soundName == sequenceName then
				return soundName
			end
		end
	end
	lib.FindSound = findSound
end
do
	local _tmp_0
	_tmp_0 = function(ply)
		return ply.m_bIsPlayingTaunt
	end
	PLAYER.IsPlayingTaunt = _tmp_0
	lib.IsPlayingAnyTaunt = _tmp_0
end
local getCycle
do
	local Clamp = math.Clamp
	getCycle = function(ply, sequenceID, startTime)
		return Clamp((CurTime() - (startTime or getStartTime(ply))) / SequenceDuration(ply, sequenceID), 0, 1)
	end
	lib.GetCycle = getCycle
end
do
	local length, id, duration = 0, 0, 0
	lib.FindSequences = function(entity, pattern)
		local sequences
		sequences, length = { }, 0
		local _list_0 = GetSequenceList(entity)
		for _index_0 = 1, #_list_0 do
			local name = _list_0[_index_0]
			if find(name, pattern, 1, false) == nil then
				goto _continue_0
			end
			id = LookupSequence(entity, name)
			if id < 1 then
				goto _continue_0
			end
			duration = SequenceDuration(entity, id)
			if duration <= 0 then
				goto _continue_0
			end
			length = length + 1
			sequences[length] = {
				id = id,
				name = name,
				duration = duration
			}
			::_continue_0::
		end
		return sequences, length
	end
end
local isValidTauntingPlayer
isValidTauntingPlayer = function(ply)
	return ply and IsValid(ply) and Alive(ply) and isPlayingTaunt(ply)
end
lib.IsValidTauntingPlayer = isValidTauntingPlayer
local GetInt, GetFloat, GetBool
do
	local _obj_0 = FindMetaTable("ConVar")
	GetInt, GetFloat, GetBool = _obj_0.GetInt, _obj_0.GetFloat, _obj_0.GetBool
end
local sv_utaunt_allow_weapons, sv_utaunt_allow_movement, sv_utaunt_allow_attack, sv_utaunt_audio_volume, sv_utaunt_camera_distance_min, sv_utaunt_camera_distance_max
do
	local flags = bor(FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY)
	sv_utaunt_allow_weapons = CreateConVar("sv_utaunt_allow_weapons", "0", flags, "Allow players to hold weapons in their hands while taunting.", 0, 1)
	sv_utaunt_allow_movement = CreateConVar("sv_utaunt_allow_movement", "0", flags, "Allow players to move while taunting.", 0, 1)
	sv_utaunt_allow_attack = CreateConVar("sv_utaunt_allow_attack", "0", flags, "Allow players to attack while taunting.", 0, 1)
	sv_utaunt_audio_volume = CreateConVar("sv_utaunt_audio_volume", "1", flags, "Volume of taunts audio.", 0, 10)
	sv_utaunt_camera_distance_min = CreateConVar("sv_utaunt_camera_distance_min", "16", flags, "Minimum distance of taunt camera.", 0, 2 ^ 12)
	sv_utaunt_camera_distance_max = CreateConVar("sv_utaunt_camera_distance_max", "1024", flags, "Maximum distance of taunt camera.", 0, 2 ^ 12)
	local sv_utaunt_audio_override = CreateConVar("sv_utaunt_audio_override", "", flags, "Overrides the audio of all taunts to the specified one. Leave it blank so it won't be used.")
	Add("UnknownTauntSound", addonName .. "::SoundOverride", function()
		local value = sv_utaunt_audio_override:GetString()
		if #value == 0 then
			return
		end
		if value == "0" then
			return false
		end
		return value
	end)
end
if SERVER then
	resource.AddWorkshop("3161527342")
	local GetInfo = PLAYER.GetInfo
	lib.SetSequenceName = function(ply, sequenceName)
		return SetNW2Var(ply, "uTaunt-Name", sequenceName)
	end
	lib.SetRenderAngles = function(ply, angles)
		return SetNW2Var(ply, "uTaunt-Angles", angles)
	end
	lib.SetCycle = function(ply, cycle, sequenceID)
		if not isnumber(cycle) then
			cycle = 0
		end
		if not isnumber(sequenceID) then
			local sequenceName = GetNW2Var(ply, "uTaunt-Name")
			if sequenceName == nil then
				return false
			end
			sequenceID = LookupSequence(ply, sequenceName)
		end
		if sequenceID < 1 then
			return false
		end
		SetNW2Var(ply, "uTaunt-Start", CurTime() - (cycle * SequenceDuration(ply, sequenceID)))
		return true
	end
	lib.IsAudioEnabled = function(ply)
		return GetInfo(ply, "cl_utaunt_audio") == "1"
	end
	lib.IsCoopEnabled = function(ply)
		return GetInfo(ply, "cl_utaunt_coop") == "1"
	end
	lib.IsLoopingEnabled = function(ply)
		return GetInfo(ply, "cl_utaunt_loop") == "1"
	end
	local sv_utaunt_menu_key, sv_utaunt_real_origin, sv_utaunt_coop_distance, sv_utaunt_collisions = nil, nil, nil, nil
	do
		local flags = bor(FCVAR_ARCHIVE, FCVAR_NOTIFY)
		sv_utaunt_menu_key = CreateConVar("sv_utaunt_menu_key", KEY_I, flags, "Default key to open menu of unknown taunts, uses keys from https://wiki.facepunch.com/gmod/Enums/KEY", 0, 512)
		sv_utaunt_real_origin = CreateConVar("sv_utaunt_real_origin", "0", flags, "Uses the player's real position instead of initial position at the end of taunt.", 0, 1)
		sv_utaunt_coop_distance = CreateConVar("sv_utaunt_coop_distance", "512", flags, "Minimum required distance to join in a co-op taunt.", 0, 16384)
		sv_utaunt_collisions = CreateConVar("sv_utaunt_collisions", "0", flags, "Allow players to collide with each other while taunting.", 0, 1)
	end
	local GetModel, SetCollisionGroup = ENTITY.GetModel, ENTITY.SetCollisionGroup
	Add("PlayerInitialSpawn", addonName .. "::CoopData", function(ply)
		ply.m_tUnknownTauntPlayers = { }
	end, PRE_HOOK)
	do
		local sequenceName, sequenceID, curTime, finishTime, timeRemaining = "", 0, 0, 0, 0
		local isbool = isbool
		lib.Finish = function(ply, force)
			sequenceName = GetNW2Var(ply, "uTaunt-Name")
			if sequenceName == nil then
				return false
			end
			curTime, timeRemaining = CurTime(), 0
			finishTime = curTime
			sequenceID = LookupSequence(ply, sequenceName)
			if sequenceID > 0 then
				finishTime = getStartTime(ply) + SequenceDuration(ply, sequenceID)
				timeRemaining = finishTime - curTime
				if timeRemaining < 0 then
					timeRemaining = 0
				end
			end
			if not force and Run("PlayerShouldFinishTaunt", ply, sequenceName, finishTime < curTime, timeRemaining, sequenceID, finishTime) == false then
				return false
			end
			local origin = ply.m_vUnknownTauntOrigin
			if GetBool(sv_utaunt_real_origin) then
				local leftFoot, rightFoot = LookupBone(ply, "ValveBiped.Bip01_L_Foot"), LookupBone(ply, "ValveBiped.Bip01_R_Foot")
				if leftFoot > 0 and rightFoot > 0 then
					origin = (GetBonePosition(ply, leftFoot) + GetBonePosition(ply, rightFoot)) / 2
				else
					origin = GetBonePosition(ply, 0)
				end
			end
			if isvector(origin) then
				ply:SetPos(origin)
			end
			ply.m_vUnknownTauntOrigin = nil
			ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
			SetNW2Var(ply, "uTaunt-Name", nil)
			ply:CrosshairEnable()
			local angles = GetNW2Var(ply, "uTaunt-Angles")
			if isangle(angles) then
				angles[1], angles[3] = 0, 0
				ply:SetEyeAngles(angles)
			end
			SetNW2Var(ply, "uTaunt-Angles", nil)
			local players = ply.m_tUnknownTauntPlayers
			for index = 1, #players do
				local otherPlayer = players[index]
				players[index] = nil
				if isValidTauntingPlayer(otherPlayer) then
					lib.Finish(otherPlayer, force)
				end
			end
			local collisionGroup = ply.m_iUnknownTauntCollisionGroup
			if isnumber(collisionGroup) then
				SetCollisionGroup(ply, collisionGroup)
			end
			ply.m_iUnknownTauntCollisionGroup = nil
			local avoidPlayers = ply.m_bUnknownTauntAvoidPlayers
			if isbool(avoidPlayers) then
				ply:SetAvoidPlayers(avoidPlayers)
			end
			ply.m_bUnknownTauntAvoidPlayers = nil
			local className = ply.m_sUnknownTauntWeapon
			if isstring(className) then
				ply:SelectWeapon(className)
			end
			ply.m_sUnknownTauntWeapon = nil
			local cSound = ply.m_csUnknownTauntSound
			if cSound and cSound:IsPlaying() then
				cSound:Stop()
			end
			ply.m_csUnknownTauntSound = nil
			Run("PlayerFinishedTaunt", ply, sequenceName, finishTime < curTime, timeRemaining, sequenceID, finishTime)
			return true
		end
	end
	local forcedFinish
	forcedFinish = function(ply)
		lib.Finish(ply, true)
		return
	end
	Add("PlayerDisconnected", addonName .. "::Finish", forcedFinish, PRE_HOOK)
	Add("PostPlayerDeath", addonName .. "::Finish", forcedFinish, PRE_HOOK)
	Add("PlayerSpawn", addonName .. "::Finish", forcedFinish, PRE_HOOK)
	Add("PlayerShouldTaunt", addonName .. "::DefaultTauntBlocking", function(ply, _, isUTaunt)
		if not isUTaunt and isPlayingTaunt(ply) then
			return false
		end
	end)
	local DistToSqr = FindMetaTable("Vector").DistToSqr
	local Iterator = player.Iterator
	local maxDistance = GetInt(sv_utaunt_coop_distance) ^ 2
	cvars.AddChangeCallback(sv_utaunt_coop_distance:GetName(), function(_, __, value)
		maxDistance = (tonumber(value) or 0) ^ 2
	end, addonName)
	lib.Start = function(ply, sequenceName, force, cycle, noSound, startOrigin, startAngles)
		if isPlayingCTaunt(ply) then
			if isPlayingTaunt(ply) then
				forcedFinish(ply)
			end
			return false
		end
		local sequenceID = LookupSequence(ply, sequenceName)
		if sequenceID < 1 then
			return false
		end
		if not force then
			if Run("PlayerShouldUnknownTaunt", ply, sequenceID) ~= true or Run("PlayerShouldTaunt", ply, ACT_GMOD_TAUNT_DANCE, true) == false then
				return false
			end
			if GetInfo(ply, "cl_utaunt_coop") == "1" and maxDistance > 0 then
				local origin = GetBonePosition(ply, 0)
				for _, otherPlayer in Iterator() do
					if not (Alive(otherPlayer) and otherPlayer.m_bIsPlayingTaunt) or otherPlayer == ply then
						goto _continue_0
					end
					if GetNW2Var(otherPlayer, "uTaunt-Name") ~= sequenceName then
						goto _continue_0
					end
					if DistToSqr(origin, GetBonePosition(otherPlayer, 0), nil) > maxDistance then
						goto _continue_0
					end
					if not (otherPlayer:IsBot() or GetInfo(otherPlayer, "cl_utaunt_coop") == "1") then
						goto _continue_0
					end
					if Run("PlayerShouldCoopTaunt", ply, otherPlayer, sequenceName) == false then
						goto _continue_0
					end
					if lib.Join(ply, otherPlayer) then
						return true
					end
					::_continue_0::
				end
			end
		end
		local duration = SequenceDuration(ply, sequenceID)
		if duration < 0.25 then
			return false
		end
		if isPlayingTaunt(ply) then
			forcedFinish(ply)
		end
		ply.m_sUnknownTauntModel = GetModel(ply)
		if isvector(startOrigin) then
			ply.m_vUnknownTauntOrigin = ply:GetPos()
			ply:SetPos(startOrigin)
		end
		if not isangle(startAngles) then
			startAngles = getRenderAngles(ply)
		end
		SetNW2Var(ply, "uTaunt-Angles", startAngles)
		if not GetBool(sv_utaunt_collisions) then
			ply.m_iUnknownTauntCollisionGroup = GetCollisionGroup(ply)
			ply.m_bUnknownTauntAvoidPlayers = ply:GetAvoidPlayers()
			ply:SetAvoidPlayers(false)
		end
		if not GetBool(sv_utaunt_allow_weapons) then
			local weapon = ply:GetActiveWeapon()
			if weapon and IsValid(weapon) then
				ply.m_sUnknownTauntWeapon = weapon:GetClass()
				ply:SetActiveWeapon()
			end
		end
		if not cycle then
			cycle = 0
		end
		SetNW2Var(ply, "uTaunt-Start", CurTime() - (cycle * duration))
		SetNW2Var(ply, "uTaunt-Name", sequenceName)
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, sequenceID, 0, true)
		ply:CrosshairDisable()
		if noSound or not (GetInfo(ply, "cl_utaunt_audio") == "1" or ply:IsBot()) then
			SetNW2Var(ply, "uTaunt-WebAudio", false)
		elseif webSounds[sequenceName] ~= nil then
			SetNW2Var(ply, "uTaunt-WebAudio", true)
		else
			local soundPath = Run("UnknownTauntSound", ply, sequenceName, cycle, duration, sequenceID)
			if soundPath == false then
				SetNW2Var(ply, "uTaunt-WebAudio", false)
			else
				if soundPath == nil or soundPath == true then
					soundPath = findSound(sequenceName)
				end
				if soundPath and find(soundPath, "^https?://.+$") == nil and not Exists(soundPath, "GAME") then
					SetNW2Var(ply, "uTaunt-WebAudio", false)
					local cSound = CreateSound(ply, soundPath)
					ply.m_csUnknownTauntSound = cSound
					cSound:ChangeVolume(0, 0)
					cSound:SetDSP(1)
					cSound:Play()
					cSound:ChangeVolume(1, 1)
				else
					SetNW2Var(ply, "uTaunt-WebAudio", true)
				end
			end
		end
		Run("PlayerStartTaunt", ply, ACT_GMOD_TAUNT_DANCE, duration)
		Run("PlayerStartedUnknownTaunt", ply, sequenceName, duration)
		return true
	end
	lib.Join = function(ply, otherPlayer)
		local sequenceName = GetNW2Var(otherPlayer, "uTaunt-Name")
		if sequenceName == nil then
			return false
		end
		local sequenceID = LookupSequence(ply, sequenceName)
		if sequenceID < 1 then
			return false
		end
		local players = otherPlayer.m_tUnknownTauntPlayers
		if not isnumber(coopDances[sequenceName]) or coopDances[sequenceName] < 1 then
			players[#players + 1] = ply
			return lib.Start(ply, sequenceName, true, getCycle(otherPlayer, sequenceID), true)
		end
		local danceName, danceID = match(sequenceName, "^([%a_]+_?)(%d+)$")
		if danceName == nil or danceID == nil then
			return false
		end
		danceID = tonumber(danceID)
		if danceID == nil then
			return false
		end
		for index = 1, coopDances[sequenceName] do
			if not isValidTauntingPlayer(players[index]) or players[index] == ply then
				players[index] = ply
				return lib.Start(ply, danceName .. (danceID + index), true, getCycle(otherPlayer, sequenceID), true, otherPlayer:GetPos(), getRenderAngles(otherPlayer))
			end
		end
		return false
	end
	do
		local GetVolume
		do
			local _obj_0 = FindMetaTable("CSoundPatch")
			GetVolume = _obj_0.GetVolume
		end
		local COLLISION_GROUP_PASSABLE_DOOR = _G.COLLISION_GROUP_PASSABLE_DOOR
		local sequenceID, cycle, volume = 0, 0, 0
		Add("PlayerTauntThink", addonName .. "::Thinking", function(ply, isUTaunt)
			if not isUTaunt then
				return
			end
			if not Alive(ply) or Crouching(ply) then
				forcedFinish(ply)
				return
			end
			local sequenceName = GetNW2Var(ply, "uTaunt-Name")
			if sequenceName == nil then
				return
			end
			sequenceID = LookupSequence(ply, sequenceName)
			if sequenceID < 1 then
				forcedFinish(ply)
				return
			end
			if GetModel(ply) ~= ply.m_sUnknownTauntModel then
				forcedFinish(ply)
				return
			end
			cycle = getCycle(ply, sequenceID)
			if Run("UnknownTauntThink", ply, sequenceName, cycle, sequenceID) == false or cycle == 1 then
				lib.Finish(ply, false)
				return
			end
			local cSound = ply.m_csUnknownTauntSound
			if cSound then
				volume = GetFloat(sv_utaunt_audio_volume)
				if volume > 1 then
					volume = 1
				end
				if GetVolume(cSound) ~= volume then
					cSound:ChangeVolume(volume, 0)
				end
			end
			if GetBool(sv_utaunt_collisions) then
				return
			end
			if GetCollisionGroup(ply) == COLLISION_GROUP_PASSABLE_DOOR then
				return
			end
			SetCollisionGroup(ply, COLLISION_GROUP_PASSABLE_DOOR)
			return
		end, PRE_HOOK)
	end
	concommand.Add("utaunt", function(ply, _, args)
		if not (ply and IsValid(ply) and Alive(ply)) or isPlayingCTaunt(ply) then
			return
		end
		if isstring(args[1]) then
			lib.Start(ply, args[1], false)
			return
		end
	end)
	concommand.Add("utaunt_stop", function(ply)
		if isPlayingTaunt(ply) then
			return lib.Finish(ply, false)
		end
	end)
	do
		local sv_utaunt_gamemode_override = CreateConVar("sv_utaunt_gamemode_override", "0", bor(FCVAR_ARCHIVE, FCVAR_NOTIFY), "Overrides gamemode taunt functions to allow players use taunts.", 0, 1)
		local changeOverride
		changeOverride = function(_, __, value)
			if value == "1" then
				GAMEMODE.__PlayerShouldTaunt = GAMEMODE.__PlayerShouldTaunt or GAMEMODE.PlayerShouldTaunt
				GAMEMODE.PlayerShouldTaunt = function(self, ply, act)
					if not (Alive(ply) and ply:IsOnGround()) or Crouching(ply) or ply:InVehicle() or ply:GetMoveType() ~= MOVETYPE_WALK or ply:WaterLevel() > 1 then
						return false
					end
					return true
				end
			else
				GAMEMODE.PlayerShouldTaunt = GAMEMODE.__PlayerShouldTaunt or GAMEMODE.PlayerShouldTaunt
			end
		end
		cvars.AddChangeCallback(sv_utaunt_gamemode_override:GetName(), changeOverride, addonName)
		timer.Simple(0.25, function()
			changeOverride(nil, nil, sv_utaunt_gamemode_override:GetString())
			return
		end)
	end
	do
		local GetSequenceActivity = ENTITY.GetSequenceActivity
		local acts = {
			[ACT_GMOD_TAUNT_DANCE] = true,
			[ACT_GMOD_TAUNT_ROBOT] = true,
			[ACT_GMOD_TAUNT_CHEER] = true,
			[ACT_GMOD_TAUNT_LAUGH] = true,
			[ACT_GMOD_TAUNT_SALUTE] = true,
			[ACT_GMOD_TAUNT_MUSCLE] = true,
			[ACT_GMOD_TAUNT_PERSISTENCE] = true,
			[ACT_GMOD_GESTURE_BOW] = true,
			[ACT_GMOD_GESTURE_WAVE] = true,
			[ACT_GMOD_GESTURE_AGREE] = true,
			[ACT_GMOD_GESTURE_BECON] = true,
			[ACT_GMOD_GESTURE_DISAGREE] = true,
			[ACT_GMOD_GESTURE_RANGE_ZOMBIE] = true,
			[ACT_GMOD_GESTURE_TAUNT_ZOMBIE] = true,
			[ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL] = true,
			[ACT_GMOD_GESTURE_ITEM_GIVE] = true,
			[ACT_GMOD_GESTURE_ITEM_DROP] = true,
			[ACT_GMOD_GESTURE_ITEM_PLACE] = true,
			[ACT_GMOD_GESTURE_ITEM_THROW] = true,
			[ACT_SIGNAL_FORWARD] = true,
			[ACT_SIGNAL_GROUP] = true,
			[ACT_SIGNAL_HALT] = true
		}
		Add("PlayerShouldUnknownTaunt", addonName .. "::DefaultSequences", function(ply, sequenceID)
			if acts[GetSequenceActivity(ply, sequenceID)] then
				return true
			end
		end)
	end
	Add("PlayerFinishedTaunt", addonName .. "::TauntLooping", function(ply, sequenceName, isFinished)
		if isFinished and GetInfo(ply, "cl_utaunt_loop") == "1" then
			return lib.Start(ply, sequenceName, false)
		end
	end, PRE_HOOK)
	Add("PlayerButtonDown", addonName .. "::TauntMenu", function(ply, keyCode)
		if keyCode == GetInt(sv_utaunt_menu_key) then
			ply:ConCommand("utaunts " .. keyCode)
			return
		end
	end, PRE_HOOK)
end
Add("PlayerSwitchWeapon", addonName .. "::WeaponSwitch", function(ply)
	if ply.m_bIsPlayingTaunt then
		if GetBool(sv_utaunt_allow_weapons) then
			return
		end
		return true
	end
end)
do
	local Iterator = player.Iterator
	local players = { }
	Add("EntityRemoved", addonName .. "::PlayerRemoved", function(entity)
		players[entity] = nil
	end, PRE_HOOK)
	local curTime = 0
	Add("Think", addonName .. "::IsPlayingTaunt", function()
		curTime = CurTime()
		for _, ply in Iterator() do
			if IsDormant(ply) or not Alive(ply) then
				if ply.m_bIsPlayingTaunt then
					ply.m_bIsPlayingTaunt = false
				end
				goto _continue_0
			end
			if isPlayingTaunt(ply) then
				players[ply] = curTime
				Run("PlayerTauntThink", ply, true)
			elseif isPlayingCTaunt(ply) then
				players[ply] = curTime
				Run("PlayerTauntThink", ply, false)
			end
			if not players[ply] then
				if ply.m_bIsPlayingTaunt == nil then
					ply.m_bIsPlayingTaunt = false
				end
				goto _continue_0
			end
			if (curTime - players[ply]) > 0.1 then
				ply.m_bIsPlayingTaunt = false
				players[ply] = false
			else
				ply.m_bIsPlayingTaunt = true
			end
			::_continue_0::
		end
	end, PRE_HOOK)
end
do
	local SetRenderAngles = PLAYER.SetRenderAngles
	Add("UpdateAnimation", addonName .. "::RenderAngles", function(ply)
		if isPlayingTaunt(ply) then
			SetRenderAngles(ply, getRenderAngles(ply))
			return
		end
	end, PRE_HOOK)
end
do
	local ClearMovement, SetButtons, SetImpulse, KeyDown, RemoveKey
	do
		local _obj_0 = FindMetaTable("CUserCmd")
		ClearMovement, SetButtons, SetImpulse, KeyDown, RemoveKey = _obj_0.ClearMovement, _obj_0.SetButtons, _obj_0.SetImpulse, _obj_0.KeyDown, _obj_0.RemoveKey
	end
	local IN_ATTACK, IN_ATTACK2, IN_DUCK, IN_JUMP = _G.IN_ATTACK, _G.IN_ATTACK2, _G.IN_DUCK, _G.IN_JUMP
	local band = bit.band
	local buttons = 0
	Add("StartCommand", addonName .. "::Movement", function(ply, cmd)
		if not ply.m_bIsPlayingTaunt then
			return
		end
		buttons = Run("TauntStartCommand", ply, cmd, GetNW2Var(ply, "uTaunt-Name", ""))
		if not (buttons and isnumber(buttons)) then
			buttons = 0
		end
		if KeyDown(cmd, IN_JUMP) then
			RemoveKey(cmd, IN_JUMP)
			if isPlayingTaunt(ply) and CLIENT and ply.m_bIsLocalPlayer then
				RunConsoleCommand("utaunt_stop")
			end
		end
		if KeyDown(cmd, IN_DUCK) then
			RemoveKey(cmd, IN_DUCK)
		end
		if not GetBool(sv_utaunt_allow_movement) then
			ClearMovement(cmd)
		end
		if GetBool(sv_utaunt_allow_attack) then
			if KeyDown(cmd, IN_ATTACK) and band(buttons, IN_ATTACK) == 0 then
				buttons = bor(buttons, IN_ATTACK)
			end
			if KeyDown(cmd, IN_ATTACK2) and band(buttons, IN_ATTACK2) == 0 then
				buttons = bor(buttons, IN_ATTACK2)
			end
		end
		SetButtons(cmd, buttons)
		SetImpulse(cmd, 0)
		return
	end, PRE_HOOK)
end
if not CLIENT then
	return
end
local CreateClientConVar = _G.CreateClientConVar
local cl_utaunt_loop = CreateClientConVar("cl_utaunt_loop", "0", true, true, "Enables looping for all taunts.", 0, 1)
local cl_utaunt_audio = CreateClientConVar("cl_utaunt_audio", "1", true, true, "Enables audio playback for taunts that support this feature.", 0, 1)
local cl_utaunt_coop = CreateClientConVar("cl_utaunt_coop", "1", true, true, "If enabled player will automatically join/synchronize with dance of another player nearby.", 0, 1)
local cl_utaunt_camera_mode = CreateClientConVar("cl_utaunt_camera_mode", "1", true, false, "0 = Simple third person, 1 = Third person attached to head, 2 = Eyes", 0, 2)
lib.IsAudioEnabled = function()
	return GetBool(cl_utaunt_audio)
end
lib.IsCoopEnabled = function()
	return GetBool(cl_utaunt_coop)
end
lib.IsLoopingEnabled = function()
	return GetBool(cl_utaunt_loop)
end
lib.GetCameraMode = function()
	return GetInt(cl_utaunt_camera_mode)
end
local GetPhrase = language.GetPhrase
local getPhrase
getPhrase = function(placeholder)
	local fulltext = GetPhrase(placeholder)
	if fulltext == placeholder and sub(placeholder, 1, 15) == "unknown_taunts." then
		return GetPhrase(sub(placeholder, 16))
	end
	return fulltext
end
lib.GetPhrase = getPhrase
local localPlayer = LocalPlayer()
local isInTaunt
if _G.IsInTaunt then
	isInTaunt = _G.IsInTaunt()
else
	isInTaunt = false
end
IsInTaunt = function()
	return isInTaunt
end
Add("InitPostEntity", addonName .. "::Initialization", function()
	localPlayer = LocalPlayer()
	localPlayer.m_bIsLocalPlayer = true
	localPlayer.m_bIsPlayingTaunt = false
	lib.Player = localPlayer
end, PRE_HOOK)
Add("Think", addonName .. "::IsInTaunt", function()
	if localPlayer and IsValid(localPlayer) then
		isInTaunt = localPlayer.m_bIsPlayingTaunt
	end
end, PRE_HOOK)
Add("HUDShouldDraw", addonName .. "::WeaponSelector", function(name)
	if isInTaunt and name == "CHudWeaponSelection" and not GetBool(sv_utaunt_allow_weapons) then
		return false
	end
end)
local Forward
do
	local _obj_0 = FindMetaTable("Angle")
	Forward = _obj_0.Forward
end
local boneID = 0
do
	local GetVolume, SetPos
	do
		local _obj_0 = FindMetaTable("IGModAudioChannel")
		GetVolume, SetPos = _obj_0.GetVolume, _obj_0.SetPos
	end
	local Remove = hook.Remove
	local mins, maxs = Vector(-512, -512, 0), Vector(512, 512, 512)
	local stopAudio
	stopAudio = function(ply)
		local channel = ply.m_bcUnknownTauntAudio
		if channel and channel:IsValid() then
			channel:Stop()
		end
		ply.m_bcUnknownTauntAudio = nil
	end
	local playStates = {
		[GMOD_CHANNEL_PLAYING] = true,
		[GMOD_CHANNEL_STALLED] = true
	}
	Add("UnknownTauntSynced", addonName .. "::Sync", function(ply, sequenceName, cycle, sequenceID, webAudio)
		mins[3] = ply:GetModelRenderBounds()[3]
		ply:SetRenderBounds(mins, maxs)
		if not webAudio or IsDormant(ply) then
			stopAudio(ply)
			return
		end
		local filePath = Run("UnknownTauntSound", ply, sequenceName, cycle, SequenceDuration(ply, sequenceID) or 0, sequenceID) or webSounds[sequenceName]
		local channel = ply.m_bcUnknownTauntAudio
		if channel and channel:IsValid() then
			if not filePath then
				ply.m_sUnknownTauntAudioFilePath = nil
				ply.m_bcUnknownTauntAudio = nil
				channel:Stop()
				return
			end
			if filePath == ply.m_sUnknownTauntAudioFilePath then
				local length = channel:GetLength()
				if length > 0 then
					channel:SetTime(length * cycle)
				end
				if not playStates[channel:GetState()] then
					channel:Play()
				end
				return
			end
			ply.m_sUnknownTauntAudioFilePath = nil
			ply.m_bcUnknownTauntAudio = nil
			channel:Stop()
		end
		if not filePath then
			return
		end
		local isURL = find(filePath, "^https?://.+$") ~= nil
		if not (isURL or Exists(filePath, "GAME")) then
			return
		end
		sound[isURL and "PlayURL" or "PlayFile"](filePath, "3d noplay noblock", function(newChannel)
			if not (newChannel and newChannel:IsValid() and isValidTauntingPlayer(ply) and not IsDormant(ply)) then
				return
			end
			ply.m_sUnknownTauntAudioFilePath = filePath
			ply.m_bcUnknownTauntAudio = newChannel
			local length = newChannel:GetLength()
			if length > 0 then
				newChannel:SetTime(length * cycle)
			end
			newChannel:Play()
			Add("Think", newChannel, function()
				if not isValidTauntingPlayer(ply) or IsDormant(ply) then
					Remove("Think", newChannel)
					if IsValid(ply) then
						ply.m_sUnknownTauntAudioFilePath = nil
						ply.m_bcUnknownTauntAudio = nil
					end
					newChannel:Stop()
					return
				end
				if GetVolume(newChannel) ~= GetFloat(sv_utaunt_audio_volume) then
					newChannel:SetVolume(GetFloat(sv_utaunt_audio_volume))
				end
				boneID = LookupBone(ply, "ValveBiped.Bip01_Head1")
				if boneID and boneID >= 0 then
					SetPos(newChannel, GetBonePosition(ply, boneID), Forward(getRenderAngles(ply)))
					return
				end
				SetPos(newChannel, ply:WorldSpaceCenter(), Forward(getRenderAngles(ply)))
				return
			end)
			return
		end)
		return
	end, PRE_HOOK)
	Add("PlayerFinishedTaunt", addonName .. "::Cleanup", function(ply)
		ply:SetRenderBounds(ply:GetModelRenderBounds())
		stopAudio(ply)
		return
	end, PRE_HOOK)
end
do
	local cycle = 0
	Add("EntityNetworkedVarChanged", addonName .. "::Networking", function(ply, key, oldValue, value)
		if not (IsValid(ply) and ply:IsPlayer() and Alive(ply)) then
			return
		end
		if key == "uTaunt-Name" then
			if value == nil then
				if ply.m_bUsingUnknownTaunt then
					ply.m_bUsingUnknownTaunt = false
					ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
					Run("PlayerFinishedTaunt", ply, oldValue)
				end
				return
			end
			local sequenceID = LookupSequence(ply, value)
			if sequenceID < 1 then
				return
			end
			ply.m_bUsingUnknownTaunt = true
			cycle = getCycle(ply, sequenceID)
			ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, sequenceID, cycle, true)
			Run("UnknownTauntSynced", ply, value, cycle, sequenceID, GetNW2Var(ply, "uTaunt-WebAudio", false))
			return
		end
		if key == "uTaunt-Start" then
			local sequenceName = GetNW2Var(ply, "uTaunt-Name")
			if sequenceName == nil then
				if ply.m_bUsingUnknownTaunt then
					ply.m_bUsingUnknownTaunt = false
					ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
					Run("PlayerFinishedTaunt", ply, sequenceName)
				end
				return
			end
			local sequenceID = LookupSequence(ply, sequenceName)
			if sequenceID < 1 then
				return
			end
			ply.m_bUsingUnknownTaunt = true
			cycle = getCycle(ply, sequenceID, value)
			ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, sequenceID, cycle, true)
			Run("UnknownTauntSynced", ply, sequenceName, cycle, sequenceID, GetNW2Var(ply, "uTaunt-WebAudio", false))
			return
		end
		if key == "uTaunt-WebAudio" then
			local sequenceName = GetNW2Var(ply, "uTaunt-Name")
			if sequenceName == nil then
				if ply.m_bUsingUnknownTaunt then
					ply.m_bUsingUnknownTaunt = false
					ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
					Run("PlayerFinishedTaunt", ply, sequenceName)
				end
				return
			end
			local sequenceID = LookupSequence(ply, sequenceName)
			if sequenceID < 1 then
				return
			end
			ply.m_bUsingUnknownTaunt = true
			cycle = getCycle(ply, sequenceID)
			ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, sequenceID, cycle, true)
			Run("UnknownTauntSynced", ply, sequenceName, cycle, sequenceID, value == true)
			return
		end
	end, PRE_HOOK)
	Add("NotifyShouldTransmit", addonName .. "::PVS", function(ply, shouldtransmit)
		if not (shouldtransmit and IsValid(ply) and ply:IsPlayer() and Alive(ply)) then
			if ply.m_bUsingUnknownTaunt then
				ply.m_bUsingUnknownTaunt = false
				ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
				Run("PlayerFinishedTaunt", ply, oldValue)
			end
			return
		end
		local sequenceName = GetNW2Var(ply, "uTaunt-Name")
		if sequenceName == nil then
			if ply.m_bUsingUnknownTaunt then
				ply.m_bUsingUnknownTaunt = false
				ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
				Run("PlayerFinishedTaunt", ply, oldValue)
			end
			return
		end
		local sequenceID = LookupSequence(ply, sequenceName)
		if sequenceID < 1 then
			return
		end
		ply.m_bUsingUnknownTaunt = true
		cycle = getCycle(ply, sequenceID)
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, sequenceID, cycle, true)
		Run("UnknownTauntSynced", ply, sequenceName, cycle, sequenceID)
		return
	end, PRE_HOOK)
end
local toggleMenu
toggleMenu = function(ply, keyCode)
	if isPlayingCTaunt(ply) then
		return false
	end
	if keyCode ~= nil then
		local bind = input.LookupKeyBinding(keyCode)
		if bind ~= nil and #bind > 0 then
			return false
		end
	end
	local panel = lib.Panel
	if panel and panel:IsValid() then
		panel:Remove()
		return true
	end
	if Run("AllowTauntMenu", ply) == false then
		return false
	end
	panel = vgui.Create("uTaunt::Menu")
	lib.Panel = panel
	panel:Setup(ply)
	return true
end
lib.ToggleMenu = toggleMenu
concommand.Add("utaunts", function(ply, _, args)
	if not ply:Alive() then
		return
	end
	local keyCode = args[1]
	if keyCode ~= nil and #keyCode > 0 then
		keyCode = tonumber(keyCode)
	end
	toggleMenu(ply, keyCode)
	return
end)
do
	local commmands = {
		"taunt",
		"dance",
		"utaunt",
		"udance"
	}
	local allowedChars = {
		["/"] = true,
		["!"] = true
	}
	Add("OnPlayerChat", addonName .. "::ChatCommands", function(ply, text, isTeam, isDead)
		if isDead or isTeam or not ply.m_bIsLocalPlayer then
			return
		end
		text = lower(Trim(text))
		if allowedChars[sub(text, 1, 1)] == nil then
			return
		end
		text = sub(text, 2)
		for _index_0 = 1, #commmands do
			local command = commmands[_index_0]
			if find(text, command, 1, false) ~= nil then
				toggleMenu(ply)
				return true
			end
		end
	end)
end
do
	local format = string.format
	local taunts = {
		"taunt_cheer",
		"taunt_dance",
		"taunt_laugh",
		"taunt_muscle",
		"taunt_robot",
		"taunt_persistence",
		"taunt_zombie"
	}
	local gestures = {
		"gesture_agree",
		"gesture_bow",
		"gesture_becon",
		"gesture_disagree",
		"gesture_salute",
		"gesture_wave",
		"gesture_item_drop",
		"gesture_item_give",
		"gesture_item_place",
		"gesture_item_throw",
		"gesture_signal_forward",
		"gesture_signal_halt",
		"gesture_signal_group"
	}
	local zombie = {
		"zombie_attack_01",
		"zombie_attack_02",
		"zombie_attack_03",
		"zombie_attack_04",
		"zombie_attack_05",
		"zombie_attack_06",
		"zombie_attack_07",
		"zombie_attack_special"
	}
	Add("UnknownTauntMenuSetup", addonName .. "::DefaultSequences", function(ply, add)
		local sequences, sequencesCount = { }, 0
		for _index_0 = 1, #taunts do
			local sequenceName = taunts[_index_0]
			if LookupSequence(ply, sequenceName) < 0 then
				goto _continue_0
			end
			sequencesCount = sequencesCount + 1
			sequences[sequencesCount] = sequenceName
			::_continue_0::
		end
		if sequencesCount > 0 then
			add(format(GetPhrase("unknown_taunts.menu.taunts"), "Garry's Mod"), sequences)
			for index = 1, sequencesCount do
				sequences[index] = nil
			end
			sequencesCount = 0
		end
		for _index_0 = 1, #gestures do
			local sequenceName = gestures[_index_0]
			if LookupSequence(ply, sequenceName) < 0 then
				goto _continue_1
			end
			sequencesCount = sequencesCount + 1
			sequences[sequencesCount] = sequenceName
			::_continue_1::
		end
		if sequencesCount > 0 then
			add(format(GetPhrase("unknown_taunts.menu.gestures"), "Garry's Mod"), sequences)
			for index = 1, sequencesCount do
				sequences[index] = nil
			end
			sequencesCount = 0
		end
		for _index_0 = 1, #zombie do
			local sequenceName = zombie[_index_0]
			if LookupSequence(ply, sequenceName) < 0 then
				goto _continue_2
			end
			sequencesCount = sequencesCount + 1
			sequences[sequencesCount] = sequenceName
			::_continue_2::
		end
		if sequencesCount > 0 then
			add(format(GetPhrase("unknown_taunts.menu.zombie"), "Garry's Mod"), sequences)
		end
		return
	end)
end
do
	local DrawRect, SetDrawColor = surface.DrawRect, surface.SetDrawColor
	local floor, Round = math.floor, math.Round
	local cl_utaunt_menu_auto_close = CreateClientConVar("cl_utaunt_menu_auto_close", "0", true, false, "Automatically close the taunt menu when a taunt is selected.", 0, 1)
	local PANEL = { }
	PANEL.Init = function(self)
		self:SetTitle("#unknown_taunts.menu.title")
		self:SetSize(ScreenScale(128), 24)
		self:SetIcon("icon16/user.png")
		self:MakePopup()
		return self:Center()
	end
	PANEL.ClickSound = function()
		return surface.PlaySound("garrysmod/ui_click.wav")
	end
	PANEL.Setup = function(self, ply)
		local scrollPanel = self:Add("DScrollPanel")
		self.ScrollPanel = scrollPanel
		scrollPanel:Dock(FILL)
		scrollPanel.PerformLayout = function(_, width, height)
			local canvas = scrollPanel:GetCanvas()
			if canvas and canvas:IsValid() then
				local margin = ScreenScale(2)
				canvas:DockPadding(margin, 0, margin, margin)
			end
			return DScrollPanel.PerformLayout(scrollPanel, width, height)
		end
		local actions = scrollPanel:Add("EditablePanel")
		actions.Progress = 0
		actions:Dock(TOP)
		actions.PerformLayout = function()
			return actions:SetTall(32)
		end
		actions.Think = function()
			local sequenceName = GetNW2Var(ply, "uTaunt-Name")
			if sequenceName == nil then
				actions.Progress = 0
				return
			end
			local sequenceID = LookupSequence(ply, sequenceName)
			if sequenceID < 1 then
				actions.Progress = 0
				return
			end
			actions.Progress = getCycle(ply, sequenceID)
		end
		actions.Paint = function(_, width, height)
			SetDrawColor(150, 255, 50, 220)
			return DrawRect(0, height - 2, width * actions.Progress, 2)
		end
		do
			local button = actions:Add("DButton")
			button:SetText("")
			button:SetWide(32)
			button:Dock(RIGHT)
			button.Paint = function() end
			button.UpdateIcon = function(state)
				return button:SetImage(state and "icon16/group.png" or "icon16/user.png")
			end
			button.UpdateIcon(GetBool(cl_utaunt_coop))
			button.DoClick = function()
				if GetBool(cl_utaunt_coop) then
					cl_utaunt_coop:SetBool(false)
					button.UpdateIcon(false)
				else
					cl_utaunt_coop:SetBool(true)
					button.UpdateIcon(true)
				end
				return self:ClickSound()
			end
		end
		do
			local button = actions:Add("DButton")
			button:SetText("")
			button:SetWide(32)
			button:Dock(RIGHT)
			button.Paint = function() end
			button.UpdateIcon = function(state)
				local icon = "icon16/camera.png"
				if state == 1 then
					icon = "icon16/camera_link.png"
				elseif state == 2 then
					icon = "icon16/eye.png"
				end
				return button:SetImage(icon)
			end
			button.UpdateIcon(GetInt(cl_utaunt_camera_mode))
			button.DoClick = function()
				local state = GetInt(cl_utaunt_camera_mode) + 1
				if state > cl_utaunt_camera_mode:GetMax() then
					state = cl_utaunt_camera_mode:GetMin()
				end
				cl_utaunt_camera_mode:SetInt(state)
				button.UpdateIcon(state)
				return self:ClickSound()
			end
		end
		do
			local button = actions:Add("DButton")
			button:SetText("")
			button:SetWide(32)
			button:Dock(RIGHT)
			button.Paint = function() end
			button.UpdateIcon = function(state)
				return button:SetImage(state and "icon16/sound.png" or "icon16/sound_mute.png")
			end
			button.UpdateIcon(GetBool(cl_utaunt_audio))
			button.DoClick = function()
				if GetBool(cl_utaunt_audio) then
					cl_utaunt_audio:SetBool(false)
					button.UpdateIcon(false)
				else
					cl_utaunt_audio:SetBool(true)
					button.UpdateIcon(true)
				end
				return self:ClickSound()
			end
		end
		do
			local button = actions:Add("DButton")
			button:SetText("")
			button:SetWide(32)
			button:Dock(RIGHT)
			button.Paint = function() end
			button.UpdateIcon = function(state)
				return button:SetImage(state and "icon16/control_repeat_blue.png" or "icon16/control_repeat.png")
			end
			button.UpdateIcon(GetBool(cl_utaunt_loop))
			button.DoClick = function()
				if GetBool(cl_utaunt_loop) then
					cl_utaunt_loop:SetBool(false)
					button.UpdateIcon(false)
				else
					cl_utaunt_loop:SetBool(true)
					button.UpdateIcon(true)
				end
				return self:ClickSound()
			end
		end
		do
			local button = actions:Add("DButton")
			button:SetText("")
			button:SetWide(32)
			button:Dock(RIGHT)
			button.Paint = function() end
			button.Think = function()
				local state = isPlayingTaunt(ply)
				if button.State ~= state then
					button.State = state
					if state then
						return button:SetImage("icon16/control_stop_blue.png")
					else
						return button:SetImage("icon16/control_stop.png")
					end
				end
			end
			button.DoClick = function()
				if isPlayingTaunt(ply) then
					RunConsoleCommand("utaunt_stop")
					return self:ClickSound()
				end
			end
		end
		do
			local label = actions:Add("DLabel")
			label.SequenceName = ""
			label:Dock(FILL)
			label.Think = function()
				if not isPlayingTaunt(ply) then
					if label.SequenceName ~= nil then
						label.SequenceName = nil
						label:SetText("#unknown_taunts.menu.none")
					end
					return
				end
				local sequenceName = GetNW2Var(ply, "uTaunt-Name")
				if sequenceName == nil then
					if label.SequenceName ~= nil then
						label.SequenceName = nil
						label:SetText("#unknown_taunts.menu.none")
					end
					return
				end
				local sequenceID = LookupSequence(ply, sequenceName)
				if sequenceID < 1 then
					if label.SequenceName ~= nil then
						label.SequenceName = nil
						label:SetText("#unknown_taunts.menu.none")
					end
					return
				end
				if label.SequenceName ~= sequenceName then
					label.SequenceName = sequenceName
					label.SequenceTitle = getPhrase("unknown_taunts." .. sequenceName)
				end
				local duration = SequenceDuration(ply, sequenceID)
				local timeRemaining = duration * getCycle(ply, sequenceID)
				if timeRemaining > 60 then
					timeRemaining = Round(timeRemaining / 60, 1) .. "m"
				else
					timeRemaining = floor(timeRemaining) .. "s"
				end
				if duration > 60 then
					duration = Round(duration / 60, 1) .. "m"
				else
					duration = floor(duration) .. "s"
				end
				local str = label.SequenceTitle .. " ( " .. timeRemaining .. " / " .. duration .. " )"
				if str ~= label:GetText() then
					return label:SetText(str)
				end
			end
		end
		return Run("UnknownTauntMenuSetup", ply, function(title, sequences)
			if not istable(sequences) then
				return
			end
			local length = #sequences
			if length == 0 then
				return
			end
			for index = 1, length do
				if Run("AllowUnknownTaunt", ply, sequences[index], title) == false then
					sequences[index] = false
				end
			end
			length = #sequences
			if length == 0 then
				return
			end
			local combo = self[title]
			if not (combo and combo:IsValid()) then
				local label = scrollPanel:Add("DLabel")
				label:SetText(title)
				label:Dock(TOP)
				combo = scrollPanel:Add("DComboBox")
				self[title] = combo
				combo:SetText("#unknown_taunts.menu.select")
				combo:Dock(TOP)
				combo.OnSelect = function(_, __, ___, name)
					RunConsoleCommand("utaunt", name)
					if GetBool(cl_utaunt_menu_auto_close) then
						self:Close()
						return
					end
					return combo:SetText("#unknown_taunts.menu.select")
				end
			end
			for index = 1, length do
				if sequences[index] ~= false then
					combo:AddChoice(getPhrase("unknown_taunts." .. sequences[index]), sequences[index])
				end
			end
		end)
	end
	PANEL.PerformLayout = function(self, width, height)
		local scrollPanel = self.ScrollPanel
		if scrollPanel and scrollPanel:IsValid() then
			height = 0
			local _list_0 = scrollPanel:GetCanvas():GetChildren()
			for _index_0 = 1, #_list_0 do
				local pnl = _list_0[_index_0]
				height = height + pnl:GetTall()
			end
			if height == 0 then
				self:Remove()
				return
			end
			self:SetTall(math.min(height + 48, ScrH() * 0.5))
		end
		return DFrame.PerformLayout(self, width, height)
	end
	PANEL.Paint = function(self, width, height)
		SetDrawColor(50, 50, 50, 220)
		return DrawRect(0, 0, width, height)
	end
	vgui.Register("uTaunt::Menu", PANEL, "DFrame")
end
do
	local MsgC, HSVToColor = _G.MsgC, _G.HSVToColor
	local Round = math.Round
	concommand.Add("utaunt_list", function(ply, _, args)
		local modelSequences = GetSequenceList(ply)
		local allowAll = args[1] == "1"
		local sequences, count = { }, 0
		for index = 1, #modelSequences do
			local sequenceName = modelSequences[index]
			if not allowAll and Run("AllowUnknownTaunt", ply, sequenceName, "Sequences") == false then
				goto _continue_0
			end
			local placeholder = "unknown_taunts." .. sequenceName
			local fulltext = GetPhrase(placeholder)
			if not allowAll and fulltext == placeholder then
				goto _continue_0
			end
			count = count + 1
			local duration = SequenceDuration(ply, index)
			if duration > 60 then
				sequences[count] = sequenceName .. " (" .. Round(duration / 60, 1) .. " minutes) - " .. fulltext
				goto _continue_0
			end
			sequences[count] = sequenceName .. " (" .. Round(duration, 2) .. " seconds) - " .. fulltext
			::_continue_0::
		end
		if count == 0 then
			MsgC("No sequences found.\n")
			return
		end
		MsgC("Sequences:\n")
		for index = 1, count do
			MsgC(index .. ". ", HSVToColor((180 + index) % 360, 1, 1), sequences[index], "\n")
		end
	end)
end
list.Set("DesktopWindows", "utaunt-menu", {
	title = "uTaunt",
	icon = "icon16/color_swatch.png",
	init = function(icon, window)
		if window and window:IsValid() then
			window:Remove()
		end
		icon.DoClick = function()
			return RunConsoleCommand("utaunts")
		end
		return RunConsoleCommand("utaunts")
	end
})
do
	local FrameTime = _G.FrameTime
	local camera_mode = GetInt(cl_utaunt_camera_mode)
	cvars.AddChangeCallback(cl_utaunt_camera_mode:GetName(), function(_, __, value)
		camera_mode = tonumber(value) or 0
	end, addonName)
	local viewAngles, eyeAngles, distance
	local traceResult = { }
	local trace = {
		mins = Vector(-8, -8, -8),
		maxs = Vector(8, 8, 8),
		output = traceResult,
		mask = MASK_SHOT,
		filter = function(entity)
			return entity.m_bIsPlayingTaunt ~= true
		end
	}
	do
		local vector_origin, LocalToWorld, LerpVector, LerpAngle = _G.vector_origin, _G.LocalToWorld, _G.LerpVector, _G.LerpAngle
		local LookupAttachment, GetAttachment = ENTITY.LookupAttachment, ENTITY.GetAttachment
		local GetViewEntity = PLAYER.GetViewEntity
		local cl_utaunt_camera_distance = CreateClientConVar("cl_utaunt_camera_distance", "128", true, false, "Distance of the camera from the player.")
		local targetOrigin, targetAngles
		local attachmentID, fraction = 0, 0
		local view = {
			drawviewer = true
		}
		Add("ShouldDrawLocalPlayer", addonName .. "::Compatibility", function()
			if isInTaunt or fraction > 0 then
				return true
			end
		end)
		Add("CalcView", addonName .. "::Compatibility", function(ply, origin, angles)
			if not ((isInTaunt or fraction > 0) and Alive(ply) and GetViewEntity(ply) == ply) then
				if eyeAngles then
					eyeAngles = nil
				end
				if viewAngles then
					viewAngles = nil
				end
				if distance then
					distance = nil
				end
				return
			end
			if not eyeAngles then
				eyeAngles = Angle(angles)
				eyeAngles[1], eyeAngles[3] = 0, 0
			end
			if not viewAngles then
				viewAngles = (camera_mode == 2) and Angle() or Angle(eyeAngles)
			end
			if camera_mode == 2 then
				attachmentID = LookupAttachment(ply, "eyes")
				if attachmentID and attachmentID > 0 then
					local data = GetAttachment(ply, attachmentID)
					targetOrigin, targetAngles = LocalToWorld(vector_origin, viewAngles, data.Pos, data.Ang)
				else
					boneID = LookupBone(ply, "ValveBiped.Bip01_Head1")
					if boneID and boneID > 0 then
						targetOrigin, targetAngles = LocalToWorld(vector_origin, viewAngles, GetBonePosition(ply, boneID))
					else
						targetOrigin, targetAngles = LocalToWorld(vector_origin, viewAngles, GetBonePosition(ply, 0))
					end
				end
			else
				if not distance then
					distance = cl_utaunt_camera_distance:GetInt()
					if distance < sv_utaunt_camera_distance_min:GetInt() then
						distance = sv_utaunt_camera_distance_min:GetInt()
					elseif distance > sv_utaunt_camera_distance_max:GetInt() then
						distance = sv_utaunt_camera_distance_max:GetInt()
					end
				end
				if traceResult.HitPos then
					targetOrigin = traceResult.HitPos + traceResult.HitNormal
				else
					targetOrigin = origin
				end
				targetAngles = viewAngles
			end
			if isInTaunt then
				if fraction < 1 then
					fraction = fraction + (FrameTime() * 4)
					if fraction > 1 then
						fraction = 1
					end
					view.origin = LerpVector(fraction, origin, targetOrigin)
					view.angles = LerpAngle(fraction, eyeAngles, targetAngles)
					return view
				end
			elseif fraction > 0 then
				fraction = fraction - (FrameTime() * 2)
				if fraction < 0 then
					fraction = 0
				end
				view.origin = LerpVector(fraction, origin, targetOrigin)
				view.angles = LerpAngle(fraction, eyeAngles, targetAngles)
				return view
			end
			view.origin = targetOrigin
			view.angles = targetAngles
			return view
		end)
	end
	do
		local SetViewAngles, GetMouseWheel
		do
			local _obj_0 = FindMetaTable("CUserCmd")
			SetViewAngles, GetMouseWheel = _obj_0.SetViewAngles, _obj_0.GetMouseWheel
		end
		local TraceHull = util.TraceHull
		local wheel = 0
		Add("CreateMove", addonName .. "::Compatibility", function(cmd)
			if eyeAngles then
				SetViewAngles(cmd, eyeAngles)
			end
			if camera_mode ~= 2 and viewAngles and distance then
				if camera_mode == 1 then
					boneID = LookupBone(localPlayer, "ValveBiped.Bip01_Head1")
					if boneID and boneID >= 0 then
						trace.start = GetBonePosition(localPlayer, boneID)
					else
						trace.start = localPlayer:EyePos()
					end
				else
					trace.start = localPlayer:EyePos()
				end
				trace.endpos = trace.start - Forward(viewAngles) * distance
				TraceHull(trace)
			end
			return
		end, PRE_HOOK)
		return Add("InputMouseApply", addonName .. "::Camera", function(cmd, x, y)
			if viewAngles then
				if y ~= 0 then
					local _update_0 = 1
					viewAngles[_update_0] = viewAngles[_update_0] + (y * FrameTime())
					if camera_mode == 2 then
						if viewAngles[1] > 30 then
							viewAngles[1] = 30
						elseif viewAngles[1] < -60 then
							viewAngles[1] = -60
						end
					else
						if viewAngles[1] > 90 then
							viewAngles[1] = 90
						elseif viewAngles[1] < -90 then
							viewAngles[1] = -90
						end
					end
				end
				if x ~= 0 then
					local _update_0 = 2
					viewAngles[_update_0] = viewAngles[_update_0] - (x * FrameTime())
					if camera_mode == 2 then
						if viewAngles[2] > 45 then
							viewAngles[2] = 45
						elseif viewAngles[2] < -45 then
							viewAngles[2] = -45
						end
					else
						if viewAngles[2] > 180 then
							viewAngles[2] = -180
						elseif viewAngles[2] < -180 then
							viewAngles[2] = 180
						end
					end
				end
			end
			if distance and camera_mode ~= 2 then
				wheel = GetMouseWheel(cmd)
				if wheel ~= 0 then
					distance = distance - wheel * (distance * 0.1)
					if distance < sv_utaunt_camera_distance_min:GetInt() then
						distance = sv_utaunt_camera_distance_min:GetInt()
					elseif distance > sv_utaunt_camera_distance_max:GetInt() then
						distance = sv_utaunt_camera_distance_max:GetInt()
					end
				end
			end
		end, PRE_HOOK)
	end
end
