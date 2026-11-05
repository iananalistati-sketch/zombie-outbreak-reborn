--!strict
-- Shared cosmetic catalog. Templates are presentation only: this module does
-- not load services, set gameplay attributes, or alter the weapon statistics.
local WeaponSkins={}
local original=table.freeze({table.freeze({Id="Default",Label="Original"})})
local pistol=table.freeze({
    table.freeze({Id="Black",Label="Preta"}),
    table.freeze({Id="Classic",Label="Clássica"}),
    table.freeze({Id="Gold",Label="Dourada"}),
})
local empty=table.freeze({})
local known=table.freeze({Rifle=true,SMG=true,Shotgun=true,Pistol=true})

function WeaponSkins.default(id: string): string?
    if not known[id] then return nil end
    return if id=="Pistol" then "Black" else "Default"
end

function WeaponSkins.options(id: string)
    if not known[id] then return empty end
    return if id=="Pistol" then pistol else original
end

function WeaponSkins.valid(id: string,skin: string): boolean
    for _,option in WeaponSkins.options(id) do
        if skin==option.Id then return true end
    end
    return false
end

function WeaponSkins.resolve(assets: Instance?,id: string,skin: string?): Tool?
    local fallback=WeaponSkins.default(id)
    if not assets or not fallback then return nil end
    local chosen=if WeaponSkins.valid(id,skin :: any) then skin else fallback
    local folder=assets:FindFirstChild(if chosen==fallback then "Weapons" else "Skins")
    if not folder then return nil end
    local template: Instance?
    if chosen==fallback then template=folder:FindFirstChild(id)
    else
        local variants=folder:FindFirstChild(id)
        template=variants and variants:FindFirstChild(chosen :: string)
    end
    -- An explicitly selected, valid variant must exist. Never silently display
    -- a different paint job while the UI claims the selection succeeded.
    return if template and template:IsA("Tool") then template :: Tool else nil
end

return table.freeze(WeaponSkins)
