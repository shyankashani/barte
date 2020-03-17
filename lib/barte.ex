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
    %{"root" => root} = body
    root
    |> process_map()
    |> collapse_datetimes()
  end

  defp process_map(map) do
    for {key, val} <- map, into: %{}, do: {process_key(key), process_val(val)}
  end

  defp process_key("@" <> rest), do: rest |> String.to_atom()
  defp process_key(key), do: key |> String.to_atom()

  defp process_val("ROUTE " <> rest), do: String.to_integer(rest)
  defp process_val(val) when is_map(val), do: process_map(val)
  defp process_val(val) when is_list(val), do: for(v <- val, do: process_val(v))

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
      {:ok, dt} -> true
      _ -> false
    end
  end
end
