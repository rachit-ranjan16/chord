defmodule Peer do
  use GenServer

  def init([id, m, keys]) do
    finger_table = get_finger_table(id, m, 1, keys, [])
    # IO.puts("Node: " <> get_node_name(id) <> "  " <> Kernel.inspect(finger_table ++ ['0']))
    IO.puts(id)
    IO.puts(Kernel.inspect(finger_table ++ ['0']))
    # numRequests, keys, id, finger_table, target, hop_count, hop_list, source
    {:ok, {0, [], id, finger_table, 0, 0, [], 0}}
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

  def create_lookup(id, i, limit, keys, finger_table, hop_count) do
    key = get_random_key(keys, id)
    dest = Enum.at(finger_table, find_dest_index(key, finger_table, 0))
    GenServer.cast(Peer.get_node_name(dest), {:lookup, key, id, hop_count + 1})
  end

  def find_dest_index(target, finger_table, i) when i < Kernel.length(finger_table) do
    if Enum.at(finger_table, i) >= target do
      i - 1
    else
      find_dest_index(target, finger_table, i + 1)
    end
  end

  def find_dest_index(target, finger_table, i) when i == Kernel.length() do
    # IO.puts "ERRROR"
    i
  end

  def get_random_key(keys, id) do
    random_key = Enum.random(keys)

    if random_key === id do
      get_random_key(keys, id)
    else
      random_key
    end
  end

  # Handle Initiate Request from Master 
  # TODO refactor handler name 
  def handle_cast({:initiate, _received}, [
        numRequests,
        keys,
        id,
        finger_table,
        _target,
        _hop_count,
        _hop_list,
        _source
      ]) do
    create_lookup(id, 0, numRequests, keys, finger_table, 0)
    {:noreply, [numRequests, keys, id, finger_table, _target, _hop_count, _hop_list]}
  end

  # 
  def handle_cast({:lookup, _received}, [
        _numRequests,
        _keys,
        _id,
        finger_table,
        target,
        hop_count,
        hop_list,
        source
      ]) do
    if target == id do
      GenServer.cast(Peer.get_node_name(source), {:notify, {hop_count + 1}})

      {:noreply,
       [_numRequests, _keys, _id, _finger_table, _target, _hop_count, _hop_list, _source]}
    else
      dest = Enum.at(finger_table, find_dest_index(target, finger_table, 0))
      GenServer.cast(Peer.get_node_name(dest), {:lookup, target, source, hop_count + 1})

      {:noreply,
       [_numRequests, _keys, _id, _finger_table, _target, _hop_count, _hop_list, _source]}
    end
  end

  def handle_cast({:notify, _received}, [
        numRequests,
        _keys,
        _id,
        _finger_table,
        _target,
        hop_count,
        hop_list,
        _source
      ]) do
    hop_list = hop_list ++ [hop_count]

    if Kernel.length(hop_list) === numRequests do
      GenServer.cast(Master, {:hibernate, Enum.sum(hop_list) / numRequests})
    end

    {:noreply,
     [
       _numRequests,
       _keys,
       _id,
       _finger_table,
       _target,
       _hop_count,
       hop_list,
       _source
     ]}
  end
end
