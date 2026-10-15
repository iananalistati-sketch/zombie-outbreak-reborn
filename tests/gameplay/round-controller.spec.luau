-- Executed by scripts/test_round_controller.py, which injects the current server sources.
-- This runs the actual Round controller, including its Roblox service calls and scheduling.
local passed=0
local function check(ok,label) assert(ok,label);passed+=1 end

local function simulation(options)
    options=options or {}
    local now=0
    local queue={}
    local errors={}
    local history={}
    local function schedule(thread,at,args) table.insert(queue,{thread=thread,at=at,args=args or {}}) end
    local tasks={}
    function tasks.spawn(fn,...)
        local thread=if type(fn)=="thread" then fn else coroutine.create(fn)
        schedule(thread,now,{...});return thread
    end
    tasks.defer=tasks.spawn
    function tasks.delay(seconds,fn,...) schedule(coroutine.create(fn),now+seconds,{...}) end
    function tasks.wait(seconds) return coroutine.yield(seconds or .03) end
    local function signal()
        local handlers={}
        return {
            Connect=function(_,fn)
                table.insert(handlers,fn)
                return {Disconnect=function() local i=table.find(handlers,fn);if i then table.remove(handlers,i) end end}
            end,
            Fire=function(_,...) for _,fn in table.clone(handlers) do tasks.spawn(fn,...) end end,
        }
    end
    local instance
    instance=function(class,name,parent)
        local raw={ClassName=class,Name=name or class,Parent=parent,_children={},_attrs={},_attrSignals={},_propSignals={}}
        if parent then parent._children[raw.Name]=raw end
        local methods={}
        function methods:IsA(kind) return class==kind or kind=="Instance" or (class=="Part" and kind=="BasePart") end
        function methods:GetChildren() local out={};for _,v in raw._children do table.insert(out,v) end;return out end
        function methods:FindFirstChild(name) return raw._children[name] end
        function methods:FindFirstChildOfClass(kind) for _,v in raw._children do if v:IsA(kind) then return v end end;return nil end
        function methods:WaitForChild(name,timeout)
            local deadline=now+(timeout or 100)
            while not raw._children[name] and now<deadline do tasks.wait(.05) end
            return raw._children[name]
        end
        function methods:GetAttribute(name) return raw._attrs[name] end
        function methods:SetAttribute(name,value)
            local changed=raw._attrs[name]~=value;raw._attrs[name]=value
            if changed and raw._attrSignals[name] then raw._attrSignals[name]:Fire() end
            if changed and raw.Name=="ReplicatedStorage" and name=="ZO_RoundState" then table.insert(history,{time=now,state=value}) end
        end
        function methods:GetAttributeChangedSignal(name) raw._attrSignals[name]=raw._attrSignals[name] or signal();return raw._attrSignals[name] end
        function methods:GetPropertyChangedSignal(name) raw._propSignals[name]=raw._propSignals[name] or signal();return raw._propSignals[name] end
        function methods:Destroy() if raw.Parent then raw.Parent._children[raw.Name]=nil end;raw.Parent=nil end
        function methods:PivotTo(value) raw.Pivot=value;raw.PivotCount=(raw.PivotCount or 0)+1 end
        function methods:IsDescendantOf(ancestor) local node=raw.Parent;while node do if node==ancestor then return true end;node=node.Parent end;return false end
        return setmetatable(raw,{__index=function(_,key) return methods[key] or raw._children[key] end,__newindex=function(_,key,value)
            rawset(raw,key,value)
            if key=="Parent" and value then value._children[raw.Name]=raw end
            if raw._propSignals[key] then raw._propSignals[key]:Fire() end
        end})
    end
    local players=instance("Players","Players");players.PlayerAdded=signal();players.PlayerRemoving=signal()
    local list={}
    function players:GetPlayers() return table.clone(list) end
    function players:GetPlayerFromCharacter(char) for _,p in list do if p.Character==char then return p end end;return nil end
    local rs=instance("ReplicatedStorage","ReplicatedStorage")
    local ss=instance("ServerStorage","ServerStorage")
    local teams=instance("Teams","Teams")
    local world=instance("Workspace","Workspace")
    local map=instance("Model","ZO_K17Foundry",world)
    local spawns=instance("Model","Spawns",map)
    local cf
    cf=setmetatable({},{__mul=function() return cf end})
    for _,name in {"HumanSpawn","ZombieSpawn","LobbySpawn"} do local p=instance("Part",name,spawns);p.CFrame=cf end
    local internal=instance("Folder","ZO_Gameplay",ss)
    local infect=instance("BindableFunction","Infect",internal)
    local shared=instance("Folder","Shared",rs)
    local gameplay=instance("Folder","K17Gameplay",rs)
    local modules={}
    local function module(parent,name,value) local m=instance("ModuleScript",name,parent);modules[m]=value;return m end
    module(shared,"RoundConfig",ROUND_CONFIG)
    module(shared,"MapConfig",MAP_CONFIG)
    module(gameplay,"RoundRules",ROUND_RULES)
    module(gameplay,"Rules",GAMEPLAY_RULES)
    local scriptContext={Error=signal()}
    local run={IsStudio=function() return options.studio~=false end}
    local services={Players=players,ReplicatedStorage=rs,ServerStorage=ss,Teams=teams,RunService=run,Workspace=world,ScriptContext=scriptContext}
    local function character(player)
        local char=instance("Model",player.Name.."Character",world)
        local root=instance("Part","HumanoidRootPart",char);root.Color={}
        local head=instance("Part","Head",char);head.Color={}
        local hum=instance("Humanoid","Humanoid",char);hum.Health=100;hum.Died=signal()
        player.Character=char;player.CharacterAdded:Fire(char);return char
    end
    local function addPlayer(name,loaded)
        local p=instance("Player",name,players);p.CharacterAdded=signal();p.UserId=#list+1
        table.insert(list,p)
        if loaded then character(p) end
        players.PlayerAdded:Fire(p);return p
    end
    local serverScript=instance("Script","ZombieRound")
    local env=setmetatable({game={GetService=function(_,name) assert(services[name],name);return services[name] end},workspace=world,task=tasks,
        script=serverScript,require=function(m) assert(modules[m],"unexpected require");return modules[m] end,
        Instance={new=function(class) return instance(class) end},
        Random={new=function() return {NextInteger=function(_,a) return a end} end},BrickColor={new=function(v) return v end},
        Color3={fromRGB=function(...) return {...} end},CFrame={new=function() return cf end},
        typeof=function(v) return if type(v)=="table" and v.ClassName then "Instance" else type(v) end,
        os={clock=function() return now end},warn=function() end,print=function() end}, {__index=getfenv()})
    local function execute(source,name)
        local fn=assert(loadstring(source,name));setfenv(fn,env);tasks.spawn(fn)
    end
    local function advance(untilTime)
        local limit=0
        while true do
            table.sort(queue,function(a,b) return a.at<b.at end)
            if #queue==0 or queue[1].at>untilTime then break end
            local job=table.remove(queue,1);now=job.at;limit+=1;assert(limit<100000,"scheduler runaway")
            local ok,delay=coroutine.resume(job.thread,table.unpack(job.args))
            if not ok then table.insert(errors,tostring(delay));scriptContext.Error:Fire(tostring(delay),"",serverScript)
            elseif coroutine.status(job.thread)~="dead" then schedule(job.thread,now+(delay or .03)) end
        end
        now=untilTime
    end
    if options.dependencies~=false then rs:SetAttribute("ZO_GameplayCombatReady",true);rs:SetAttribute("ZO_BarricadesReady",true) end
    return {rs=rs,players=players,teams=teams,world=world,spawns=spawns,internal=internal,infect=infect,history=history,
        errors=errors,advance=advance,add=addPlayer,character=character,execute=execute,scriptContext=scriptContext,serverScript=serverScript,
        remove=function(p) local i=table.find(list,p);if i then table.remove(list,i) end;p.Parent=nil;players.PlayerRemoving:Fire(p) end}
end

local function stateSeen(s,name) for _,entry in s.history do if entry.state==name then return entry.time end end;return nil end
local function launch(s) if STARTUP_SOURCE then s.execute(STARTUP_SOURCE,"Startup.server.luau") end;s.execute(ROUND_SOURCE,"Round.server.luau") end
local totalBefore=ROUND_CONFIG.Intermission+ROUND_CONFIG.Preparation

do
    local s=simulation();local p1=s.add("A",true);local p2=s.add("B",true);launch(s);s.advance(totalBefore+1)
    check(#s.errors==0,"real Round controller has no runtime errors with two loaded characters: "..table.concat(s.errors," | "))
    check(stateSeen(s,"Intermission")~=nil and stateSeen(s,"Preparation")~=nil and stateSeen(s,"Active")~=nil,"two players reach Active through real controller")
    check(s.rs:GetAttribute("ZO_Humans")==1 and s.rs:GetAttribute("ZO_Zombies")==1,"one random mother and one survivor")
    check(math.abs(stateSeen(s,"Active")-totalBefore)<.3,"configured interval/preparation durations advance without an extra second")
    local zombie=if p1.Team.Name=="Zombies" then p1 else p2
    local human=if zombie==p1 then p2 else p1
    check(zombie.Character.PivotCount==2,"mother is not teleported away on infection")
    check(s.infect.OnInvoke(zombie,human.Character),"real server infection accepts melee-authorized opponent")
    s.advance(totalBefore+2)
    check(s.rs:GetAttribute("ZO_LastWinner")=="Zombies" and s.rs:GetAttribute("ZO_RoundState")=="Results","last survivor infection ends round")
end

do
    local s=simulation({studio=false});local p1=s.add("A",true);s.add("B",true);launch(s);s.advance(totalBefore+1)
    local firstMother=if p1.Team.Name=="Zombies" then p1 else s.players:GetPlayers()[2]
    s.advance(totalBefore+ROUND_CONFIG.Duration+.5)
    check(s.rs:GetAttribute("ZO_LastWinner")=="Humans","real active deadline awards survivors")
    s.advance(totalBefore*2+ROUND_CONFIG.Duration+ROUND_CONFIG.Results+2)
    check(s.rs:GetAttribute("ZO_RoundState")=="Active" and s.rs:GetAttribute("ZO_RoundId")==2,"second round starts automatically on live-style server")
    check(firstMother.Team.Name=="Humans","mother selection avoids same player in next round when possible")
end

do
    local s=simulation();s.add("A",true);launch(s);s.advance(60)
    check(s.rs:GetAttribute("ZO_RoundState")=="Waiting" and not stateSeen(s,"Preparation"),"one player cannot start a live-style round")
    check(#s.errors==0,"one-player waiting has no errors")
end

do
    local s=simulation();s.add("A",true);local late=s.add("B",false);launch(s);s.advance(totalBefore+2)
    check(not stateSeen(s,"Preparation"),"two connected players with one unloaded character stay in explicit loading state")
    s.character(late);s.advance(totalBefore*2+5)
    check(stateSeen(s,"Active")~=nil and #s.errors==0,"late character loading resumes round without manual restart")
end

do
    local s=simulation();s.add("A",true);local p2=s.add("B",true);launch(s);s.advance(ROUND_CONFIG.Intermission+1);s.remove(p2);s.advance(ROUND_CONFIG.Intermission+2)
    check(s.rs:GetAttribute("ZO_LastWinner")=="Cancelled","disconnect during preparation cancels instead of false victory")
end

do
    local s=simulation({dependencies=false});s.add("A",true);s.add("B",true);launch(s);s.advance(25)
    check(not stateSeen(s,"Preparation") and s.rs:GetAttribute("ZO_GameplayStatus")=="Error","missing combat/barricades never starts silent partial gameplay")
    check(type(s.rs:GetAttribute("ZO_GameplayError"))=="string" and #s.rs:GetAttribute("ZO_GameplayError")>0,"missing startup dependency leaves persistent diagnostic")
end

do
    local s=simulation({dependencies=false});s.add("A",true);s.add("B",true);launch(s);s.advance(2)
    check(not stateSeen(s,"Intermission") and s.rs:GetAttribute("ZO_RoundState")=="Starting","late combat dependency is shown as startup, not waiting for players")
    s.rs:SetAttribute("ZO_GameplayCombatReady",true);s.rs:SetAttribute("ZO_BarricadesReady",true);s.advance(totalBefore+4)
    check(stateSeen(s,"Active")~=nil and s.rs:GetAttribute("ZO_GameplayStatus")=="Ready","combat becoming ready resumes round")
end

do
    local s=simulation();s.rs:SetAttribute("ZO_BarricadesReady",false);s.add("A",true);s.add("B",true);launch(s);s.advance(totalBefore+1)
    check(s.rs:GetAttribute("ZO_RoundState")=="Active" and s.rs:GetAttribute("ZO_GameplayStatus")=="Degraded","a failed barricade prop does not block infection gameplay")
end

do
    local s=simulation();s.add("A",true);s.add("B",true);s.execute(STARTUP_SOURCE,"Startup.server.luau");s.advance(23)
    check(s.rs:GetAttribute("ZO_GameplayStatus")=="Error" and s.rs:GetAttribute("ZO_RoundState")=="Error","independent watchdog detects completely missing Round script")
end

do
    local s=simulation();s.add("A",true);s.add("B",true);s.spawns:FindFirstChild("HumanSpawn"):Destroy();launch(s);s.advance(25)
    check(s.rs:GetAttribute("ZO_GameplayStatus")=="Error" and not stateSeen(s,"Waiting"),"missing spawn fails visibly instead of waiting forever")
end

do
    local s=simulation();s.add("A",true);s.add("B",true);launch(s);s.advance(1)
    s.scriptContext.Error:Fire("intentional combat regression","line 42",s.serverScript);s.advance(3)
    check(s.rs:GetAttribute("ZO_GameplayStatus")=="Error","server error monitor exposes controller failure")
    check(s.rs:GetAttribute("ZO_RoundState")=="Error","round controller does not overwrite startup error as Waiting")
end

print(("PASS actual Round startup/controller: %d assertions; two clients, roles, infection, late loading, disconnects and startup failures"):format(passed))
