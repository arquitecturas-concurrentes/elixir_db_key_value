defmodule DB.Server do
	use GenServer

	# Public API
	def start_link db_name, servers \\ [] do
		GenServer.start_link(__MODULE__, {:ok, db_name, servers})
	end

	# Private API
	def init {:ok, db_name, servers} do
		
		IO.puts "Starting Server..."

		# Server Process Group
		:pg2.create {:server, db_name}
		:pg2.join {:server, db_name}, self
		
		# Data Process Group
		:pg2.create {:data, db_name}

		# Connect this Node with Database Node/s
		Enum.map servers, fn x -> Node.ping(x) end
		
		{:ok, {db_name, []}}

	end

	def handle_call {:get, key}, _from, {db_name, datas} do
		IO.puts "get #{inspect key}"
		value = GenServer.call data_pid(db_name, key), {:get, key}
		{:reply, value, {db_name, datas}}
	end

	def handle_call {:set, key, value}, _from, {db_name, datas} do
		IO.puts "set #{inspect key} #{inspect value}"
		GenServer.call data_pid(db_name, key), {:set, key, value}
		{:reply, :ok, {db_name, datas}}
	end

	def handle_call {:remove, key}, _from, {db_name, datas} do
		IO.puts "remove #{inspect key}"
		GenServer.call data_pid(db_name, key), {:remove, key}
		{:reply, :ok, {db_name, datas}}
	end	

	def handle_cast {:set, key, value}, {db_name, datas} do
		IO.puts "set #{inspect key} #{inspect value}"
		GenServer.cast data_pid(db_name, key), {:set, key, value}
		{:noreply, {db_name, datas}}
	end

 	# TODO: para chequear si aparecieron nodos data nuevos
	defp onDataChange(db_name, datas) do
		
		#d = :pg2.get_members db_name
		#if datas != :pg2.get_members db_name do
		#	IO.puts 'CAMBIARON LOS DATA #{inspect d}'
		#else
		#	IO.puts 'NO CAMBIARON LOS DATA #{inspect d}'
		#end

	end

	defp data_pid db_name, key do

		value = :crypto.hash(:sha256, key) |> Base.encode16 |> String.graphemes |> Enum.map(fn x -> String.to_integer x, 16 end) |> Enum.sum

		datas = :pg2.get_members {:data, db_name}
		
		index = rem(value, length(datas))
		
		Enum.at datas, index 
	
	end

end
