defmodule Barte do
  def etd(orig) do
    resp =
      HTTPoison.get(
        "http://api.bart.gov/api/etd.aspx?cmd=etd&orig=#{orig}&key=MW9S-E7SL-26DU-VV8V&json=y"
      )
  end

  def etd(orig, dir) do
    resp =
      HTTPoison.get(
        "http://api.bart.gov/api/etd.aspx?cmd=etd&orig=#{orig}&dir=#{dir}&key=MW9S-E7SL-26DU-VV8V&json=y"
      )
  end

  def depart(orig, dest) do
    {:ok, resp} =
      HTTPoison.get(
        "http://api.bart.gov/api/sched.aspx?cmd=depart&orig=#{orig}&dest=#{dest}&key=MW9S-E7SL-26DU-VV8V&json=y"
      )

    {:ok, body} = Poison.decode(resp.body)

    body
    |> get_in(["root", "schedule", "request", "trip"])
    |> process_val()
  end

  defp process_map(map) do
    processed_map = for {key, val} <- map, into: %{}, do: {process_key(key), process_val(val)}

    case processed_map do
      %{leg: leg} ->
        process_trip(processed_map)

      %{trainHeadStation: trainHeadStation} ->
        process_leg(processed_map)

      _ ->
        processed_map
    end
  end

  defp process_trip(trip) do
    trip
    |> collapse_times()
    |> Map.drop([:clipper, :fare, :fares])
  end

  defp process_leg(leg) do
    leg
    |> collapse_times()
    |> Map.drop([:load, :bikeflag])
  end

  defp collapse_times(map) do
    %{
      destTimeDate: destTimeDate,
      destTimeMin: destTimeMin,
      origTimeDate: origTimeDate,
      origTimeMin: origTimeMin
    } = map

    destinationAt =
      destTimeDate
      |> NaiveDateTime.add(destTimeMin.hour * 60 * 60, :second)
      |> NaiveDateTime.add(destTimeMin.minute * 60, :second)
      |> NaiveDateTime.add(destTimeMin.second, :second)

    originAt =
      origTimeDate
      |> NaiveDateTime.add(origTimeMin.hour * 60 * 60, :second)
      |> NaiveDateTime.add(origTimeMin.minute * 60, :second)
      |> NaiveDateTime.add(origTimeMin.second, :second)

    map
    |> Map.merge(%{destinationAt: destinationAt, originAt: originAt})
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
end
