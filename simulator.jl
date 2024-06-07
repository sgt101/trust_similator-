#"""Author : Simon Thompson, BT."""
#"""License : MIT"""
#using(Plots)
# parameters for the experiments; change these to get a different simulation


rawUT_record=Array{Float64}(1);
increment=0.01
# function definitions drawn from the paper
"""
float updateTTP (float qualityexplationAI, float qualityAI,float tTPα, float tp∃)
#Arguements
qualityexplainationAI
qualityAI

Third Party's Trust  - function of the qualityuality of the explanations
TPT = f(qualityexplainationAI,qualityAI)
The Third Party is the community that is providing out of band information on
the trustworthyness of the AI to the user. This allows users to form opinions
about the AI without interacting with it and to decide whether to interact or not
"""
function updateTTP(qualityExplainationAI, tTP, tTPδ)
    if (tTPδ<0.0)
        if (rand()>qualityExplainationAI)
            tTPδ=1.0
        end
    end
    retval=((1.0 - tTP)*tTPδ)+tTP
    if (retval>1.0) retval=1.0
    end
    return retval
end


"""
this is a user trust update function that ignores the third party
in order to demonstrate the impact on the dynamics of user
trust
"""
function updateUT_noTP(qualityExplainationAI,  tUTP, tTp,uT, userδ)
    if (userδ>0.0)
        if (rand()>qualityExplainationAI)
            userδ =1.0 #get out of gaol
        end
    end
    #rawUT=uT+userδ
    rawUT=((1.0 - uT)*userδ)+uT
    push!(rawUT_record,rawUT)
    retval=(rawUT)
    #this is the difference.
    #retval=(rawUT + (tUTP * tTp)) /2.0 ;
    if retval>1.0 retval=1.0
    end
    return retval
end

function updateUT(qualityExplainationAI,  tUTP, tTp,uT, userδ)
    if (userδ>0.0)
        if (rand()>qualityExplainationAI)
            userδ =1.0 #get out of gaol
        end
    end
    #rawUT=uT+userδ
    rawUT=((1.0 - uT)*userδ)+uT
    push!(rawUT_record,rawUT)
    retval=(rawUT)
    #this is the difference.
    retval=(rawUT + (tUTP * tTp)) /2.0 ;
    if retval>1.0 retval=1.0
    end
    return retval
end


#trying to implement as asymptote of 0
function userGame(thisChance, uT,αU)
    if (thisChance>αU)
        return increment
    else
        return -increment
    end
end


#trying to implement as asymptote of 0
function tpGame(thisChance, tpT,αTP)
    if (thisChance>αTP)
        return  increment
    else
        return -increment
    end
end



#= main loop

=#

noIters = 100
noTrials =10000
thirdPartyTrust = Array{Float64,2}(noIters,noTrials)

userTrust = Array{Float64,2}(noIters,noTrials)
userDeltas = Array{Float64,2}(noIters,noTrials)

userRands = Array{Float64,1}(noIters)
thirdPartyRands = Array{Float64,1}(noIters)
qaiRands = Array{Float64,1}(noTrials)
αTPRands = Array{Float64,1}(noTrials)
αURands = Array{Float64,1}(noTrials)
tUTPRands = Array{Float64,1}(noTrials)
stdres = Array{Float64,1}(noTrials)
meanTrusts = Array{Float64,1}(noTrials)
medianTrusts  = Array{Float64,1}(noTrials)
rand!(userRands)
rand!(αURands)
rand!(thirdPartyRands)
rand!(qaiRands)
rand!(αTPRands)
rand!(tUTPRands)

for trial in 1:noTrials
    #uTrustα=rand()#1.0;
    uTrust=0.9#rand()#1.0;
    tpTrust=0.9#rand()#1.0;
    #startingUT = 0.0
    #startingTPT = 0.0
    trustThreshold = 0.4 #0.4 works
    # decay function
    #k = 0.0
    # number of iterations

    qualityExplainationAI = qaiRands[trial]
    αTP = αTPRands[trial] #perception of TP vs reality as per user explaination
    αU= αURands[trial]#perception of AI vs
    tUTP = tUTPRands[trial]

    for n in 1:noIters
        #run the trials
        #update trust values
        #save them in the arrays
        if (uTrust>trustThreshold)
            userδ = userGame(userRands[n],uTrust,αU)
            #    @show userδ
            tpδ = tpGame(thirdPartyRands[n],tpTrust,αTP)
            #expAIϕ = userRands>αTP ? 1.0 : 0.0
            #change this to updateUT_noTP to run without consulations
            uTrustα = updateUT(qualityExplainationAI, tUTP, tpTrust,uTrust, userδ)
            #    @show uTrustα
            tpTrustα = updateTTP(qualityExplainationAI, tpTrust, tpδ)
        else
            #user sits this one out
            tpδ =tpGame(thirdPartyRands[n],tpTrust,αTP)
            uTrustα = uTrust
            tpTrustα = updateTTP(qualityExplainationAI, tpTrust, tpδ)
            userδ = 0.0

        end
        #if (tpTrustα =NaN)
        #    @show n
        # copy this epoch to the last epoch
        userTrust[n,trial]=uTrustα;
        userDeltas[n,trial]=userδ;
        thirdPartyTrust[n,trial]=tpTrustα;
        uTrust=uTrustα
        tpTrust=tpTrustα
    end
    stdres[trial]=std(userTrust[1:100,trial])
    meanTrusts[trial]=mean(userTrust[1:100,trial])
    medianTrusts[trial]=median(userTrust[1:100,trial])
    #    uTrust = uTrustCache
end



@show "success"
using(Plots)

@show "done"

function doPlots()
    plotJourneys(100)
    renderComparisonMaps()
    plotRelations()
end

function seeParams(trial)
    @show qaiRands[trial]
    @show αTPRands[trial] #perception of TP vs reality as per user explaination
    @show αURands[trial] #perception of AI vs
    @show tUTPRands[trial]
end

"""
create a sorted version of the heatmap for an 2d Array
TO-DO this is a stop gap until t-sne can be used
"""
function sortandmap(array,title)
    firstSort=sort(array,1)
    secondSort=sort(firstSort,2)
    return(heatmap(secondSort,title=title))
end

function renderComparisonMaps()
    allFour = plot(titlefont=font(8),
        heatmap(userTrust, title="User Trust"), sortandmap(userTrust,"User Trust Sorted"),
        heatmap(thirdPartyTrust, title="Third Party Trust"),sortandmap(thirdPartyTrust, "Third Party Trust Sorted"),
        layout =@layout [a b ; c d])
    display(allFour)
    png("simulatorstats\\trustmaps"*string(time()))
end

function plotJourneys(samples)
    x=1:noIters
    #layout = ["showlegend" => false]
    journeys=plot(x,userTrust[1:noIters,1],linewidth=0.01,leg=false,color="blue")
    for n in 1:samples
        plot!(x,userTrust[1:noIters,rand(1:noTrials)],linewidth=1,color="blue",alpha=0.2,leg=false)
        @show n
    end

    display(journeys)
    png("simulatorstats\\journeys"*string(time()))
end

function plotRelations()
    userStats= plot(1:100,stdres[1:100],label="Stdv",title="Statistics of 100 trials")
    plot!(userStats, 1:100,meanTrusts[1:100],label="Mean")
    plot!(userStats,1:100,medianTrusts[1:100],label="Median")
    plot!(userStats, 1:100,userTrust[100,1:100],label="End Value")
    display(userStats)
    png("simulatorstats\\userStats"*string(time()))
end
