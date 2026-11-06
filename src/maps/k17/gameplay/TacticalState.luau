--!strict
-- Presentation policies only: this module never grants damage, money or roles.
local State={}
function State.ratio(value: number,maximum: number): number
    if maximum<=0 or value~=value or maximum~=maximum then return 0 end
    return math.clamp(value/maximum,0,1)
end
function State.zone(refuges: any,x: number,y: number,z: number): (string,any)
    local chosen,area=nil,math.huge
    for id,refuge in refuges do
        local b=refuge.Bounds
        if y>=refuge.Floor-.5 and y<refuge.Floor+10 and x>=b[1] and x<=b[2] and z>=b[3] and z<=b[4] then
            local size=(b[2]-b[1])*(b[4]-b[3])
            if size<area then chosen={Id=id,Data=refuge};area=size end
        end
    end
    if chosen then return ("%02d / %s"):format(chosen.Id,chosen.Data.Label),chosen.Data end
    if y<-8 then return "Subterrâneo / drenagem",nil end
    if z<=-120 and x<20 then return "Administração",nil end
    if z<=-120 and x>=20 then return "Estação elétrica",nil end
    if x<-165 then return "Depósito",nil end
    if x>165 and z<80 then return "Torre de controle",nil end
    if z>=65 and x<150 then return "Fundição / prensas",nil end
    return "Pátio industrial",nil
end
function State.objective(phase: string,role: string?,winner: string?,stage: string?): (string,string)
    if phase=="Training" then
        local titles={Loading="Preparando personagem",Intro="Prepare sua posição",Fighting="Elimine os infectados",
            Between="Onda vencida · reorganize a defesa",Won="Treino concluído",Lost="Você caiu · preparando nova tentativa"}
        return titles[stage or "Loading"] or "Treino solo","Treino solo"
    end
    if phase=="Preparation" then return "Escolha um refúgio · equipe-se · prepare as barricadas","Preparação" end
    if phase=="Active" then
        if role=="Zombies" then return "Rompa a defesa e infecte os humanos","Infecção" end
        if role=="Humans" then return "Sobreviva ao relógio · vigie os acessos","Sobrevivência" end
        return "Aguarde a próxima rodada","Espectador"
    end
    if phase=="Results" then
        if winner=="Humans" then return "Os humanos resistiram","Vitória humana" end
        if winner=="Zombies" then return "A infecção dominou o complexo","Vitória zumbi" end
        return "Rodada cancelada","Resultado"
    end
    if phase=="Intermission" then return "A próxima preparação começa em instantes","Intervalo" end
    return "Aguardando jogadores prontos","Aguardando"
end
function State.order(rows: {any}): {any}
    local result=table.clone(rows)
    local rank={Humans=1,Zombies=2,Lobby=3}
    table.sort(result,function(a,b)
        local ar,br=rank[a.Role] or 3,rank[b.Role] or 3
        if ar~=br then return ar<br end
        if a.Kills~=b.Kills then return a.Kills>b.Kills end
        if a.Infections~=b.Infections then return a.Infections>b.Infections end
        if a.Name~=b.Name then return a.Name<b.Name end
        return a.Id<b.Id
    end)
    return result
end
local function name(value: any): string
    return if type(value)=="string" then value:sub(1,64) else "Infectado"
end
function State.report(event: any,weapons: any): string?
    if type(event)~="table" then return nil end
    local actor,victim=name(event.Actor),name(event.Victim)
    if event.Kind=="Infection" then return actor.."  → INFECTOU →  "..victim end
    if event.Kind=="Barricade" then return actor.."  → ROMPEU →  "..victim end
    if event.Kind~="Elimination" or not weapons[event.Weapon] then return nil end
    return actor.."  ["..weapons[event.Weapon].Label..(if event.Head==true then " · CABEÇA" else "").."]  "..victim
end
function State.feed(capacity: number,lifetime: number)
    local self={items={},capacity=capacity,lifetime=lifetime}
    function self:expire(now: number)
        for i=#self.items,1,-1 do if self.items[i].expires<=now then table.remove(self.items,i) end end
    end
    function self:push(text: string,now: number,accent: boolean)
        self:expire(now)
        table.insert(self.items,1,{text=text,expires=now+self.lifetime,accent=accent})
        while #self.items>self.capacity do table.remove(self.items) end
    end
    return self
end
return table.freeze(State)
