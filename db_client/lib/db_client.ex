defmodule DB.Client do
	use GenServer

	# Public API
  	def start_link(name, db_name, servers) do
    	GenServer.start_link(__MODULE__, {:ok, db_name, servers}, [name: name])
  	end

  	def get(pid, key) do
  		GenServer.call pid, {:get, key}
  	end

    def set(pid, key, value) do
      GenServer.call pid, {:set, key, value} 
    end

    def unsafe_set(pid, key, value) do
      GenServer.cast pid, {:set, key, value}
    end

    def remove(pid, key) do
      GenServer.call pid, {:remove, key}
    end

  	# Private API
  	def init({:ok, db_name, servers}) do
  		IO.puts "Starting Client..."
  		Enum.map servers, fn x -> Node.ping(x) end
  		{:ok, db_name}
  	end

  	def handle_call({:get, key}, _from, db_name) do
  		{:reply, GenServer.call({:global, db_name}, {:get, key}), db_name}
  	end

    def handle_call({:set, key, value}, _from, db_name) do
      GenServer.call {:global, db_name}, {:set, key, value}
      {:reply, :ok, db_name}
    end

    def handle_call({:remove, key}, _from, db_name) do
      GenServer.call {:global, db_name}, {:remove, key}
      {:reply, :ok, db_name}
    end    

    def handle_call(_, _from, db_name) do
      {:reply, :unknown, db_name}
    end    

    def handle_cast({:set, key, value}, db_name) do
      GenServer.cast {:global, db_name}, {:set, key, value}
      {:noreply, db_name}
    end

    def handle_cast(_, db_name) do
      {:noreply, db_name}
    end

end
