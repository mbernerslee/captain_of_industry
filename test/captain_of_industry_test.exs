defmodule CaptainOfIndustryTest do
  use ExUnit.Case
  doctest CaptainOfIndustry

  describe "run/1" do
    test "given the required output per 60s, gives us what we need to achieve it" do
      # CaptainOfIndustry.run([{"construction parts", 12}])
      # |> IO.inspect()

      # CaptainOfIndustry.run([{"construction parts", 6}, {"vehicle parts", 4}])
      assert {%{
                {"assembly 1", "construction parts"} => 1.0,
                {"blast furnace", "molten iron"} => 0.1875,
                {"groundwater pump", "water"} => 0.0625,
                {"kiln", "concrete slab"} => 0.5,
                {"metal caster", "iron"} => 0.375
              },
              %{"coal" => 3.75, "iron ore" => 5.625, "limestone" => 9.0, "wood" => 4.5}} ==
               CaptainOfIndustry.run([{"construction parts", 6}])

      assert {
               %{
                 {"groundwater pump", "water"} => 1.0,
                 {"kiln", "concrete slab"} => 8.0
               },
               %{"coal" => 24.0, "limestone" => 144.0}
             } == CaptainOfIndustry.run([{"concrete slab", 96}])
    end
  end
end
