defmodule Chord do
  use GenServer

  @moduledoc """
  Documentation for Chord.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Chord.hello()
      :world

  """
  # def init(args) do
  #   {:ok, []}
  # end
  def get_number_of_bits(numNodes) do
    Kernel.trunc(:math.ceil(:math.log2(numNodes)))
  end

  def main(args) when Kernel.length(args) != 2 do
    raise ArgumentError, message: "Insufficient/Excess Arguments. Enter numRequests and numNodes"
  end

  def main(args) do
    numNodes = String.to_integer(Enum.at(args, 0))
    numRequests = String.to_integer(Enum.at(args, 1))
    m = get_number_of_bits(numNodes)
    keys = get_keys(Kernel.trunc(:math.pow(2, m)), numNodes, [])
    IO.inspect(keys ++ ['0'])
    Peer.create(numNodes, keys, m)
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
end
