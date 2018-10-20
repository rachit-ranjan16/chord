defmodule Peer do
  use GenServer

  def init([id, m, keys]) do
    finger_table = get_finger_table(id, m, 1, keys, [])
    # IO.puts("Node: " <> get_node_name(id) <> "  " <> Kernel.inspect(finger_table ++ ['0']))
    IO.puts(id)
    IO.puts(Kernel.inspect(finger_table ++ ['0']))
    {:ok, finger_table}
  end

  def create(n, keys, m) do
    # nodes =
    for i <- 0..(n - 1) do
      GenServer.start_link(Peer, [Enum.at(keys, i), m, keys], name: get_node_name(i))
    end
  end

  def get_finger_table(id, m, i, keys, finger_table) when i > m do
    finger_table
  end

  def get_finger_table(id, m, i, keys, finger_table) when i === 0 do
    low = rem(id + 1, Kernel.trunc(:math.pow(2, m)))
    high = rem(id + 2, Kernel.trunc(:math.pow(2, m)))

    finger =
      if low < high do
        temp = Enum.filter(keys, fn x -> x >= low end)

        temp =
          if Kernel.length(temp) > 0 do
            temp
          else
            Enum.filter(keys, fn x -> x < low end) |> Enum.sort()
          end
      else
        temp =
          Enum.filter(keys, fn x -> x < low end)
          |> Enum.map(fn x -> x + Kernel.trunc(:math.pow(2, m)) end)

        IO.puts(Kernel.inspect(temp))
        (temp ++ Enum.filter(keys, fn x -> x >= low end)) |> Enum.sort()
      end

    get_finger_table(
      id,
      m,
      i + 1,
      keys,
      finger_table ++
        if Enum.at(finger, 0) >= :math.pow(2, m) do
          [rem(Kernel.trunc(Enum.at(finger, 0)), Kernel.trunc(:math.pow(2, m)))]
        else
          [Enum.at(finger, 0)]
        end
    )
  end

  def get_finger_table(id, m, i, keys, finger_table) when i <= m do
    low = rem(id + Kernel.trunc(:math.pow(2, i - 1)), Kernel.trunc(:math.pow(2, m)))
    high = rem(id + Kernel.trunc(:math.pow(2, i)), Kernel.trunc(:math.pow(2, m)))

    finger =
      if low < high do
        temp = Enum.filter(keys, fn x -> x >= low end)

        temp =
          if Kernel.length(temp) > 0 do
            temp
          else
            Enum.filter(keys, fn x -> x < low end) |> Enum.sort()
          end
      else
        temp =
          Enum.filter(keys, fn x -> x < low end)
          |> Enum.map(fn x -> x + Kernel.trunc(:math.pow(2, m)) end)

        (temp ++ Enum.filter(keys, fn x -> x >= low end)) |> Enum.sort()
      end

    # "ID=#{id} finger=#{Kernel.inspect finger} Finger Table=#{Kernel.inspect(finger_table)} i=#{i} low=#{low} high=#{high}"  |> IO.puts 
    get_finger_table(
      id,
      m,
      i + 1,
      keys,
      finger_table ++
        if Enum.at(finger, 0) >= :math.pow(2, m) do
          [rem(Kernel.trunc(Enum.at(finger, 0)), Kernel.trunc(:math.pow(2, m)))]
        else
          [Enum.at(finger, 0)]
        end
    )
  end

  def get_node_name(i) do
    id = i |> Integer.to_string() |> String.pad_leading(4, "0")
    ("Elixir.N" <> id) |> String.to_atom()
  end
end
