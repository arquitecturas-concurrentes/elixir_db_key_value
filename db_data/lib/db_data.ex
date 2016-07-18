defmodule DB.Data do
	use GenServer

	# Public API
  	def start_link(name, db_name, servers) do
    	GenServer.start_link(__MODULE__, {:ok, db_name, servers}, [name: name])
  	end	

  	# Private API
  	def init({:ok, db_name, servers}) do
  		IO.puts "Starting Data..."
  		Enum.map servers, fn x -> Node.ping(x) end
  		:pg2.create db_name
  		:pg2.join db_name, self
  		{:ok, db_name} 
  	end  	

end
