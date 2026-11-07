--!strict
-- Server records accepted volleys and actual removed health; never client hits.
local Stats={}
function Stats.new(id: number)
    return {Id=id,Shots=0,Hits=0,Damage=0,Kills=0,Headshots=0,Infections=0,Reward=0}
end
function Stats.shot(record: any)record.Shots+=1 end
function Stats.hit(record: any)if record.Hits<record.Shots then record.Hits+=1 end end
function Stats.damage(record: any,damage: number)
    if damage==damage and damage>0 and damage<1e6 then record.Damage+=damage end
end
function Stats.accuracy(shots: number,hits: number): number
    return if shots<=0 then 0 else math.floor(math.clamp(hits/shots,0,1)*100+.5)
end
function Stats.best(rows: {any}): any
    local best,bestScore=nil,0
    for _,row in rows do
        local score=row.Kills*4+row.Infections*5+row.Objectives*3+(if row.Survived then 2 else 0)+math.min(row.Damage/500,3)
        if score>bestScore or (best and score==bestScore and row.Id<best.Id) then best=row;bestScore=score end
    end
    return best
end
return table.freeze(Stats)
