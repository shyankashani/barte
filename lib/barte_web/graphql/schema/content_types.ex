defmodule BarteWeb.Schema.ContentTypes do
  use Absinthe.Schema.Notation

  object :depart do
    field :id, :id
    field :destination, :string
    field :message, :string
    field :origin, :string
    field :schedule, :schedule
  end

  object :schedule do
    field :after, :integer
    field :before, :integer
    field :date, :string
    field :request, :request
  end

  object :request do
    field :trip, list_of(:trip)
  end

  object :trip do
    field :clipper, :float
    field :destTimeDate, :string
    field :destTimeMin, :string
    field :origTimeDate, :string
    field :origTimeMin, :string
    field :origin, :string
    field :destination, :string
    field :tripTime, :integer
    field :fare, :float
    field :leg, list_of(:leg)
  end

  object :leg do
    field :bikeflag, :integer
    field :destTimeDate, :string
    field :destTimeMin, :string
    field :destination, :string
    field :line, :integer
    field :load, :integer
    field :order, :integer
    field :origTimeDate, :string
    field :origTimeMin, :string
    field :origin, :string
    field :trainHeadStation, :string
  end
end
