local ITEM = {}

ITEM.Name = "Funny"
ITEM.Type = "OneUse"

ITEM.FillWeight = 20
ITEM.MinAmt = 0



local funnies = {
    {
        {audio="player/voice/whiskey_passwhiskey2.wav",wait=0,}
    },
    {
        {audio="vo/eli_lab/eli_handle_b.wav",wait=0,}
    },
    {
        {audio="hgrunt/my.wav",wait=0,},
        {audio="hgrunt/ass.wav",wait=0,},
        {audio="hgrunt/is.wav",wait=0,},
        {audio="hgrunt/heavy.wav",wait=0,},
    },
    {
        {audio="vox/ass.wav",wait=0,},
        {audio="vox/blast.wav",wait=0,},
        {audio="vox/usa.wav",wait=0,}
    },
    {
        {audio="scientist/donuteater.wav",wait=0,}
    },
    {
        {audio="scientist/weartie.wav",wait=0,}
    },
    {
        {audio="vo/npc/male01/question06.wav",wait=0,}
    },
    {
        {audio="npc/metropolice/vo/pickupthecan1.wav",wait=0,}
    },
    {
        {audio="vo/engineer_no01.mp3",wait=0,}
    },
    {
        {audio="vo/engineer_moveup01.mp3",wait=0,}
    },
    {
        {audio="vo/heavy_needdispenser01.mp3",wait=0,}
    },
    {
        {audio="vo/soldier_jeers07.mp3",wait=0,}
    },
}

local DoFunny

local function DoFunny(funny,index)
    local audio = funny[index].audio
    EmitSound(audio,vector_origin,0,CHAN_STATIC,1,0)
    nextfunny = funny[index+1]
    if nextfunny then
        local delay = SoundDuration(audio)
        if nextfunny.wait then
            delay = delay + nextfunny.wait
        end
        timer.Simple(delay,function() DoFunny(funny,index+1) end)
    end
end

local lastredeem = 0

function ITEM.RedeemCheck()
    local sinceredeem = CurTime() - lastredeem
    print("running redeemcheck",sinceredeem)
    if sinceredeem < 5 then
        return 5.5 - sinceredeem
    else 
        return true
    end
end

local funnyamt = #funnies

function ITEM.Redeem()
    lastredeem = CurTime()
    DoFunny(funnies[math.random(1,funnyamt)],1)
    --EmitSound("player/voice/whiskey_passwhiskey2.wav",vector_origin,0,CHAN_STATIC,1,0)
end

return ITEM