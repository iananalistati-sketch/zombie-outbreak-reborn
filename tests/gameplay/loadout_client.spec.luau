-- The runner injects the current real LocalScript and its pure modules. These
-- doubles check protocol/control flow; no UI rendering or engine input runs.
local Config=assert(loadstring(CONFIG_SOURCE))()
local Rules=assert(loadstring(RULES_SOURCE))()
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end

local function simulation()
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
        }
    end
    local methods={}
    local function instance(class,name,parent)
        local data={ClassName=class,Name=name or class,_children={},_attrs={},_attributeSignals={},_propertySignals={}}
        local result={_data=data}
        setmetatable(result,{__index=function(_,key) return methods[key] or data[key] or data._children[key] end,
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
        if class=="TextButton" then result.Activated=signal() end
        if class=="Humanoid" then result.Health=100;result.HealthChanged=signal() end
        if parent then result.Parent=parent end
        return result
    end
    function methods:IsA(class) return self.ClassName==class or class=="Instance" end
    function methods:GetChildren() local children={};for _,child in self._children do table.insert(children,child) end;return children end
    function methods:FindFirstChild(name) return self._children[name] end
    function methods:WaitForChild(name) return assert(self._children[name],"Unexpected dependency/yield: "..self.Name.."."..name) end
    function methods:FindFirstChildOfClass(class) for _,child in self._children do if child:IsA(class) then return child end end;return nil end
    function methods:IsDescendantOf(parent) local node=self.Parent;while node do if node==parent then return true end;node=node.Parent end;return false end
    function methods:GetAttribute(name) return self._attrs[name] end
    function methods:SetAttribute(name,value) local previous=self._attrs[name];self._attrs[name]=value;if previous~=value and self._attributeSignals[name] then self._attributeSignals[name]:Fire() end end
    function methods:GetAttributeChangedSignal(name) self._attributeSignals[name]=self._attributeSignals[name] or signal();return self._attributeSignals[name] end
    function methods:GetPropertyChangedSignal(name) self._propertySignals[name]=self._propertySignals[name] or signal();return self._propertySignals[name] end
    function methods:Destroy() self.Parent=nil end
    local rs=instance("ReplicatedStorage","ReplicatedStorage")
    local world=instance("Workspace","Workspace")
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
    local modules={}
    for name,value in {Config=Config,Rules=Rules} do local module=instance("ModuleScript",name,shared);modules[module]=value end
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
    local runService={callbacks={},IsStudio=function() return false end}
    function runService:BindToRenderStep(name,priority,callback) self.callbacks[name]={priority=priority,callback=callback} end
    local enum={
        ZIndexBehavior={Sibling="Sibling"},ApplyStrokeMode={Border="Border"},Font={Gotham="Gotham",GothamMedium="GothamMedium",GothamBold="GothamBold"},
        TextXAlignment={Left="Left"},TextYAlignment={Top="Top"},AutomaticSize={Y="Y"},SortOrder={LayoutOrder="LayoutOrder"},
        MouseBehavior={Default="Default",LockCenter="LockCenter"},UserInputState={Begin="Begin",End="End"},ContextActionResult={Pass="Pass",Sink="Sink"},
        KeyCode={B="B",DPadUp="DPadUp",Escape="Escape",ButtonB="ButtonB"},RenderPriority={Camera={Value=200}},
    }
    local services={Players=players,ReplicatedStorage=rs,UserInputService=uis,ContextActionService=cas,GuiService=guiService,RunService=runService}
    local env=setmetatable({game={GetService=function(_,name) return assert(services[name],name) end},workspace=world,
        script={Destroying=signal()},
        Instance={new=function(class) return instance(class) end},Enum=enum,task=tasks,os={clock=function() return now end},
        require=function(module) return assert(modules[module],"Unexpected require") end,
        Color3={fromRGB=function(r,g,b) return {R=r,G=g,B=b} end,new=function(r,g,b) return {R=r*255,G=g*255,B=b*255} end},
        Vector2={new=function(x,y) return {X=x,Y=y} end},UDim={new=function(scale,offset) return {Scale=scale,Offset=offset} end},
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
        cards=panel.Catalog.Weapons,advance=advance,click=click,uis=uis,guiService=guiService,cas=cas,
        key=function(name,state) local action=assert(cas.actions[name],name);local result=action.callback(name,state or "Begin");advance(0);return result end,
        result=function(...) remote.OnClientEvent:Fire(...);advance(0) end,
        render=function(dt) for _,entry in runService.callbacks do entry.callback(dt) end;advance(0) end}
end
local function opened(s) return s.player:GetAttribute("ZO_ShopOpen")==true and s.panel.Visible==true end
local function open(s) s.key("ZO_OpenShop") end
local function choose(s,id) assert(s.click(s.cards[id]),"weapon card must be reachable") end

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
    local s=simulation();s.rs.ZO_WeaponAssets.Weapons.SMG:Destroy();open(s);choose(s,"SMG")
    check(not s.buy.Active,"shop disables purchase until the actual weapon template is present")
    s.click(s.buy,true)
    check(#s.requests==0,"queued purchase callback cannot request an unavailable template")
end

print(("PASS actual Loadout client: %d assertions; UI bindings, Result protocol, pending timers and server-owned attributes (Roblox API doubles)"):format(checks))
