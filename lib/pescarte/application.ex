defmodule Pescarte.Application do
  use Application

  @impl true
  def start(_, _) do
    if Pescarte.env() == :prod do
      :logger.add_handler(:pescarte_sentry_handler, Sentry.LoggerHandler, %{
        config: %{metadata: [:file, :line]}
      })
    end

    opts = [strategy: :one_for_one, name: Pescarte.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PescarteWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp children do
    if Pescarte.env() == :dev, do: Faker.start()

    [
      Pescarte.Database.Supervisor,
      PescarteWeb.Telemetry,
      {Phoenix.PubSub, name: Pescarte.PubSub},
      PescarteWeb.Endpoint,
      Pescarte.CotacoesETL.InjesterSupervisor,
      Pescarte.Supabase,
      {Finch, name: PescarteHTTPClient}
    ]
    |> maybe_append_children(Pescarte.env())
  end

  defp maybe_append_children(children, :test), do: children
  # defp maybe_append_children(children, _), do: [ChromicPDF | children]
  defp maybe_append_children(children, _), do: children
end
