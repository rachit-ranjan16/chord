defmodule Chord do
  use GenServer

  def init([numNodes, numRequests]) do
    # avg_hops, hop_list, numNodes
    {:ok, {[], numNodes, numRequests}}
  end

  def get_number_of_bits(numNodes) do
    Kernel.trunc(:math.ceil(:math.log2(numNodes)))
  end

  # Validation Check
  def main(args) when Kernel.length(args) != 2 do
    raise ArgumentError, message: "Insufficient/Excess Arguments. Enter numRequests and numNodes"
  end

  def main(args) do
    numNodes = String.to_integer(Enum.at(args, 0))
    numRequests = String.to_integer(Enum.at(args, 1))

    m = get_number_of_bits(numNodes)
    keys = get_keys(Kernel.trunc(:math.pow(2, m)), numNodes, [])
    # IO.inspect(keys ++ ['0'])

    GenServer.start_link(Chord, [numNodes, numRequests], name: Master)
    # Create Chord Ring
    IO.puts "Initializing Chord Ring with #{numNodes} nodes..."
    Peer.create(numNodes, keys, m, numRequests)
    # Initiate numRequest random lookups in each of numNodes 
    for i <- 0..(numNodes - 1) do
      GenServer.cast(Peer.get_node_name(Enum.at(keys, i)), {:initiate, {numRequests, keys}})
    end

    Process.sleep(:infinity)
  end

  def get_keys(n, limit, keys) when limit === 1 do
    Enum.sort(keys)
  end

  def get_keys(n, limit, keys) when limit > 1 and Kernel.length(keys) === 0 do
    get_keys(n, limit, keys ++ [Enum.random(1..n)])
  end

  def get_keys(n, limit, keys) when limit > 1 do
    random_key = Enum.random(0..(n - 1))

    if random_key in keys do
      get_keys(n, limit, keys)
    else
      get_keys(n, limit - 1, keys ++ [random_key])
    end
  end

  # Node hibernate finale
  def handle_cast(
        {:hibernate, avg},
        {hop_list, numNodes, numRequests}
      ) do
    # IO.puts("Received Hibernate")
    new_list = hop_list ++ [avg]
    # Calculate Hop Average  
    if Kernel.length(new_list) === numNodes do
      IO.puts("\n\n\nConverged with Avg Hops=#{Enum.sum(new_list) / numNodes}\n\n\n")
      Process.exit(self(), "Execution Complete :)")
    end

    {:noreply, {hop_list ++ [avg], numNodes, numRequests}}
  end
end
