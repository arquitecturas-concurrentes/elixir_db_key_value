defmodule DB.Server do
	use GenServer

	# Public API
	def start_link(db_name) do
		GenServer.start_link(__MODULE__, {:ok, db_name}, [name: {:global, db_name}])
	end

	# Private API
	def init({:ok, db_name}) do
		IO.puts "Starting Server..."
		:pg2.create db_name
		{:ok, {db_name, :pg2.get_members db_name}}
	end

	def handle_call({:get, key}, _from, {db_name, datas}) do
		IO.puts "get #{key}"
		onDataChange db_name, datas
		{:reply, "VALUE", {db_name, :pg2.get_members db_name}}
	end

	def handle_call({:set, key, value}, _from, {db_name, datas}) do
		IO.puts "set #{key} #{value}"
		onDataChange db_name, datas
		{:reply, :ok, {db_name, :pg2.get_members db_name}}
	end

	def handle_cast({:set, key, value}, {db_name, datas}) do
		IO.puts "set #{key} #{value}"
		onDataChange db_name, datas
		{:noreply, {db_name, :pg2.get_members db_name}}
	end

	def handle_call({:remove, key}, _from, {db_name, datas}) do
		IO.puts "remove #{key}"
		onDataChange db_name, datas
		{:reply, :ok, {db_name, :pg2.get_members db_name}}
	end

	defp onDataChange(db_name, datas) do
		
		d = :pg2.get_members db_name
		if datas != :pg2.get_members db_name do
			IO.puts 'CAMBIARON LOS DATA #{inspect d}'
		else
			IO.puts 'NO CAMBIARON LOS DATA #{inspect d}'
		end

	end

end
