local addonName, Addon = ...

local TWO_PI = math.pi * 2
local SLOT_ANGLE = TWO_PI / 8
local LAYOUT_ANGLE = TWO_PI / 4
local WHEEL_SIZE = 512
local ICON_RADIUS = 132
local LABEL_RADIUS = 214
local LAYOUT_RADIUS = 76
local DEAD_ZONE = 48
local LAYOUT_ZONE = 101
local LAYOUT_DWELL = 0.22

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

local function CursorPosition()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    return x / scale, y / scale
end

local function CreateIconFrame(parent, index)
    local angle = (index - 1) * SLOT_ANGLE
    local frame = Addon:CreateBackdropFrame("Frame", nil, parent)
    frame:SetSize(50, 50)
    frame:SetPoint("CENTER", parent, "CENTER", math.sin(angle) * ICON_RADIUS, math.cos(angle) * ICON_RADIUS)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 13,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.03, 0.03, 0.03, 0.95)
    frame:SetBackdropBorderColor(0.42, 0.42, 0.42, 0.95)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 5, -5)
    icon:SetPoint("BOTTOMRIGHT", -5, 5)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.icon = icon

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetWidth(150)
    label:SetJustifyH("CENTER")
    label:SetPoint("CENTER", parent, "CENTER", math.sin(angle) * LABEL_RADIUS, math.cos(angle) * LABEL_RADIUS)
    label:SetTextColor(0.93, 0.93, 0.93)
    frame.label = label

    return frame
end

local function CreateLayoutSelector(parent, index)
    local angle = (index - 1) * LAYOUT_ANGLE
    local selector = Addon:CreateBackdropFrame("Frame", nil, parent)
    selector:SetSize(30, 30)
    selector:SetPoint("CENTER", parent, "CENTER", math.sin(angle) * LAYOUT_RADIUS, math.cos(angle) * LAYOUT_RADIUS)
    selector:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    selector:SetBackdropColor(0.035, 0.04, 0.05, 0.96)
    selector:SetBackdropBorderColor(0.42, 0.44, 0.48, 1)

    local text = selector:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", 0, 0)
    text:SetText(index)
    selector.text = text
    return selector
end

function Addon:CreateRing()
    if self.ring then
        return
    end

    -- The anchor itself is never scaled. Only the visual child is scaled,
    -- keeping its exact center fixed below the cursor at every ring size.
    local wheel = CreateFrame("Frame", "EmoteRingWheel", UIParent)
    wheel:SetSize(1, 1)
    wheel:SetFrameStrata("FULLSCREEN_DIALOG")
    wheel:SetFrameLevel(500)
    wheel:EnableMouse(false)
    wheel:EnableKeyboard(false)
    wheel:SetPropagateKeyboardInput(true)
    wheel:Hide()

    local visual = CreateFrame("Frame", nil, wheel)
    visual:SetSize(WHEEL_SIZE, WHEEL_SIZE)
    visual:SetPoint("CENTER")
    wheel.visual = visual

    local shade = visual:CreateTexture(nil, "BACKGROUND", nil, -2)
    shade:SetTexture("Interface\\AddOns\\EmoteRing\\Media\\donut")
    shade:SetAllPoints()
    shade:SetVertexColor(0.02, 0.025, 0.035, 0.82)
    wheel.shade = shade

    wheel.wedges = {}
    for index = 1, 8 do
        local wedge = visual:CreateTexture(nil, "BACKGROUND", nil, -1)
        wedge:SetTexture("Interface\\AddOns\\EmoteRing\\Media\\wedge")
        wedge:SetAllPoints()
        wedge:SetRotation(-((index - 1) * SLOT_ANGLE))
        wedge:SetVertexColor(0.24, 0.27, 0.32, 0.54)
        wheel.wedges[index] = wedge
    end

    local highlight = visual:CreateTexture(nil, "BORDER")
    highlight:SetTexture("Interface\\AddOns\\EmoteRing\\Media\\wedge")
    highlight:SetAllPoints()
    highlight:SetVertexColor(1.0, 0.70, 0.08, 0.90)
    highlight:Hide()
    wheel.highlight = highlight

    local center = visual:CreateTexture(nil, "ARTWORK")
    center:SetTexture("Interface\\AddOns\\EmoteRing\\Media\\center")
    center:SetSize(94, 94)
    center:SetPoint("CENTER")
    wheel.center = center

    local cancelText = visual:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    cancelText:SetPoint("CENTER", 0, -2)
    cancelText:SetText("×")
    cancelText:SetTextColor(0.95, 0.15, 0.08)
    wheel.cancelText = cancelText

    local selectionText = visual:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectionText:SetPoint("BOTTOM", visual, "CENTER", 0, 103)
    selectionText:SetWidth(230)
    selectionText:SetJustifyH("CENTER")
    selectionText:SetTextColor(1.0, 0.82, 0.18)
    selectionText:Hide()
    wheel.selectionText = selectionText

    local targetText = visual:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    targetText:SetPoint("TOP", visual, "CENTER", 0, -31)
    targetText:SetWidth(190)
    targetText:SetJustifyH("CENTER")
    targetText:SetTextColor(0.78, 0.81, 0.87)
    wheel.targetText = targetText

    wheel.icons = {}
    for index = 1, 8 do
        wheel.icons[index] = CreateIconFrame(visual, index)
    end

    wheel.layoutSelectors = {}
    for index = 1, 4 do
        wheel.layoutSelectors[index] = CreateLayoutSelector(visual, index)
    end

    wheel:SetScript("OnUpdate", function()
        Addon:UpdateSelection()
    end)
    wheel:SetScript("OnKeyDown", function(self, key)
        if self.previewMode and key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    wheel:SetScript("OnHide", function()
        wheel:EnableKeyboard(false)
        wheel:SetPropagateKeyboardInput(true)
        wheel.selectedIndex = nil
        wheel.hoverLayout = nil
        wheel.hoverStarted = nil
        wheel.subjectGUID = nil
        wheel.subjectName = nil
        wheel.previewMode = nil
        wheel.highlight:Hide()
        wheel.selectionText:Hide()
    end)

    self.ring = wheel
    self:RefreshRing()
end

function Addon:RefreshLayoutSelectors()
    local wheel = self.ring
    if not wheel then
        return
    end

    for index = 1, 4 do
        local selector = wheel.layoutSelectors[index]
        local active = index == self.activeLayout
        local hovered = index == wheel.hoverLayout
        if hovered then
            selector:SetBackdropColor(0.22, 0.16, 0.035, 1)
            selector:SetBackdropBorderColor(1.0, 0.76, 0.12, 1)
        elseif active then
            selector:SetBackdropColor(0.16, 0.11, 0.025, 1)
            selector:SetBackdropBorderColor(0.93, 0.62, 0.08, 1)
        else
            selector:SetBackdropColor(0.035, 0.04, 0.05, 0.96)
            selector:SetBackdropBorderColor(0.42, 0.44, 0.48, 1)
        end
        selector.text:SetTextColor(active and 1.0 or 0.78, active and 0.82 or 0.80, active and 0.18 or 0.84)
    end
end

function Addon:RefreshRing()
    local wheel = self.ring
    if not wheel or not self.db then
        return
    end

    wheel.visual:SetScale(self.db.ringScale or 1)
    for index = 1, 8 do
        local entry = self:GetEntry(index)
        local iconFrame = wheel.icons[index]
        if entry then
            iconFrame.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            iconFrame.label:SetText(entry.label)
        else
            iconFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            iconFrame.label:SetText("?")
        end
        iconFrame:SetBackdropBorderColor(0.42, 0.42, 0.42, 0.95)
        iconFrame.label:SetTextColor(0.93, 0.93, 0.93)
    end
    self:RefreshLayoutSelectors()
end

function Addon:PositionRingAtCursor()
    local wheel = self.ring
    local cursorX, cursorY = CursorPosition()
    local scale = self.db.ringScale or 1
    local margin = 248 * scale
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()

    local centerX = math.max(margin, math.min(width - margin, cursorX))
    local centerY = math.max(margin, math.min(height - margin, cursorY))

    wheel:ClearAllPoints()
    wheel:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    wheel.centerX = centerX
    wheel.centerY = centerY
end

function Addon:SetSelectedIndex(index)
    local wheel = self.ring
    if wheel.selectedIndex == index then
        return
    end

    wheel.selectedIndex = index
    for slotIndex = 1, 8 do
        local iconFrame = wheel.icons[slotIndex]
        if slotIndex == index then
            iconFrame:SetBackdropBorderColor(1.0, 0.72, 0.08, 1)
            iconFrame.label:SetTextColor(1.0, 0.82, 0.18)
        else
            iconFrame:SetBackdropBorderColor(0.42, 0.42, 0.42, 0.95)
            iconFrame.label:SetTextColor(0.93, 0.93, 0.93)
        end
    end

    if index then
        local entry = self:GetEntry(index)
        wheel.highlight:SetRotation(-((index - 1) * SLOT_ANGLE))
        wheel.highlight:Show()
        wheel.selectionText:SetText(entry and entry.label or "")
        wheel.selectionText:Show()
        self:PlayUISound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    else
        wheel.highlight:Hide()
        wheel.selectionText:Hide()
    end
end

function Addon:SetHoveredLayout(index)
    local wheel = self.ring
    if wheel.hoverLayout == index then
        return
    end
    wheel.hoverLayout = index
    wheel.hoverStarted = index and GetTime() or nil
    self:RefreshLayoutSelectors()
end

function Addon:UpdateSelection()
    local wheel = self.ring
    if not wheel or not wheel:IsShown() then
        return
    end

    local cursorX, cursorY = CursorPosition()
    local deltaX = cursorX - wheel.centerX
    local deltaY = cursorY - wheel.centerY
    local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)
    local scale = self.db.ringScale or 1

    if distance < DEAD_ZONE * scale then
        self:SetSelectedIndex(nil)
        self:SetHoveredLayout(nil)
        return
    end

    -- Swapping x/y makes zero point upward; positive values move clockwise.
    local angle = Atan2(deltaX, deltaY)
    if angle < 0 then
        angle = angle + TWO_PI
    end

    if distance < LAYOUT_ZONE * scale then
        self:SetSelectedIndex(nil)
        local layoutIndex = (math.floor((angle + LAYOUT_ANGLE / 2) / LAYOUT_ANGLE) % 4) + 1
        self:SetHoveredLayout(layoutIndex)
        if layoutIndex ~= self.activeLayout
            and wheel.hoverStarted
            and GetTime() - wheel.hoverStarted >= LAYOUT_DWELL then
            self:SetActiveLayout(layoutIndex)
            self:PlayUISound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
        return
    end

    self:SetHoveredLayout(nil)
    local index = (math.floor((angle + SLOT_ANGLE / 2) / SLOT_ANGLE) % 8) + 1
    self:SetSelectedIndex(index)
end

function Addon:OpenRing(previewMode)
    local wheel = self.ring
    if not wheel or wheel:IsShown() then
        return
    end

    self.activeLayout = self.db.defaultLayout or 1
    self:RefreshRing()
    self:PositionRingAtCursor()
    local subjectUnit
    wheel.subjectGUID, wheel.subjectName, subjectUnit = self:CaptureSubject()
    wheel.subjectState = not previewMode and self:LockMouseoverSubject(subjectUnit, wheel.subjectGUID) or nil
    wheel.previewMode = previewMode
    wheel.selectedIndex = nil
    wheel:EnableKeyboard(previewMode and true or false)

    if self.db.showTarget then
        if wheel.subjectName then
            wheel.targetText:SetText(self.L.TARGET:format(wheel.subjectName))
        else
            wheel.targetText:SetText(self.L.NO_TARGET)
        end
        wheel.targetText:Show()
    else
        wheel.targetText:Hide()
    end

    wheel:Show()
    self:PlayUISound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPEN)

    if previewMode then
        wheel.previewSerial = (wheel.previewSerial or 0) + 1
        local previewSerial = wheel.previewSerial
        Addon:After(5, function()
            if wheel:IsShown() and wheel.previewMode and wheel.previewSerial == previewSerial then
                wheel:Hide()
            end
        end)
    end
end

function Addon:ToggleRingPreview()
    local wheel = self.ring
    if wheel and wheel:IsShown() and wheel.previewMode then
        wheel:Hide()
        return
    end
    self:OpenRing(true)
end

function Addon:ReleaseRing(skipTargetRestore)
    local wheel = self.ring
    if not wheel or not wheel:IsShown() then
        return
    end

    local selectedIndex = wheel.selectedIndex
    local subjectGUID = wheel.subjectGUID
    local subjectState = wheel.subjectState
    local entry = selectedIndex and self:GetEntry(selectedIndex) or nil
    local previewMode = wheel.previewMode
    wheel.subjectState = nil
    wheel:Hide()

    if entry and not previewMode then
        self:PerformEntry(entry, subjectGUID)
        self:PlayUISound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end

    if subjectState and not skipTargetRestore then
        Addon:After(0, function()
            Addon:RestoreMouseoverSubject(subjectState)
        end)
    end
end
