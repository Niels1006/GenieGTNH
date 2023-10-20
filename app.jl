module App
using GenieFramework
@genietools

using JSON
using Dates
using PlotlyBase


function read_json()
    return JSON.parsefile(pwd() * "/data/measurements/data.json", inttype=BigInt)
end

function parse_json_energy(json_file, time_limit)
    
    


    arr = json_file["logs"]

    #t_1 = datetime2unix(now())
    t = round(Int, last(arr)["time"])

    averaging_steps::Int16 = 60
    energy_averages = Int128[0 for i in 1:(time_limit/averaging_steps)]
    energy_arr = Int128[0 for i in 1:time_limit]



    for i in (length(arr)-time_limit):length(arr)
        time_ = round(Int, arr[i]["time"])

        delta = (t - (length(arr) - i)) - time_
        absolute_time_delta = time_limit - (t - time_)
        if absolute_time_delta > 0
            energy_arr[absolute_time_delta] = arr[i]["energy"]
        end
    end

    while true
        for i in 1:length(energy_arr)
            if energy_arr[i] == 0
                if i > 1
                    energy_arr[i] = energy_arr[i-1]
                else
                    energy_arr[i] = energy_arr[i+1]
                end
            end
        end
        if energy_arr[1] > 0
            break
        end

    end

    for i::Int32 in 1:(time_limit/averaging_steps)
        energy_averages[i] = sum([energy_arr[(i*averaging_steps-(x-1))] for x in 1:averaging_steps]) / averaging_steps
    end

    return energy_averages
end

function parse_json_mspt(json_file, time_limit)

    arr = json_file["logs"]

    t_1 = datetime2unix(now())
    t = round(Int, last(arr)["time"])

    averaging_steps::Int16 = 60
    energy_averages = Float64[0 for i in 1:(time_limit/averaging_steps)]
    energy_arr = Float64[0 for i in 1:time_limit]



    for i in (length(arr)-time_limit):length(arr)
        time_ = round(Int, arr[i]["time"])

        #delta = (t - (length(arr) - i)) - time_
        absolute_time_delta = time_limit - (t - time_)
        if absolute_time_delta > 0
            energy_arr[absolute_time_delta] = arr[i]["tick_time"]
        end
    end

    while true
        for i in 1:length(energy_arr)
            if energy_arr[i] == 0
                if i > 1
                    energy_arr[i] = energy_arr[i-1]
                else
                    energy_arr[i] = energy_arr[i+1]
                end
            end
        end
        if energy_arr[1] > 0
            break
        end

    end


    for i::Int32 in 1:(time_limit/averaging_steps)
        energy_averages[i] = sum([energy_arr[(i*averaging_steps-(x-1))] for x in 1:averaging_steps]) / averaging_steps
    end

    return energy_averages
end

function get_energy_trace(time_limit)
    energy_averages = parse_json_energy(read_json(), time_limit)

    trace = scatter(
        x=1:length(energy_averages),
        y=energy_averages,
        mode="lines+markers",
        name="Energy",
        line=attr(color="black")
    )

    return trace

end

function get_mspt_trace(time_limit)
    energy_averages = parse_json_mspt(read_json(), time_limit)

    trace = scatter(
        x=1:length(energy_averages),
        y=energy_averages,
        mode="lines+markers",
        name="Energy",
        line=attr(color="black")
    )

    return trace

end


plotlayout_ = PlotlyBase.Layout(
    title="test")


@app begin
    @out options = [
        Dict("label" => x,
            "value" => x
        ) for x in [1, 2, 4, 8]
    ]



    @in time_limit_energy = 1
    @out plotdata_ = []
    @out plotlayout_ = PlotlyBase.Layout(
        title="Wireless Energy Stored",
        colorway="black", plot_bgcolor="white",
        xaxis=Dict(
            :linecolor => "black",
            :showgrid => false,
            :zeroline => true),
        yaxis=Dict(
            :showgrid => false,
            :gridcolor => "black",
            :linecolor => "black",
            :zeroline => true
        )
    )

    @onchange time_limit_energy begin
        if time_limit_energy == -1
            return
        end

        plotdata_ = [get_energy_trace(time_limit_energy * 60 * 60)]

        hours = time_limit_energy

        tick_vals = [(i) * 60 for i in 0:hours]
        tick_labels = [Dates.format(Dates.now() - Hour(i), "HH:MM") for i in reverse(0:hours)]

        plotlayout_ = PlotlyBase.Layout(
            title="Wireless Energy Stored in EU, $time_limit_energy Hours",
            colorway="black", plot_bgcolor="white",
            xaxis=Dict(
                :linecolor => "black",
                :showgrid => false,
                :zeroline => true,
                :dtick => "M1",
                :tickvals => tick_vals,
                :ticktext => tick_labels
            ),
            yaxis=Dict(
                :showgrid => false,
                :gridcolor => "black",
                :linecolor => "black",
                :zeroline => true,
                :showexponent => "all",
                :exponentformat => "e"
            )
        )

    end

    @in time_limit_mspt = -1
    @out plotdata_mspt = []
    @out plotlayout_mspt = PlotlyBase.Layout(
        title="Tick time in ms",
        colorway="black", plot_bgcolor="white",
        xaxis=Dict(
            :linecolor => "black",
            :showgrid => false,
            :zeroline => true),
        yaxis=Dict(
            :showgrid => false,
            :gridcolor => "black",
            :linecolor => "black",
            :zeroline => true
        )
    )

    @onchange time_limit_mspt begin
        if time_limit_mspt == -1
            return
        end

        plotdata_mspt = [get_mspt_trace(time_limit_mspt * 60 * 60)]
        hours = time_limit_mspt

        tick_vals = [(i) * 60 for i in 0:hours]
        tick_labels = [Dates.format(Dates.now() - Hour(i), "HH:MM") for i in reverse(0:hours)]

        plotlayout_mspt = PlotlyBase.Layout(
            title="Tick Time in ms, $time_limit_mspt Hours",
            colorway="black", plot_bgcolor="white",
            xaxis=Dict(
                :linecolor => "black",
                :showgrid => false,
                :zeroline => true,
                :dtick => "M1",
                :tickvals => tick_vals,
                :ticktext => tick_labels
            ),
            yaxis=Dict(
                :showgrid => false,
                :gridcolor => "black",
                :linecolor => "black",
                :zeroline => true,
                :showexponent => "all",
                :exponentformat => "e"
            )
        )
        @info "finished"
    end
end

println("hello")

# register a new route and the page that will be
# loaded on access
@page("/", "app.jl.html")
end
