defmodule BytepackedWeb.MountHelpers do
  import Phoenix.LiveView
  alias Bytepacked.Accounts
  alias BytepackedWeb.Router.Helpers, as: Routes

  @doc """
  Assign default values on the socket.
  """
  def assign_defaults(socket, _params, session, acl) do
    socket
    |> assign_current_user(session)
    |> ensure_access(acl)
  end

  defp assign_current_user(socket, session) do
    assign_new(socket, :current_user, fn ->
      Accounts.get_user_by_session_token(session["user_token"])
    end)
  end

  defp ensure_access(socket, [:user, _] = acl) do
    assign(socket, :acl, acl)
  end

  defp ensure_access(socket, acl) do
    cond do
      is_nil(socket.assigns.current_user.confirmed_at) ->
        socket
        |> put_flash(:error, "You need to confirm your account to access this page")
        |> push_redirect(to: Routes.dashboard_index_path(socket, :index))

      true ->
        assign(socket, :acl, acl)
    end
  end
end
