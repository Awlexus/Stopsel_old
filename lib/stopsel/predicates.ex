defmodule Stopsel.Predicates do
  @type options :: keyword

  @callback predicate(Stopsel.Request.t(), options) :: Stopsel.Request.t()
end
