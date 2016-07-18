defmodule DB.Data.Supervisor do
	use Supervisor

	# Public API
	def start_link(name, db_name, servers) do
		Supervisor.start_link(__MODULE__, {:ok, name, db_name, servers})
	end	

	# Private API
	def init({:ok, name, db_name, servers}) do
		children = [
			worker(DB.Data, [name, db_name, servers]) 
		]
		supervise(children, strategy: :one_for_one)
	end

end