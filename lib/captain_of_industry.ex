defmodule CaptainOfIndustry do
  @moduledoc """
  Documentation for `CaptainOfIndustry`.
  """

  @doc """
  Given a list of {product, desired_amount_per_60} tuples, returns the number of each production buildings you need, and raw resources

  ## Examples

      iex> CaptainOfIndustry.run([{"iron", 24}])
      {
        %{
          {"blast furnace", "molten iron"} => 1.0,
          {"metal caster", "iron"} => 2.0
        },
        %{
          "coal" => 12.0,
          "iron ore" => 30.0
        }
      }

  """

  def run(output) do
    output
    |> required()
    |> group()
    |> sort()
    |> pretty_format()
  end

  defp pretty_format({buildings, raw_resources}) do
    IO.puts("building, resource, tier, amount")

    Enum.each(buildings, fn {{building, resource, tier}, amount} ->
      IO.puts("#{building}, #{resource}, #{tier}, #{amount}")
    end)

    IO.inspect(raw_resources)

    {buildings, raw_resources}
  end

  defp sort({buildings, raw_resources}) do
    buildings =
      Enum.sort(buildings, fn {{_, _, tier_1}, _}, {{_, _, tier_2}, _} ->
        tier_1 <= tier_2
      end)

    {buildings, raw_resources}
  end

  def group(inputs) do
    {buildings, raw_resources} =
      Enum.reduce(inputs, {%{}, %{}}, fn
        %{building: name, number_required: n, producing: producing, tier: tier},
        {buildings, raw_resources} ->
          {Map.update(buildings, {name, producing, tier}, n, &(&1 + n)), raw_resources}

        %{raw_resource: raw_resource, demand_per_60: d}, {buildings, raw_resources} ->
          {buildings, Map.update(raw_resources, raw_resource, d, &(&1 + d))}
      end)

    buildings = Map.new(buildings, fn {name, amount} -> {name, Float.round(amount, 1)} end)

    raw_resources =
      Map.new(raw_resources, fn {name, amount} -> {name, Float.round(amount, 1)} end)

    {buildings, raw_resources}
  end

  defp required(output) do
    required([], output)
  end

  defp required(acc, []) do
    acc
  end

  defp required(acc, :raw_resource) do
    acc
  end

  defp required(acc, [{product_name, demand_per_60} | rest]) do
    product =
      case Map.get(recipes(), product_name) do
        nil -> raise "Unknown recipe for \"#{product_name}\""
        recipe -> recipe
      end

    parent_demand = calc_demand(product_name, product, demand_per_60)

    child_resources =
      product
      |> recipe(parent_demand)
      |> required()

    parent_tier =
      child_resources
      |> Enum.max_by(& &1.tier, fn -> %{tier: -1} end)
      |> Map.fetch!(:tier)
      |> Kernel.+(1)

    parent_demand = Map.put(parent_demand, :tier, parent_tier)

    acc = List.flatten([[parent_demand], child_resources | acc])
    required(acc, rest)
  end

  defp recipe(%{recipe: recipe}, %{number_required: number_required}) do
    Enum.map(recipe, fn {name, amount} -> {name, amount * number_required} end)
  end

  defp recipe(:raw_resource, _) do
    :raw_resource
  end

  defp calc_demand(product_name, :raw_resource, demand_per_60) do
    %{raw_resource: product_name, demand_per_60: demand_per_60}
  end

  defp calc_demand(product_name, product, demand_per_60) do
    %{
      building: product.building,
      number_required: demand_per_60 / product.amount_produced_per_60,
      producing: product_name,
      tier: product[:tier]
    }
  end

  defp recipes do
    basic_recipes()
    |> Map.merge(assembly_1_recipes())
    |> Map.merge(farm_recipes())
    |> Map.merge(maintenance_depo_recipes())
    # |> Map.merge(irrigated_farm_recipes())
    # |> Map.merge(assembly_2_recipes())
    # |> Map.merge(assembly_3_recipes())
    # |> Map.merge(glass_maker_recipes())
    |> Map.merge(blast_furnace_recipes())

    # |> Map.merge(mixer_recipes())
    # |> Map.merge(evaporation_pond_heated_recipes())
  end

  defp assembly_1_recipes do
    %{
      "construction parts" => %{
        building: "assembly 1",
        amount_produced_per_60: 6,
        recipe: [{"iron", 4.5}, {"wood", 4.5}, {"concrete slab", 6}]
      },
      "vehicle parts" => %{
        building: "assembly 1",
        amount_produced_per_60: 4,
        recipe: [{"electronics", 2}, {"mechanical parts", 6}]
      },
      "mechanical parts" => %{
        building: "assembly 1",
        amount_produced_per_60: 6,
        recipe: [{"iron", 7.5}]
      },
      "construction parts 2" => %{
        building: "assembly 1",
        amount_produced_per_60: 3,
        recipe: [{"construction parts", 6}, {"electronics", 3}]
      },
      "electronics" => %{
        building: "assembly 1",
        amount_produced_per_60: 4,
        recipe: [{"rubber", 1}, {"copper", 4}]
      }
    }
  end

  defp irrigated_farm_recipes do
    %{
      "potato" => %{
        building: "irrigated farm",
        # amount produced per 60 if 2 farm slots used
        amount_produced_per_60: 4.2,
        recipe: [{"water", 36}]
      },
      "vegetables" => %{
        building: "irrigated farm",
        # amount produced per 60 if 2 farm slots used
        amount_produced_per_60: 3.8,
        recipe: [{"water", 32}]
      },
      "tree sapling" => %{
        building: "irrigated farm",
        amount_produced_per_60: 5,
        recipe: [{"water", 27}]
      }
    }
  end

  defp farm_recipes do
    %{
      "potato" => %{
        building: "farm",
        amount_produced_per_60: 19,
        recipe: [{"water", 36}]
      }
    }
  end

  defp basic_recipes do
    %{
      "limestone" => :raw_resource,
      "wood" => :raw_resource,
      "iron ore" => :raw_resource,
      "copper ore" => :raw_resource,
      "coal" => :raw_resource,
      "sand" => :raw_resource,
      #      "coal" => %{
      #        building: "coal maker",
      #        amount_produced_per_60: 7.5,
      #        recipe: [{"wood", 18}]
      #      },
      "water" => %{
        tier: 0,
        building: "groundwater pump",
        amount_produced_per_60: 48,
        recipe: []
      },
      # "water" => %{
      #  building: "basic distiller",
      #  amount_produced_per_60: 36,
      #  recipe: [{"seawater", 60}, {"coal", 6}]
      # }
      "crude oil" => %{
        building: "oil pump",
        amount_produced_per_60: 20,
        recipe: []
      },
      "rubber" => %{
        building: "rubber maker",
        amount_produced_per_60: 16,
        recipe: [{"diesel", 8}, {"coal", 2}]
      },
      "diesel" => %{
        building: "basic distiller",
        amount_produced_per_60: 27,
        recipe: [{"crude oil", 60}, {"coal", 6}]
      },
      "iron" => %{
        building: "metal caster",
        amount_produced_per_60: 12,
        recipe: [{"molten iron", 12}]
      },
      "concrete slab" => %{
        building: "kiln",
        amount_produced_per_60: 12,
        recipe: [{"limestone", 18}, {"coal", 3}, {"water", 6}]
      },
      "copper" => %{
        tier: 0,
        building: "copper electrolysis",
        amount_produced_per_60: 19.5,
        recipe: [{"impure copper", 24}, {"water", 6}]
      },
      "impure copper" => %{
        tier: 0,
        building: "metal caster",
        amount_produced_per_60: 12,
        recipe: [{"molten copper", 12}]
      },
      "molten copper" => %{
        tier: 0,
        building: "blast furance",
        amount_produced_per_60: 24,
        recipe: [{"copper ore", 30}, {"coal", 12}]
      },
      "steel" => %{
        building: "cooled caster",
        amount_produced_per_60: 12,
        recipe: [{"molten steel", 12}, {"water", 6}]
      },
      "molten steel" => %{
        building: "oxygen furnace",
        amount_produced_per_60: 12,
        recipe: [{"molten iron", 24}, {"oxygen", 18}]
      },
      "oxygen" => %{
        building: "air separator",
        amount_produced_per_60: 36,
        recipe: []
      },
      "seawater" => %{
        building: "seawater pump",
        amount_produced_per_60: 108,
        recipe: []
      }
    }
  end

  defp assembly_3_recipes do
    %{
      "construction parts" => %{
        building: "assembly 3",
        amount_produced_per_60: 24,
        recipe: [{"iron", 18}, {"wood", 18}, {"concrete slab", 24}]
      },
      "construction parts" => %{
        building: "assembly 3",
        amount_produced_per_60: 24,
        recipe: [{"steel", 12}, {"wood", 18}, {"concrete slab", 18}]
      },
      "construction parts 2" => %{
        building: "assembly 3",
        amount_produced_per_60: 12,
        recipe: [{"construction parts", 24}, {"electronics", 12}]
      },
      "construction parts 3" => %{
        building: "assembly 3",
        amount_produced_per_60: 6,
        recipe: [{"construction parts 2", 12}, {"steel", 6}]
      },
      "construction parts 4" => %{
        building: "assembly 3",
        amount_produced_per_60: 3,
        recipe: [{"construction parts 3", 6}, {"electronics 2", 3}]
      },
      "mechanical parts" => %{
        building: "assembly 3",
        amount_produced_per_60: 24,
        recipe: [{"iron", 30}]
      },
      "mechanical parts" => %{
        building: "assembly 3",
        amount_produced_per_60: 24,
        recipe: [{"steel", 12}]
      },
      "vehicle parts" => %{
        building: "assembly 3",
        amount_produced_per_60: 16,
        recipe: [{"electronics", 8}, {"mechanical parts", 24}]
      },
      "vehicle parts 2" => %{
        building: "assembly 3",
        amount_produced_per_60: 4,
        recipe: [{"vehicle parts", 8}, {"steel", 8}, {"glass", 2}]
      },
      "lab equipment" => %{
        building: "assembly 3",
        amount_produced_per_60: 24,
        recipe: [{"mechanical parts", 16}, {"electronics", 8}]
      },
      "lab equipment 2" => %{
        building: "assembly 3",
        amount_produced_per_60: 12,
        recipe: [{"lab equipment", 12}, {"paper", 4}, {"glass", 4}]
      },
      "rail parts" => %{
        building: "assembly 3",
        amount_produced_per_60: 16,
        recipe: [{"concrete slab", 8}, {"steel", 4}]
      },
      "electronics" => %{
        building: "assembly 3",
        amount_produced_per_60: 24,
        recipe: [{"rubber", 6}, {"copper", 24}]
      }
    }
  end

  defp blast_furnace_recipes do
    %{
      "molten iron" => %{
        building: "blast furnace",
        amount_produced_per_60: 24,
        recipe: [{"iron ore", 30}, {"coal", 12}]
      },
      "molten glass" => %{
        building: "blast furnace",
        amount_produced_per_60: 24,
        recipe: [{"glass mix", 30}, {"coal", 12}]
      }
      # ignoring broken glass calc, because it causes an infinite loop in recipe calculation
      # "molten glass" => %{
      #  building: "blast furnace",
      #  amount_produced_per_60: 24,
      #  recipe: [{"broken glass", 36}, {"coal", 6}]
      # }
    }
  end

  defp evaporation_pond_heated_recipes do
    %{
      # "brine" => %{
      #  building: "evaporation pond (heated)",
      #  amount_produced_per_60: 48,
      #  recipe: [{"seawater", 60}]
      # },
      "salt" => %{
        building: "evaporation pond (heated)",
        amount_produced_per_60: 6,
        recipe: [{"seawater", 96}]
      }
      # "salt" => %{
      #   building: "evaporation pond (heated)",
      #   amount_produced_per_60: 12,
      #   recipe: [{"brine", 96}]
      # }
    }
  end

  defp mixer_recipes do
    %{
      "glass mix" => %{
        building: "mixer",
        amount_produced_per_60: 60,
        recipe: [{"sand", 60}, {"limestone", 15}, {"salt", 6}]
      }
      # "glass mix" => %{
      #  building: "mixer",
      #  amount_produced_per_60: 60,
      #  recipe: [{"sand", 48}, {"limestone", 12}, {"salt", 6}, {"acid", 12}]
      # }
    }
  end

  defp glass_maker_recipes do
    %{
      "glass" => %{
        building: "glass maker",
        amount_produced_per_60: 12,
        recipe: [{"molten glass", 12}]
      }
      # ignoring broken glass calc, because it causes an infinite loop in recipe calculation
      # "broken glass" => %{
      #  building: "glass maker",
      #  amount_produced_per_60: 12,
      #  recipe: [{"molten glass", 12}]
      # }
    }
  end

  defp maintenance_depo_recipes do
    %{
      "maintenance 1" => %{
        building: "maintenance depo (basic)",
        amount_produced_per_60: 220,
        recipe: [{"mechanical parts", 12}, {"electronics", 6}]
      }
      # "maintenance 1" => %{
      #  building: "maintenance depo",
      #  amount_produced_per_60: 480,
      #  recipe: [{"mechanical parts", 24}, {"electronics", 12}]
      # }
      # "maintenance 1" => %{
      #  building: "maintenance depo",
      #  amount_produced_per_60: 480,
      #  recipe: [{"mechanical parts", 24}, {"electronics", 12}, {"recycleables", 18}]
      # }
    }
  end

  defp assembly_2_recipes do
    %{
      "construction parts" => %{
        building: "assembly 2",
        amount_produced_per_60: 12,
        recipe: [{"iron", 9}, {"wood", 9}, {"concrete slab", 12}]
      },
      "vehicle parts" => %{
        building: "assembly 2",
        amount_produced_per_60: 8,
        recipe: [{"electronics", 4}, {"mechanical parts", 12}]
      },
      "mechanical parts" => %{
        building: "assembly 2",
        amount_produced_per_60: 12,
        recipe: [{"iron", 15}]
      },
      "construction parts 2" => %{
        building: "assembly 2",
        amount_produced_per_60: 6,
        recipe: [{"construction parts", 12}, {"electronics", 6}]
      },
      "electronics" => %{
        building: "assembly 2",
        amount_produced_per_60: 12,
        recipe: [{"rubber", 3}, {"copper", 12}]
      },
      "lab equipment" => %{
        building: "assembly 2",
        amount_produced_per_60: 12,
        recipe: [{"mechanical parts", 8}, {"electronics", 4}]
      },
      "construction parts 3" => %{
        building: "assembly 2",
        amount_produced_per_60: 3,
        recipe: [{"construction parts 2", 6}, {"steel", 3}]
      }
    }
  end
end
