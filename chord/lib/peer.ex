defmodule Peer do
  use GenServer

  def init([id, m, keys, numRequests]) do
    finger_table = get_finger_table(id, m, 1, keys, [])

    # IO.puts("Node: " <> get_node_name(id) <> "  " <> Kernel.inspect(finger_table ++ ['0']))
    # IO.puts(id)
    # IO.puts(Kernel.inspect(finger_table ++ ['0']))

    # numRequests, keys, id, finger_table, target, hop_count, hop_list, source
    {:ok, [numRequests, [], id, finger_table, 0, 0, [], 0]}
  end

  # Creates Chord Ring 
  def create(n, keys, m, numRequests) do
    for i <- 0..(n - 1) do
      GenServer.start_link(Peer, [Enum.at(keys, i), m, keys, numRequests],
        name: get_node_name(Enum.at(keys, i))
      )
    end
  end

  # Populates Finger Table for each node 
  def get_finger_table(_id, m, i, _keys, finger_table) when i > m do
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

        # IO.puts(Kernel.inspect(temp))
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

  # Helper function to get node name 
  def get_node_name(i) do
    id = i |> Integer.to_string() |> String.pad_leading(4, "0")
    ("Elixir.N" <> id) |> String.to_atom()
  end

  # Starts lookup for a random key from the set of keys 
  def create_lookup(id, i, limit, _keys, _finger_table, _hop_count) when i === limit do
    IO.puts("ID=#{id} All set initiating requests")
  end

  def create_lookup(id, i, limit, keys, finger_table, hop_count) when i < limit do
    key = get_random_key(keys, id)
    dest = Enum.at(Enum.sort(finger_table), find_dest_index(key, finger_table, 0))

    # IO.puts("ID=#{id} Target=#{key} Dest=#{dest} Dest_Ind=#{find_dest_index(key, finger_table, 0)} DestName=#{Peer.get_node_name(dest)}")
    # IO.puts(Kernel.inspect(finger_table ++ ['0']))

    GenServer.cast(Peer.get_node_name(dest), {:lookup, {key, id, hop_count + 1}})
    Process.sleep(1000)
    create_lookup(id, i + 1, limit, keys, finger_table, hop_count)
  end

  # Traverses finger table to find destination node's index 
  def find_dest_index(target, finger_table, i) when i < Kernel.length(finger_table) do
    if Enum.at(Enum.sort(finger_table), i) > target do
      i - 1
    else
      find_dest_index(target, finger_table, i + 1)
    end
  end

  def find_dest_index(target, finger_table, i) when i == Kernel.length(finger_table) do
    i - 1
  end

  # Returns a random key to be looked up -excluding self key
  def get_random_key(keys, id) do
    random_key = Enum.random(keys)

    if random_key === id do
      get_random_key(keys, id)
    else
      random_key
    end
  end

  # Handle Initiate Request from Master 
  def handle_cast({:initiate, {numR, ks}}, [
        _numRequests,
        _keys,
        id,
        finger_table,
        _target,
        _hop_count,
        _hop_list,
        _source
      ]) do
    IO.puts("ID=#{id} Received Initiate. Will start lookups")
    create_lookup(id, 0, numR, ks, finger_table, 0)
    {:noreply, [numR, ks, id, finger_table, _target, _hop_count, _hop_list, _source]}
  end

  # Handle Lookup request for a key from peer node 
  def handle_cast({:lookup, {target_key, src, hop_count_received}}, [
        _numRequests,
        _keys,
        id,
        finger_table,
        _target,
        _hop_count,
        _hop_list,
        _source
      ]) do
    IO.puts("ID=#{id} Received Lookup Request for Target=#{target_key} ")

    if target_key === id do
      # IO.puts("In the notify block")
      GenServer.cast(Peer.get_node_name(src), {:notify, {hop_count_received + 1}})

      {:noreply,
       [
         _numRequests,
         _keys,
         id,
         finger_table,
         target_key,
         hop_count_received + 1,
         _hop_list,
         _source
       ]}
    else
      # IO.puts("In the forward lookup block")

      dest = Enum.at(Enum.sort(finger_table), find_dest_index(target_key, finger_table, 0))

      # IO.puts(
      #   "ID=#{id} Target=#{target_key} Dest=#{dest} DestName=#{Peer.get_node_name(dest)} Dest_Ind=#{
      #     find_dest_index(target_key, finger_table, 0)
      #   } Src=#{src}"
      # )

      GenServer.cast(
        Peer.get_node_name(dest),
        {:lookup, {target_key, src, hop_count_received + 1}}
      )

      {:noreply,
       [_numRequests, _keys, id, finger_table, target_key, hop_count_received, _hop_list, _source]}
    end
  end

  # Notification once a key is found in chord
  def handle_cast({:notify, {hop_count_received}}, [
        numRequests,
        _keys,
        id,
        _finger_table,
        _target,
        _hop_count,
        hop_list,
        _source
      ]) do
    hop_list = hop_list ++ [hop_count_received]
    IO.puts("ID=#{id} Received Notify. Lookup Succeeded")

    # IO.puts("hop_list=#{Kernel.inspect(hop_list ++ ['0'])} length=#{Kernel.length(hop_list)} numRequests=#{numRequests} Sum=#{Enum.sum(hop_list)}")

    if Kernel.length(hop_list) === numRequests do
      GenServer.cast(Master, {:hibernate, Enum.sum(hop_list) / numRequests})
    end

    {:noreply,
     [
       numRequests,
       _keys,
       id,
       _finger_table,
       _target,
       hop_count_received,
       hop_list,
       _source
     ]}
  end
end
