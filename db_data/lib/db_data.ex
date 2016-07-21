defmodule DB.Data do
    use GenServer

    # Public API
  	def start_link db_name, conf, servers do
      GenServer.start_link(__MODULE__, {:ok, db_name, conf, servers})
  	end	

    # Check key distribution
    def check_key_distribution db_name do
      :pg2.get_members({:data, db_name}) |> Enum.map(fn pid -> GenServer.call(pid,{:keys}) |> Enum.map(fn key -> GenServer.call(pid, {:get, key}) end) |> length end)
    end

  	# Private API
  	def init {:ok, db_name, conf, servers} do

  		IO.puts "Starting Data..."
  		
      # Data Process Group
      :pg2.create {:data, db_name}
      :pg2.join {:data, db_name}, self

      # Connect this Node with Database Node/s
      servers |> Enum.map(fn x -> Node.ping(x) end)

  		{:ok, {conf, %{}}} 
  	
    end

    def handle_call {:get, key}, _from, {conf,data} do
      check_key_length conf, key
      {:reply, data |> Map.get(key), {conf, data}}  
    end

    def handle_call {:set, key, value}, _from, {conf,data} do
      try do
        check_key_length conf, key
        check_value_length conf, value
        new_data = data |> Map.put(key, value)
        check_key_count conf, new_data
        {:reply, :ok, {conf,new_data}}
      catch
        msg -> {:error, msg}
      end
    end

    def handle_call {:remove, key}, _from, {conf,data} do
      try do
        check_key_length conf, key
        {:reply, :ok, {conf,data |> Map.delete(key)}}
      catch
        msg -> {:error, msg}
      end      
    end

    def handle_call {:keys}, _from, {conf,data} do
      {:reply, data |> Map.keys, {conf, data}}
    end

    def handle_call {:lower, value}, _from, {conf,data} do
      try do
        check_value_length conf, value
        {:reply, data |> Map.values |> Enum.filter(fn x -> x < value end), {conf, data}}
      catch
        msg -> {:error, msg}
      end
    end

    def handle_call {:higher, value}, _from, {conf,data} do
      try do
        check_value_length conf, value
        {:reply, data |> Map.values |> Enum.filter(fn x -> x > value end), {conf, data}}
      catch
        msg -> {:error, msg}
      end
    end    

    def handle_call _, _from, state do
      {:reply, :unknown, state}
    end    

    def handle_cast {:set, key, value}, {conf,data} do
      try do
        check_value_length conf, value
        {:noreply, {conf,data |> Map.put(key, value)}}
      catch
        msg -> {:error, msg}
      end
    end

    def handle_cast _, state do
      {:noreply, state}
    end

    defp check_key_count conf, data do
      {max, _, _} = conf
      if Map.values(data) |> length > max do
        throw :not_enough_space
      end
    end

    defp check_key_length conf, key do
      {_, max, _} = conf
      if key |> String.length > max do
        throw :key_too_large
      end
    end

    defp check_value_length conf, value do
      {_, _, max} = conf
      if value |> String.length > max do
        throw :value_too_large
      end
    end

end
