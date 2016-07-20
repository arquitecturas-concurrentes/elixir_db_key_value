defmodule DB.Client do
	use GenServer

	  # Public API
  	def start_link(name, db_name, servers) do
    	GenServer.start_link(__MODULE__, {:ok, db_name, servers}, [name: name])
  	end

    # Get a value by key
  	def get(pid, key) do
  		GenServer.call pid, {:get, key}
  	end

    # Set a value by key
    def set(pid, key, value) do
      GenServer.call pid, {:set, key, value} 
    end

    # Set a value by key (it doesn't await for confirmation)
    def unsafe_set(pid, key, value) do
      GenServer.cast pid, {:set, key, value}
    end

    # Remove a key
    def remove(pid, key) do
      GenServer.call pid, {:remove, key}
    end

    # Get all values lower than
    def lower(pid, value) do
      GenServer.call pid, {:lower, value}
    end    

    # Get all values higher than
    def higher(pid, value) do
      GenServer.call pid, {:higher, value}
    end      

  	# Private API
  	def init({:ok, db_name, servers}) do

  		IO.puts "Starting Client..."
  	
      # Init Server Process Group
      :pg2.create {:server, db_name}

      # Connect this Node with Node Server/s
      servers |> Enum.map(fn x -> Node.ping(x) end)
  		
      {:ok, db_name}
  	
    end

  	def handle_call({:get, key}, _from, db_name) do
      case master_process db_name do 
        [master|_] -> {:reply, GenServer.call(master, {:get, key}), db_name}
        [] -> {:reply, :no_master, db_name}
      end
  	end

    def handle_call({:lower, value}, _from, db_name) do
      case master_process db_name do 
        [master|_] -> {:reply, GenServer.call(master, {:lower, value}), db_name}
        [] -> {:reply, :no_master, db_name}
      end
    end   

    def handle_call({:higher, value}, _from, db_name) do
      case master_process db_name do 
        [master|_] -> {:reply, GenServer.call(master, {:higher, value}), db_name}
        [] -> {:reply, :no_master, db_name}
      end
    end      

    def handle_call({:set, key, value}, _from, db_name) do
      case master_process db_name do
        [master|_] -> 
          GenServer.call master, {:set, key, value}
          {:reply, :ok, db_name}
        [] -> {:reply, :no_master, db_name}          
      end
    end

    def handle_call({:remove, key}, _from, db_name) do
      case master_process db_name do
        [master|_] -> 
          GenServer.call master, {:remove, key}
          {:reply, :ok, db_name}
        [] -> {:reply, :no_master, db_name}  
      end

    end    

    def handle_call(_, _from, db_name) do
      {:reply, :unknown, db_name}
    end    

    def handle_cast({:set, key, value}, db_name) do
      case master_process db_name do
        [master|_] -> GenServer.cast master, {:set, key, value}
        [] -> {}
      end
      {:noreply, db_name}
    end

    def handle_cast(_, db_name) do
      {:noreply, db_name}
    end

    defp master_process db_name do
      :pg2.get_members {:server, db_name} 
    end

end
