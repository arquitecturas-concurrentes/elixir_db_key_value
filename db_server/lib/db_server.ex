defmodule DB.Server do
	use GenServer

	# Public API
	def start_link(db_name) do
		GenServer.start_link(__MODULE__, :ok, [name: db_name])
	end

	# Private API
	def init(:ok) do
		IO.puts "Starting Server..."
		{:ok, []}
	end

	def handle_call({:get, key}, _from, state) do
		IO.puts "get #{key}"
		{:reply, "VALUE", state}
	end

	def handle_call({:set, key, value}, _from, state) do
		IO.puts "set #{key} #{value}"
		{:reply, :ok, state}
	end

	def handle_cast({:set, key, value}, state) do
		IO.puts "set #{key} #{value}"
		{:noreply, state}
	end

	def handle_call({:remove, key}, _from, state) do
		IO.puts "remove #{key}"
		{:reply, :ok, state}
	end

end
