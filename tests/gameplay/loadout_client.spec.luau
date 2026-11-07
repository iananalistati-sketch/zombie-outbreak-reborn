-- The runner injects the current real LocalScript and its pure modules. These
-- doubles check protocol/control flow; no UI rendering or engine input runs.
local Config=assert(loadstring(CONFIG_SOURCE))()
local Rules=assert(loadstring(RULES_SOURCE))()
local WeaponSkins=assert(loadstring(SKINS_SOURCE))()
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end

local function simulation(options)
    options=options or {}
    local now=10
    local queue={}
    local errors={}
    local function schedule(thread,at,args) table.insert(queue,{thread=thread,at=at,args=args or {}}) end
    local tasks={}
    function tasks.spawn(fn,...) local thread=if type(fn)=="thread" then fn else coroutine.create(fn);schedule(thread,now,{...});return thread end
    tasks.defer=tasks.spawn
    function tasks.delay(seconds,fn,...) schedule(coroutine.create(fn),now+seconds,{...}) end
    function tasks.wait(seconds) return coroutine.yield(seconds or .03) end
    local function signal()
        local callbacks={}
        return {
            Connect=function(_,fn) table.insert(callbacks,fn);return {Disconnect=function() local index=table.find(callbacks,fn);if index then table.remove(callbacks,index) end end} end,
            Fire=function(_,...) for _,fn in table.clone(callbacks) do tasks.spawn(fn,...) end end,
            FireNow=function(_,...) for _,fn in table.clone(callbacks) do fn(...) end end,
        }
    end
    local methods={}
    local function instance(class,name,parent)
        local data={ClassName=class,Name=name or class,_children={},_attrs={},_attributeSignals={},_propertySignals={}}
        local result={_data=data}
        setmetatable(result,{__index=function(_,key)
                if methods[key]~=nil then return methods[key] end
                if data[key]~=nil then return data[key] end
                return data._children[key]
            end,
            __newindex=function(_,key,value)
                local previous=data[key]
                if key=="Parent" then
                    if previous then previous._children[data.Name]=nil end
                    data.Parent=value
                    if value then value._children[data.Name]=result end
                else data[key]=value end
                if value~=previous and data._propertySignals[key] then data._propertySignals[key]:Fire() end
                if key=="Health" and value~=previous and data.HealthChanged then data.HealthChanged:Fire(value) end
            end})
        result.AbsoluteSize={X=960,Y=680};result.Visible=true;result.Active=true
        result.Destroying=signal()
        if class=="TextButton" then result.Activated=signal() end
        if class=="Humanoid" then result.Health=100;result.HealthChanged=signal() end
        if parent then result.Parent=parent end
        return result
    end
    function methods:IsA(class) return self.ClassName==class or class=="Instance" end
    function methods:GetChildren() local children={};for _,child in self._children do table.insert(children,child) end;return children end
    function methods:GetDescendants()
        local result={}
        local function visit(parent) for _,child in parent:GetChildren() do table.insert(result,child);visit(child) end end
        visit(self);return result
    end
    function methods:FindFirstChild(name) return self._children[name] end
    function methods:WaitForChild(name) return assert(self._children[name],"Unexpected dependency/yield: "..self.Name.."."..name) end
    function methods:FindFirstChildOfClass(class) for _,child in self._children do if child:IsA(class) then return child end end;return nil end
    function methods:IsDescendantOf(parent) local node=self.Parent;while node do if node==parent then return true end;node=node.Parent end;return false end
    function methods:GetAttribute(name) return self._attrs[name] end
    function methods:SetAttribute(name,value) local previous=self._attrs[name];self._attrs[name]=value;if previous~=value and self._attributeSignals[name] then self._attributeSignals[name]:Fire() end end
    function methods:GetAttributeChangedSignal(name) self._attributeSignals[name]=self._attributeSignals[name] or signal();return self._attributeSignals[name] end
    function methods:GetPropertyChangedSignal(name) self._propertySignals[name]=self._propertySignals[name] or signal();return self._propertySignals[name] end
    function methods:Destroy() self.Parent=nil end
    local clones={}
    function methods:Clone() table.insert(clones,self.Name);return instance(self.ClassName,self.Name) end
    local rs=instance("ReplicatedStorage","ReplicatedStorage")
    rs.DescendantAdded=signal();rs.DescendantRemoving=signal()
    local world=instance("Workspace","Workspace")
    function world:GetServerTimeNow() return now+1000 end
    local players=instance("Players","Players");players.PlayerAdded=signal();players.PlayerRemoving=signal()
    local player=instance("Player","LocalPlayer",players);players.LocalPlayer=player
    player.Team={Name="Humans"};player.CharacterAdded=signal();player.CharacterRemoving=signal()
    local playerGui=instance("PlayerGui","PlayerGui",player)
    local character=instance("Model","Character",world);local hum=instance("Humanoid","Humanoid",character);player.Character=character
    local other=instance("Player","Other",players)
    function players:GetPlayers() return {player,other} end
    for name,value in {ZO_WeaponId="Rifle",ZO_PrimaryWeapon="Rifle",ZO_SecondaryWeapon="Pistol",
        ZO_Credits=Config.Economy.StartingCredits,ZO_Ammo=Config.Weapons.Rifle.Magazine,ZO_Reserve=Config.Weapons.Rifle.Reserve} do player:SetAttribute(name,value) end
    rs:SetAttribute("ZO_RoundState","Preparation")
    local shared=instance("Folder","K17Gameplay",rs)
    local kit=instance("Folder","ZO_WeaponAssets",rs)
    local templates=instance("Folder","Weapons",kit)
    for _,id in Config.WeaponOrder do instance("Tool",id,templates) end
    local skins=instance("Folder","Skins",kit)
    for _,weapon in Config.WeaponOrder do
        local variants=instance("Folder",weapon,skins)
        for _,option in WeaponSkins.options(weapon) do
            if option.Id~=WeaponSkins.default(weapon) then instance("Tool",option.Id,variants) end
        end
    end
    for _,id in Config.WeaponOrder do player:SetAttribute("ZO_Skin_"..id,WeaponSkins.default(id)) end
    player:SetAttribute("ZO_WeaponSkin","Default")
    local modules={}
    for name,value in {Config=Config,Rules=Rules,WeaponSkins=WeaponSkins} do local module=instance("ModuleScript",name,shared);modules[module]=value end
    local previewWeapons={}
    local previewSkins={}
    local realPreview
    local env
    local previewModule=instance("ModuleScript","WeaponPreview",shared)
    modules[previewModule]={new=function(viewport)
        if options.realPreview then
            local constructor=assert(loadstring(PREVIEW_SOURCE));setfenv(constructor,env)
            realPreview=constructor().new(viewport);return realPreview
        end
        return {setWeapon=function(_,id,skin) table.insert(previewWeapons,id);table.insert(previewSkins,skin) end,destroy=function() end}
    end}
    local remote=instance("RemoteEvent","ZO_LoadoutAction",rs);remote.OnClientEvent=signal()
    local requests={}
    function remote:FireServer(...) table.insert(requests,{...}) end
    local uis={MouseBehavior="LockCenter",MouseIconEnabled=false,TouchEnabled=false,GamepadEnabled=false,
        LastInputTypeChanged=signal(),WindowFocusReleased=signal(),focused=false}
    function uis:GetLastInputType() return {Name="Keyboard"} end
    function uis:GetFocusedTextBox() return if self.focused then {} else nil end
    local guiService={MenuOpened=signal()}
    local cas={actions={}}
    function cas:BindActionAtPriority(name,callback,createButton,priority,...)
        self.actions[name]={callback=callback,createButton=createButton,priority=priority,keys={...}}
    end
    local runService={callbacks={},RenderStepped=signal(),IsStudio=function() return false end}
    function runService:BindToRenderStep(name,priority,callback) self.callbacks[name]={priority=priority,callback=callback} end
    local enum={
        ZIndexBehavior={Sibling="Sibling"},ApplyStrokeMode={Border="Border"},Font={Gotham="Gotham",GothamMedium="GothamMedium",GothamBold="GothamBold"},
        TextXAlignment={Left="Left"},TextYAlignment={Top="Top"},AutomaticSize={Y="Y"},SortOrder={LayoutOrder="LayoutOrder"},
        MouseBehavior={Default="Default",LockCenter="LockCenter"},UserInputState={Begin="Begin",End="End"},ContextActionResult={Pass="Pass",Sink="Sink"},
        KeyCode={B="B",DPadUp="DPadUp",Escape="Escape",ButtonB="ButtonB",One="One",Two="Two",Three="Three",Four="Four",
            Five="Five",Six="Six",Seven="Seven",Eight="Eight",Nine="Nine"},RenderPriority={Camera={Value=200}},
    }
    local services={Players=players,ReplicatedStorage=rs,UserInputService=uis,ContextActionService=cas,GuiService=guiService,RunService=runService}
    env=setmetatable({game={GetService=function(_,name) return assert(services[name],name) end},workspace=world,
        script={Destroying=signal()},
        Instance={new=function(class) return instance(class) end},Enum=enum,task=tasks,os={clock=function() return now end},
        require=function(module) return assert(modules[module],"Unexpected require") end,
        Color3={fromRGB=function(r,g,b) return {R=r,G=g,B=b} end,new=function(r,g,b) return {R=r*255,G=g*255,B=b*255} end},
        Vector2={new=function(x,y) return {X=x,Y=y} end},UDim={new=function(scale,offset) return {Scale=scale,Offset=offset} end},
        Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end},
        UDim2={new=function(...) return {...} end,fromOffset=function(x,y) return {0,x,0,y} end,fromScale=function(x,y) return {x,0,y,0} end}},
        {__index=getfenv()})
    local function advance(seconds)
        local deadline=now+seconds;local limit=0
        while true do
            table.sort(queue,function(a,b) return a.at<b.at end)
            if #queue==0 or queue[1].at>deadline+1e-9 then break end
            local job=table.remove(queue,1);now=job.at;limit+=1;assert(limit<100000,"scheduler runaway")
            local ok,delay=coroutine.resume(job.thread,table.unpack(job.args))
            if not ok then table.insert(errors,tostring(delay))
            elseif coroutine.status(job.thread)~="dead" then schedule(job.thread,now+(delay or .03)) end
        end
        now=deadline
        assert(#errors==0,"real Loadout LocalScript runtime error: "..table.concat(errors," | "))
    end
    local fn=assert(loadstring(LOADOUT_CLIENT_SOURCE,"Loadout.client.luau"));setfenv(fn,env);tasks.spawn(fn);advance(0)
    local gui=assert(playerGui:FindFirstChild("ZO_Loadout"))
    local panel=gui.Arsenal;local actions=panel.Actions
    local function click(button,force)
        if not force then
            if not button.Active then return false end
            local node=button;while node and node~=playerGui do if node.Visible==false then return false end;node=node.Parent end
        end
        button.Activated:Fire();advance(0);return true
    end
    return {player=player,hum=hum,character=character,rs=rs,world=world,remote=remote,requests=requests,gui=gui,panel=panel,
        availability=panel.Availability,credits=panel.Credits,inventory=panel.Inventory,buy=actions.Buy,equip=actions.Equip,ammo=actions.Ammo,
        cards=panel.Catalog.Weapons,categories=panel.Categories,previewWeapons=previewWeapons,previewSkins=previewSkins,
        skins=panel.Catalog.WeaponDetail.Appearances,advance=advance,click=click,uis=uis,guiService=guiService,cas=cas,
        realPreview=realPreview,create=instance,clones=clones,
        key=function(name,state,keyCode) local action=assert(cas.actions[name],name);local result=action.callback(name,state or "Begin",{KeyCode=keyCode});advance(0);return result end,
        result=function(...) remote.OnClientEvent:Fire(...);advance(0) end,
        render=function(dt) for _,entry in runService.callbacks do entry.callback(dt) end;advance(0) end}
end
local function opened(s) return s.player:GetAttribute("ZO_ShopOpen")==true and s.panel.Visible==true end
local function open(s) s.key("ZO_OpenShop") end
local function choose(s,id) assert(s.click(s.cards[id]),"weapon card must be reachable") end
local function category(s,id) assert(s.click(s.categories["Category_"..id]),"category must be reachable") end

do
    for _,entry in {{"SMG","Bronze"},{"Shotgun","Sand"}} do
        local id,skin=entry[1],entry[2]
        local s=simulation();open(s);choose(s,id)
        local before=s.player:GetAttribute("ZO_Credits")
        check(s.buy.Active and s.click(s.buy),id.." bundled model enables a real purchase request")
        check(s.requests[#s.requests][1]=="Buy" and s.requests[#s.requests][2]==id,"category purchase names the selected firearm")
        s.player:SetAttribute("ZO_Credits",before-Config.Weapons[id].Price)
        s.player:SetAttribute("ZO_PrimaryWeapon",id);s.player:SetAttribute("ZO_WeaponId",id)
        s.player:SetAttribute("ZO_Ammo",Config.Weapons[id].Magazine);s.result("Result",true,"Compra confirmada")
        check(s.cards[id].Price.Text=="EM MÃOS" and s.previewWeapons[#s.previewWeapons]==id,"confirmed purchase refreshes selected firearm and preview")
        check(s.skins.Visible and s.skins.Choices["Skin_"..skin].Active,"new weapon shows only its available source finishes")
        s.click(s.skins.Choices["Skin_"..skin])
        check(s.previewSkins[#s.previewSkins]==skin and s.skins.ApplySkin.Active,"native finish can be previewed before application")
        local credits=s.player:GetAttribute("ZO_Credits")
        s.click(s.skins.ApplySkin)
        local request=s.requests[#s.requests]
        check(request[1]=="Skin" and request[2]==id and request[3]==skin,"apply keeps cosmetic and weapon identities separate")
        s.player:SetAttribute("ZO_Skin_"..id,skin);s.player:SetAttribute("ZO_WeaponSkin",skin)
        s.result("Result",true,"Aparência aplicada")
        check(s.player:GetAttribute("ZO_Credits")==credits and not s.skins.ApplySkin.Active,"confirmed finish never spends gameplay credits")
        choose(s,"Pistol");choose(s,id)
        check(s.previewWeapons[#s.previewWeapons]==id and s.previewSkins[#s.previewSkins]==skin,"returning from the pistol restores this firearm's confirmed finish")
    end
end

do
    local s=simulation();open(s)
    check(s.cards.Rifle.Visible and s.cards.SMG.Visible and s.cards.Shotgun.Visible and s.cards.Pistol.Visible,"All category exposes the actual four configured weapons")
    check(#s.previewWeapons>0 and s.previewWeapons[#s.previewWeapons]=="Rifle","shop preview starts with the selected real weapon id")
    category(s,"Pistols")
    check(s.cards.Pistol.Visible and not s.cards.Rifle.Visible and not s.cards.SMG.Visible and not s.cards.Shotgun.Visible,"pistol category hides all primary cards")
    check(s.cards.Pistol.QuickSelect.Text=="1" and s.previewWeapons[#s.previewWeapons]=="Pistol","filtered key label and 3D preview follow the newly visible pistol")
    check(not s.buy.Active and s.equip.Active,"category selection preserves owned secondary equipment rules")
    check(not s.click(s.cards.Rifle),"hidden cards cannot be activated by pointer navigation")
    s.click(s.cards.Rifle,true)
    check(s.previewWeapons[#s.previewWeapons]=="Pistol","late activation from a hidden card cannot change the filtered selection")
    s.key("ZO_ShopSelect","Begin","Four")
    check(s.previewWeapons[#s.previewWeapons]=="Pistol","keys beyond the visible category leave selection unchanged")
    category(s,"All");s.key("ZO_ShopSelect","Begin","Four")
    check(s.previewWeapons[#s.previewWeapons]=="Pistol" and s.cards.Pistol.QuickSelect.Text=="4","all-category keys retain the existing catalog ordering")
    category(s,"Rifles");s.key("ZO_ShopSelect","Begin","One")
    check(s.cards.Rifle.Visible and not s.cards.Pistol.Visible and s.previewWeapons[#s.previewWeapons]=="Rifle","rifle category key 1 targets its first visible entry")
    category(s,"Shotguns")
    check(s.cards.Shotgun.Visible and s.cards.Shotgun.QuickSelect.Text=="1" and s.previewWeapons[#s.previewWeapons]=="Shotgun","shotgun category selects only its real configured entry")
    category(s,"SMG")
    check(s.cards.SMG.Visible and s.cards.SMG.QuickSelect.Text=="1" and s.previewWeapons[#s.previewWeapons]=="SMG","SMG category targets its own entry")
    check(#s.requests==0,"browsing and keyboard category selection do not purchase or mutate inventory")
    s.key("ZO_CloseShop");s.key("ZO_OpenShop")
    check(s.cards.Rifle.Visible and s.cards.Pistol.Visible and s.previewWeapons[#s.previewWeapons]=="Rifle","reopening resets to All and selects the authoritative equipped weapon")
end

do
    local s=simulation();open(s);category(s,"Shotguns");s.click(s.buy)
    category(s,"Pistols");s.click(s.equip,true);s.click(s.ammo,true)
    check(#s.requests==1 and s.requests[1][1]=="Buy" and s.requests[1][2]=="Shotgun","changing categories cannot bypass a pending purchase guard")
    check(s.previewWeapons[#s.previewWeapons]=="Pistol" and not s.equip.Active,"preview browsing remains available while overlapping economic actions stay blocked")
    s.result("Result",true,"Compra confirmada.")
    check(s.equip.Active and s.availability.Text=="Compra confirmada.","server acknowledgement releases actions in the currently visible category")
end

do
    local s=simulation();open(s)
    s.guiService.SelectedObject=s.cards.Rifle
    category(s,"Pistols")
    check(s.guiService.SelectedObject==s.cards.Pistol,"gamepad focus leaves a card that becomes hidden after filtering")
    check(s.categories.Category_Pistols.NextSelectionDown==s.cards.Pistol
        and s.cards.Pistol.NextSelectionUp==s.categories.Category_Pistols,"category and weapon links provide consistent vertical gamepad navigation")
    s.uis.TouchEnabled=true;s.panel.AbsoluteSize={X=320,Y=360};s.advance(0)
    check(s.categories.Size[4]==44 and s.categories.Category_Pistols.Text=="PIST.","compact touch layout keeps all categories in a 44-pixel row with short labels")
end

do
    local s=simulation()
    check(not opened(s) and s.player:GetAttribute("ZO_ShopOpen")==false,"complete real LocalScript starts with its shop closed")
    check(s.cas.actions.ZO_OpenShop.keys[1]=="B","real open action binds B")
    check(s.key("ZO_OpenShop")=="Sink" and opened(s),"B action opens panel and publishes shop-open input guard")
    check(s.uis.MouseBehavior=="Default" and s.uis.MouseIconEnabled,"opening shop releases the cursor")
    s.render(.3)
    check(s.uis.MouseBehavior=="Default","real render callback retains cursor while shop is open")
    check(s.key("ZO_CloseShop")=="Sink" and not opened(s),"close action hides shop")
    check(s.uis.MouseBehavior=="LockCenter" and not s.uis.MouseIconEnabled,"closing restores earlier cursor ownership")
    s.uis.focused=true
    check(s.key("ZO_OpenShop")=="Pass" and not opened(s),"typing in a text box prevents B from opening shop")
    s.uis.focused=false;open(s)
    s.player:SetAttribute("ZO_TacticalMapOpen",true);s.advance(0)
    check(not opened(s) and not s.gui.OpenShop.Visible,"tactical map opening closes shop and hides its toggle")
    check(s.key("ZO_CloseShop")=="Pass","closed shop does not consume another panel's close action")
end

do
    local s=simulation();open(s);choose(s,"Shotgun")
    local credits=s.player:GetAttribute("ZO_Credits")
    check(s.buy.Active,"affordable unowned primary enables purchase")
    check(s.click(s.buy) and #s.requests==1 and s.requests[1][1]=="Buy" and s.requests[1][2]=="Shotgun","buy click requests the selected id through actual FireServer")
    check(not s.buy.Active and not s.equip.Active and not s.ammo.Active,"pending purchase disables overlapping actions")
    check(s.player:GetAttribute("ZO_Credits")==credits and s.player:GetAttribute("ZO_PrimaryWeapon")=="Rifle","sending purchase never mutates server-owned credits or ownership optimistically")
    s.click(s.buy,true);s.click(s.ammo,true)
    check(#s.requests==1,"pending guard rejects duplicate activation even if a callback is delivered twice")
    local waiting=s.availability.Text
    s.result("OtherMessage",true,"unrelated")
    check(s.availability.Text==waiting and not s.buy.Active,"unknown message kind does not clear pending transaction")
    s.result("Result",true,"Compra confirmada: escopeta equipada.")
    check(s.availability.Text=="Compra confirmada: escopeta equipada.","success protocol preserves the server's exact message")
    check(s.availability.TextColor3.R==150 and s.availability.TextColor3.G==221,"success result is presented as success instead of shifted protocol arguments")
    check(s.buy.Active and s.player:GetAttribute("ZO_Credits")==credits,"acknowledgement alone does not invent replicated ownership or debit")
    s.player:SetAttribute("ZO_Credits",credits-Config.Weapons.Shotgun.Price)
    s.player:SetAttribute("ZO_PrimaryWeapon","Shotgun");s.player:SetAttribute("ZO_WeaponId","Shotgun")
    s.player:SetAttribute("ZO_Ammo",Config.Weapons.Shotgun.Magazine);s.player:SetAttribute("ZO_Reserve",Config.Weapons.Shotgun.Reserve);s.advance(0)
    check(s.credits.Text==("CRÉDITOS  $%d"):format(credits-Config.Weapons.Shotgun.Price),"replicated balance changes refresh displayed credits")
    check(not s.buy.Active and s.buy.Text=="ARMA JÁ ADQUIRIDA","replicated ownership changes prevent rebuying owned primary")
    check(s.cards.Shotgun.Price.Text=="EM MÃOS" and string.find(s.inventory.Text,Config.Weapons.Shotgun.Label,1,true)~=nil,"replicated weapon selection refreshes catalogue and inventory")
end

do
    local s=simulation();open(s);choose(s,"SMG");s.click(s.buy)
    s.player:SetAttribute("ZO_Credits",Config.Economy.StartingCredits-Config.Weapons.SMG.Price)
    s.player:SetAttribute("ZO_PrimaryWeapon","SMG");s.player:SetAttribute("ZO_WeaponId","SMG");s.advance(0)
    check(not s.buy.Active and string.find(s.availability.Text,"Aguardando",1,true)~=nil,"attribute replication arriving before Result preserves pending transaction")
    check(s.cards.SMG.Price.Text=="EM MÃOS","early server attributes refresh ownership without fabricating an acknowledgement")
    s.result("Result",true,"Servidor confirmou a SMG.")
    check(s.availability.Text=="Servidor confirmou a SMG." and not s.buy.Active,"Result finishes early-replicated purchase while owned weapon remains unbuyable")
end

do
    local s=simulation();open(s);choose(s,"Shotgun");s.click(s.buy)
    local credits=s.player:GetAttribute("ZO_Credits")
    s.result("Result",false,"Créditos insuficientes no servidor.")
    check(s.availability.Text=="Créditos insuficientes no servidor.","rejection protocol preserves the server's exact reason")
    check(s.availability.TextColor3.R==240 and s.availability.TextColor3.G==146,"rejected result receives failure styling")
    check(s.buy.Active and s.player:GetAttribute("ZO_Credits")==credits,"rejection releases pending state without changing credits")
    s.advance(1);s.click(s.buy);local pendingText=s.availability.Text
    s.advance(3.1)
    check(s.availability.Text==pendingText and not s.buy.Active,"old request timeout cannot clear a newer pending request")
    s.result("Result",true,"Resposta da segunda tentativa.");s.advance(1)
    check(s.availability.Text=="Resposta da segunda tentativa.","second request's completed result survives its obsolete timeout callback")
end

do
    local s=simulation();open(s);choose(s,"SMG");s.click(s.buy)
    s.advance(3.9)
    check(not s.buy.Active,"request remains pending before timeout deadline")
    s.advance(.2)
    check(s.buy.Active and string.find(s.availability.Text,"Sem resposta",1,true)~=nil,"unanswered request times out and allows retry")
    s.click(s.buy)
    check(#s.requests==2 and not s.buy.Active,"retry emits one new request after timeout")
    s.result("Result",false,"Estoque indisponível.")
    check(s.availability.Text=="Estoque indisponível.","retry response reaches visible feedback")
end

do
    local s=simulation();open(s);choose(s,"Pistol")
    check(not s.buy.Active and s.equip.Active,"owned secondary enables equip and blocks purchase")
    s.click(s.equip)
    check(s.requests[1][1]=="Equip" and s.requests[1][2]=="Pistol","equip click sends selected owned weapon id")
    check(s.player:GetAttribute("ZO_WeaponId")=="Rifle","equip request waits for server ownership attributes")
    s.result("Result",true,"Pistola equipada.")
    s.player:SetAttribute("ZO_WeaponId","Pistol");s.advance(0)
    check(not s.equip.Active and s.equip.Text=="EM MÃOS","replicated equipped id disables redundant equip")
    s.click(s.ammo)
    check(#s.requests==2 and s.requests[2][1]=="Ammo" and s.requests[2][2]==nil,"ammo button requests reserve purchase without a client price")
    s.result("Result",true,"Reserva abastecida.")
    s.rs:SetAttribute("ZO_RoundState","Active");s.advance(0);choose(s,"Shotgun")
    check(not s.buy.Active and not s.ammo.Active,"Active phase disables buying weapons and ammunition")
    s.click(s.buy,true);s.click(s.ammo,true)
    check(#s.requests==2,"request guards reject late purchase callbacks after preparation ends")
    choose(s,"Rifle")
    check(s.equip.Active,"owned primary remains available for equip during Active")
end

do
    local s=simulation();open(s);s.hum.Health=0;s.advance(0)
    check(not opened(s),"Humanoid death closes the actual panel")
    check(not s.ammo.Active and not s.buy.Active,"corpse cannot purchase after death")
    s.click(s.ammo,true)
    check(#s.requests==0,"death state is checked again when a queued click arrives")
    s.hum.Health=100;s.advance(0);open(s)
    s.player.Team={Name="Zombies"};s.advance(0)
    check(not opened(s) and not s.ammo.Active,"team change closes shop and disables purchases")
    s.click(s.ammo,true)
    check(#s.requests==0,"zombie cannot send a purchase through client callbacks")
end

do
    local s=simulation();open(s);s.player.CharacterRemoving:Fire(s.character);s.advance(0)
    check(not opened(s),"character removal closes shop")
    open(s);s.uis.WindowFocusReleased:Fire();s.advance(0)
    check(not opened(s),"window focus loss closes shop")
    open(s);s.guiService.MenuOpened:Fire();s.advance(0)
    check(not opened(s),"Roblox menu opening closes shop")
end

do
    local s=simulation();s.rs.ZO_WeaponAssets.Weapons.SMG:Destroy()
    s.rs.ZO_WeaponAssets:SetAttribute("Status_SMG","Missing");open(s);choose(s,"SMG")
    check(not s.buy.Active,"shop disables purchase until the actual weapon template is present")
    check(s.cards.SMG.Price.Text:find("MODELO INDISPONÍVEL",1,true)~=nil
        and s.availability.Text=="Modelo ainda não incluído nesta versão.","unbundled models report availability rather than pretending a download is running")
    s.click(s.buy,true)
    check(#s.requests==0,"queued purchase callback cannot request an unavailable template")
end

do
    local s=simulation();open(s);category(s,"Pistols")
    check(s.skins.Visible and s.skins.Choices.Skin_Black.Visible and s.skins.Choices.Skin_Classic.Visible
        and s.skins.Choices.Skin_Gold.Visible,"pistol displays the three catalogued appearance choices")
    check(s.previewSkins[#s.previewSkins]=="Black" and not s.skins.ApplySkin.Active,"pistol preview begins with the authoritative default appearance")
    local credits,ammo=s.player:GetAttribute("ZO_Credits"),s.player:GetAttribute("ZO_Ammo")
    s.click(s.skins.Choices.Skin_Gold)
    check(s.previewWeapons[#s.previewWeapons]=="Pistol" and s.previewSkins[#s.previewSkins]=="Gold","appearance choice sends the actual variant id to the preview module")
    check(#s.requests==0 and s.player:GetAttribute("ZO_Skin_Pistol")=="Black","browsing a finish does not equip it or send a gameplay request")
    check(s.player:GetAttribute("ZO_Credits")==credits and s.player:GetAttribute("ZO_Ammo")==ammo,"appearance previews do not change credits or ammunition")
    check(s.skins.ApplySkin.Active and s.skins.Status.Text:find("PRÉVIA",1,true)~=nil,"unapplied appearance is labelled as a preview")
    s.click(s.skins.ApplySkin)
    check(#s.requests==1 and s.requests[1][1]=="Skin" and s.requests[1][2]=="Pistol" and s.requests[1][3]=="Gold","apply requests the weapon and appearance through the real loadout remote")
    check(not s.skins.ApplySkin.Active and not s.skins.Choices.Skin_Classic.Active
        and not s.equip.Active and not s.ammo.Active,"pending appearance request shares the existing transaction guard")
    s.click(s.skins.ApplySkin,true);s.click(s.skins.Choices.Skin_Classic,true);s.click(s.ammo,true)
    check(#s.requests==1 and s.previewSkins[#s.previewSkins]=="Gold","queued callbacks cannot overlap a pending appearance change")
    s.player:SetAttribute("ZO_Skin_Pistol","Gold");s.advance(0)
    check(not s.skins.ApplySkin.Active and s.skins.Status.Text=="APLICADA: Dourada","early server appearance replication updates display without clearing the pending request")
    s.result("Result",true,"Aparência aplicada.")
    check(s.availability.Text=="Aparência aplicada." and s.equip.Active,"server acknowledgement releases ordinary equipment controls")
    check(s.player:GetAttribute("ZO_Credits")==credits and s.player:GetAttribute("ZO_Ammo")==ammo,"a cosmetic acknowledgement does not invent an economy or magazine change")
    category(s,"Rifles")
    check(not s.skins.Visible,"weapons with only their original finish do not create an empty skin selector")
end

do
    local s=simulation();open(s);category(s,"Pistols");s.click(s.skins.Choices.Skin_Classic);s.click(s.skins.ApplySkin)
    s.result("Result",false,"Aparência indisponível.")
    check(s.skins.ApplySkin.Active and s.skins.Status.Text:find("PRÉVIA",1,true)~=nil
        and s.player:GetAttribute("ZO_Skin_Pistol")=="Black","rejection preserves the applied appearance and permits a retry")
    s.click(s.skins.ApplySkin);s.result("Result",true,"Aparência aplicada.")
    check(s.skins.Status.Text:find("PRÉVIA",1,true)~=nil,"Result alone does not fabricate an appearance attribute before replication")
    s.key("ZO_CloseShop");s.key("ZO_OpenShop");category(s,"Pistols")
    check(s.previewSkins[#s.previewSkins]=="Black","reopening the shop restores the last server-applied appearance")
    s.rs.ZO_WeaponAssets.Skins.Pistol.Gold:Destroy();s.render(.3)
    check(not s.skins.Choices.Skin_Gold.Active,"a missing variant is disabled even while the default weapon remains available")
    local before=#s.requests;s.click(s.skins.Choices.Skin_Gold,true)
    check(#s.requests==before and s.previewSkins[#s.previewSkins]=="Black","a queued missing-variant activation cannot show or apply another model")
end

do
    local s=simulation();open(s);category(s,"Pistols");s.click(s.skins.Choices.Skin_Gold)
    s.player:SetAttribute("ZO_WeaponId","Pistol");s.player:SetAttribute("ZO_Reloading",true);s.advance(0)
    check(not s.skins.ApplySkin.Active and not s.skins.Choices.Skin_Classic.Active,"current weapon reload disables appearance changes")
    s.click(s.skins.ApplySkin,true);check(#s.requests==0,"reload guard is checked again when an apply callback arrives")
    s.player:SetAttribute("ZO_Reloading",false);s.player:SetAttribute("ZO_EquipReadyAt",s.world:GetServerTimeNow()+1);s.advance(0)
    check(not s.skins.ApplySkin.Active,"current weapon equip delay disables appearance application")
    s.advance(1.1);s.render(.3)
    check(s.skins.ApplySkin.Active,"appearance action resumes after the authoritative equip deadline")
    s.player:SetAttribute("ZO_WeaponId","Rifle");s.player:SetAttribute("ZO_Reloading",true);s.advance(0)
    check(s.skins.ApplySkin.Active,"reloading a different weapon does not block an owned pistol's cosmetic change")
    s.player:SetAttribute("ZO_SecondaryWeapon",nil);s.advance(0)
    check(not s.skins.ApplySkin.Active,"an unowned weapon can be previewed but not customized")
    s.click(s.skins.ApplySkin,true);check(#s.requests==0,"unowned appearance callback emits no request")
end

do
    local s=simulation();open(s);category(s,"Pistols");s.click(s.skins.Choices.Skin_Gold)
    s.uis.TouchEnabled=true;s.panel.AbsoluteSize={X=320,Y=360};s.advance(0)
    check(s.skins.Choices.Size[4]==44 and s.skins.ApplySkin.Size[4]==44,"compact touch skins retain 44-pixel selection and apply targets")
    check(s.panel.Actions.Position[4]==-68 and s.panel.Catalog.WeaponDetail.AutomaticCanvasSize=="Y","skin details scroll without moving the existing purchase footer off screen")
    s.hum.Health=0;s.advance(0);s.click(s.skins.ApplySkin,true)
    check(not s.skins.ApplySkin.Active and #s.requests==0,"death closes and blocks a queued cosmetic action")
    s.hum.Health=100;s.advance(0);open(s);category(s,"Pistols");s.click(s.skins.Choices.Skin_Gold)
    s.player.Team={Name="Zombies"};s.advance(0);s.click(s.skins.ApplySkin,true)
    check(not s.skins.Choices.Skin_Classic.Active and #s.requests==0,"infected role cannot select or apply human weapon appearances")
end

do
    local s=simulation();s.player:SetAttribute("ZO_Skin_Pistol","Gold")
    s.rs.ZO_WeaponAssets.Weapons.Pistol:Destroy();s.advance(0);open(s);category(s,"Pistols")
    check(s.equip.Active and s.cards.Pistol.Price.Text=="NO SEU EQUIPAMENTO","an applied Gold variant remains equippable when the unused Black template is missing")
    s.click(s.equip)
    check(#s.requests==1 and s.requests[1][1]=="Equip" and s.requests[1][2]=="Pistol","equipment requests resolve the server-applied variant rather than requiring the default model")
end

do
    local s=simulation();s.player:SetAttribute("ZO_Skin_Pistol","Gold")
    s.rs.ZO_WeaponAssets.Skins.Pistol.Gold:Destroy();s.advance(0);open(s);category(s,"Pistols")
    check(not s.equip.Active and s.cards.Pistol.Price.Text:find("CARREGANDO MODELO",1,true)~=nil,"a missing applied variant blocks equipment even if the Black template is present")
    s.click(s.equip,true)
    check(#s.requests==0,"queued equip callback cannot silently fall back to a different appearance")
end

do
    -- Exercise the real preview's event/cancellation policy. Rendering and mesh
    -- bounds are outside these UI doubles; seed the completed retained-clone state.
    local s=simulation({realPreview=true});local preview=s.realPreview
    local kit=s.rs.ZO_WeaponAssets
    local gold=kit.Skins.Pistol.Gold
    local function retained(template)
        preview.id="Pistol";preview.skin="Gold";preview.template=template
        preview.model=s.create("Model","RetainedGoldClone",preview.world)
        preview.viewport:SetAttribute("ZO_PreviewStatus","Ready")
        return preview.model
    end
    local clone=retained(gold);local serial=preview.serial;local count=#s.clones
    s.rs.DescendantRemoving:FireNow(gold)
    check(preview.model==nil and clone.Parent==nil and preview.viewport:GetAttribute("ZO_PreviewStatus")=="Unavailable",
        "removing the source template immediately invalidates a retained Ready clone")
    check(preview.serial>serial and preview.id=="Pistol" and preview.skin=="Gold","template removal cancels work while retaining the exact requested weapon and appearance")
    check(gold.Parent~=nil and #s.clones==count,"the before-detachment removal callback never recreates the still-parented source")
    gold:Destroy();s.rs.DescendantAdded:FireNow(kit.Weapons.Pistol);s.advance(0)
    check(#s.clones==count,"a Black template arrival cannot satisfy a missing Gold appearance")
    local replacement=s.create("Tool","Gold",kit.Skins.Pistol)
    s.rs.DescendantAdded:FireNow(replacement);s.advance(0)
    check(#s.clones==count+1 and s.clones[#s.clones]=="Gold" and preview.template==replacement,
        "matching arrival retries cloning the exact replacement variant")
    clone=retained(replacement);s.rs.DescendantRemoving:FireNow(kit)
    check(preview.model==nil and clone.Parent==nil and preview.viewport:GetAttribute("ZO_PreviewStatus")=="Unavailable",
        "removing an ancestor asset provider also invalidates the retained clone")
    kit:Destroy();count=#s.clones;kit.Parent=s.rs;s.rs.DescendantAdded:FireNow(replacement);s.advance(0)
    check(#s.clones==count+1 and s.clones[#s.clones]=="Gold" and preview.template==replacement,"provider restoration recovers the same selected finish")
    preview:destroy();count=#s.clones;s.rs.DescendantAdded:FireNow(replacement);s.advance(0)
    check(#s.clones==count,"destroyed previews disconnect asset lifecycle callbacks")
end

do
    local s=simulation();s.rs:SetAttribute('ZO_RoundMode','Escape');s.rs:SetAttribute('ZO_RoundState','Active');s.advance(0);open(s);choose(s,'Shotgun')
    check(s.ammo.Active and not s.buy.Active,'Escape enables reserve refill while new weapon purchases stay closed')
    s.click(s.ammo);check(s.requests[#s.requests][1]=='Ammo','Escape refill uses the existing authoritative loadout protocol')
    s.result('Result',true,'Reserva abastecida')
    s.rs:SetAttribute('ZO_RoundMode','Survival');s.rs:SetAttribute('ZO_RoundState','Results');s.advance(0)
    s.rs:SetAttribute('ZO_RoundState','Active');s.advance(0)
    check(not s.ammo.Active,'Survival keeps active-round refill unavailable')
end
print(("PASS actual Loadout client: %d assertions; UI bindings, Result protocol, pending timers and server-owned attributes (Roblox API doubles)"):format(checks))
