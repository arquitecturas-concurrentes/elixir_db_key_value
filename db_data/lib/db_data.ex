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
      Enum.map servers, fn x -> Node.ping(x) end

  		{:ok, %{}} 
  	
    end

    def handle_call {:get, key}, _from, data do
      {:reply, Map.get(data, key), data}  
    end

    def handle_call {:set, key, value}, _from, data do
      {:reply, :ok, Map.put(data, key, value)}
    end

    def handle_call {:remove, key}, _from, data do
      {:reply, :ok, Map.delete(data, key)}
    end

    def handle_call {:keys}, _from, data do
      {:reply, Map.keys(data), data}
    end

    def handle_call _, _from, data do
      {:reply, :unknown, data}
    end    

    def handle_cast {:set, key, value}, data do
      {:noreply, Map.put(data, key, value)}
    end

    def handle_cast _, data do
      {:noreply, data}
    end

end
