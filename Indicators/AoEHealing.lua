
local _, Cell = ...
local L = Cell.L
---@type CellFuncs
local F = Cell.funcs
---@class CellIndicatorFuncs
local I = Cell.iFuncs

-------------------------------------------------
-- CreateAoEHealing -- not support for npc
-------------------------------------------------
local function GetCLEUInfo(...)
    if CombatLogGetCurrentEventInfo then
        return CombatLogGetCurrentEventInfo()
    end
    return ...
end

local function Display(b)
    b.indicators.aoeHealing:Display()
end

local playerSummoned = {}
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event ~= "COMBAT_LOG_EVENT_UNFILTERED" then return end

    local timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = GetCLEUInfo(...)

    -- SPELL_SUMMON
    if subevent == "SPELL_SUMMON" then
        if sourceGUID == Cell.vars.playerGUID and destGUID and I.IsAoEHealing(spellName, spellId) then
            local duration = I.GetSummonDuration(spellName)
            if duration then
                playerSummoned[destGUID] = GetTime() + duration
                C_Timer.After(duration, function()
                    playerSummoned[destGUID] = nil
                end)
            end
        end
    end

    -- HEAL EVENTS
    if subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL" then
        if destGUID then
            if (sourceGUID == Cell.vars.playerGUID and I.IsAoEHealing(spellName, spellId)) or playerSummoned[sourceGUID] then
                F.HandleUnitButton("guid", destGUID, Display)
            end
        end
    end
end)
--[[
function I.CreateAoEHealing(parent)
    local aoeHealing = CreateFrame("Frame", parent:GetName().."AoEHealing", parent.widgets.indicatorFrame)
    parent.indicators.aoeHealing = aoeHealing
	--print("AOE Create:", parent:GetName())
    aoeHealing:SetPoint("TOPLEFT", parent.widgets.healthBar)
    aoeHealing:SetPoint("TOPRIGHT", parent.widgets.healthBar)
    aoeHealing:Hide()

    aoeHealing.tex = aoeHealing:CreateTexture(nil, "ARTWORK")
    aoeHealing.tex:SetAllPoints(aoeHealing)
   -- aoeHealing.tex:SetTexture(Cell.vars.whiteTexture)
	aoeHealing.tex:SetTexture("Interface\\Buttons\\WHITE8x8")

    local ag = aoeHealing:CreateAnimationGroup()
    local a1 = ag:CreateAnimation("Alpha")
    a1:SetFromAlpha(0)
    a1:SetToAlpha(1)
    a1:SetDuration(0.5)
    a1:SetOrder(1)
    a1:SetSmoothing("OUT")
    local a2 = ag:CreateAnimation("Alpha")
    a2:SetFromAlpha(1)
    a2:SetToAlpha(0)
    a2:SetDuration(0.5)
    a2:SetOrder(2)
    a2:SetSmoothing("IN")

    ag:SetScript("OnPlay", function()
        aoeHealing:Show()
    end)
    ag:SetScript("OnFinished", function()
        aoeHealing:Hide()
    end)

    function aoeHealing:SetColor(r, g, b)
        aoeHealing.tex:SetGradient("VERTICAL", CreateColor(r, g, b, 0), CreateColor(r, g, b, 0.77))
    end
--
    function aoeHealing:Display()
        -- if ag:IsPlaying() then
        --     ag:Restart()
        -- else
            ag:Play()
        -- end
    end
end
]]
--[[
function I.CreateAoEHealing(parent)
    local aoeHealing = CreateFrame("Frame", parent:GetName().."AoEHealing", parent.widgets.indicatorFrame)
    parent.indicators.aoeHealing = aoeHealing

    aoeHealing:SetPoint("TOPLEFT", parent.widgets.healthBar)
    aoeHealing:SetPoint("TOPRIGHT", parent.widgets.healthBar)
    aoeHealing:Hide()
-------------------------------------------------

    local bg = aoeHealing:CreateTexture(nil, "BACKGROUND")
    aoeHealing.bg = bg
    bg:SetAllPoints(aoeHealing)
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")

    function aoeHealing:SetColor(r, g, b)
        -- градиент задаём ОДИН РАЗ, не во время анимации
        bg:SetGradientAlpha(
            "VERTICAL",
            r, g, b, 0,
            r, g, b, 0.77
        )
    end
 -------------------------------------------------

    local overlay = aoeHealing:CreateTexture(nil, "ARTWORK")
    aoeHealing.overlay = overlay
    overlay:SetAllPoints(aoeHealing)
    overlay:SetTexture("Interface\\Buttons\\WHITE8x8")
    overlay:SetVertexColor(1, 1, 1, 0)

    local ag = overlay:CreateAnimationGroup()

    local a1 = ag:CreateAnimation("Alpha")
    a1:SetFromAlpha(0)
    a1:SetToAlpha(0)
    a1:SetDuration(0.5)
    a1:SetOrder(1)
	a1:SetSmoothing("OUT")

    local a2 = ag:CreateAnimation("Alpha")
    a2:SetFromAlpha(1)
    a2:SetToAlpha(0)
    a2:SetDuration(0.5)
    a2:SetOrder(2)
    a2:SetSmoothing("IN")

    ag:SetScript("OnPlay", function()
        aoeHealing:Show()
        --overlay:SetAlpha(1)
    end)

    ag:SetScript("OnFinished", function()
        aoeHealing:Hide()
    end)

    function aoeHealing:Display()
        if ag:IsPlaying() then
            ag:Restart()
        else
            ag:Play()
        end
    end
end
]]
function I.CreateAoEHealing(parent)
    local aoeHealing = CreateFrame("Frame", parent:GetName().."AoEHealing", parent.widgets.indicatorFrame)
    parent.indicators.aoeHealing = aoeHealing

    aoeHealing:SetPoint("TOPLEFT", parent.widgets.healthBar)
    aoeHealing:SetPoint("TOPRIGHT", parent.widgets.healthBar)
    aoeHealing:Hide()

    local bg = aoeHealing:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(aoeHealing)
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    aoeHealing.bg = bg

    local r, g, b = 1, 1, 1
    local intensity = 1

    local function applyGradient()
        local alphaTop = 0.85 * intensity
        local alphaBottom = 0.15 * intensity

        bg:SetGradientAlpha(
            "VERTICAL",
            r, g, b, alphaBottom,
            r, g, b, alphaTop
        )

        aoeHealing:SetAlpha(0.3 + intensity * 0.7)
    end

    local ag = aoeHealing:CreateAnimationGroup()

    local tick = ag:CreateAnimation("Alpha")
    tick:SetFromAlpha(1)
    tick:SetToAlpha(1)
    tick:SetDuration(1.5)
    tick:SetSmoothing("NONE")

    tick:SetScript("OnUpdate", function(self, elapsed)
        if intensity <= 0 then return end

        intensity = intensity - elapsed * 0.7
        if intensity < 0 then intensity = 0 end

        applyGradient()

        if intensity == 0 then
            aoeHealing:Hide()
        end
    end)

    ag:SetScript("OnPlay", function()
        aoeHealing:Show()
        intensity = 1
        applyGradient()
    end)

    ag:SetScript("OnFinished", function()
        aoeHealing:Hide()
    end)

    function aoeHealing:SetColor(rr, gg, bb)
        r, g, b = rr, gg, bb
        intensity = 1
        applyGradient()
    end

    function aoeHealing:Display()
        ag:Stop()
        ag:Play()
    end
end

function I.EnableAoEHealing(enabled)
    if enabled then
        eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        eventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end
