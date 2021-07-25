defmodule BytepackedWeb.DashboardLive.Index do
  use BytepackedWeb, :live_view
  alias Bytepacked.{Accounts}

  @impl true
  def mount(params, session, socket) do
    socket =
      socket
      |> MountHelpers.assign_defaults(params, session, [:user, :dashboard])
      |> assign(:page_title, "Dashboard")

    {:ok, socket}
  end

  @impl true
  def handle_event("confirmation_resend", _, socket) do
    socket.assigns.current_user
    |> Accounts.deliver_user_confirmation_instructions(
      &Routes.user_confirmation_url(socket, :confirm, &1)
    )

    {
      :noreply,
      socket |> put_flash(:info, "You will receive an e-mail with instrucation shortly.")
    }
  end
end
