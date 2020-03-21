defmodule BarteWeb.Resolvers.Content do
  def list_departs(_parent, _args, _resolution) do
    {:ok, Barte.Content.list_departs()}
  end
end
