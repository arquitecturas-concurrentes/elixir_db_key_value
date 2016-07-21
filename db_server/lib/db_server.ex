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

	def handle_call {:get, key}, _from, {db_name, old_data_processes} do
		IO.puts "get #{inspect key}"
		on_data_change db_name, old_data_processes
		value = GenServer.call lookup_data(db_name, key), {:get, key}
		{:reply, value, {db_name, data_processes(db_name)}}
	end

	def handle_call {:set, key, value}, _from, {db_name, old_data_processes} do
		IO.puts "set #{inspect key} #{inspect value}"
		on_data_change db_name, old_data_processes
		GenServer.call lookup_data(db_name, key), {:set, key, value}
		{:reply, :ok, {db_name, data_processes(db_name)}}
	end

	def handle_call {:remove, key}, _from, {db_name, old_data_processes} do
		IO.puts "remove #{inspect key}"
		on_data_change db_name, old_data_processes
		GenServer.call lookup_data(db_name, key), {:remove, key}
		{:reply, :ok, {db_name, data_processes(db_name)}}
	end	

	def handle_call {:lower, value}, _from, {db_name, old_data_processes} do
		IO.puts "lower than #{inspect value}"
		on_data_change db_name, old_data_processes
		values = data_processes(db_name) |> Enum.map(fn x -> GenServer.call x, {:lower, value} end) |> List.flatten
		{:reply, values, {db_name, data_processes(db_name)}}
	end

	def handle_call {:higher, value}, _from, {db_name, old_data_processes} do
		IO.puts "higher than #{inspect value}"
		on_data_change db_name, old_data_processes
		values = data_processes(db_name) |> Enum.map(fn x -> GenServer.call x, {:higher, value} end) |> List.flatten
		{:reply, values, {db_name, data_processes(db_name)}}
	end	

	def handle_cast {:set, key, value}, {db_name, old_data_processes} do
		IO.puts "set #{inspect key} #{inspect value}"
		on_data_change db_name, old_data_processes
		GenServer.cast lookup_data(db_name, key), {:set, key, value}
		{:noreply, {db_name, data_processes(db_name)}}
	end

 	# it checks if data processes have changed
	defp on_data_change db_name, old_data_processes do
		
		if data_processes(db_name) != old_data_processes do

			data_processes(db_name) |> Enum.each(fn pid ->
				GenServer.call(pid, {:keys}) |> Enum.each(fn key ->

					if lookup_data(db_name, key) != pid do
						value = GenServer.call pid, {:get, key}
						GenServer.call pid, {:remove, key}
						GenServer.call lookup_data(db_name, key), {:set, key, value}
						IO.puts "key #{key} migrated from #{inspect pid} to #{inspect lookup_data(db_name, key)}"
					end

				end)	
			end)

		else
			# no changes
		end

		#d = :pg2.get_members db_name
		#if datas != :pg2.get_members db_name do
		#	IO.puts 'CAMBIARON LOS DATA #{inspect d}'
		#else
		#	IO.puts 'NO CAMBIARON LOS DATA #{inspect d}'
		#end

	end

	# list of current data pids
	defp data_processes db_name do
		:pg2.get_members {:data, db_name}	
	end

	# lookup data pid by key
	defp lookup_data db_name, key do

		value = :crypto.hash(:sha256, key) |> Base.encode16 |> String.graphemes |> Enum.map(fn x -> String.to_integer x, 16 end) |> Enum.sum

		datas = data_processes db_name
		
		index = rem(value, length(datas))
		
		Enum.at datas, index 
	
	end

end
