AddCSLuaFile()
local CAM = {
	ShouldDrawLocalPlayer = function() end,
	CreateMove = function() end,
	CalcView = function() end
}
TauntCamera = function()
	return CAM
end
