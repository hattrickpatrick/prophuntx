-- Initialize shared variable
PHX = {}
PHX.__index = PHX

PHX.ConfigPath 	= "phx_data"
PHX.VERSION		= "X"
PHX.REVISION	= "16.08.20" --Format: dd/mm/yy.

--[[------------------------------------------------
    Complete overhaul and replacement of ConVars in
    favor of client/server networked globals and
    storage in sv.db (sql library)

    @author HatTrickPatrick
------------------------------------------------]]--

-- Default Configuration
PHX.DEFAULT_VARS = {
    ["UseForceLang"] = "0",
    ["ForcedLanguage"] = "en_us",
    ["DefaultLang"] = "en_us",
    ["UseCustomMdlProp"] = "0",
    ["UseCustomMdlHunter"] = "0",
    ["UseModelType"] = "0",
    ["AutoTauntEnable"] = "1",
    ["AutoTauntDelay"] = "45",
    ["CustomTauntMode"] = "0",
    ["CustomTauntDelay"] = "6",
    ["NormalTauntDelay"] = "2",
    ["PropJumpPower"] = "1.4",
    ["PropNotifyRotation"] = "1",
    ["FreezeCamera"] = "1",
    ["FreezeCamUseSingle"] = "0",
    ["FreezeCamCue"] = "misc/freeze_cam.wav",
    ["NotifyPlayerJoinLeaves"] = "1",
    ["UseLuckyBall"] = "1",
    ["UseDevilCrystal"] = "1",
    ["HunterPenalty"] = "5",
    ["HunterKillBonus"] = "100",
    ["GameTime"] = "30",
    ["BlindTime"] = "30",
    ["RoundTime"] = "300",
    ["TotalRounds"] = "10",
    ["WaitForPlayers"] = "1",
    ["MinWaitForPlayers"] = "1",
    ["EnableOBBMod"] = "1",
    ["ApplyOBBonRound"] = "1",
    ["UseNewMKBren"] = "1",
    ["CheckSpace"] = "0",
    ["SeePlayerNames"] = "0",
    ["CameraCollision"] = "0",
    ["PropCollide"] = "0",
    ["HLACombine"] = "1",
    ["SwapTeam"] = "1",
    ["ChangeTeamLimit"] = "8",
    ["EnableTeamBalance"] = "1",
    ["EnableNewChat"] = "0",
    ["NewChatPosSubtract"] = "50",
    ["AllowRespawnOnBlind"] = "1",
    ["AllowRespawnOnBlindTeam"] = "0",
    ["AllowSpectatorRespawnOnBlind"] = "1",
    ["BlindRespawnTimePercent"] = "0.75",
    ["AllowPickupProp"] = "3",
    ["UseCustomMapVote"] = "0",
    ["CustomMapVoteCall"] = "MapVote.Start()",
    ["ForceJoinBalancedTeams"] = "0",
    ["SMGGrenadeCounts"] = "1",
    ["BeVerbose"] = "0",
    ["AllowRespawnOnBlindBetweenTeams"] = "0",
}

-- Query SQL for var data
-- If the data isn't in the SQL db yet, we create the table and
-- insert the default values
-- Once they're read in, create global strings of the values

if SERVER then
    PHX.VARS = {}

    if sql.TableExists("prop_hunt_vars") then
        local datas = sql.Query("SELECT * FROM prop_hunt_vars")
        
        if datas then
            for _, row in pairs(datas) do
                PHX.VARS[row.key] = row.value
            end
        else
            print("[PHX] WARNING: Failed to load vars/settings from prop_hunt_vars in SQL DB. Using the default config as a failsafe! Please check your sv.db for issues")
            print("[PHX] The SQL error was: " .. sql.LastError() or "(unavailable)")
            PHX.VARS = table.Copy(PHX.DEFAULT_VARS)
        end
    else
        print("[PHX] NOTICE: Table prop_hunt_vars not found in SQL DB. Attempting to create it.")
        if sql.Query("CREATE TABLE prop_hunt_vars (key TEXT NOT NULL PRIMARY KEY, value TEXT)") then
            print("[PHX] NOTICE: Table prop_hunt_vars created in SQL DB. Attempting to setup default config.")
            for k,v in SortedPairs(PHX.DEFAULT_VARS) do
                if sql.Query(string.format("INSERT INTO prop_hunt_vars(name, value) VALUES('%s', '%s')", k, v)) then
                    print("[PHX] Added default config '" .. k .. "'='" .. v .. "' to prop_hunt_vars")
                else
                    print("[PHX] ERROR: Failed to insert default config '" .. k .. "'='" .. v .. " to prop_hunt_vars")
                    print("[PHX] The SQL error was: " .. sql.LastError())
                end
            end
        else
            print("[PHX] ERROR: Failed to create table prop_hunt_vars")
            print("[PHX] The SQL error was: " .. sql.LastError())
        end
        
        PHX.VARS = table.Copy(PHX.DEFAULT_VARS)
    end
    
    for k,v in pairs(PHX.VARS) do
        SetGlobalString("phvar_"..k, v)
    end
end

function PHX.GetVarBool(n)
    return GetGlobalString(n, PHX.DEFAULT_VARS[n]) != "0"
end
function PHX.GetVarNum(n)
    return tonumber(GetGlobalString(n, PHX.DEFAULT_VARS[n]))
end
function PHX.GetVarString(n)
    return tostring(GetGlobalString(n, PHX.DEFAULT_VARS[n]))
end



function PHX.VerboseMsg(text)
	if ( PHX.GetVarBool("phvar_BeVerbose") and text ) then
		print( tostring(text) )
	end
end

--Include Languages
PHX.LANGUAGES = {}

local f = file.Find(engine.ActiveGamemode() .. "/gamemode/langs/*.lua", "LUA")
for _,lgfile in SortedPairs(f) do
	PHX.VerboseMsg("[PHX] [LANGUAGE] Adding Language File -> ".. lgfile)
	AddCSLuaFile("langs/" .. lgfile)
	include("langs/" .. lgfile)
end

-- Inclusions! yay...
AddCSLuaFile("cl_lang.lua")
AddCSLuaFile("config/sh_init.lua")
AddCSLuaFile("sh_drive_prop.lua")
AddCSLuaFile("ulx/modules/sh/sh_phx_mapvote.lua")
AddCSLuaFile("sh_config.lua")
AddCSLuaFile("sh_player.lua")

if CLIENT then
	include("cl_lang.lua")
end
include("config/sh_init.lua")
include("sh_drive_prop.lua")
include("ulx/modules/sh/sh_phx_mapvote.lua")
include("sh_config.lua")
include("sh_player.lua")

-- Special Inclusion: ChatBox.
if PHX.GetVarBool("phvar_EnableNewChat") then
	AddCSLuaFile("sh_chatbox.lua")
	include("sh_chatbox.lua")
end

-- MapVote
if SERVER then
    AddCSLuaFile("sh_mapvote.lua")
    AddCSLuaFile("mapvote/cl_mapvote.lua")

    include("sh_mapvote.lua")
    include("mapvote/sv_mapvote.lua")
    include("mapvote/rtv.lua")
else
    include("sh_mapvote.lua")
    include("mapvote/cl_mapvote.lua")
end

-- Update
AddCSLuaFile("sh_httpupdates.lua")
include("sh_httpupdates.lua")

-- Fretta!
DeriveGamemode("fretta")
IncludePlayerClasses()

-- Information about the gamemode
GM.Name		= "Prop Hunt X"
GM.Author	= "Wolvindra-Vinzuerio & D4UNKN0WNM4N"

-- Versioning
GM._VERSION		= PHX.VERSION
GM.REVISION		= PHX.REVISION --dd/mm/yy.
GM.DONATEURL 	= "https://prophunt.wolvindra.net/donate"
GM.UPDATEURL 	= "https://prophunt.wolvindra.net/ph_update_check.php" --return json only

--[[ if CLIENT then
	GM.Help		= PHX:FTranslate( "HELP_F1" )
else
	GM.Help		= PHX.DefaultHelp
end ]]

GM.Help			= ""

-- Fretta configuration
GM.GameLength				= PHX.GetVarNum("phvar_GameTime")
GM.AddFragsToTeamScore		= true
GM.CanOnlySpectateOwnTeam 	= true
GM.ValidSpectatorModes 		= { OBS_MODE_CHASE, OBS_MODE_IN_EYE, OBS_MODE_ROAMING }
GM.Data 					= {}
GM.EnableFreezeCam			= true
GM.NoAutomaticSpawning		= true
GM.NoNonPlayerPlayerDamage	= true
GM.NoPlayerPlayerDamage 	= true
GM.RoundBased				= true
GM.RoundLimit				= PHX.GetVarNum("phvar_TotalRounds")
GM.RoundLength 				= PHX.GetVarNum("phvar_RoundTime")
GM.RoundPreStartTime		= 0
GM.SuicideString			= "dead" -- obsolete
GM.TeamBased 				= true

--GM.AutomaticTeamBalance 		= false -- Do not edit.
GM.ForceJoinBalancedTeams 	= GetGlobalBool("bJoinBalancedTeam", false)

-- Called on gamemdoe initialization to create teams
function GM:CreateTeams()
	if !GAMEMODE.TeamBased then
		return
	end
	
	TEAM_HUNTERS = 1
	team.SetUp(TEAM_HUNTERS, "Hunters", Color(150, 205, 255, 255))
	team.SetSpawnPoint(TEAM_HUNTERS, {"info_player_counterterrorist", "info_player_combine", "info_player_deathmatch", "info_player_axis", "info_player_hunter"})
	team.SetClass(TEAM_HUNTERS, {"Hunter"})

	TEAM_PROPS = 2
	team.SetUp(TEAM_PROPS, "Props", Color(255, 60, 60, 255))
	team.SetSpawnPoint(TEAM_PROPS, {"info_player_terrorist", "info_player_rebel", "info_player_deathmatch", "info_player_allies", "info_player_props"})
	team.SetClass(TEAM_PROPS, {"Prop"})
end

-- Check collisions
function CheckPropCollision(entA, entB)
	-- Disable prop on prop collisions
	if !PHX.GetVarBool("phvar_PropCollide") && (entA && entB && ((entA:IsPlayer() && entA:Team() == TEAM_PROPS && entB:IsValid() && entB:GetClass() == "ph_prop") || (entB:IsPlayer() && entB:Team() == TEAM_PROPS && entA:IsValid() && entA:GetClass() == "ph_prop"))) then
		return false
	end
	
	-- Disable hunter on hunter collisions so we can allow bullets through them
	if (IsValid(entA) && IsValid(entB) && (entA:IsPlayer() && entA:Team() == TEAM_HUNTERS && entB:IsPlayer() && entB:Team() == TEAM_HUNTERS)) then
		return false
	end
end
hook.Add("ShouldCollide", "CheckPropCollision", CheckPropCollision)

-- Plugins Section
PHX.PLUGINS = {}

function PHX:InitializePlugin()

	for name,plugin in pairs(list.Get("PHE.Plugins")) do
		self.VerboseMsg("[PHX Plugin] Adding Plugin: "..name)
		self.PLUGINS[name] = plugin
	end
	
	if !table.IsEmpty(self.PLUGINS) then
		for pName,pData in pairs(self.PLUGINS) do
			self.VerboseMsg("[PHX Plugin] Loading Plugin "..pName)
			self.VerboseMsg("--> Loaded Plugins: "..pData.name.."\n--> Version: "..pData.version.."\n--> Info: "..pData.info)
		end
	else
		self.VerboseMsg("[PHX Plugin] No plugins detected, skipping...")
	end
end
hook.Add("PostGamemodeLoaded", "PHX.LoadPlugins", function()
	PHX:InitializePlugin()
end)

if CLIENT then	
	hook.Add("PH_CustomTabMenu", "PHX.NewPlugins", function(tab, pVgui, paintPanelFunc)
	
		local main = {}
	
		main.panel = vgui.Create("DPanel", tab)
		main.panel:Dock(FILL)
		main.panel:SetBackgroundColor(Color(40,40,40,120))
			
		main.scroll = vgui.Create( "DScrollPanel", main.panel )
		main.scroll:Dock(FILL)
		
		main.grid = vgui.Create("DGrid", main.scroll)
		main.grid:SetPos(10,10)
		main.grid:SetSize(tab:GetWide()-20,280)
		main.grid:SetCols(1)
		main.grid:SetColWide(tab:GetWide()-100)
		main.grid:SetRowHeight(300)
		
		if table.IsEmpty(PHX.PLUGINS) then
			if (LocalPlayer():IsSuperAdmin() or LocalPlayer():CheckUserGroup()) then
				local lbl = vgui.Create("DLabel",main.panel)
				lbl:SetPos(40,60)
				lbl:SetText(PHX:FTranslate("PLUGINS_NO_PLUGINS"))
				lbl:SetFont("Trebuchet24")
				lbl:SetTextColor(color_white)
				lbl:SizeToContents()
				
				local but = vgui.Create("DButton",main.panel)
				but:SetPos(40,96)
				but:SetSize(256,40)
				but:SetText(PHX:FTranslate("PLUGINS_BROWSE_MORE"))
				but.DoClick = function() gui.OpenURL("https://prophunt.wolvindra.net/plugins") end
				but:SetIcon("icon16/bricks.png")
			else
				local lbl = vgui.Create("DLabel",main.panel)
				lbl:SetPos(40,60)
				lbl:SetText(PHX:FTranslate("PLUGINS_SERVER_HAS_NO_PLUGINS"))
				lbl:SetFont("Trebuchet24")
				lbl:SetTextColor(color_white)
				lbl:SizeToContents()
			end
		else
			for plName,Data in pairs(PHX.PLUGINS) do
				local section = {}
				section.main = vgui.Create("DPanel",main.grid)
				section.main:SetSize(main.grid:GetWide()-200,main.grid:GetTall())
				section.main:SetBackgroundColor(Color(20,20,20,150))
				
				section.roll = vgui.Create("DScrollPanel",section.main)
				section.roll:SetSize(section.main:GetWide(),section.main:GetTall())
				
				section.grid = vgui.Create("DGrid",section.roll)
				section.grid:SetPos(20,20)
				section.grid:SetSize(section.roll:GetWide()-20,section.roll:GetTall())
				section.grid:SetCols(1)
				section.grid:SetColWide(800)
				section.grid:SetRowHeight(40)
				
				pVgui("","label","Trebuchet24",section.grid, Data.name.."| v."..Data.version )
				pVgui("","label",false,section.grid, "INFO: "..Data.info )
				if (LocalPlayer():IsSuperAdmin() or LocalPlayer():CheckUserGroup()) then
					if !table.IsEmpty(Data.settings) then
						pVgui("","label",false,section.grid, PHX:FTranslate("PLUGINS_SERVER_SETTINGS") )
						for _,val in pairs(Data.settings) do
							pVgui(val[1],val[2],val[3],section.grid,val[4])
						end
					end
				end
				if !table.IsEmpty(Data.client) then
					pVgui("","label",false,section.grid, PHX:FTranslate("PLUGINS_CLIENT_SETTINGS") )
					for _,val in pairs(Data.client) do
						pVgui(val[1],val[2],val[3],section.grid,val[4])
					end
				end				
				main.grid:AddItem(section.main)
			end
		end
	
	local PanelModify = tab:AddSheet("", main.panel, "vgui/ph_iconmenu/m_plugins.png")
	paintPanelFunc(PanelModify, PHX:FTranslate("PHXM_TAB_PLUGINS"))
	
	end)
end
