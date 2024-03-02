AddCSLuaFile()

local util_TraceHull = util.TraceHull
local LerpVector = LerpVector
local LerpAngle = LerpAngle
local FrameTime = FrameTime

local CAM = {}

local wasOn = false

local viewAngles = angle_zero
local eyeAngles = nil

local outLerp = 1
local inLerp = 0

function CAM:ShouldDrawLocalPlayer( ply, on )
    return on or outLerp < 1
end

local trace = {
    mins = Vector( -8, -8, -8 ),
    maxs = Vector( 8, 8, 8 ),
    mask = MASK_SHOT
}

function CAM:CalcView( view, ply, on )
    if not ( ply:Alive() and ply:GetViewEntity():IsValid() and ply:GetViewEntity() == ply ) then
        on = false
    end

    if wasOn ~= on then
        if on then inLerp = 0 end
        if not on then outLerp = 0 end
        wasOn = on
    end

    if not on and outLerp >= 1 then
        viewAngles = view.angles
        viewAngles[ 3 ] = 0
        eyeAngles = nil
        inLerp = 0
        return
    end

    if ( eyeAngles == nil ) then return end

    trace.start = view.origin
    trace.endpos = trace.start - viewAngles:Forward() * 100
    trace.filter = ply

    local traceResult = util_TraceHull( trace )

    if ( inLerp < 1 ) then
        inLerp = inLerp + FrameTime() * 5.0
        view.origin = LerpVector( inLerp, view.origin, traceResult.HitPos + traceResult.HitNormal )
        view.angles = LerpAngle( inLerp, eyeAngles, viewAngles )
    elseif ( outLerp < 1 ) then
        outLerp = outLerp + FrameTime() * 3.0
        view.origin = LerpVector( 1 - outLerp, view.origin, traceResult.HitPos + traceResult.HitNormal )
        view.angles = LerpAngle( 1 - outLerp, eyeAngles, viewAngles )
    else
        view.origin = traceResult.HitPos + traceResult.HitNormal
        view.angles = viewAngles
    end

    return true
end

function CAM:CreateMove( cmd, ply, on )
    if not ply:Alive() then on = false end
    if not on then return end

    if ( eyeAngles == nil ) then
        eyeAngles = viewAngles
    end

    viewAngles[ 1 ] = viewAngles[ 1 ] + cmd:GetMouseY() * FrameTime()
    viewAngles[ 2 ] = viewAngles[ 2 ] - cmd:GetMouseX() * FrameTime()

    cmd:SetViewAngles( eyeAngles )
end

function TauntCamera()
    return CAM
end
