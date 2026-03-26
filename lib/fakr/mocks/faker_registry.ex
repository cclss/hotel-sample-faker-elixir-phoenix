defmodule Fakr.Mocks.FakerRegistry do
  @moduledoc """
  Registry of available data generators.
  Each generator has a category, function name, description, and optional configurable options.

  Generator types:
  - :faker — calls a Faker library function
  - :custom — custom generation logic with options
  """

  # Option types: :integer, :float, :string, :textarea, :select
  # Each option: {key, label, type, default, extra}

  @generators %{
    # ── Custom generators (no Faker dependency) ──────────────────────────
    "Custom" => %{
      type: :custom,
      functions: [
        {"integer", "Random integer", [
          {"min", "Min", :integer, 0},
          {"max", "Max", :integer, 100}
        ]},
        {"float", "Random float", [
          {"min", "Min", :float, 0.0},
          {"max", "Max", :float, 100.0},
          {"decimals", "Decimal places", :integer, 2}
        ]},
        {"price", "Price (with symbol)", [
          {"min", "Min", :float, 1.0},
          {"max", "Max", :float, 999.99},
          {"symbol", "Currency symbol", :string, "$"},
          {"decimals", "Decimal places", :integer, 2}
        ]},
        {"boolean", "True/False", [
          {"true_ratio", "True probability (%)", :integer, 50}
        ]},
        {"pick", "Pick from list", [
          {"items", "Items (one per line)", :textarea, "option_a\noption_b\noption_c"}
        ]},
        {"sequence", "Sequential number", [
          {"prefix", "Prefix", :string, ""},
          {"start", "Start from", :integer, 1}
        ]},
        {"template", "Template (combine fields)", [
          {"template", "Template string", :textarea, "{{Person.first_name}} from {{Address.city}}"}
        ]},
        {"paragraph", "Paragraph text", [
          {"sentences", "Number of sentences", :integer, 3}
        ]},
        {"date_range", "Date in range", [
          {"from", "From (days ago)", :integer, 365},
          {"to", "To (days ahead)", :integer, 0}
        ]},
        {"image_placeholder", "Placeholder image URL", [
          {"width", "Width", :integer, 640},
          {"height", "Height", :integer, 480},
          {"text", "Text overlay", :string, ""}
        ]},
        {"nanoid", "NanoID", [
          {"length", "Length", :integer, 21},
          {"alphabet", "Alphabet", :string, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-"}
        ]},
        {"ulid", "ULID (sortable unique ID)", []},
        {"slug", "URL slug (random words)", [
          {"words", "Word count", :integer, 3}
        ]}
      ]
    },
    # ── Faker library generators ─────────────────────────────────────────
    "Person" => %{
      type: :faker,
      module: Faker.Person,
      functions: [
        {"name", "Full name", []},
        {"first_name", "First name", []},
        {"last_name", "Last name", []},
        {"prefix", "Name prefix (Mr., Mrs.)", []},
        {"suffix", "Name suffix (Jr., Sr.)", []},
        {"title", "Job title", []}
      ]
    },
    "Internet" => %{
      type: :faker,
      module: Faker.Internet,
      functions: [
        {"email", "Email address", []},
        {"free_email", "Free email (gmail, etc.)", []},
        {"user_name", "Username", []},
        {"domain_name", "Domain name", []},
        {"url", "URL", []},
        {"ip_v4_address", "IPv4 address", []},
        {"ip_v6_address", "IPv6 address", []},
        {"mac_address", "MAC address", []},
        {"slug", "URL slug", []},
        {"image_url", "Image URL", []}
      ]
    },
    "Address" => %{
      type: :faker,
      module: Faker.Address,
      functions: [
        {"street_address", "Street address", []},
        {"city", "City", []},
        {"state", "State", []},
        {"state_abbr", "State abbreviation", []},
        {"postcode", "Postal code", []},
        {"country", "Country", []},
        {"country_code", "Country code", []},
        {"latitude", "Latitude", []},
        {"longitude", "Longitude", []},
        {"time_zone", "Time zone", []}
      ]
    },
    "Commerce" => %{
      type: :faker,
      module: Faker.Commerce,
      functions: [
        {"product_name", "Product name", []},
        {"product_name_adjective", "Product adjective", []},
        {"product_name_material", "Product material", []},
        {"product_name_product", "Product type", []},
        {"department", "Department", []},
        {"color", "Color name", []},
        {"price", "Price (number)", []}
      ]
    },
    "Company" => %{
      type: :faker,
      module: Faker.Company,
      functions: [
        {"name", "Company name", []},
        {"suffix", "Company suffix (Inc, Ltd)", []},
        {"catch_phrase", "Catch phrase", []},
        {"bs", "Business speak", []},
        {"buzzword", "Buzzword", []}
      ]
    },
    "Lorem" => %{
      type: :faker,
      module: Faker.Lorem,
      functions: [
        {"word", "Single word", []},
        {"words", "Multiple words (joined)", [
          {"count", "Word count", :integer, 5}
        ]},
        {"sentence", "Sentence", [
          {"words", "Word count", :integer, 7}
        ]},
        {"sentences", "Multiple sentences (joined)", [
          {"count", "Sentence count", :integer, 3}
        ]},
        {"paragraph", "Paragraph", [
          {"sentences", "Sentence count", :integer, 3}
        ]},
        {"paragraphs", "Multiple paragraphs (joined)", [
          {"count", "Paragraph count", :integer, 2}
        ]}
      ]
    },
    "Date" => %{
      type: :faker,
      module: Faker.Date,
      functions: [
        {"backward", "Past date", [
          {"days", "Max days ago", :integer, 365}
        ]},
        {"forward", "Future date", [
          {"days", "Max days ahead", :integer, 365}
        ]}
      ]
    },
    "DateTime" => %{
      type: :faker,
      module: Faker.DateTime,
      functions: [
        {"backward", "Past datetime", [
          {"days", "Max days ago", :integer, 365}
        ]},
        {"forward", "Future datetime", [
          {"days", "Max days ahead", :integer, 365}
        ]}
      ]
    },
    "UUID" => %{
      type: :faker,
      module: Faker.UUID,
      functions: [
        {"v4", "UUID v4", []}
      ]
    },
    "Phone" => %{
      type: :faker,
      module: Faker.Phone.EnUs,
      functions: [
        {"phone", "Phone number", []}
      ]
    },
    "App" => %{
      type: :faker,
      module: Faker.App,
      functions: [
        {"name", "App name", []},
        {"version", "Version number", []},
        {"author", "Author name", []}
      ]
    },
    "Avatar" => %{
      type: :faker,
      module: Faker.Avatar,
      functions: [
        {"image_url", "Avatar image URL", []}
      ]
    },
    "Color" => %{
      type: :faker,
      module: Faker.Color.En,
      functions: [
        {"name", "Color name", []},
        {"fancy_name", "Fancy color name", []}
      ]
    },
    "Currency" => %{
      type: :faker,
      module: Faker.Currency,
      functions: [
        {"code", "Currency code (USD, EUR)", []},
        {"name", "Currency name", []},
        {"symbol", "Currency symbol", []}
      ]
    },
    "Food" => %{
      type: :faker,
      module: Faker.Food.En,
      functions: [
        {"dish", "Dish name", []},
        {"description", "Food description", []},
        {"ingredient", "Ingredient", []},
        {"spice", "Spice name", []}
      ]
    },
    "Vehicle" => %{
      type: :faker,
      module: Faker.Vehicle.En,
      functions: [
        {"make", "Vehicle make", []},
        {"model", "Vehicle model", []},
        {"make_and_model", "Make and model", []}
      ]
    },
    "Beer" => %{
      type: :faker,
      module: Faker.Beer.En,
      functions: [
        {"name", "Beer name", []},
        {"style", "Beer style", []},
        {"hop", "Hop variety", []},
        {"malt", "Malt type", []}
      ]
    }
  }

  def categories do
    # Custom first, then alphabetical
    custom = ["Custom"]
    rest = @generators |> Map.keys() |> Enum.reject(&(&1 == "Custom")) |> Enum.sort()
    custom ++ rest
  end

  def functions_for_category(category) do
    case Map.get(@generators, category) do
      nil -> []
      %{functions: fns} -> Enum.map(fns, fn {name, desc, _opts} -> {name, desc} end)
    end
  end

  def options_for_function(category, function_name) do
    case Map.get(@generators, category) do
      nil ->
        []

      %{functions: fns} ->
        case Enum.find(fns, fn {name, _desc, _opts} -> name == function_name end) do
          {_, _, opts} -> opts
          nil -> []
        end
    end
  end

  def valid_generator?(category, function_name) do
    case Map.get(@generators, category) do
      nil -> false
      %{functions: fns} -> Enum.any?(fns, fn {name, _, _} -> name == function_name end)
    end
  end

  def generate(category, function_name, options \\ %{})

  def generate("Custom", function_name, options) do
    generate_custom(function_name, options)
  end

  def generate(category, function_name, options) do
    case Map.get(@generators, category) do
      nil ->
        nil

      %{type: :faker, module: mod, functions: functions} ->
        if Enum.any?(functions, fn {name, _, _} -> name == function_name end) do
          result = call_faker(mod, function_name, options)
          to_json_safe(result)
        else
          nil
        end
    end
  end

  # Faker functions that accept arguments
  defp call_faker(mod, "words", opts) do
    count = parse_int(opts["count"], 5)
    apply(mod, :words, [count]) |> Enum.join(" ")
  end

  defp call_faker(mod, "sentences", opts) do
    count = parse_int(opts["count"], 3)
    apply(mod, :sentences, [count]) |> Enum.join(" ")
  end

  defp call_faker(mod, "paragraphs", opts) do
    count = parse_int(opts["count"], 2)
    apply(mod, :paragraphs, [count]) |> Enum.join("\n\n")
  end

  defp call_faker(mod, "sentence", opts) do
    words = parse_int(opts["words"], 7)
    apply(mod, :sentence, [words])
  end

  defp call_faker(mod, "paragraph", opts) do
    sentences = parse_int(opts["sentences"], 3)
    apply(mod, :paragraph, [sentences])
  end

  defp call_faker(mod, "backward", opts) do
    days = parse_int(opts["days"], 365)
    apply(mod, :backward, [days])
  end

  defp call_faker(mod, "forward", opts) do
    days = parse_int(opts["days"], 365)
    apply(mod, :forward, [days])
  end

  # Default: no args
  defp call_faker(mod, function_name, _opts) do
    func = String.to_atom(function_name)
    apply(mod, func, [])
  end

  # ── Custom generators ──────────────────────────────────────────────────

  defp generate_custom("integer", opts) do
    min = parse_int(opts["min"], 0)
    max = parse_int(opts["max"], 100)
    Enum.random(min..max)
  end

  defp generate_custom("float", opts) do
    min = parse_float(opts["min"], 0.0)
    max = parse_float(opts["max"], 100.0)
    decimals = parse_int(opts["decimals"], 2)
    value = min + :rand.uniform() * (max - min)
    Float.round(value, decimals)
  end

  defp generate_custom("price", opts) do
    min = parse_float(opts["min"], 1.0)
    max = parse_float(opts["max"], 999.99)
    symbol = opts["symbol"] || "$"
    decimals = parse_int(opts["decimals"], 2)
    value = min + :rand.uniform() * (max - min)
    "#{symbol}#{:erlang.float_to_binary(Float.round(value, decimals), decimals: decimals)}"
  end

  defp generate_custom("boolean", opts) do
    ratio = parse_int(opts["true_ratio"], 50)
    :rand.uniform(100) <= ratio
  end

  defp generate_custom("pick", opts) do
    items =
      (opts["items"] || "option_a\noption_b\noption_c")
      |> String.split("\n", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    if items == [], do: nil, else: Enum.random(items)
  end

  defp generate_custom("sequence", opts) do
    # Note: sequence uses record_index injected by Generator, this is a fallback
    prefix = opts["prefix"] || ""
    start = parse_int(opts["start"], 1)
    "#{prefix}#{start + :rand.uniform(9999)}"
  end

  defp generate_custom("template", opts) do
    template = opts["template"] || ""

    Regex.replace(~r/\{\{(\w+)\.(\w+)\}\}/, template, fn _full, cat, func ->
      case generate(cat, func) do
        nil -> "{{#{cat}.#{func}}}"
        val -> to_string(val)
      end
    end)
  end

  defp generate_custom("paragraph", opts) do
    sentences = parse_int(opts["sentences"], 3)

    1..max(sentences, 1)
    |> Enum.map(fn _ -> Faker.Lorem.sentence() end)
    |> Enum.join(" ")
  end

  defp generate_custom("date_range", opts) do
    from_days = parse_int(opts["from"], 365)
    to_days = parse_int(opts["to"], 0)

    from_date = Date.add(Date.utc_today(), -from_days)
    to_date = Date.add(Date.utc_today(), to_days)

    diff = Date.diff(to_date, from_date)
    offset = if diff > 0, do: :rand.uniform(diff), else: 0
    Date.add(from_date, offset) |> Date.to_iso8601()
  end

  defp generate_custom("image_placeholder", opts) do
    w = parse_int(opts["width"], 640)
    h = parse_int(opts["height"], 480)
    text = opts["text"] || ""

    if text == "" do
      "https://placehold.co/#{w}x#{h}"
    else
      "https://placehold.co/#{w}x#{h}?text=#{URI.encode(text)}"
    end
  end

  defp generate_custom("nanoid", opts) do
    length = parse_int(opts["length"], 21)

    alphabet =
      (opts["alphabet"] || "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-")
      |> String.graphemes()

    Enum.map(1..length, fn _ -> Enum.random(alphabet) end) |> Enum.join()
  end

  defp generate_custom("ulid", _opts) do
    # ULID: 10 chars timestamp (base32) + 16 chars random (base32)
    timestamp = System.system_time(:millisecond)
    crockford = ~c"0123456789ABCDEFGHJKMNPQRSTVWXYZ"

    ts_part =
      Enum.map(9..0//-1, fn i ->
        idx = timestamp |> Bitwise.bsr(i * 5) |> Bitwise.band(31)
        Enum.at(crockford, idx)
      end)
      |> List.to_string()

    rand_part =
      Enum.map(1..16, fn _ -> Enum.at(crockford, :rand.uniform(32) - 1) end)
      |> List.to_string()

    ts_part <> rand_part
  end

  defp generate_custom("slug", opts) do
    words = parse_int(opts["words"], 3)

    Faker.Lorem.words(words)
    |> Enum.map(&String.downcase/1)
    |> Enum.join("-")
  end

  defp generate_custom(_, _), do: nil

  # ── Public helpers (used by Mocks context) ──────────────────────────────
  def parse_int_public(val, default), do: parse_int(val, default)

  # ── Helpers ────────────────────────────────────────────────────────────

  defp to_json_safe(%Date{} = date), do: Date.to_iso8601(date)
  defp to_json_safe(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp to_json_safe(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)
  defp to_json_safe(value) when is_float(value), do: Float.round(value, 2)
  defp to_json_safe(value), do: value

  defp parse_int(nil, default), do: default
  defp parse_int(val, _default) when is_integer(val), do: val

  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} -> n
      :error -> default
    end
  end

  defp parse_int(val, _default) when is_float(val), do: round(val)
  defp parse_int(_, default), do: default

  defp parse_float(nil, default), do: default
  defp parse_float(val, _default) when is_float(val), do: val
  defp parse_float(val, _default) when is_integer(val), do: val / 1

  defp parse_float(val, default) when is_binary(val) do
    case Float.parse(val) do
      {n, _} -> n
      :error -> default
    end
  end

  defp parse_float(_, default), do: default
end
