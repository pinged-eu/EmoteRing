local addonName, Addon = ...

local function Atan2(y, x)
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi / 2
    elseif x == 0 and y < 0 then
        return -math.pi / 2
    end
    return 0
end

function Addon:PositionMinimapButton()
    local button = self.minimapButton
    if not button or not self.db then
        return
    end

    local angle = math.rad(self.db.minimapAngle or 220)
    local radius = (Minimap:GetWidth() / 2) + 13
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function Addon:UpdateMinimapButton()
    if not self.minimapButton or not self.db then
        return
    end
    self:PositionMinimapButton()
    self.minimapButton:SetShown(self.db.showMinimap)
end

function Addon:CreateMinimapButton()
    if self.minimapButton then
        return
    end

    local button = CreateFrame("Button", "EmoteRingMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(24, 24)
    background:SetPoint("CENTER")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\EmoteRing\\Media\\logo")
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("EmoteRing", 1, 0.82, 0.18)
        GameTooltip:AddLine(Addon.L.MINIMAP_TOOLTIP, 0.92, 0.92, 0.92, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    button:SetScript("OnDragStart", function(self)
        self.dragging = true
        self.wasDragged = true
        self:SetScript("OnUpdate", function()
            local cursorX, cursorY = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            cursorX, cursorY = cursorX / scale, cursorY / scale
            local minimapX, minimapY = Minimap:GetCenter()
            Addon.db.minimapAngle = math.deg(Atan2(cursorY - minimapY, cursorX - minimapX))
            Addon:PositionMinimapButton()
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self.dragging = nil
        self:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        if self.wasDragged then
            self.wasDragged = nil
            return
        end
        if mouseButton == "RightButton" then
            Addon:ToggleRingPreview()
        else
            Addon:OpenOptions()
        end
    end)

    self.minimapButton = button
    self:UpdateMinimapButton()
end
