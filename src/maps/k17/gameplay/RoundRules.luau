--!strict
local RoundRules={}
function RoundRules.motherCount(count: number,ratio: number): number
    if count<2 then return 0 end
    return math.clamp(math.floor(count*ratio),1,count-1)
end
function RoundRules.choose(eligible,previous,count: number,randomIndex)
    local pool={}
    for _,id in eligible do if not previous[id] then table.insert(pool,id) end end
    -- With too few alternatives, include everyone rather than failing selection.
    if #pool<count then pool=table.clone(eligible) end
    for i=#pool,2,-1 do
        local j=randomIndex(i)
        pool[i],pool[j]=pool[j],pool[i]
    end
    local selected={}
    for i=1,math.min(count,#pool) do table.insert(selected,pool[i]) end
    return selected
end
function RoundRules.canInfect(state: string,attackerRole: string?,victimRole: string?,attackerParticipant: boolean,victimParticipant: boolean,attackerAlive: boolean,victimAlive: boolean): boolean
    return state=="Active" and attackerRole=="Zombies" and victimRole=="Humans"
        and attackerParticipant and victimParticipant and attackerAlive and victimAlive
end
function RoundRules.result(humans: number,zombies: number,players: number,minimum: number,remaining: number): string?
    if players<minimum then return "Cancelled" end
    if humans==0 then return "Zombies" end
    if zombies==0 then return "Cancelled" end
    if remaining<=0 then return "Humans" end
    return nil
end
return table.freeze(RoundRules)
