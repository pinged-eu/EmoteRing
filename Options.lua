local addonName, Addon = ...

local GOLD = { 1.0, 0.82, 0.18 }
local TEXT = { 0.93, 0.93, 0.93 }
local MUTED = { 0.65, 0.67, 0.72 }
local OPTIONS_DESIGN_WIDTH = 900
local OPTIONS_DESIGN_HEIGHT = 800
local OPTIONS_MAX_SCALE = 0.90

local PICKER_CATEGORIES = {
    "CATEGORY_ALL",
    "CATEGORY_SOCIAL",
    "CATEGORY_REACTION",
    "CATEGORY_ROLEPLAY",
    "CATEGORY_GROUP",
    "CATEGORY_STATUS",
    "CATEGORY_OTHER",
}

local function ApplyDarkBackdrop(frame, alpha)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.035, 0.035, 0.045, alpha or 0.94)
    frame:SetBackdropBorderColor(0.34, 0.35, 0.38, 1)
end

local function CreateSectionTitle(parent, text, anchor, x, y)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint(anchor, x, y)
    title:SetText(text)
    title:SetTextColor(TEXT[1], TEXT[2], TEXT[3])

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.72, 0.50, 0.08, 0.55)
    line:SetHeight(1)
    line:SetPoint("LEFT", title, "RIGHT", 14, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -30, 0)
    return title
end

local function CreateCheck(parent, label, tooltip)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(28, 28)

    local text = check:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", check, "RIGHT", 4, 1)
    text:SetText(label)
    text:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    check.label = text

    if tooltip then
        check:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 0.82, 0.18)
            GameTooltip:AddLine(tooltip, 0.92, 0.92, 0.92, true)
            GameTooltip:Show()
        end)
        check:SetScript("OnLeave", GameTooltip_Hide)
    end
    return check
end

local function KeyWithModifiers(key)
    if not key then
        return nil
    end

    local upper = key:upper()
    if upper == "LSHIFT" or upper == "RSHIFT"
        or upper == "LCTRL" or upper == "RCTRL"
        or upper == "LALT" or upper == "RALT" then
        return nil
    end

    if key == "LeftButton" then
        upper = "BUTTON1"
    elseif key == "RightButton" then
        upper = "BUTTON2"
    elseif key == "MiddleButton" then
        upper = "BUTTON3"
    elseif upper:match("^BUTTON%d+$") then
        -- Already in binding format.
    elseif key:match("^Button%d+$") then
        upper = key:upper()
    end

    local prefix = ""
    if IsAltKeyDown() then
        prefix = prefix .. "ALT-"
    end
    if IsControlKeyDown() then
        prefix = prefix .. "CTRL-"
    end
    if IsShiftKeyDown() then
        prefix = prefix .. "SHIFT-"
    end
    return prefix .. upper
end

function Addon:ApplyBinding(key)
    if InCombatLockdown() then
        self:Print(self.L.BINDING_COMBAT)
        return false
    end

    local first, second = GetBindingKey("CLICK EmoteRingBindingButton:LeftButton")
    if first then
        SetBinding(first)
    end
    if second then
        SetBinding(second)
    end

    local oldFirst, oldSecond = GetBindingKey("EMOTERING_OPEN")
    if oldFirst then
        SetBinding(oldFirst)
    end
    if oldSecond then
        SetBinding(oldSecond)
    end

    local success = SetBindingClick(key, "EmoteRingBindingButton", "LeftButton")
    if success then
        SaveBindings(GetCurrentBindingSet())
        self:Print(self.L.BINDING_SAVED:format(GetBindingText(key, "KEY_", 1)))
        self:RefreshOptions()
    end
    return success
end

function Addon:FinishBindingCapture(key)
    local capture = self.bindingCapture
    if not capture or not capture:IsShown() then
        return
    end

    capture:Hide()
    if not key or key == "ESCAPE" then
        return
    end

    local bindingKey = KeyWithModifiers(key)
    if not bindingKey then
        return
    end

    local existing = GetBindingAction(bindingKey)
    if existing and existing ~= ""
        and existing ~= "EMOTERING_OPEN"
        and existing ~= "CLICK EmoteRingBindingButton:LeftButton" then
        self.pendingBindingKey = bindingKey
        local prettyKey = GetBindingText(bindingKey, "KEY_", 1)
        local existingName = _G["BINDING_NAME_" .. existing] or existing
        StaticPopup_Show("EMOTERING_BINDING_CONFLICT", prettyKey, existingName)
    else
        self:ApplyBinding(bindingKey)
    end
end

function Addon:StartBindingCapture()
    if InCombatLockdown() then
        self:Print(self.L.BINDING_COMBAT)
        return
    end
    self.bindingCapture:Show()
end

local function CreateBindingCapture(panel)
    local capture = CreateFrame("Button", nil, panel, "BackdropTemplate")
    capture:SetAllPoints()
    capture:SetFrameLevel(1000)
    capture:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    capture:SetBackdropColor(0.015, 0.015, 0.02, 0.94)
    capture:EnableMouse(true)
    capture:EnableKeyboard(true)
    capture:SetPropagateKeyboardInput(false)
    capture:Hide()

    local border = capture:CreateTexture(nil, "ARTWORK")
    border:SetColorTexture(0.92, 0.64, 0.08, 0.85)
    border:SetPoint("CENTER")
    border:SetSize(430, 126)

    local inner = CreateFrame("Frame", nil, capture, "BackdropTemplate")
    inner:SetPoint("CENTER")
    inner:SetSize(426, 122)
    ApplyDarkBackdrop(inner, 1)

    local title = inner:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", 0, -28)
    title:SetText(Addon.L.PRESS_KEY)
    title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])

    local hint = inner:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hint:SetPoint("TOP", title, "BOTTOM", 0, -14)
    hint:SetText(Addon.L.PRESS_KEY_HINT)

    capture:SetScript("OnKeyDown", function(_, key)
        Addon:FinishBindingCapture(key)
    end)
    capture:SetScript("OnMouseDown", function(_, button)
        Addon:FinishBindingCapture(button)
    end)
    return capture
end

local function CreateSlotCard(parent, index)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(326, 54)
    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 13,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    card:SetBackdropColor(0.08, 0.065, 0.035, 0.80)
    card:SetBackdropBorderColor(0.43, 0.36, 0.20, 0.95)

    local iconBorder = CreateFrame("Frame", nil, card, "BackdropTemplate")
    iconBorder:SetSize(42, 42)
    iconBorder:SetPoint("LEFT", 8, 0)
    iconBorder:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    iconBorder:SetBackdropColor(0.02, 0.02, 0.02, 1)
    iconBorder:SetBackdropBorderColor(0.70, 0.52, 0.13, 1)

    local icon = iconBorder:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 5, -5)
    icon:SetPoint("BOTTOMRIGHT", -5, 5)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    card.icon = icon

    local number = card:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    number:SetPoint("TOPLEFT", iconBorder, "TOPRIGHT", 9, -7)
    number:SetText(Addon.L.SLOT:format(index))
    number:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

    local label = card:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    label:SetPoint("BOTTOMLEFT", iconBorder, "BOTTOMRIGHT", 9, 7)
    label:SetWidth(112)
    label:SetJustifyH("LEFT")
    label:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    card.label = label

    local change = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    change:SetSize(74, 26)
    change:SetPoint("RIGHT", -8, 0)
    change:SetText(Addon.L.CHANGE)
    change:SetScript("OnClick", function()
        Addon:OpenPicker(index, Addon.optionsLayout)
    end)
    card.change = change

    local nextButton = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    nextButton:SetSize(25, 26)
    nextButton:SetPoint("RIGHT", change, "LEFT", -3, 0)
    nextButton:SetText("›")
    nextButton:SetScript("OnClick", function()
        Addon:MoveSlot(Addon.optionsLayout, index, 1)
    end)
    nextButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(Addon.L.MOVE_RIGHT)
        GameTooltip:Show()
    end)
    nextButton:SetScript("OnLeave", GameTooltip_Hide)
    card.nextButton = nextButton

    local previousButton = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    previousButton:SetSize(25, 26)
    previousButton:SetPoint("RIGHT", nextButton, "LEFT", -2, 0)
    previousButton:SetText("‹")
    previousButton:SetScript("OnClick", function()
        Addon:MoveSlot(Addon.optionsLayout, index, -1)
    end)
    previousButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(Addon.L.MOVE_LEFT)
        GameTooltip:Show()
    end)
    previousButton:SetScript("OnLeave", GameTooltip_Hide)
    card.previousButton = previousButton
    return card
end

local function GetSortedCatalog()
    local entries = {}
    for _, entry in ipairs(Addon.catalog) do
        entries[#entries + 1] = entry
    end
    table.sort(entries, function(left, right)
        return left.label:lower() < right.label:lower()
    end)
    return entries
end

local function CreatePicker()
    local picker = CreateFrame("Frame", "EmoteRingPicker", UIParent, "BackdropTemplate")
    picker:SetSize(730, 620)
    picker:SetPoint("CENTER")
    picker:SetFrameStrata("TOOLTIP")
    picker:SetFrameLevel(1000)
    picker:SetClampedToScreen(true)
    ApplyDarkBackdrop(picker, 0.99)
    picker:Hide()
    table.insert(UISpecialFrames, "EmoteRingPicker")

    local title = picker:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 26, -22)
    title:SetText(Addon.L.PICKER_TITLE)
    title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])

    local close = CreateFrame("Button", nil, picker, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetFrameLevel(picker:GetFrameLevel() + 10)

    local search = CreateFrame("EditBox", nil, picker, "SearchBoxTemplate")
    search:SetSize(305, 30)
    search:SetPoint("TOPRIGHT", -48, -17)
    search:SetAutoFocus(false)
    if search.Instructions then
        search.Instructions:SetText(Addon.L.SEARCH)
    end
    picker.search = search

    picker.category = "CATEGORY_ALL"
    picker.categoryButtons = {}
    for index, categoryKey in ipairs(PICKER_CATEGORIES) do
        local button = CreateFrame("Button", nil, picker, "UIPanelButtonTemplate")
        button:SetSize(92, 25)
        button:SetPoint("TOPLEFT", 23 + ((index - 1) * 97), -58)
        button:SetText(Addon.L[categoryKey])
        button.categoryKey = categoryKey
        button:SetScript("OnClick", function(self)
            picker.category = self.categoryKey
            Addon:RefreshPicker()
        end)
        picker.categoryButtons[index] = button
    end

    local scroll = CreateFrame("ScrollFrame", nil, picker, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 22, -94)
    scroll:SetPoint("BOTTOMRIGHT", -34, 54)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(660, 1)
    scroll:SetScrollChild(child)
    picker.scrollChild = child

    local footer = picker:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    footer:SetPoint("BOTTOMLEFT", 26, 22)
    footer:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    picker.footer = footer

    local closeButton = CreateFrame("Button", nil, picker, "UIPanelButtonTemplate")
    closeButton:SetSize(110, 28)
    closeButton:SetPoint("BOTTOMRIGHT", -22, 16)
    closeButton:SetText(Addon.L.CLOSE)
    closeButton:SetScript("OnClick", function()
        picker:Hide()
    end)

    picker.buttons = {}
    for catalogIndex, entry in ipairs(GetSortedCatalog()) do
        local button = CreateFrame("Button", nil, child, "BackdropTemplate")
        button:SetSize(318, 48)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 11,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        button:SetBackdropColor(0.065, 0.065, 0.075, 0.94)
        button:SetBackdropBorderColor(0.28, 0.29, 0.32, 1)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(36, 36)
        icon:SetPoint("LEFT", 7, 0)
        icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local label = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -3)
        label:SetText(entry.label)
        label:SetTextColor(TEXT[1], TEXT[2], TEXT[3])

        local category = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        category:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 4)
        category:SetText(Addon.L[entry.category] or entry.category)
        category:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

        button.entry = entry
        button:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.24, 0.17, 0.045, 0.96)
            self:SetBackdropBorderColor(0.95, 0.68, 0.12, 1)
        end)
        button:SetScript("OnLeave", function(self)
            local layout = Addon:GetLayout(picker.activeLayout)
            local selected = layout and layout.slots[picker.activeSlot] == self.entry.id
            self:SetBackdropColor(selected and 0.18 or 0.065, selected and 0.13 or 0.065, selected and 0.035 or 0.075, 0.94)
            self:SetBackdropBorderColor(selected and 0.95 or 0.28, selected and 0.68 or 0.29, selected and 0.12 or 0.32, 1)
        end)
        button:SetScript("OnClick", function(self)
            local layout = Addon:GetLayout(picker.activeLayout)
            if layout then
                layout.slots[picker.activeSlot] = self.entry.id
            end
            picker:Hide()
            Addon:RefreshRing()
            Addon:RefreshOptions()
            Addon:PlayUISound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end)
        picker.buttons[catalogIndex] = button
    end

    search:SetScript("OnTextChanged", function()
        Addon:RefreshPicker()
    end)
    picker:SetScript("OnShow", function(self)
        self:Raise()
    end)
    return picker
end

function Addon:RefreshPicker()
    local picker = self.picker
    if not picker then
        return
    end

    local query = strtrim(picker.search:GetText() or ""):lower()
    local visibleIndex = 0
    local layout = self:GetLayout(picker.activeLayout)

    for _, categoryButton in ipairs(picker.categoryButtons) do
        local active = categoryButton.categoryKey == picker.category
        categoryButton:SetEnabled(not active)
    end

    for _, button in ipairs(picker.buttons) do
        local entry = button.entry
        local categoryMatches = picker.category == "CATEGORY_ALL" or entry.category == picker.category
        local searchMatches = query == ""
            or entry.label:lower():find(query, 1, true)
            or entry.id:lower():find(query, 1, true)

        if categoryMatches and searchMatches then
            visibleIndex = visibleIndex + 1
            local column = (visibleIndex - 1) % 2
            local row = math.floor((visibleIndex - 1) / 2)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", column * 330, -(row * 54))

            local selected = layout and layout.slots[picker.activeSlot] == entry.id
            button:SetBackdropColor(selected and 0.18 or 0.065, selected and 0.13 or 0.065, selected and 0.035 or 0.075, 0.94)
            button:SetBackdropBorderColor(selected and 0.95 or 0.28, selected and 0.68 or 0.29, selected and 0.12 or 0.32, 1)
            button:Show()
        else
            button:Hide()
        end
    end

    local rows = math.ceil(visibleIndex / 2)
    picker.scrollChild:SetHeight(math.max(1, rows * 54))
    picker.footer:SetText(self.L.PICKER_COUNT:format(visibleIndex))
end

function Addon:OpenPicker(slotIndex, layoutIndex)
    self.picker.activeSlot = slotIndex
    self.picker.activeLayout = layoutIndex or self.optionsLayout or self.db.defaultLayout
    self.picker.category = "CATEGORY_ALL"
    self.picker.search:SetText("")
    self:RefreshPicker()
    self.picker:Show()
    self.picker:Raise()
    self.picker.search:SetFocus()
    self:PlayUISound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPEN)
end

function Addon:SelectOptionsLayout(layoutIndex)
    self.optionsLayout = math.max(1, math.min(4, tonumber(layoutIndex) or 1))
    self:RefreshOptions()
end

function Addon:RefreshOptions()
    local panel = self.optionsPanel
    if not panel or not self.db then
        return
    end

    self.optionsLayout = self.optionsLayout or self.db.defaultLayout or 1
    local layout = self:GetLayout(self.optionsLayout)
    panel.keyButton:SetText(self:GetPrettyBinding())

    for index = 1, 4 do
        local tab = panel.layoutTabs[index]
        tab:SetText(("%d. %s"):format(index, self.db.layouts[index].name))
        tab:SetEnabled(index ~= self.optionsLayout)
    end

    if not panel.layoutName:HasFocus() then
        panel.layoutName:SetText(layout.name)
    end
    panel.defaultLayout:SetChecked(self.db.defaultLayout == self.optionsLayout)

    for index = 1, 8 do
        local entry = self:GetEntry(index, self.optionsLayout)
        local card = panel.slotCards[index]
        card.icon:SetTexture(entry and entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        card.label:SetText(entry and entry.label or "?")
        card.previousButton:SetEnabled(index > 1)
        card.nextButton:SetEnabled(index < 8)
    end

    panel.preferMouseover:SetChecked(self.db.preferMouseover)
    panel.showTarget:SetChecked(self.db.showTarget)
    panel.playSounds:SetChecked(self.db.playSounds)
    panel.showMinimap:SetChecked(self.db.showMinimap)

    panel.updating = true
    panel.scaleSlider:SetValue(self.db.ringScale)
    panel.scaleSlider.Text:SetText(("%s: %d%%"):format(self.L.RING_SCALE, math.floor(self.db.ringScale * 100 + 0.5)))
    panel.updating = false
end

function Addon:CreateOptions()
    if self.optionsPanel then
        return
    end

    StaticPopupDialogs.EMOTERING_BINDING_CONFLICT = {
        text = self.L.BINDING_CONFLICT,
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            if Addon.pendingBindingKey then
                Addon:ApplyBinding(Addon.pendingBindingKey)
                Addon.pendingBindingKey = nil
            end
        end,
        OnCancel = function()
            Addon.pendingBindingKey = nil
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs.EMOTERING_RESET_CONFIRM = {
        text = self.L.RESET_CONFIRM,
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            Addon:ResetDatabase()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local panel = CreateFrame("Frame")
    panel.name = "EmoteRing"

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 3, -3)
    scroll:SetPoint("BOTTOMRIGHT", -28, 3)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    -- The outer frame always matches WoW's available canvas exactly. Only
    -- the fixed design surface inside it is scaled, so neither the backdrop
    -- nor right-anchored controls can extend beyond the visible boundary.
    local outerBackground = CreateFrame("Frame", nil, content, "BackdropTemplate")
    outerBackground:SetAllPoints()
    ApplyDarkBackdrop(outerBackground, 0.78)

    local background = CreateFrame("Frame", nil, content)
    background:SetSize(OPTIONS_DESIGN_WIDTH, OPTIONS_DESIGN_HEIGHT)
    background:SetPoint("TOP", content, "TOP", 0, -4)

    local function ResizeOptionsCanvas(_, width)
        width = math.max(1, width or scroll:GetWidth() or 1)
        local availableWidth = math.max(1, width - 12)
        local scale = math.min(OPTIONS_MAX_SCALE, availableWidth / OPTIONS_DESIGN_WIDTH)
        scale = math.max(0.25, scale)

        background:SetScale(scale)
        content:SetWidth(math.max(1, width - 4))
        content:SetHeight((OPTIONS_DESIGN_HEIGHT * scale) + 8)
    end
    scroll:SetScript("OnSizeChanged", ResizeOptionsCanvas)

    local title = background:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 28, -22)
    title:SetText(self.L.OPTIONS_TITLE)
    title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])

    local subtitle = background:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText(self.L.OPTIONS_SUBTITLE)
    subtitle:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

    CreateSectionTitle(background, self.L.KEYBIND_TITLE, "TOPLEFT", 28, -78)

    local keyHint = background:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    keyHint:SetPoint("TOPLEFT", 31, -109)
    keyHint:SetText(self.L.KEYBIND_HINT)
    keyHint:SetTextColor(GOLD[1], GOLD[2], GOLD[3])

    local keyButton = CreateFrame("Button", nil, background, "UIPanelButtonTemplate")
    keyButton:SetSize(180, 30)
    keyButton:SetPoint("TOPLEFT", 370, -98)
    keyButton:SetScript("OnClick", function()
        Addon:StartBindingCapture()
    end)
    panel.keyButton = keyButton

    local setKeyLabel = background:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    setKeyLabel:SetPoint("LEFT", keyButton, "RIGHT", 10, 0)
    setKeyLabel:SetText(self.L.SET_KEY)
    setKeyLabel:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

    CreateSectionTitle(background, self.L.LAYOUTS_TITLE, "TOPLEFT", 28, -146)

    local layoutHint = background:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    layoutHint:SetPoint("TOPLEFT", 31, -176)
    layoutHint:SetWidth(675)
    layoutHint:SetJustifyH("LEFT")
    layoutHint:SetText(self.L.LAYOUT_HINT)
    layoutHint:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

    panel.layoutTabs = {}
    for index = 1, 4 do
        local tab = CreateFrame("Button", nil, background, "UIPanelButtonTemplate")
        tab:SetSize(158, 28)
        tab:SetPoint("TOPLEFT", 28 + ((index - 1) * 166), -204)
        tab:SetScript("OnClick", function()
            Addon:SelectOptionsLayout(index)
        end)
        panel.layoutTabs[index] = tab
    end

    local nameLabel = background:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", 31, -246)
    nameLabel:SetText(self.L.LAYOUT_NAME .. ":")
    nameLabel:SetTextColor(GOLD[1], GOLD[2], GOLD[3])

    local layoutName = CreateFrame("EditBox", nil, background, "InputBoxTemplate")
    layoutName:SetSize(210, 28)
    layoutName:SetPoint("LEFT", nameLabel, "RIGHT", 12, 0)
    layoutName:SetAutoFocus(false)
    layoutName:SetMaxLetters(22)
    local function SaveLayoutName(self)
        local layout = Addon:GetLayout(Addon.optionsLayout)
        local value = strtrim(self:GetText() or "")
        if value == "" then
            value = Addon.defaults.layouts[Addon.optionsLayout].name
        end
        layout.name = value
        self:SetText(value)
        self:ClearFocus()
        Addon:RefreshOptions()
    end
    layoutName:SetScript("OnEnterPressed", SaveLayoutName)
    layoutName:SetScript("OnEditFocusLost", SaveLayoutName)
    panel.layoutName = layoutName

    local defaultLayout = CreateCheck(background, self.L.DEFAULT_LAYOUT)
    defaultLayout:SetPoint("TOPLEFT", 370, -237)
    defaultLayout:SetScript("OnClick", function(self)
        Addon.db.defaultLayout = Addon.optionsLayout
        self:SetChecked(true)
        Addon.activeLayout = Addon.db.defaultLayout
        Addon:RefreshRing()
    end)
    panel.defaultLayout = defaultLayout

    CreateSectionTitle(background, self.L.SLOT_TITLE, "TOPLEFT", 28, -286)

    local slotHint = background:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    slotHint:SetPoint("TOPLEFT", 31, -316)
    slotHint:SetWidth(680)
    slotHint:SetJustifyH("LEFT")
    slotHint:SetText(self.L.SLOT_HINT)
    slotHint:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

    panel.slotCards = {}
    for index = 1, 8 do
        local card = CreateSlotCard(background, index)
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        card:SetPoint("TOPLEFT", 28 + (column * 340), -338 - (row * 58))
        panel.slotCards[index] = card
    end

    CreateSectionTitle(background, self.L.GENERAL_TITLE, "TOPLEFT", 28, -584)

    local preferMouseover = CreateCheck(background, self.L.PREFER_MOUSEOVER, self.L.PREFER_MOUSEOVER_TOOLTIP)
    preferMouseover:SetPoint("TOPLEFT", 30, -615)
    preferMouseover:SetScript("OnClick", function(self)
        Addon.db.preferMouseover = self:GetChecked() and true or false
    end)
    panel.preferMouseover = preferMouseover

    local showTarget = CreateCheck(background, self.L.SHOW_TARGET)
    showTarget:SetPoint("TOPLEFT", 30, -648)
    showTarget:SetScript("OnClick", function(self)
        Addon.db.showTarget = self:GetChecked() and true or false
    end)
    panel.showTarget = showTarget

    local playSounds = CreateCheck(background, self.L.PLAY_SOUNDS)
    playSounds:SetPoint("TOPLEFT", 370, -615)
    playSounds:SetScript("OnClick", function(self)
        Addon.db.playSounds = self:GetChecked() and true or false
    end)
    panel.playSounds = playSounds

    local showMinimap = CreateCheck(background, self.L.SHOW_MINIMAP)
    showMinimap:SetPoint("TOPLEFT", 370, -648)
    showMinimap:SetScript("OnClick", function(self)
        Addon.db.showMinimap = self:GetChecked() and true or false
        Addon:UpdateMinimapButton()
    end)
    panel.showMinimap = showMinimap

    local scaleSlider = CreateFrame("Slider", "EmoteRingScaleSlider", background, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", 390, -694)
    scaleSlider:SetWidth(210)
    scaleSlider:SetMinMaxValues(0.75, 1.35)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider.Low = scaleSlider.Low or _G.EmoteRingScaleSliderLow
    scaleSlider.High = scaleSlider.High or _G.EmoteRingScaleSliderHigh
    scaleSlider.Text = scaleSlider.Text or _G.EmoteRingScaleSliderText
    scaleSlider.Low:SetText("75%")
    scaleSlider.High:SetText("135%")
    scaleSlider.Text:SetText(self.L.RING_SCALE)
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        if panel.updating then
            return
        end
        value = math.floor(value * 20 + 0.5) / 20
        Addon.db.ringScale = value
        self.Text:SetText(("%s: %d%%"):format(Addon.L.RING_SCALE, math.floor(value * 100 + 0.5)))
        Addon:RefreshRing()
    end)
    panel.scaleSlider = scaleSlider

    local previewButton = CreateFrame("Button", nil, background, "UIPanelButtonTemplate")
    previewButton:SetSize(145, 30)
    previewButton:SetPoint("BOTTOMLEFT", 28, 22)
    previewButton:SetText(GetLocale() == "deDE" and "Ring-Vorschau" or "Preview ring")
    previewButton:SetScript("OnClick", function()
        Addon:ToggleRingPreview()
    end)

    local resetButton = CreateFrame("Button", nil, background, "UIPanelButtonTemplate")
    resetButton:SetSize(180, 30)
    resetButton:SetPoint("BOTTOMRIGHT", -28, 22)
    resetButton:SetText(self.L.RESET)
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("EMOTERING_RESET_CONFIRM")
    end)

    panel:SetScript("OnShow", function()
        ResizeOptionsCanvas(scroll, scroll:GetWidth())
        Addon:RefreshOptions()
    end)

    self.optionsPanel = panel
    self.bindingCapture = CreateBindingCapture(panel)
    self.picker = CreatePicker()

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "EmoteRing")
        Settings.RegisterAddOnCategory(category)
        self.settingsCategory = category
    end

    self:RefreshOptions()
end
