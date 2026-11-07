--!strict
-- Restrict observation to the viewer's side; late spectators watch zombies in
-- Active so they cannot reveal human refuges to the infection side.
local State={}
function State.allowed(role: string?,alive: boolean,phase: string?): boolean
    return (phase=="Active" or phase=="Preparation") and (not alive or role=="Lobby")
end
function State.side(role: string?,phase: string?): string
    return if phase=="Preparation" then "Humans" else "Zombies"
end
function State.targets(rows: {any},ownId: number,side: string): {any}
    local list={}
    for _,row in rows do
        if row.Id~=ownId and row.Role==side and row.Alive and row.Ready then table.insert(list,row) end
    end
    table.sort(list,function(a,b)return a.Id<b.Id end)
    return list
end
function State.pick(rows: {any},current: number?,direction: number?): any
    if #rows==0 then return nil end
    local index=1
    for i,row in rows do if row.Id==current then index=i;break end end
    if direction then index=(index-1+direction)%#rows+1 end
    return rows[index]
end
return table.freeze(State)
