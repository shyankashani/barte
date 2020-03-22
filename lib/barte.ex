defmodule Barte do
  def trips(orig, dest) do
    {etd, depart} = {etd(orig), depart(orig, dest)}
  end

  def etd(orig) do
    {:ok, resp} =
      HTTPoison.get(
        "http://api.bart.gov/api/etd.aspx?cmd=etd&orig=#{orig}&key=MW9S-E7SL-26DU-VV8V&json=y"
      )

    {:ok, body} = Poison.decode(resp.body)
    [station] = body |> get_in(["root", "station"])
    %{ "etd" => etd } = station

    etd
    |> process_val()
  end

  def depart(orig, dest) do
    {:ok, resp} =
      HTTPoison.get(
        "http://api.bart.gov/api/sched.aspx?cmd=depart&orig=#{orig}&dest=#{dest}&b=#{0}&a=#{4}&key=MW9S-E7SL-26DU-VV8V&json=y"
      )

    {:ok, body} = Poison.decode(resp.body)

    body
    |> get_in(["root", "schedule", "request", "trip"])
    |> process_val()
  end

  defp pair(etd, depart) do

  end

  defp process_map(map) do
    processed_map = for {key, val} <- map, into: %{}, do: {process_key(key), process_val(val)}

    case processed_map do
      %{estimate: estimate} ->
        process_etd(processed_map)

      %{minutes: minutes} ->
         process_estimate(processed_map)

      %{leg: leg} ->
        process_trip(processed_map)

      %{trainHeadStation: trainHeadStation} ->
        process_leg(processed_map)

      _ ->
        processed_map
    end
  end

  defp process_etd(etd) do
    etd
    |> Map.merge(%{estimates: etd.estimate, headStation: station_abbreviation(etd.destination)})
    |> Map.drop([:estimate, :destination, :abbreviation, :limited])
  end

  defp process_estimate(estimate) do
    estimate
    |> Map.drop([:bikeflag])
  end

  defp process_trip(trip) do
    trip
    |> collapse_times()
    |> Map.merge(%{destStation: trip.destination, origStation: trip.origin, legs: trip.leg})
    |> Map.drop([:clipper, :fare, :fares, :leg, :destination, :origin])
  end

  defp process_leg(leg) do
    leg
    |> collapse_times()
    |> Map.merge(%{destStation: leg.destination, origStation: leg.origin, headStation: station_abbreviation(leg.trainHeadStation)})
    |> Map.drop([:load, :bikeflag, :trainHeadStation, :destination, :origin])
  end

  defp collapse_times(map) do
    %{
      destTimeDate: destTimeDate,
      destTimeMin: destTimeMin,
      origTimeDate: origTimeDate,
      origTimeMin: origTimeMin
    } = map

    destAt =
      destTimeDate
      |> NaiveDateTime.add(destTimeMin.hour * 60 * 60, :second)
      |> NaiveDateTime.add(destTimeMin.minute * 60, :second)
      |> NaiveDateTime.add(destTimeMin.second, :second)

    origAt =
      origTimeDate
      |> NaiveDateTime.add(origTimeMin.hour * 60 * 60, :second)
      |> NaiveDateTime.add(origTimeMin.minute * 60, :second)
      |> NaiveDateTime.add(origTimeMin.second, :second)

    map
    |> Map.merge(%{destAt: destAt, origAt: origAt})
    |> Map.drop([:destTimeDate, :destTimeMin, :origTimeDate, :origTimeMin])
  end

  defp process_key("@" <> rest), do: rest |> String.to_atom()
  defp process_key(key), do: key |> String.to_atom()

  defp process_val("ROUTE " <> rest), do: String.to_integer(rest)
  defp process_val(val) when is_list(val), do: for(v <- val, do: process_val(v))
  defp process_val(val) when is_map(val), do: process_map(val)

  defp process_val(val) do
    cond do
      is_val_integer(val) ->
        String.to_integer(val)

      is_val_float(val) ->
        String.to_float(val)

      is_val_datetime(val, "{Mshort} {D}, {YYYY}") ->
        elem(Timex.parse(val, "{Mshort} {D}, {YYYY}"), 1)

      is_val_datetime(val, "{M}/{D}/{YYYY}") ->
        elem(Timex.parse(val, "{M}/{D}/{YYYY}"), 1)

      is_val_datetime(val, "{h12}:{m} {AM}") ->
        elem(Timex.parse(val, "{h12}:{m} {AM}"), 1)

      true ->
        val
    end
  end

  defp is_val_integer(val) do
    case Integer.parse(val) do
      {int, ""} -> true
      _ -> false
    end
  end

  defp is_val_float(val) do
    case Float.parse(val) do
      {flo, ""} -> true
      _ -> false
    end
  end

  defp is_val_datetime(val, format) do
    case Timex.parse(val, format) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp station_abbreviation(station) do
    case station do
      station when station in ["12th St. Oakland City Center"] ->
        "12TH"
      station when station in ["16th St. Mission"] ->
        "16TH"
      station when station in ["19th St. Oakland"] ->
        "19TH"
      station when station in ["24th St. Mission"] ->
        "24TH"
      station when station in ["Antioch"] ->
        "ANTC"
      station when station in ["Ashby"] ->
        "ASHB"
      station when station in ["Balboa Park"] ->
        "BALB"
      station when station in ["Bay Fair"] ->
        "BAYF"
      station when station in ["Castro Valley"] ->
        "CAST"
      station when station in ["Civic Center/UN Plaza"] ->
        "CIVC"
      station when station in ["Coliseum"] ->
        "COLS"
      station when station in ["Colma"] ->
        "COLM"
      station when station in ["Concord"] ->
        "CONC"
      station when station in ["Daly City"] ->
        "DALY"
      station when station in ["Downtown Berkeley"] ->
        "DBRK"
      station when station in ["Dublin/Pleasanton"] ->
        "DUBL"
      station when station in ["El Cerrito del Norte"] ->
        "DELN"
      station when station in ["El Cerrito Plaza"] ->
        "PLZA"
      station when station in ["Embarcadero"] ->
        "EMBR"
      station when station in ["Fremont"] ->
        "FRMT"
      station when station in ["Fruitvale"] ->
        "FTVL"
      station when station in ["Glen Park"] ->
        "GLEN"
      station when station in ["Hayward"] ->
        "HAYW"
      station when station in ["Lafayette"] ->
        "LAFY"
      station when station in ["Lake Merritt"] ->
        "LAKE"
      station when station in ["MacArthur"] ->
        "MCAR"
      station when station in ["Millbrae"] ->
        "MLBR"
      station when station in ["Montgomery St."] ->
        "MONT"
      station when station in ["North Berkeley"] ->
        "NBRK"
      station when station in ["North Concord/Martinez"] ->
        "NCON"
      station when station in ["Oakland International Airport"] ->
        "OAKL"
      station when station in ["Orinda"] ->
        "ORIN"
      station when station in ["Pittsburg/Bay Point"] ->
        "PITT"
      station when station in ["Pittsburg Center"] ->
        "PCTR"
      station when station in ["Pleasant Hill/Contra Costa Centre"] ->
        "PHIL"
      station when station in ["Powell St."] ->
        "POWL"
      station when station in ["Richmond"] ->
        "RICH"
      station when station in ["Rockridge"] ->
        "ROCK"
      station when station in ["San Bruno"] ->
        "SBRN"
      station when station in ["San Francisco International Airport", "SF Airport"] ->
        "SFIA"
      station when station in ["San Leandro"] ->
        "SANL"
      station when station in ["South Hayward"] ->
        "SHAY"
      station when station in ["South San Francisco"] ->
        "SSAN"
      station when station in ["Union City"] ->
        "UCTY"
      station when station in ["Walnut Creek"] ->
        "WCRK"
      station when station in ["Warm Springs/South Fremont", "Warm Springs"] ->
        "WARM"
      station when station in ["West Dublin/Pleasanton"] ->
        "WDUB"
      station when station in ["West Oakland"] ->
        "WOAK"
    end
  end
end
