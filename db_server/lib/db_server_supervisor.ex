defmodule DB.Server.Supervisor do
	use Supervisor

	# Public API
	def start_link(db_name, servers \\ []) do
		Supervisor.start_link(__MODULE__, {:ok, db_name, servers})
	end

	# Private API
	def init({:ok, db_name, servers}) do
	    children = [
	      worker(DB.Server, [db_name, servers], restart: :transient)
	    ]
    	supervise(children, strategy: :one_for_one, max_restarts: 10, max_seconds: 2)	    
	end

end