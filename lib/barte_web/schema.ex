defmodule BarteWeb.Schema do
  use Absinthe.Schema
  import_types(BarteWeb.Schema.ContentTypes)

  alias BarteWeb.Resolver

  query do
    field :departures, list_of(:depart) do
      resolve(&Resolvers.Content.list_departs/3)
    end
  end
end
