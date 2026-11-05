-- Actual shared catalog, with a minimal read-only Instance-shaped asset tree.
local Skins=require("../../src/maps/k17/gameplay/WeaponSkins")
local count=0
local function check(ok,label) assert(ok,label);count+=1 end
local function node(class,children)
    return {ClassName=class,FindFirstChild=function(_,id) return children and children[id] end,
        IsA=function(_,wanted) return wanted==class end}
end
local base,classic,gold=node("Tool"),node("Tool"),node("Tool")
local rifle=node("Tool")
local variants={Classic=classic,Gold=gold}
local asset=node("Folder",{Weapons=node("Folder",{Pistol=base,Rifle=rifle}),
    Skins=node("Folder",{Pistol=node("Folder",variants)})})
check(Skins.default("Pistol")=="Black" and Skins.default("Rifle")=="Default","correct defaults")
check(Skins.default("Exploit")==nil and #Skins.options("Exploit")==0,"unknown weapon has no cosmetics")
for _,id in {"Rifle","SMG","Shotgun"} do
    check(#Skins.options(id)==1 and Skins.valid(id,"Default") and not Skins.valid(id,"Gold"),"primary has only original finish")
end
check(Skins.default("LMG")==nil and not Skins.valid("LMG","Default"),"an unimplemented weapon is not advertised by the cosmetic catalog")
check(#Skins.options("Pistol")==3,"three pistol finishes")
check(table.isfrozen(Skins) and table.isfrozen(Skins.options("Pistol")) and table.isfrozen(Skins.options("Pistol")[1]),"catalog and nested options are immutable")
check(not pcall(function() Skins.options("Pistol")[1].Id="Forged" end),"caller cannot mutate selection ids")
for _,bad in {"Default","gold","",{},true,42} do check(not Skins.valid("Pistol",bad),"invalid pistol variant rejected without coercion") end
check(not Skins.valid("Pistol",nil),"nil is not a server-authorized selection")
check(Skins.resolve(asset,"Pistol")==base and Skins.resolve(asset,"Pistol","Black")==base,"black uses existing primary pistol Tool")
check(Skins.resolve(asset,"Pistol","Classic")==classic and Skins.resolve(asset,"Pistol","Gold")==gold,"valid variants use dedicated Tool templates")
check(Skins.resolve(asset,"Pistol","Forged")==base,"presentation of invalid data normalizes to original")
check(Skins.resolve(asset,"Rifle","Gold")==rifle,"invalid primary variant normalizes in presentation only")
check(Skins.resolve(nil,"Pistol","Gold")==nil and Skins.resolve(asset,"Forged","Black")==nil,"missing provider and unknown weapon have no template")
variants.Gold=nil
check(Skins.resolve(asset,"Pistol","Gold")==nil,"selected valid missing variant never silently falls back")
variants.Gold=node("Folder")
check(Skins.resolve(asset,"Pistol","Gold")==nil,"folder masquerading as a variant is rejected")
check(Skins.resolve(asset,"SMG")==nil,"missing base weapon stays absent")
print(("PASS WeaponSkins catalog: %d assertions; immutable options and actual template resolution"):format(count))
