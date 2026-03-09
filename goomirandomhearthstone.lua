-- goomirandomhearthstone.lua - Random weighted hearthstone module for GoomiUI

if not GoomiUI then
    print("Error: GoomiRandomHearthstone requires GoomiUI to be installed!")
    return
end

local RandomHearthstone = {
    name = "Random Hearthstone",
    version = "1.0",
}

GoomiRandomHearthstoneDB = GoomiRandomHearthstoneDB or {}

-- ========================
-- Constants
-- ========================

local MACRO_NAME = "GoomiHearthstone"
local MACRO_ICON = "INV_Misc_Rune_01"

local REQ_DRAENEI   = "draenei"
local REQ_KYRIAN    = "kyrian"
local REQ_NECROLORD = "necrolord"
local REQ_NIGHTFAE  = "nightfae"
local REQ_VENTHYR   = "venthyr"

local DRAENEI_RACE_IDS = { [11] = true, [30] = true }

local COVENANT_MAP = {
    [REQ_KYRIAN]    = 1,
    [REQ_VENTHYR]   = 2,
    [REQ_NIGHTFAE]  = 3,
    [REQ_NECROLORD] = 4,
}

local CATEGORY_WEIGHTS = {
    [3] = 55,
    [2] = 30,
    [1] = 15,
}

local WEIGHT_LABELS = {
    [0] = "Disabled",
    [1] = "Less Often",
    [2] = "Default",
    [3] = "Very Often",
}

-- ========================
-- Hearthstone Database
-- ========================

local HEARTHSTONE_DATA = {
    { itemID = 166747, name = "Brewfest Reveler's Hearthstone",         isToy = true  },
    { itemID = 190237, name = "Broker Translocation Matrix",            isToy = true  },
    { itemID = 265100, name = "Corewarden's Hearthstone",               isToy = true  },
    { itemID = 246565, name = "Cosmic Hearthstone",                     isToy = true  },
    { itemID = 93672,  name = "Dark Portal",                            isToy = true  },
    { itemID = 208704, name = "Deepdweller's Earthen Hearthstone",      isToy = true  },
    { itemID = 188952, name = "Dominated Hearthstone",                  isToy = true  },
    { itemID = 210455, name = "Draenic Hologem",                        isToy = true,  req = REQ_DRAENEI },
    { itemID = 190196, name = "Enlightened Hearthstone",                isToy = true  },
    { itemID = 172179, name = "Eternal Traveler's Hearthstone",         isToy = true  },
    { itemID = 54452,  name = "Ethereal Portal",                        isToy = true  },
    { itemID = 236687, name = "Explosive Hearthstone",                  isToy = true  },
    { itemID = 166746, name = "Fire Eater's Hearthstone",               isToy = true  },
    { itemID = 162973, name = "Greatfather Winter's Hearthstone",       isToy = true  },
    { itemID = 163045, name = "Headless Horseman's Hearthstone",        isToy = true  },
    { itemID = 6948,   name = "Hearthstone",                            isToy = false, defaultWeight = 0 },
    { itemID = 209035, name = "Hearthstone of the Flame",               isToy = true  },
    { itemID = 168907, name = "Holographic Digitalization Hearthstone",  isToy = true  },
    { itemID = 184353, name = "Kyrian Hearthstone",                     isToy = true,  req = REQ_KYRIAN },
    { itemID = 257736, name = "Lightcalled Hearthstone",                isToy = true  },
    { itemID = 165669, name = "Lunar Elder's Hearthstone",              isToy = true  },
    { itemID = 263489, name = "Naaru's Enfold",                         isToy = true  },
    { itemID = 182773, name = "Necrolord Hearthstone",                  isToy = true,  req = REQ_NECROLORD },
    { itemID = 180290, name = "Night Fae Hearthstone",                  isToy = true,  req = REQ_NIGHTFAE },
    { itemID = 165802, name = "Noble Gardener's Hearthstone",           isToy = true  },
    { itemID = 228940, name = "Notorious Thread's Hearthstone",         isToy = true  },
    { itemID = 200630, name = "Ohn'ir Windsage's Hearthstone",         isToy = true  },
    { itemID = 206195, name = "Path of the Naaru",                      isToy = true  },
    { itemID = 165670, name = "Peddlefeet's Lovely Hearthstone",        isToy = true  },
    { itemID = 245970, name = "P.O.S.T. Master's Express Hearthstone",  isToy = true  },
    { itemID = 263933, name = "Preyseeker's Hearthstone",               isToy = true  },
    { itemID = 235016, name = "Redeployment Module",                    isToy = true  },
    { itemID = 212337, name = "Stone of the Hearth",                    isToy = true  },
    { itemID = 64488,  name = "The Innkeeper's Daughter",               isToy = true  },
    { itemID = 193588, name = "Timewalker's Hearthstone",               isToy = true  },
    { itemID = 142542, name = "Tome of Town Portal",                    isToy = true,  defaultWeight = 0 },
    { itemID = 183716, name = "Venthyr Sinstone",                       isToy = true,  req = REQ_VENTHYR },
}

-- ========================
-- Database
-- ========================

local function InitDB()
    local db = GoomiRandomHearthstoneDB
    if db.setupComplete == nil then db.setupComplete = false end
    if not db.weights then db.weights = {} end

    for _, hs in ipairs(HEARTHSTONE_DATA) do
        if db.weights[hs.itemID] == nil then
            db.weights[hs.itemID] = hs.defaultWeight or 2
        end
        local w = tonumber(db.weights[hs.itemID]) or 2
        db.weights[hs.itemID] = math.max(0, math.min(3, w))
    end
end

-- ========================
-- Ownership & Usability
-- ========================

local cachedRaceID = nil

local function GetPlayerRaceID()
    if not cachedRaceID then
        local _, _, raceID = UnitRace("player")
        cachedRaceID = raceID
    end
    return cachedRaceID
end

local function GetPlayerCovenantID()
    if C_Covenants and C_Covenants.GetActiveCovenantID then
        return C_Covenants.GetActiveCovenantID()
    end
    return 0
end

local function IsHearthstoneOwned(entry)
    if entry.isToy then
        return PlayerHasToy(entry.itemID)
    end
    return C_Item.GetItemCount(entry.itemID) > 0
end

local function IsHearthstoneUsable(entry)
    if not entry.req then return true end

    if entry.req == REQ_DRAENEI then
        return DRAENEI_RACE_IDS[GetPlayerRaceID()] == true
    end

    local requiredCovenant = COVENANT_MAP[entry.req]
    if requiredCovenant then
        return GetPlayerCovenantID() == requiredCovenant
    end

    return true
end

-- ========================
-- Category-Based Selection
-- ========================

local function PickRandomHearthstone()
    local db = GoomiRandomHearthstoneDB
    local pools = { [1] = {}, [2] = {}, [3] = {} }

    for _, hs in ipairs(HEARTHSTONE_DATA) do
        local weight = db.weights[hs.itemID] or 2
        if weight > 0 and IsHearthstoneOwned(hs) and IsHearthstoneUsable(hs) then
            table.insert(pools[weight], hs)
        end
    end

    local categoryPool = {}
    local totalCategoryWeight = 0
    for cat, catWeight in pairs(CATEGORY_WEIGHTS) do
        if #pools[cat] > 0 then
            table.insert(categoryPool, { category = cat, weight = catWeight })
            totalCategoryWeight = totalCategoryWeight + catWeight
        end
    end

    if totalCategoryWeight == 0 then
        return { itemID = 6948, name = "Hearthstone", isToy = false }
    end

    local roll = math.random(1, totalCategoryWeight)
    local cumulative = 0
    local selectedCategory = 2
    for _, entry in ipairs(categoryPool) do
        cumulative = cumulative + entry.weight
        if roll <= cumulative then
            selectedCategory = entry.category
            break
        end
    end

    local pool = pools[selectedCategory]
    return pool[math.random(1, #pool)]
end

-- ========================
-- Toy Name Resolution
-- ========================

local function GetUsableName(entry)
    if entry.isToy then
        local _, name = C_ToyBox.GetToyInfo(entry.itemID)
        return name or GetItemInfo(entry.itemID)
    end
    return GetItemInfo(entry.itemID) or entry.name
end

-- ========================
-- Macro Management
-- ========================

local function BuildMacroBody(pick, useName)
    return "#showtooltip item:" .. pick.itemID .. "\n/use " .. useName .. "\n/run GoomiRH_SetNext()"
end

function GoomiRH_SetNext()
    C_Timer.After(0.1, function()
        if InCombatLockdown() then return end

        local pick = PickRandomHearthstone()
        if not pick then return end

        local useName = GetUsableName(pick)
        if not useName then return end

        local macroIndex = GetMacroIndexByName(MACRO_NAME)
        if not macroIndex or macroIndex == 0 then return end

        EditMacro(macroIndex, MACRO_NAME, MACRO_ICON, BuildMacroBody(pick, useName))
        GoomiRandomHearthstoneDB.lastUsedID = pick.itemID
    end)
end

local function CreateHearthMacro()
    local pick = PickRandomHearthstone()
    local useName = pick and GetUsableName(pick)

    if not useName then
        useName = "Hearthstone"
        pick = { itemID = 6948 }
    end

    local body = BuildMacroBody(pick, useName)
    local existingIndex = GetMacroIndexByName(MACRO_NAME)

    if existingIndex > 0 then
        EditMacro(existingIndex, MACRO_NAME, MACRO_ICON, body)
        print("|cFF3AC2D6GoomiUI:|r Random Hearthstone macro updated!")
        GoomiRandomHearthstoneDB.lastUsedID = pick.itemID
        return true
    end

    if GetNumMacros() >= 120 then
        print("|cFF3AC2D6GoomiUI:|r Could not create macro - general macro slots are full!")
        return false
    end

    CreateMacro(MACRO_NAME, MACRO_ICON, body, false)
    GoomiRandomHearthstoneDB.lastUsedID = pick.itemID
    print("|cFF3AC2D6GoomiUI:|r Random Hearthstone macro created! Drag '" .. MACRO_NAME .. "' from your macro window to an action bar.")
    return true
end

-- ========================
-- First-Time Setup Popup
-- ========================

local setupPopup = nil

local function ShowSetupPopup()
    if setupPopup then setupPopup:Show(); return end

    local frame = CreateFrame("Frame", "GoomiRandomHearthstoneSetup", UIParent, "BackdropTemplate")
    frame:SetSize(480, 260)
    frame:SetPoint("CENTER", 0, 100)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cFF3AC2D6Random Hearthstone|r - Setup")

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", 20, -50)
    text:SetPoint("TOPRIGHT", -20, -50)
    text:SetJustifyH("LEFT")
    text:SetSpacing(3)
    text:SetText(
        "This addon lets you use a random hearthstone toy each time you hearth.\n\n" ..
        "It works through a macro that the addon manages for you. " ..
        "Click the button below to create the macro, then drag it to your action bar.\n\n" ..
        "Each time you use it, the addon automatically picks a new random hearthstone " ..
        "for next time. Configure weights in |cFF3AC2D6/goomi|r settings."
    )
    text:SetTextColor(0.85, 0.85, 0.85, 1)

    local createBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    createBtn:SetSize(180, 30)
    createBtn:SetPoint("BOTTOMLEFT", 30, 20)
    createBtn:SetText("Create Macro For Me")
    createBtn:SetScript("OnClick", function()
        if not InCombatLockdown() then
            CreateHearthMacro()
        else
            print("|cFF3AC2D6GoomiUI:|r Cannot create macro while in combat.")
        end
        GoomiRandomHearthstoneDB.setupComplete = true
        frame:Hide()
    end)

    local dismissBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    dismissBtn:SetSize(180, 30)
    dismissBtn:SetPoint("BOTTOMRIGHT", -30, 20)
    dismissBtn:SetText("I'll Do It Myself")
    dismissBtn:SetScript("OnClick", function()
        GoomiRandomHearthstoneDB.setupComplete = true
        frame:Hide()
    end)

    setupPopup = frame
    frame:Show()
end

-- ========================
-- Border Helper
-- ========================

local function CreateBorder(parent, thickness, r, g, b, a)
    thickness = thickness or 1
    r, g, b, a = r or 0, g or 0, b or 0, a or 1

    for _, info in ipairs({
        { "TOPLEFT", "TOPRIGHT", "height", thickness },
        { "BOTTOMLEFT", "BOTTOMRIGHT", "height", thickness },
        { "TOPLEFT", "BOTTOMLEFT", "width", thickness },
        { "TOPRIGHT", "BOTTOMRIGHT", "width", thickness },
    }) do
        local tex = parent:CreateTexture(nil, "OVERLAY")
        tex:SetColorTexture(r, g, b, a)
        tex:SetPoint(info[1])
        tex:SetPoint(info[2])
        if info[3] == "height" then
            tex:SetHeight(info[4])
        else
            tex:SetWidth(info[4])
        end
    end
end

-- ========================
-- Module Lifecycle
-- ========================

function RandomHearthstone:OnLoad()
    InitDB()

    C_Timer.After(1, function()
        if not InCombatLockdown() then
            GoomiRH_SetNext()
        end
    end)

    if not GoomiRandomHearthstoneDB.setupComplete then
        C_Timer.After(3, function()
            if not GoomiRandomHearthstoneDB.setupComplete then
                ShowSetupPopup()
            end
        end)
    end
end

function RandomHearthstone:OnEnable()
    InitDB()
end

function RandomHearthstone:OnDisable()
end

-- ========================
-- Settings UI
-- ========================

function RandomHearthstone:CreateSettings(parentFrame)
    InitDB()
    local db = GoomiRandomHearthstoneDB

    -- Title + Macro button
    local title = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText("RANDOM HEARTHSTONE")
    title:SetTextColor(1, 1, 1, 1)

    local macroBtn = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate")
    macroBtn:SetSize(130, 22)
    macroBtn:SetPoint("LEFT", title, "RIGHT", 15, 0)
    macroBtn:SetText("Create Macro")
    macroBtn:SetScript("OnClick", function()
        if InCombatLockdown() then
            print("|cFF3AC2D6GoomiUI:|r Cannot create macro in combat.")
            return
        end
        CreateHearthMacro()
    end)

    local yOffset = 30

    -- Filter state
    local activeFilters = {
        owned = false, notOwned = false,
        weight0 = false, weight1 = false, weight2 = false, weight3 = false,
    }

    -- Column header bar
    local colHeaderContainer = CreateFrame("Frame", nil, parentFrame)
    colHeaderContainer:SetSize(600, 22)
    colHeaderContainer:SetPoint("TOPLEFT", 0, -yOffset)
    colHeaderContainer.bg = colHeaderContainer:CreateTexture(nil, "BACKGROUND")
    colHeaderContainer.bg:SetAllPoints()
    colHeaderContainer.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    CreateBorder(colHeaderContainer, 1, 0.2, 0.2, 0.2, 0.5)

    -- Filter popup system
    local activePopup = nil

    local function CloseActivePopup()
        if activePopup then activePopup:Hide(); activePopup = nil end
    end

    local function CreateFilterPopup(anchorFrame, options)
        CloseActivePopup()

        local popup = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
        popup:SetFrameStrata("DIALOG")
        popup:SetSize(140, #options * 24 + 32)
        popup:SetPoint("TOP", anchorFrame, "BOTTOM", 0, -2)
        popup:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        popup:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
        popup:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local popupY = -4
        for _, opt in ipairs(options) do
            local cb = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 6, popupY)
            cb:SetSize(20, 20)
            cb:SetChecked(activeFilters[opt.key])
            cb.text:SetText(opt.label)
            cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            cb.text:SetTextColor(0.9, 0.9, 0.9, 1)
            cb.text:SetFontObject("GameFontNormalSmall")
            cb:SetScript("OnClick", function(self)
                activeFilters[opt.key] = self:GetChecked() and true or false
                RandomHearthstone:RefreshHearthstoneList()
            end)
            popupY = popupY - 24
        end

        local clearBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
        clearBtn:SetSize(60, 18)
        clearBtn:SetPoint("BOTTOM", 0, 5)
        clearBtn:SetText("Clear")
        clearBtn:SetScript("OnClick", function()
            for _, opt in ipairs(options) do activeFilters[opt.key] = false end
            CloseActivePopup()
            RandomHearthstone:RefreshHearthstoneList()
        end)

        popup:SetScript("OnShow", function()
            popup:SetScript("OnUpdate", function()
                if not popup:IsMouseOver() and not anchorFrame:IsMouseOver() and IsMouseButtonDown("LeftButton") then
                    CloseActivePopup()
                end
            end)
        end)
        popup:SetScript("OnHide", function() popup:SetScript("OnUpdate", nil) end)

        activePopup = popup
        popup:Show()
    end

    -- Column header factory
    local allHeaders = {}

    local function CreateColumnHeader(text, xPos, width, filterOptions)
        local header = CreateFrame("Button", nil, colHeaderContainer)
        header:SetSize(width, 22)
        header:SetPoint("TOPLEFT", xPos, 0)

        header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header.text:SetPoint("LEFT", 4, 0)
        header.text:SetTextColor(1, 1, 1, 1)

        local function UpdateHeaderText()
            local anyActive = false
            if filterOptions then
                for _, opt in ipairs(filterOptions) do
                    if activeFilters[opt.key] then anyActive = true; break end
                end
            end
            header.text:SetText(anyActive and (text .. " |cFF3AC2D6*|r") or text)
        end
        header.UpdateHeaderText = UpdateHeaderText
        UpdateHeaderText()

        if filterOptions then
            header:SetScript("OnClick", function()
                if activePopup then CloseActivePopup() else CreateFilterPopup(header, filterOptions) end
            end)
            header:SetScript("OnEnter", function(self) self.text:SetTextColor(0.23, 0.76, 0.84, 1) end)
            header:SetScript("OnLeave", function(self) self.text:SetTextColor(1, 1, 1, 1); UpdateHeaderText() end)
        end

        table.insert(allHeaders, header)
        return header
    end

    CreateColumnHeader("Name", 38, 60, nil)

    local searchBox = CreateFrame("EditBox", nil, colHeaderContainer, "InputBoxTemplate")
    searchBox:SetSize(130, 18)
    searchBox:SetPoint("LEFT", 100, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("GameFontNormalSmall")

    searchBox.placeholder = colHeaderContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchBox.placeholder:SetPoint("LEFT", searchBox, "LEFT", 4, 0)
    searchBox.placeholder:SetText("Search...")
    searchBox.placeholder:SetTextColor(0.4, 0.4, 0.4, 1)

    searchBox:SetScript("OnEditFocusGained", function(self) self.placeholder:Hide() end)
    searchBox:SetScript("OnEditFocusLost", function(self) if self:GetText() == "" then self.placeholder:Show() end end)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    CreateColumnHeader("Status", 310, 100, {
        { key = "owned", label = "Owned" },
        { key = "notOwned", label = "Not Owned" },
    })

    CreateColumnHeader("Weight", 420, 130, {
        { key = "weight0", label = "0: Disabled" },
        { key = "weight1", label = "1: Less Often" },
        { key = "weight2", label = "2: Default" },
        { key = "weight3", label = "3: Very Often" },
    })

    yOffset = yOffset + 24

    -- Scroll frame
    local listContainer = CreateFrame("Frame", nil, parentFrame)
    listContainer:SetPoint("TOPLEFT", 0, -yOffset)
    listContainer:SetPoint("BOTTOMRIGHT", parentFrame:GetParent(), "BOTTOMRIGHT", -20, 45)
    listContainer.bg = listContainer:CreateTexture(nil, "BACKGROUND")
    listContainer.bg:SetAllPoints()
    listContainer.bg:SetColorTexture(0.06, 0.06, 0.06, 0.5)
    CreateBorder(listContainer, 1, 0.2, 0.2, 0.2, 0.5)

    local scrollFrame = CreateFrame("ScrollFrame", "GoomiRHScrollFrame", listContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 2, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -22, 2)

    local scrollBar = _G["GoomiRHScrollFrameScrollBar"]
    if scrollBar then
        scrollBar:GetThumbTexture():SetColorTexture(0.3, 0.3, 0.3, 0.8)
        scrollBar:GetThumbTexture():SetSize(8, 40)
        scrollBar:SetWidth(8)
    end

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(560, 1)
    scrollFrame:SetScrollChild(scrollChild)

    local listRows = {}

    -- Build / Refresh the list
    function RandomHearthstone:RefreshHearthstoneList()
        for _, row in ipairs(listRows) do row:Hide(); row:ClearAllPoints(); row:SetParent(nil) end
        wipe(listRows)

        local searchText = searchBox:GetText():lower()
        local anyOwnerFilter = activeFilters.owned or activeFilters.notOwned
        local anyWeightFilter = activeFilters.weight0 or activeFilters.weight1 or activeFilters.weight2 or activeFilters.weight3

        local ownedList, unownedList = {}, {}

        for _, hs in ipairs(HEARTHSTONE_DATA) do
            local owned = IsHearthstoneOwned(hs)
            local weight = db.weights[hs.itemID] or 2
            local pass = true

            if searchText ~= "" and not hs.name:lower():find(searchText, 1, true) then pass = false end
            if pass and anyOwnerFilter and not ((activeFilters.owned and owned) or (activeFilters.notOwned and not owned)) then pass = false end
            if pass and anyWeightFilter and not ((activeFilters.weight0 and weight == 0) or (activeFilters.weight1 and weight == 1) or (activeFilters.weight2 and weight == 2) or (activeFilters.weight3 and weight == 3)) then pass = false end

            if pass then
                table.insert(owned and ownedList or unownedList, hs)
            end
        end

        local displayList = {}
        for _, hs in ipairs(ownedList) do table.insert(displayList, { entry = hs, owned = true }) end
        for _, hs in ipairs(unownedList) do table.insert(displayList, { entry = hs, owned = false }) end

        local ROW_HEIGHT = 36
        local rowY = 0

        for i, item in ipairs(displayList) do
            local hs = item.entry
            local owned = item.owned
            local weight = db.weights[hs.itemID] or 2
            local usable = owned and IsHearthstoneUsable(hs)

            local row = CreateFrame("Frame", nil, scrollChild)
            row:SetSize(555, ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 0, -rowY)

            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            local shade = i % 2 == 0 and 0.09 or 0.07
            row.bg:SetColorTexture(shade, shade, shade, i % 2 == 0 and 0.6 or 0.3)

            -- Icon
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(28, 28)
            icon:SetPoint("LEFT", 4, 0)
            if hs.isToy then
                local _, _, toyIcon = C_ToyBox.GetToyInfo(hs.itemID)
                icon:SetTexture(toyIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
            else
                icon:SetTexture(C_Item.GetItemIconByID(hs.itemID) or "Interface\\Icons\\INV_Misc_Rune_01")
            end
            if not owned then icon:SetDesaturated(true); icon:SetAlpha(0.4) end

            -- Name
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("LEFT", 38, 0)
            nameText:SetWidth(260)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(hs.name)
            nameText:SetTextColor(owned and 1 or 0.5, owned and 1 or 0.5, owned and 1 or 0.5, owned and 1 or 0.7)

            -- Tooltip (icon + name area)
            local hoverZone = CreateFrame("Frame", nil, row)
            hoverZone:SetPoint("LEFT", 0, 0)
            hoverZone:SetSize(300, ROW_HEIGHT)
            hoverZone:EnableMouse(true)
            local hsID, hsToy = hs.itemID, hs.isToy
            hoverZone:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if hsToy then GameTooltip:SetToyByItemID(hsID) else GameTooltip:SetItemByID(hsID) end
                GameTooltip:Show()
            end)
            hoverZone:SetScript("OnLeave", function() GameTooltip:Hide() end)

            -- Status
            local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            statusText:SetPoint("LEFT", 310, 0)
            if not owned then
                statusText:SetText("|cFF888888Not Owned|r")
            elseif usable then
                statusText:SetText("|cFF55DD55Owned|r")
            else
                statusText:SetText("|cFFDD8822Unusable|r")
            end

            -- Weight controls
            if usable then
                local WEIGHT_COLORS = {
                    [0] = {0.5, 0.5, 0.5}, [1] = {0.9, 0.7, 0.2},
                    [2] = {1, 1, 1},        [3] = {0.2, 0.8, 0.4},
                }

                local minus = CreateFrame("Button", nil, row)
                minus:SetSize(20, 20)
                minus:SetPoint("LEFT", 420, 0)
                minus.bg = minus:CreateTexture(nil, "BACKGROUND"); minus.bg:SetAllPoints(); minus.bg:SetColorTexture(0.2, 0.2, 0.2, 1)
                CreateBorder(minus, 1, 0.3, 0.3, 0.3, 1)
                minus.text = minus:CreateFontString(nil, "OVERLAY", "GameFontNormal"); minus.text:SetPoint("CENTER", 0, 1); minus.text:SetText("-"); minus.text:SetTextColor(0.9, 0.9, 0.9, 1)

                local weightDisplay = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                weightDisplay:SetPoint("LEFT", minus, "RIGHT", 6, 0)
                weightDisplay:SetWidth(24); weightDisplay:SetJustifyH("CENTER")

                local function UpdateWeight()
                    local w = db.weights[hs.itemID] or 2
                    local c = WEIGHT_COLORS[w] or WEIGHT_COLORS[2]
                    weightDisplay:SetTextColor(c[1], c[2], c[3], 1)
                    weightDisplay:SetText(tostring(w))
                end
                UpdateWeight()

                local plus = CreateFrame("Button", nil, row)
                plus:SetSize(20, 20)
                plus:SetPoint("LEFT", weightDisplay, "RIGHT", 6, 0)
                plus.bg = plus:CreateTexture(nil, "BACKGROUND"); plus.bg:SetAllPoints(); plus.bg:SetColorTexture(0.2, 0.2, 0.2, 1)
                CreateBorder(plus, 1, 0.3, 0.3, 0.3, 1)
                plus.text = plus:CreateFontString(nil, "OVERLAY", "GameFontNormal"); plus.text:SetPoint("CENTER", 0, 1); plus.text:SetText("+"); plus.text:SetTextColor(0.9, 0.9, 0.9, 1)

                local wLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                wLabel:SetPoint("LEFT", plus, "RIGHT", 8, 0)
                wLabel:SetText(WEIGHT_LABELS[weight] or ""); wLabel:SetTextColor(0.6, 0.6, 0.6, 1)

                minus:SetScript("OnClick", function()
                    db.weights[hs.itemID] = math.max(0, (db.weights[hs.itemID] or 2) - 1)
                    UpdateWeight(); wLabel:SetText(WEIGHT_LABELS[db.weights[hs.itemID]] or "")
                end)
                plus:SetScript("OnClick", function()
                    db.weights[hs.itemID] = math.min(3, (db.weights[hs.itemID] or 2) + 1)
                    UpdateWeight(); wLabel:SetText(WEIGHT_LABELS[db.weights[hs.itemID]] or "")
                end)
                for _, btn in ipairs({minus, plus}) do
                    btn:SetScript("OnEnter", function(self) self.bg:SetColorTexture(0.3, 0.3, 0.3, 1) end)
                    btn:SetScript("OnLeave", function(self) self.bg:SetColorTexture(0.2, 0.2, 0.2, 1) end)
                end
            else
                local d = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                d:SetPoint("LEFT", 420, 0); d:SetText("—"); d:SetTextColor(0.3, 0.3, 0.3, 1)
            end

            table.insert(listRows, row)
            rowY = rowY + ROW_HEIGHT + 1
        end

        scrollChild:SetHeight(math.max(rowY, 1))
        for _, h in ipairs(allHeaders) do if h.UpdateHeaderText then h:UpdateHeaderText() end end
    end

    searchBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then RandomHearthstone:RefreshHearthstoneList() end
    end)

    RandomHearthstone:RefreshHearthstoneList()

    -- Reset Weights
    local resetBtn = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 30)
    resetBtn:SetPoint("BOTTOMRIGHT", parentFrame:GetParent(), "BOTTOMRIGHT", -20, 10)
    resetBtn:SetText("Reset Weights")
    resetBtn:SetScript("OnClick", function()
        for _, hs in ipairs(HEARTHSTONE_DATA) do db.weights[hs.itemID] = hs.defaultWeight or 2 end
        RandomHearthstone:RefreshHearthstoneList()
    end)
end

GoomiUI:RegisterModule("Random Hearthstone", RandomHearthstone)