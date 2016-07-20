defmodule DB.Data do
    use GenServer

    # Public API
  	def start_link db_name, servers \\ [] do
      GenServer.start_link(__MODULE__, {:ok, db_name, servers})
  	end	

  	# Private API
  	def init {:ok, db_name, servers} do

  		IO.puts "Starting Data..."
  		
      # Data Process Group
      :pg2.create {:data, db_name}
      :pg2.join {:data, db_name}, self

      # Connect this Node with Database Node/s
      servers |> Enum.map(fn x -> Node.ping(x) end)

  		{:ok, %{}} 
  	
    end

    def handle_call {:get, key}, _from, data do
      {:reply, data |> Map.get(key), data}  
    end

    def handle_call {:set, key, value}, _from, data do
      {:reply, :ok, data |> Map.put(key, value)}
    end

    def handle_call {:remove, key}, _from, data do
      {:reply, :ok, data |> Map.delete(key)}
    end

    def handle_call {:keys}, _from, data do
      {:reply, data |> Map.keys, data}
    end

    def handle_call {:lower, value}, _from, data do
      {:reply, data |> Map.values |> Enum.filter(fn x -> x < value end), data}
    end

    def handle_call {:higher, value}, _from, data do
      {:reply, data |> Map.values |> Enum.filter(fn x -> x > value end), data}
    end    

    def handle_call _, _from, data do
      {:reply, :unknown, data}
    end    

    def handle_cast {:set, key, value}, data do
      {:noreply, data |> Map.put(key, value)}
    end

    def handle_cast _, data do
      {:noreply, data}
    end

end
