--[[---------------------------------------------------------------------------------
-  ManaPerc: Originally MyACEPercentage by Instant                                  -
-----------------------------------------------------------------------------------]]
ManaPerc = LibStub("AceAddon-3.0"):NewAddon("ManaPerc", "AceHook-3.0", "AceConsole-3.0")
local ManaPerc, self = ManaPerc, ManaPerc
-- Default options
local defaults = {
	profile = {
		current = false,
		total = true,
		colour = true,
	},
}
-- Locale
local L = LibStub("AceLocale-3.0"):GetLocale("ManaPerc")
-- Some local functions/values
local sformat = string.format
local smatch = string.match
local sgsub = string.gsub
local tonumber = tonumber
local GetSpellInfo = GetSpellInfo
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local MANA_COST = MANA_COST
local MANA_COST_PATTERN = sgsub(MANA_COST, "%%s", "([%%d.,]+)")
local SPELL_POWER_MANA = SPELL_POWER_MANA
local math_inf = 1/0
-- Our SV DB, we'll fill this in later
local db

-- Return our options table
local function getOptions()
	local options = {
		type = "group",
		name = GetAddOnMetadata("ManaPerc", "Title"),
		get = function(info) return db[info[#info]] end,
		set = function(info, value) db[info[#info]] = value end,
		args = {
			mpdesc = {
				type = "description",
				order = 0,
				name = GetAddOnMetadata("ManaPerc", "Notes"),
			},
			total = {
				name = L["Show Total"],
				desc = L["TOTAL_DESC"],
				type = "toggle",
				order = 2,
				width = "full",
			},
			current = {
				name = L["Show Current"],
				desc = L["CURRENT_DESC"],
				type = "toggle",
				order = 3,
				width = "full",
			},
			colour = {
				name = L["Enable Colour"],
				desc = L["COLOUR_DESC"],
				type = "toggle",
				order = 1,
				width = "full",
			}
		}
	}
	return options
end

--[[--------------------------------------------------------------------------------
  Addon Enabling/Disabling
-----------------------------------------------------------------------------------]]
function ManaPerc:OnInitialize()
	-- Grab our DB and fill in the 'db' variable
	self.db = LibStub("AceDB-3.0"):New("ManaPercDB", defaults, "Default")
	db = self.db.profile
	-- Register our options
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("ManaPerc", getOptions)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ManaPerc", GetAddOnMetadata("ManaPerc", "Title"))
	-- Register chat command to open the options dialog
	self:RegisterChatCommand("manaperc", function() InterfaceOptionsFrame_OpenToCategory(GetAddOnMetadata("ManaPerc", "Title")) end)
end

function ManaPerc:OnEnable()
	self:HookScript(GameTooltip, "OnTooltipSetSpell", "ProcessOnShow")
end

local function getCost(tt)
    local line = _G["GameTooltipTextLeft2"]
    local text = line:GetText()
    if text then
        local costString = text:match(MANA_COST_PATTERN)
        local costNum = costString:gsub("%D", "")
        return tonumber(costNum)
    end
    return nil
end

--[[--------------------------------------------------------------------------------
  Main Processing
-----------------------------------------------------------------------------------]]
function ManaPerc:ProcessOnShow(tt, ...)
	-- Get the name of the spell along with the cost and power type.
	local name = tt:GetSpell()
	if name then
        local cost = getCost(tt)
		-- If the spell costs something and is a Mana using spell...
		-- We must check that they're not nil here too, due to Blizzard
		-- doing something funky when setting Talents in the tooltip.
		if cost and cost > 0 then
			local dttext, dctext = "", ""
			-- Work out the percentage vs. the players total mana
			if db.total then
				local pct = cost / (UnitPowerMax('player', SPELL_POWER_MANA) / 100)
				dttext = sformat(" %s%.1f%%)", db.colour and "|cFFFFFF00(" or "(t:", pct ~= math_inf and pct or 0)
			end
			-- Work out the percentage vs. the players current mana
			if db.current then
				local pct = cost / (UnitPower('player', SPELL_POWER_MANA) / 100)
				dctext = sformat(" %s%.1f%%)", db.colour and "|cFF00FF00(" or "(c:", pct ~= math_inf and pct or 0)
			end
			-- Add the new information to the tooltip
			GameTooltipTextLeft2:SetText(sformat(MANA_COST, cost)..dctext..dttext)
		end
	end
	-- Call the original function
	self.hooks[GameTooltip]["OnTooltipSetSpell"](tt, ...)
end
