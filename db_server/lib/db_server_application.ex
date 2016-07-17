defmodule DBServerApplication do
	use Application	

	def start(_type, _args) do
		DB.Server.Supervisor.start_link(OwesomeDatabase)
	end	

end