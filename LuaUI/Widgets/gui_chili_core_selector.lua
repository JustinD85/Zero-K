-------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Core Selector",
    desc      = "v0.6 Manage your boi, idle cons, and factories.",
    author    = "KingRaptor, GoogleFrog",
    date      = "2011-6-2",
    license   = "GNU GPL, v2 or later",
    layer     = 1001,
    enabled   = true,
  }
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

include("Widgets/COFCTools/ExportUtilities.lua")
VFS.Include("LuaRules/Configs/customcmds.h.lua")

Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/unitDefReplacements.lua")
local GetUnitCanBuild = Spring.Utilities.GetUnitCanBuild

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitHealth     = Spring.GetUnitHealth
local spGetFullBuildQueue = Spring.GetFullBuildQueue
local spGetMouseState     = Spring.GetMouseState
local spTraceScreenRay    = Spring.TraceScreenRay

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local BUTTON_COLOR = {nil, nil, nil, 1}
local BUTTON_COLOR_FACTORY = {0.6, 0.6, 0.6, 0.3}
local BUTTON_COLOR_WARNING = {1, 0.2, 0.1, 1}
local BUTTON_COLOR_DISABLED = {0.2,0.2,0.2,1}
local IMAGE_COLOR_DISABLED = {0.3, 0.3, 0.3, 1}

local stateCommands = {	-- FIXME: is there a better way of doing this?
  [CMD_WANT_CLOAK] = true,	-- this is the only one that's really needed, since it can occur without user input (when a temporarily decloaked unit recloaks)
  [CMD.FIRE_STATE] = true,
  [CMD.MOVE_STATE] = true,
  [CMD.ONOFF] = true,
  [CMD.REPEAT] = true,
  [CMD.IDLEMODE] = true,
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Control
local Label
local Window
local Panel
local Image
local Progressbar
local screen0
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local mainWindow, buttonsHolder, background
local conButton = {}	-- {button, image, healthbar/label}

local echo = Spring.Echo

local windowPositionX, windowPositionY

function WG.CoreSelector_SetOptions(maxbuttons)
	options.maxbuttons.value = maxbuttons
	options.maxbuttons.OnChange(options.maxbuttons)
end

-- list and interface vars
local buttonList 

local factoryList = {}
local commanderList = {}

local idleCons = {}	-- [unitID] = true
local wantUpdateCons = false
local readyUntaskedBombers = {}	-- [unitID] = true
local idleConCount = 0
local factoryIndex = 1
local commanderIndex = 1

local buttonCountLimit = 7

local myTeamID = Spring.GetMyTeamID()

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local IMAGE_REPEAT = LUAUI_DIRNAME .. 'Images/repeat.png'
local FACTORY_FRAME = "bitmaps/icons/frame_cons.png"
local BUILD_ICON_ACTIVE = LUAUI_DIRNAME .. 'Images/idlecon.png' --LUAUI_DIRNAME .. 'Images/commands/Bold/build.png'
local BUILD_ICON_DISABLED = LUAUI_DIRNAME .. 'Images/idlecon_bw.png'

local UPDATE_FREQUENCY = 0.25
local COMM_WARNING_TIME	= 2 

local CONSTRUCTOR_ORDER = 1
local COMMANDER_ORDER = 2
local FACTORY_ORDER = 3

local CONSTRUCTOR_BUTTON_ID = "cons"

local exceptionList = {
	armasp = true,
	armcarry = true,
	reef = true,
}

local exceptionArray = {}
for name in pairs(exceptionList) do
	if UnitDefNames[name] then
		exceptionArray[UnitDefNames[name].id] = true
	end
end

local function ClearData(reinitialize) end

local hidden = false
local panelHidden = false
local fancySkinning = false

local function UpdateBackgroundSkin()
	local currentSkin = Chili.theme.skin.general.skinName
	local skin = Chili.SkinHandler.GetSkin(currentSkin)

	local newClass = skin.panel
	if fancySkinning and skin.panel_1100 then
		if panelHidden and skin.panel_0100 then
			newClass = skin.panel_0100
		else
			newClass = skin.panel_1100
		end
	end

	background.tiles = newClass.tiles
	background.TileImageFG = newClass.TileImageFG
	background.backgroundColor = newClass.backgroundColor
	background.TileImageBK = newClass.TileImageBK
	background:Invalidate()
end

local function UpdateBackground(showPanel)
	if showPanel and panelHidden then
		panelHidden = false
		mainWindow:AddChild(buttonsHolder)
		UpdateBackgroundSkin()
		UpdateBackgroundSize()
		
		background:SetVisibility(true)
		buttonsHolder:BringToFront()
		
		mainWindow.padding[3] = -1
		mainWindow:UpdateClientArea()
	elseif not showPanel and not panelHidden then
		panelHidden = true
		mainWindow:RemoveChild(buttonsHolder)
		UpdateBackgroundSkin()
		UpdateBackgroundSize()
		
		background:SetVisibility(WG.IntegralVisible)
		
		mainWindow.padding[3] = 0
		mainWindow:UpdateClientArea()
	end
end

local function CheckHide()
	local spec = Spring.GetSpectatingState()
	local shouldShow, showPanel
	if options.showCoreSelector.value == 'always' then
		showPanel = true
		shouldShow = true
	elseif options.showCoreSelector.value == 'specSpace' then
		showPanel = not spec
		shouldShow = true
	elseif options.showCoreSelector.value == 'specHide' then
		showPanel = true
		shouldShow = not spec
	else
		showPanel = true
		shouldShow = false
	end
	
	if shouldShow and hidden then
		hidden = false
		if not screen0:GetChildByName("selector_window") then
			screen0:AddChild(mainWindow)
		end
	elseif not shouldShow and not hidden then
		hidden = true
		if screen0:GetChildByName("selector_window") then
			screen0:RemoveChild(mainWindow)
		end
	end
	
	UpdateBackground(showPanel)
end

function widget:PlayerChanged()
	CheckHide()
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Widget options

options_path = 'Settings/HUD Panels/Quick Selection Bar'
options_order = {  'showCoreSelector', 'vertical', 'maxbuttons', 'background_opacity', 'monitoridlecomms','monitoridlenano', 'monitorInbuiltCons', 'leftMouseCenter', 'lblSelectionIdle', 'selectprecbomber', 'selectidlecon', 'selectidlecon_all', 'lblSelection', 'selectcomm', 'horPadding', 'vertPadding', 'buttonSpacing', 'minButtonSpaces', 'specSpaceOverride', 'fancySkinning'}
options = { 
	showCoreSelector = {
		name = 'Selection Bar Visibility',
		type = 'radioButton',
		value = 'specHide',
		items = {
			{key = 'always',    name = 'Always enabled'},
			{key = 'specSpace', name = 'Only keep space when spectating'},
			{key = 'specHide',  name = 'Hide when spectating'},
			{key = 'never',     name = 'Always disabled'},
		},
		OnChange = CheckHide,
		noHotkey = true,
	},
	vertical = {
		name = 'Vertical Bar',
		type = 'bool',
		value = false,
		noHotkey = true,
	},
	maxbuttons = {
		name = 'Maximum number of buttons (3-16)',
		type = 'number',
		value = 6,
		min=3,max=16,step=1,
	},
	background_opacity = {
		name = "Opacity",
		type = "number",
		value = 0, min = 0, max = 1, step = 0.01,
	},
	monitoridlecomms = {
		name = 'Track idle comms',
		type = 'bool',
		value = true,
		noHotkey = true,	
	},
	monitoridlenano = {
		name = 'Track idle nanotowers',
		type = 'bool',
		value = true,
		noHotkey = true,	
	},
	monitorInbuiltCons = {
		name = 'Track constructors being built',
		type = 'bool',
		value = false,
		noHotkey = true,	
	},
	leftMouseCenter = {
		name = 'Swap Camera Center Button',
		desc = 'When enabled left click a commander or factory to center the camera on it. When disabled right click centers.',
		type = 'bool',
		value = false,		
		noHotkey = true,
	},
	lblSelectionIdle = { type='label', name='Idle Units', path='Game/Selection Hotkeys', },
	selectprecbomber = { type = 'button',
		name = 'Select idle precision bomber',
		desc = 'Selects an idle, armed precision bomber. Use multiple times to select more. Deselects any units which are not idle, armed precision bombers.',
		action = 'selectprecbomber',
		path = 'Game/Selection Hotkeys',
		dontRegisterAction = true,
	},
	selectidlecon = { type = 'button',
		name = 'Select idle constructor',
		desc = 'Selects an idle constructor. Use multiple times to select more. Deselects any units which are not idle constructors.',
		action = 'selectidlecon',
		path = 'Game/Selection Hotkeys',
		dontRegisterAction = true,
	},
	selectidlecon_all = { type = 'button',
		name = 'Select all idle constructors',
		action = 'selectidlecon_all',
		path = 'Game/Selection Hotkeys',
		dontRegisterAction = true,
	},
	lblSelection = { type='label', name='Commander', path='Game/Selection Hotkeys', },
	selectcomm = { type = 'button',
		name = 'Select Commander',
		action = 'selectcomm',
		path = 'Game/Selection Hotkeys',
		dontRegisterAction = true,
	},
	horPadding = {
		name = 'Horizontal Padding',
		type = 'number',
		value = 0,
		advanced = true,
		min = 0, max = 100, step = 0.25,
	},
	vertPadding = {
		name = 'Vertical Padding',
		type = 'number',
		value = 0,
		advanced = true,
		min = 0, max = 100, step = 0.25,
	},
	buttonSpacing = {
		name = 'Button Spacing',
		type = 'number',
		value = 0,
		advanced = true,
		min = 0, max = 100, step = 0.25,
	},
	minButtonSpaces = {  
		name = 'Minimum Button Space',
		type = 'number',
		value = 0,
		advanced = true,
		min = 0, max = 16, step=1,
	},
	specSpaceOverride = {
		name = 'Spectating Space Override',
		desc = 'Size of the spacer which is present while spectating with "Only keep space when spectating".',
		type = 'number',
		value = 50,
		advanced = true,
		min = 0, max = 400, step = 1,
	},
	fancySkinning = {
		name = 'Fancy Skinning',
		type = 'bool',
		value = false,
		advanced = true,
		noHotkey = true,
		OnChange = function (self)
			fancySkinning = self.value
			UpdateBackgroundSkin()
		end
	}
}


local standardFactoryTooltip =  "\n\255\0\255\0" .. WG.Translate("interface", "lmb") .. ": " .. (options.leftMouseCenter.value and WG.Translate("interface", "select_and_go_to") or WG.Translate("interface", "select")) .. "\n" .. WG.Translate("interface", "rmb") .. ": " .. ((not options.leftMouseCenter.value) and WG.Translate("interface", "select_and_go_to") or WG.Translate("interface", "select")) .. "\n" .. WG.Translate("interface", "shift") .. ": " .. WG.Translate("interface", "append_to_current_selection") .. "\008"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Selection Functions

-- comm selection functionality
local commIndex = 1
local function SelectComm()
	local commCount = #commanderList
	if commCount <= 0 then 
		return 
	end
	
	-- This check deals with the case of spectators selecting
	-- teams with different numbers of commanders.
	if commCount < commIndex then
		commIndex = commCount
	end
	
	local unitID
	-- Loop long enough to check every commander.
	-- The most recently Ctrl+C selected commander is checked last.
	-- Select the first non-selected commander encountered.
	for i = 1, commCount do
		unitID = commanderList[commIndex].unitID
		commIndex = commIndex + 1
		if commIndex > commCount then
			commIndex = 1
		end
		if not Spring.IsUnitSelected(unitID) then
			break
		end
	end
	
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	Spring.SelectUnitArray({unitID}, shift)
	if not shift then
		local x, y, z = Spring.GetUnitPosition(unitID)
		SetCameraTarget(x, y, z)
	end
end

local mapMiddle = {Game.mapSizeX / 2, 0, Game.mapSizeZ / 2}
local function SelectPrecBomber()

	-- Check to see if anything other than a ready bomber is selected
	--	If not, then we'll increment the number of ready bombers selected
	--	If so, then we'll either:
	--		Select one ready bomber if none are selected
	--		Select only the already selected ready bombers if at least one is selected	
	
	local toBeSelected = {}
	
	local currentSelection = Spring.GetSelectedUnits()
	local isAnythingElseSelected = nil
	for i,uid in ipairs(currentSelection) do
		if not readyUntaskedBombers[uid] then
			isAnythingElseSelected = true
			break
		end
	end
	
	local mx,my = spGetMouseState()
	local pos = select(2, spTraceScreenRay(mx,my,true)) or mapMiddle
	local mindist = math.huge
	local muid = nil

	for uid, v in pairs(readyUntaskedBombers) do
		if (Spring.IsUnitSelected(uid)) then
			table.insert(toBeSelected,uid)
		else
			local x,_,z = spGetUnitPosition(uid)
			dist = (pos[1]-x)*(pos[1]-x) + (pos[3]-z)*(pos[3]-z)
			if (dist < mindist) then
				mindist = dist
				muid = uid
			end
		end
	end
	if (muid ~= nil) and (not isAnythingElseSelected or #toBeSelected == 0) then
		table.insert(toBeSelected,muid)
	end
	Spring.SelectUnitArray(toBeSelected)
end

local function SelectIdleCon_all()
	Spring.SelectUnitMap(idleCons, select(4, Spring.GetModKeyState()))
end

local conIndex = 1
local function SelectIdleCon()
	local shift = select(4, Spring.GetModKeyState())
	if shift then
		local mx,my = spGetMouseState()
		local pos = select(2, spTraceScreenRay(mx,my,true)) or mapMiddle
		local mindist = math.huge
		local muid = nil

		for uid, v in pairs(idleCons) do
			if uid ~= "count" then
				if (not Spring.IsUnitSelected(uid)) then
					local x,_,z = spGetUnitPosition(uid)
					dist = (pos[1]-x)*(pos[1]-x) + (pos[3]-z)*(pos[3]-z)
					if (dist < mindist) then
						mindist = dist
						muid = uid
					end
				end
			end
		end

		Spring.SelectUnitArray({muid}, true)
	else
		if idleConCount == 0 then
			Spring.SelectUnitArray({})
		else
			conIndex = (conIndex % idleConCount) + 1
			local i = 1
			for uid, v in pairs(idleCons) do
				if uid ~= "count" then
					if i == conIndex then
						Spring.SelectUnitArray({uid})
						SetCameraTarget(Spring.GetUnitPosition(uid))
						return
					else
						i = i + 1
					end
				end
			end
		end
	end
end


local function SelectFactory(index)
	if factoryList[index] then
		factoryList[index].SelectUnit()
	end
end

local SELECT_FACTORY = "epic_chili_core_selector_select_factory_"

-- Factory hotkeys
local hotkeyPath = 'Settings/HUD Panels/Quick Selection Bar/Hotkeys'
for i = 1, 16 do
	local optionName = "select_factory_" .. i
	options_order[#options_order + 1] = optionName
	options[optionName] = {
		name = "Select Factory " .. i,
		desc = "Selects the factory in position " .. i .. " of the selection bar.",
		type = 'button',
		path = hotkeyPath,
		OnChange = function()
			SelectFactory(i)
		end
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Helper Functions

local function GetHealthColor(fraction, wantString)
	local midpt = (fraction > 0.5)
	local r, g
	if midpt then 
		r = ((1 - fraction)/0.5)
		g = 1
	else
		r = 1
		g = (fraction)/0.5
	end
	if wantString then
		return string.char(255,math.floor(255*r),math.floor(255*g),0)
	else
		return {r, g, 0, 1}
	end
end

local function GetButtonPosition(index)
	index = index - 1
	if options.vertical.value then
		return 0, index*60, 60, 60
	else
		return index*60, 0, 60, 60
	end
end

function UpdateBackgroundSize()
	if options.background_opacity.value == 0 or not background then
		return
	end
	
	local sizeOverride
	if panelHidden then
		sizeOverride = options.specSpaceOverride.value
	end
	
	local buttons = math.max(options.minButtonSpaces.value, 3 + 1)
	local sideSpacing = 2*((options.vertical.value and options.vertPadding.value) or options.horPadding.value)
	local buttonSpace = buttons/options.maxbuttons.value
	
	if options.vertical.value then
		buttonSpace = buttonSpace*buttonsHolder.height
		
		local top = mainWindow.height - (sizeOverride or (buttonSpace + sideSpacing))
		top = math.max(top, 0)
		
		background._relativeBounds.top = top
		background._relativeBounds.bottom = 0
		background:UpdateClientArea()
	else
		buttonSpace = buttonSpace*buttonsHolder.width
		
		local right = buttonSpace + (sizeOverride or sideSpacing)
		right = math.max(right, 0)
		
		background._relativeBounds.right = right
		background._relativeBounds.left = 0
		background:UpdateClientArea()
	end
end

function options.background_opacity.OnChange(self)
	background.backgroundColor[4] = self.value
	background:Invalidate()
	UpdateBackgroundSize()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Button Handling

local function GetNewButton(parent, onClick, category, index, backgroundColor, imageFile, imageFile2)
	local hPad = ((not options.vertical.value) and options.buttonSpacing.value) or 0
	local vPad = (options.vertical.value and options.buttonSpacing.value) or 0
	
	local position = 1
	local bX, bY, bWidth, bHeight = GetButtonPosition(position)
	
	local hotkeyLabel, buildProgress, repeatImage, healthBar, hotkeyText, bottomLabel
	
	-- Controls
	local button = Button:New{
		parent = parent,
		x = bX,
		y = bY,
		width = bWidth,
		height = bHeight,
		caption = '',
		padding = {1,1,1,1},
		backgroundColor = backgroundColor,
		OnClick = {	
			function (self, x, y, mouse)
				local _, _, meta, shift = Spring.GetModKeyState()
				if meta then
					WG.crude.OpenPath(options_path)
					WG.crude.ShowMenu()
					return true
				end
				onClick(mouse)
			end
		},
	}
	
	local image = Image:New {
		parent = button,
		x = "5%",
		y = "5%",
		right = "5%",
		bottom = "5%",
		file = imageFile,
		file2 = imageFile2,
		keepAspect = false,
	}
	
	local externalFunctions = {}
	
	-- Update attributes
	function externalFunctions.SetImage(newImageFile)
		image.file = newImageFile
		image:Invalidate()
	end
	
	function externalFunctions.SetImageColor(color)
		image.color = color
		image:Invalidate()
	end
	
	function externalFunctions.SetBackgroundColor(newBackgroundColor)
		button.backgroundColor = newBackgroundColor
		button:Invalidate()
	end
	
	function externalFunctions.SetProgress(newProgress)
		if not buildProgress then
			buildProgress = Progressbar:New{
				x = "8%",
				y = "8%",
				width = "85%",
				height = "85%",
				max = 1,
				caption = "",
				skin = nil,
				skinName = 'default',
				color = {0.7, 0.7, 0.4, 0.6},
				backgroundColor = {1, 1, 1, 0.01},
				parent = image,	
			}	
		end
		buildProgress:SetValue(newProgress)
	end
	
	function externalFunctions.SetRepeat(newRepeat)
		if not repeatImage then
			repeatImage = Image:New {
				x = "55%",
				y = "10%",
				width = "40%",
				height = "40%",
				file = IMAGE_REPEAT,
				keepAspect = true,
				parent = image,	
			}
		end
		repeatImage.file = (newRepeat and IMAGE_REPEAT) or nil
		repeatImage:Invalidate()
	end
	
	function externalFunctions.SetHealthbar(newHealth)
		if not newHealth then
			if healthBar then
				healthBar:SetVisibility(false)
			end
			return
		end
		local color = GetHealthColor(newHealth)
		if not healthBar then
			healthBar = Progressbar:New{
				x       = 0,
				y       = "85%",
				width   = "100%",
				height  = "15%",
				max     = 1,
				caption = "",
				color   = {0,0.8,0,1},
				parent  = image,
			}
		end
		healthBar:SetVisibility(true)
		healthBar.color = color
		healthBar:SetValue(newHealth)
	end

	function externalFunctions.SetTooltip(newTooltip)
		button.tooltip = newTooltip
		button:Invalidate()
	end

	function externalFunctions.SetHotkey(newHotkeyText)
		if newHotkeyText == hotkeyText then
			return
		end
		hotkeyText = newHotkeyText
		if not hotkeyLabel then
			hotkeyLabel = Label:New {
				x = 2,
				y = 3,
				right = 0,
				bottom = 0,
				autosize = false,
				align = "left",
				valign = "top",
				caption = '\255\0\255\0' .. hotkeyText,
				fontSize = 11,
				fontShadow = true,
				parent = button
			}
			hotkeyLabel:BringToFront()
		end
		hotkeyLabel:SetCaption('\255\0\255\0' .. hotkeyText)
	end
	
	function externalFunctions.SetBottomLabel(caption)
		if not bottomLabel then
			bottomLabel = Label:New {
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
				align = "right",
				valign = "bottom",
				caption = caption,
				fontSize = 16,
				autosize = false,
				fontShadow = true,
				parent = image,
			}
		end
		bottomLabel:SetCaption(caption)
	end
	
	-- Movement
	function externalFunctions.GetPosition()
		return position
	end
	
	function externalFunctions.SetPosition(newPosition)
		position = newPosition
		if position > buttonCountLimit then
			button:SetVisibility(false)
			return
		end
		button:SetVisibility(true)
		bX, bY, bWidth, bHeight = GetButtonPosition(position)
		button:SetPos(bX, bY, bWidth, bHeight)
	end
	
	function externalFunctions.MoveUp(compCategory, compIndex)
		if compCategory < category or (compCategory == category and compIndex < index) then
			externalFunctions.SetPosition(position + 1)
			return true 
		else
			return false -- Button did not move
		end
	end
	
	function externalFunctions.MoveDown(compCategory, compIndex)
		if compCategory < category or (compCategory == category and compIndex < index) then
			externalFunctions.SetPosition(position - 1)
			return true -- Button moved
		else
			return false -- Button did not move
		end
	end
	
	function externalFunctions.GetOrder()
		return category, index
	end
	
	-- Desctruction
	function externalFunctions.Destroy()
		button:Dispose()
		button = nil
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Factory Handling

local function GetFactoryButton(parent, unitID, unitDefID, categoryOrder)
	
	local function OnClick(mouse)
		Spring.SelectUnitArray({unitID}, shift)
		if mouse == ((options.leftMouseCenter.value and 1) or 3) then
			local x, y, z = Spring.GetUnitPosition(unitID)
			SetCameraTarget(x, y, z)
		end
	end
	
	local constructionDefID
	local buildProgress
	local repeatState
	
	local button = GetNewButton(
		parent,
		OnClick, 
		FACTORY_ORDER,
		categoryOrder,
		BUTTON_COLOR_FACTORY, 
		'#' .. unitDefID, 
		FACTORY_FRAME
	)
	
	local function UpdateConstruction(newConstructionDefID)
		if newConstructionDefID == constructionDefID then
			return
		end
		constructionDefID = newConstructionDefID
		button.SetImage('#' .. (constructionDefID or unitDefID))
	end
	
	local function UpdateBuildProgress(newBuildProgress)
		if newBuildProgress == buildProgress then
			return
		end
		buildProgress = newBuildProgress
		button.SetProgress(buildProgress)
	end
	
	local function UpdateRepeat(newRepeat)
		if newRepeat == repeatState then
			return
		end
		repeatState = newRepeat
		button.SetRepeat(repeatState)
	end
	
	local function UpdateTooltip(constructionCount)
		local tooltip = WG.Translate("interface", "factory") .. ": ".. Spring.Utilities.GetHumanName(UnitDefs[unitDefID]) .. "\n" .. WG.Translate("interface", "x_units_in_queue", {count = constructionCount})
		if repeatState then
			tooltip = tooltip .. "\255\0\255\255 (" .. WG.Translate("interface", "repeating") .. ")\008"
		end
		if constructionDefID then
			tooltip = tooltip .. "\n" .. WG.Translate("interface", "current_project") .. ": " .. Spring.Utilities.GetHumanName(UnitDefs[constructionDefID]) .." (".. WG.Translate("interface", "x%_done", {x = math.floor(buildProgress*100)}) .. ")"
		end
		tooltip = tooltip .. standardFactoryTooltip
		
		button.SetTooltip(tooltip)
	end
	
	local externalFunctions = {
		unitID = unitID,
		GetOrder = button.GetOrder,
	}
	
	function externalFunctions.UpdateButton()
		if not Spring.ValidUnitID(unitID) then
			return false
		end
		
		-- Update progress and construction
		local buildeeID = Spring.GetUnitIsBuilding(unitID)
		if buildeeID then
			local progress = select(5, Spring.GetUnitHealth(buildeeID))
			local buildeeDefID = Spring.GetUnitDefID(buildeeID)
			UpdateConstruction(buildeeDefID)
			UpdateBuildProgress(progress)
		else
			UpdateConstruction()
			UpdateBuildProgress(0)
		end
		
		-- Update repeat
		local states = Spring.GetUnitStates(unitID)
		UpdateRepeat(states and states["repeat"])
		
		-- Update tooltip
		local queue = Spring.GetFullBuildQueue(unitID) or {}
		local constructionCount = 0
		for i = 1, #queue do
			for udid, num in pairs(queue[i]) do
				constructionCount = constructionCount + num
				break
			end
		end
		
		UpdateTooltip(constructionCount)
		return true
	end
	
	function externalFunctions.UpdateHotkey()
		local factoryPos = button.GetPosition() - (#commanderList + 1)
		button.SetHotkey(WG.crude.GetHotkey(SELECT_FACTORY .. factoryPos) or '')
	end
	
	function externalFunctions.SetPosition(position)
		button.SetPosition(position)
		externalFunctions.UpdateHotkey()
	end
	
	function externalFunctions.MoveUp(category, index)
		local moved = button.MoveUp(category, index)
		if moved then
			externalFunctions.UpdateHotkey()
		end
		return moved
	end
	
	function externalFunctions.MoveDown(category, index)
		local moved = button.MoveDown(category, index)
		if moved then
			externalFunctions.UpdateHotkey()
		end
		return moved
	end
	
	function externalFunctions.SelectUnit()
		OnClick()
	end
	
	function externalFunctions.Destroy()
		button.Destroy()
		button = nil
	end
	
	externalFunctions.UpdateButton()
	externalFunctions.UpdateHotkey()
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Commander Handling

local function GetCommanderButton(parent, unitID, unitDefID, categoryOrder)

	local function OnClick(mouse)
		Spring.SelectUnitArray({unitID}, shift)
		if mouse == ((options.leftMouseCenter.value and 1) or 3) then
			local x, y, z = Spring.GetUnitPosition(unitID)
			SetCameraTarget(x, y, z)
		end
	end
	
	local healthProp, health, maxHealth = 1, 1, 1
	local warningTime = false
	local warningPhase = true
	
	local button = GetNewButton(
		parent, 
		OnClick, 
		COMMANDER_ORDER,
		categoryOrder,
		BUTTON_COLOR, 
		'#' .. unitDefID
	)
	
	local function UpdateHealth(newHealthProp)
		if newHealthProp == healthProp then
			return
		end
		healthProp = newHealthProp
		button.SetHealthbar(healthProp ~= 1 and healthProp)
	end
	
	local function UpdateTooltip(constructionCount)
		local tooltip = WG.Translate("interface", "commander") .. ": " .. Spring.Utilities.GetHumanName(UnitDefs[unitDefID], unitID) ..
			"\n\255\0\255\255" .. WG.Translate("interface", "health") .. ":\008 "..GetHealthColor(health/maxHealth, true)..math.floor(health).."/"..maxHealth.."\008"..
			"\n\255\0\255\0" .. WG.Translate("interface", "lmb") .. ": " .. (options.leftMouseCenter.value and WG.Translate("interface", "select_and_go_to") or WG.Translate("interface", "select")) ..
			"\n" .. WG.Translate("interface", "rmb") .. ": " .. ((not options.leftMouseCenter.value) and WG.Translate("interface", "select_and_go_to") or WG.Translate("interface", "select")) ..
			"\n" .. WG.Translate("interface", "shift") .. ": " .. WG.Translate("interface", "append_to_current_selection") .. "\008"
	
		button.SetTooltip(tooltip)
	end
	
	local externalFunctions = {
		unitID = unitID,
		SetPosition = button.SetPosition,
		MoveUp = button.MoveUp,
		MoveDown = button.MoveDown,
		GetOrder = button.GetOrder,
	}
	
	function externalFunctions.UpdateButton(dt)
		if not Spring.ValidUnitID(unitID) then
			return false
		end
		
		health, maxHealth = spGetUnitHealth(unitID)
		if not health then
			return false
		end
		UpdateHealth(health/maxHealth)
		
		if warningTime then
			warningTime = warningTime - dt
			if warningTime <= 0 then
				warningTime = false
				warningPhase = false
			else
				warningPhase = not warningPhase
			end
			
			button.SetBackgroundColor((warningPhase and BUTTON_COLOR_WARNING) or BUTTON_COLOR)
		end
		
		UpdateTooltip(constructionCount)
		return true
	end
	
	function externalFunctions.UpdateHotkey()
		button.SetHotkey(WG.crude.GetHotkey("selectcomm") or '')
	end
	
	function externalFunctions.SetWarning(newWarningTime)
		warningTime = newWarningTime
	end
	
	function externalFunctions.Destroy()
		button.Destroy()
		button = nil
	end
	
	externalFunctions.UpdateButton(0)
	externalFunctions.UpdateHotkey()
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Constructor Handling

local function GetConstructorButton(parent)

	local function OnClick(mouse)
		if mouse == 1 then
			SelectIdleCon()
		elseif mouse == 3 and idleConCount > 0 then
			SelectIdleCon_all()
		end
	end
	
	local active = true
	
	local button = GetNewButton(
		parent, 
		OnClick, 
		CONSTRUCTOR_ORDER,
		0,
		BUTTON_COLOR, 
		BUILD_ICON_ACTIVE
	)
	
	local function SetActive(newActive)
		if newActive == active then
			return
		end
		active = newActive
		button.SetImage((active and BUILD_ICON_ACTIVE) or BUILD_ICON_DISABLED)
		button.SetImageColor(((not active) and IMAGE_COLOR_DISABLED) or nil)
		button.SetBackgroundColor((active and BUTTON_COLOR) or BUTTON_COLOR_DISABLED)
	end
	
	local externalFunctions = {
		SetPosition = button.SetPosition,
		MoveUp = button.MoveUp,
		MoveDown = button.MoveDown,
		GetOrder = button.GetOrder,
	}
	
	function externalFunctions.UpdateButton()
		local total = 0
		for unitID in pairs(idleCons) do
			total = total + 1
		end
		idleConCount = total

		button.SetTooltip(WG.Translate("interface", "idle_cons", {count = total}) ..
						"\n\255\0\255\0" .. WG.Translate("interface", "lmb") .. ": " .. WG.Translate("interface", "select") ..
						"\n" .. WG.Translate("interface", "rmb") .. ": " .. WG.Translate("interface", "select_all") .. "\008")

		SetActive(total > 0)
		button.SetBottomLabel(tostring(total))
		
		return true
	end
	
	function externalFunctions.UpdateHotkey()
		local hotkeyCaption
		if WG.crude.GetHotkey("selectidlecon") and WG.crude.GetHotkey("selectidlecon_all") then
			hotkeyCaption = WG.crude.GetHotkey("selectidlecon") .. "\n" .. WG.crude.GetHotkey("selectidlecon_all")
		else
			hotkeyCaption = (WG.crude.GetHotkey("selectidlecon") or WG.crude.GetHotkey("selectidlecon_all") or '')
		end
		button.SetHotkey(hotkeyCaption)
	end
	
	function externalFunctions.Destroy()
		button.Destroy()
		button = nil
	end
	
	externalFunctions.UpdateButton()
	externalFunctions.UpdateHotkey()
	
	return externalFunctions
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Unit List Handler

local function GetButtonListHandler()

	local buttons = {}
	local buttonMap = {}
	local buttonList = {}
	local buttonCount = 0

	local externalFunctions = {}
	
	function externalFunctions.GetButton(buttonID)
		return buttonID and buttons[buttonID]
	end
	
	function externalFunctions.MoveDown(category, index)
		for i = 1, buttonCount do
			local button = buttons[buttonList[i]]
			button.MoveDown(category, index)
		end
	end
	
	function externalFunctions.RemoveButton(buttonID)
		if not externalFunctions.GetButton(buttonID) then
			return
		end
		local category, index = buttons[buttonID].GetOrder()
		buttons[buttonID].Destroy()
		buttons[buttonID] = nil
		
		buttonList[buttonMap[buttonID]] = buttonList[buttonCount]
		buttonMap[buttonList[buttonCount]] = buttonMap[buttonID]
		buttonMap[buttonID] = nil
		buttonList[buttonCount] = nil
		buttonCount = buttonCount - 1
		
		externalFunctions.MoveDown(category, index)
	end
		
	function externalFunctions.MoveUp(category, index)
		local position = 1
		local i = 1
		while i <= buttonCount do
			local buttonID = buttonList[i]
			local button = buttons[buttonID]
			local moved, toRemove = button.MoveUp(category, index)
			if not moved then
				position = position + 1
			end
			if toRemove then
				externalFunctions.RemoveButton(buttonID)
			else
				i = i + 1
			end
		end
		return position
	end
	
	function externalFunctions.AddButton(buttonID, button)
		buttons[buttonID] = button
		
		local category, index = button.GetOrder()
		local position = externalFunctions.MoveUp(category, index)
		button.SetPosition(position)
		
		buttonCount = buttonCount + 1
		buttonList[buttonCount] = buttonID
		buttonMap[buttonID] = buttonCount
	end
	
	function externalFunctions.UpdateButtons(dt)
		local i = 1
		while i <= buttonCount do
			local buttonID = buttonList[i]
			if buttons[buttonID].UpdateButton(dt) then
				i = i + 1
			else
				externalFunctions.RemoveButton(buttonID)
			end
		end
	end
	
	function externalFunctions.Destroy()
		for i = 1, buttonCount do
			local buttonID = buttonList[i]
			buttons[buttonID].Destroy()
		end
	end
	
	return externalFunctions
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Factory and Commander Handling

local function AddComm(unitID, unitDefID)
	if buttonList.GetButton(unitID) then
		return
	end
	
	local button = GetCommanderButton(buttonsHolder, unitID, unitDefID, commanderIndex)
	commanderIndex = commanderIndex + 1
	
	commanderList[#commanderList + 1] = button
	
	buttonList.AddButton(unitID, button)
end

local function RemoveComm(unitID)
	local i = 1
	local removing = false
	local commCount = #commanderList
	for i = 1, commCount do
		if removing then
			commanderList[i - 1] = commanderList[i]
		elseif commanderList[i].unitID == unitID then
			removing = true
		end
	end
	if removing then
		commanderList[commCount] = nil
	end

	buttonList.RemoveButton(unitID)
end

local function AddFac(unitID, unitDefID)
	if buttonList.GetButton(unitID) then
		return
	end
	
	local button = GetFactoryButton(buttonsHolder, unitID, unitDefID, factoryIndex)
	factoryIndex = factoryIndex + 1
	
	factoryList[#factoryList + 1] = button
	
	buttonList.AddButton(unitID, button)
end

local function RemoveFac(unitID)
	local i = 1
	local removing = false
	local facCount = #factoryList
	for i = 1, facCount do
		if removing then
			factoryList[i - 1] = factoryList[i]
		elseif factoryList[i].unitID == unitID then
			removing = true
		end
	end
	if removing then
		factoryList[facCount] = nil
	end
	
	buttonList.RemoveButton(unitID)
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Constructor Handling

local function RefreshConsList()
	idleCons = {}
	if Spring.GetGameFrame() > 1 and myTeamID then
		local buttonList = Spring.GetTeamUnits(myTeamID)
		for _,unitID in pairs(buttonList) do
			local unitDefID = spGetUnitDefID(unitID)
			if unitDefID then
				widget:UnitFinished(unitID, unitDefID, myTeamID)
			end
		end
	end
end

options.monitoridlecomms.OnChange = RefreshConsList
options.monitoridlenano.OnChange = RefreshConsList
options.monitorInbuiltCons.OnChange = RefreshConsList

-- Check current cmdID and the queue for a double-wait
local function HasDoubleCommand(unitID, cmdID)
	if cmdID == CMD.WAIT or cmdID == CMD.SELFD then
		local cmdsLen = Spring.GetCommandQueue(unitID,0)
		if cmdsLen == 0 then -- Occurs in the case of SELFD
			return true
		elseif cmdsLen == 1 then
			local cmds = Spring.GetCommandQueue(unitID,1)
			return cmds[1].id == CMD.WAIT
		end
	end
	return false
end

-- Check the queue for an attack command
local function isAttackQueued(unitID)
	local cmdsLen = Spring.GetCommandQueue(unitID,0)
	if cmdsLen and (cmdsLen > 0) then
		local cmds = Spring.GetCommandQueue(unitID,-1)
		for i = 1,cmdsLen do
			if cmds and cmds[i] and ((cmds[i].id == CMD.ATTACK) or (cmds[i].id == CMD.AREA_ATTACK)) then
				return true
			end
		end
	end
	return false
end

-- Check to see if the bomber is ready and untasked
local function setBomberReadyStatus(unitID)
	local noAmmo = spGetUnitRulesParam(unitID, "noammo")
	if (noAmmo and noAmmo ~= 0) or select(3, Spring.GetUnitIsStunned(unitID)) or isAttackQueued(unitID) then
		readyUntaskedBombers[unitID] = nil
	else
		readyUntaskedBombers[unitID] = true
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Initialization

local function InitializeUnits()
	if Spring.GetGameFrame() > 1 and myTeamID then
		local buttonList = Spring.GetTeamUnits(myTeamID)
		for _,unitID in pairs(buttonList) do
			local unitDefID = spGetUnitDefID(unitID)
			--Spring.Echo(unitID, unitDefID)
			if unitDefID then
				widget:UnitCreated(unitID, unitDefID, myTeamID)
				widget:UnitFinished(unitID, unitDefID, myTeamID)
			end
		end
	end
end

local function InitializeControls()
	-- Set the size for the default settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local BUTTON_WIDTH = math.min(60, screenHeight/16)
	local BUTTON_HEIGHT = 55*BUTTON_WIDTH/60
	local integralWidth = math.max(350, math.min(450, screenWidth*screenHeight*0.0004))
	local integralHeight = math.min(screenHeight/4.5, 200*integralWidth/450)
	local bottom = integralHeight
	
	local hPad = options.horPadding.value
	local vPad = options.vertPadding.value
	
	local windowY = bottom - BUTTON_HEIGHT * ((options.vertical.value and options.maxbuttons.value) or 1) + 2*vPad
	
	local windowWidth, windowHeight
	if options.vertical.value then
		windowWidth  = BUTTON_WIDTH + 2*hPad
		windowHeight = (BUTTON_HEIGHT + 2*options.buttonSpacing.value) * options.maxbuttons.value + 2*vPad
	else
		windowWidth  = (BUTTON_WIDTH + 2*options.buttonSpacing.value) * options.maxbuttons.value + 2*hPad
		windowHeight = BUTTON_HEIGHT + 2*vPad
	end
	windowHeight = math.ceil(windowHeight)
	
	local specChanges = Spring.GetSpectatingState() and options.showCoreSelector.value == 'specSpace'
	
	mainWindow = Window:New{
		padding = {-1, 0, (specChanges and 0) or -1, -1},
		itemMargin = {0, 0, 0, 0},
		dockable = true,
		name = "selector_window",
		x = windowPositionX or 0, 
		y = windowPositionY or windowY,
		width  = windowWidth,
		height = windowHeight,
		parent = Chili.Screen0,
		draggable = false,
		tweakDraggable = true,
		tweakResizable = true,
		resizable = false,
		dragUseGrip = false,
		minWidth = 32,
		minHeight = 32,
		color = {0,0,0,0},
		OnClick={ function(self)
			local alt, ctrl, meta, shift = Spring.GetModKeyState()
			if not meta then return false end
			WG.crude.OpenPath(options_path)
			WG.crude.ShowMenu()
			return true
		end },
	}	
	
	buttonsHolder = Control:New{
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {hPad, vPad, hPad, vPad},
		itemMargin = {0, 0, 0, 0},
		OnResize = {
			UpdateBackgroundSize,
			UpdateButtonPositions
		},
		parent = mainWindow,
	}
	background = Panel:New{
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		backgroundColor = {1, 1, 1, options.background_opacity.value},
		parent = mainWindow,
	}
	
	buttonList = GetButtonListHandler()
	buttonList.AddButton(CONSTRUCTOR_BUTTON_ID, GetConstructorButton(buttonsHolder))
	
	
	if options.fancySkinning.value then
		options.fancySkinning.OnChange(options.fancySkinning)
	end
	
	InitializeUnits()
	
	hidden = false
	CheckHide()
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- External functions

local externalFunctions = {}

function externalFunctions.SetSpecSpaceVisible(newVisible)
	if panelHidden and background then
		background:SetVisibility(newVisible)
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Callins

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if (not myTeamID or unitTeam ~= myTeamID) then
		return
	end
	local ud = UnitDefs[unitDefID]
	
	if ud.isFactory and (not exceptionArray[unitDefID]) then
		AddFac(unitID, unitDefID)
	elseif ud.customParams.level then
		AddComm(unitID, unitDefID)
	elseif options.monitorInbuiltCons.value and (
			(ud.buildSpeed > 0) and (not exceptionArray[unitDefID]) and (not ud.isFactory) and 
			(options.monitoridlecomms.value or not ud.customParams.dynamic_comm) and 
			(options.monitoridlenano.value or ud.canMove)
		) then
		idleCons[unitID] = true
		wantUpdateCons = true
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if (not myTeamID or unitTeam ~= myTeamID) or exceptionArray[unitDefID] then
		return
	end
	local ud = UnitDefs[unitDefID]
	if GetUnitCanBuild(unitID, unitDefID) then  --- can build
		local bQueue = spGetFullBuildQueue(unitID)
		if not bQueue[1] then  --- has no build queue
			local _, _, _, _, buildProg = spGetUnitHealth(unitID)
			if not ud.isFactory then
				local cQueue = Spring.GetCommandQueue(unitID, 1)
				--Spring.Echo("Con "..unitID.." queue "..tostring(cQueue[1]))
				if not cQueue[1] then
					--Spring.Echo("\tCon "..unitID.." must be idle")
					widget:UnitIdle(unitID, unitDefID, myTeamID)
				end
			end
		end
	end
	local unitName = UnitDefs[unitDefID].name
	if (unitName == "corshad") then
		setBomberReadyStatus(unitID)
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  widget:UnitCreated(unitID, unitDefID, unitTeam)
  widget:UnitFinished(unitID, unitDefID, unitTeam)  
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (not myTeamID or unitTeam ~= myTeamID) then
		return
	end
	if idleCons[unitID] then
		idleCons[unitID] = nil
		wantUpdateCons = true
	end	
	if readyUntaskedBombers[unitID] then
		readyUntaskedBombers[unitID] = nil
	end	
	
	local ud = UnitDefs[unitDefID]
	if ud.isFactory and (not exceptionArray[unitDefID]) then
		RemoveFac(unitID)
	elseif ud.customParams.level then
		RemoveComm(unitID)
	end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  widget:UnitDestroyed(unitID, unitDefID, unitTeam)
end

function widget:UnitIdle(unitID, unitDefID, unitTeam)
	if (unitTeam ~= myTeamID) then
		return
	end
	local ud = UnitDefs[unitDefID]
	if (ud.buildSpeed > 0) and (not exceptionArray[unitDefID]) and (not UnitDefs[unitDefID].isFactory)
	and (options.monitoridlecomms.value or not UnitDefs[unitDefID].customParams.dynamic_comm)
	and (options.monitoridlenano.value or UnitDefs[unitDefID].canMove) then
		idleCons[unitID] = true
		wantUpdateCons = true
	end
	local unitName = UnitDefs[unitDefID].name
	if (unitName == "corshad") then
		setBomberReadyStatus(unitID)
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOpts, cmdParams)
	if (not myTeamID or unitTeam ~= myTeamID) then
		return
	end
	if cmdID and stateCommands[cmdID] then
		return
	end
	
	-- Double wait means the same as an empty queue
	-- It is just an engine hack
	if HasDoubleCommand(unitID,cmdID) then
		widget:UnitIdle(unitID,unitDefID,unitTeam)
		return
	end
	
	if idleCons[unitID] then
		idleCons[unitID] = nil
		wantUpdateCons = true
	end

	local unitName = UnitDefs[unitDefID].name
	if (unitName == "corshad") then
		setBomberReadyStatus(unitID)
	end
end

local timer = 0
function widget:Update(dt)
	if myTeamID ~= Spring.GetMyTeamID() then
		myTeamID = Spring.GetMyTeamID()
		ClearData(false)
		InitializeUnits()
	end
	
	if wantUpdateCons then
		buttonList.GetButton(CONSTRUCTOR_BUTTON_ID).UpdateButton()
		wantUpdateCons = false
	end

	timer = timer + dt
	if timer < UPDATE_FREQUENCY then
		return
	end
	
	buttonList.UpdateButtons(timer)
	timer = 0
end

-- for "under attack" achtung sign
function widget:UnitDamaged(unitID, unitDefID, unitTeam)
	local button = buttonList.GetButton(unitID)
	if button and button.SetWarning then
		button.SetWarning(COMM_WARNING_TIME)
	end
end

function widget:Shutdown()
	if mainWindow then
		mainWindow:Dispose()
	end
	widgetHandler:RemoveAction("selectcomm")
	widgetHandler:RemoveAction("selectprecbomber")
end

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	
	widgetHandler:AddAction("selectcomm", SelectComm, nil, 'tp')
	widgetHandler:AddAction("selectprecbomber", SelectPrecBomber, nil, 'tp')
	widgetHandler:AddAction("selectidlecon", SelectIdleCon, nil, 'tp')
	widgetHandler:AddAction("selectidlecon_all", SelectIdleCon_all, nil, 'tp')

	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Control = Chili.Control
	Label = Chili.Label
	Window = Chili.Window
	Panel = Chili.Panel
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	screen0 = Chili.Screen0

	InitializeControls()
	
	WG.CoreSelector = externalFunctions
end
