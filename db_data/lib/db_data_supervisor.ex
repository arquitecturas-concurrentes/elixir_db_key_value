defmodule DB.Data.Supervisor do
  	use Supervisor

	# Public API
	def start_link db_name, max_keys \\ 1000, key_length \\ 100, value_length \\ 100, servers \\ [] do
		Supervisor.start_link(__MODULE__, {:ok, db_name, max_keys, key_length, value_length, servers})
	end	

	# Private API
	def init {:ok, db_name, max_keys, key_length, value_length, servers} do
		children = [
			worker(DB.Data, [db_name, {max_keys, key_length, value_length}, servers])
		]
		supervise(children, strategy: :one_for_one)
	end

end