defmodule BytepackedWeb.RequestContext do
  alias Bytepacked.AuditLog

  def put_audit_context(conn_or_socket, opts \\ [])

  def put_audit_context(%Plug.Conn{} = conn, _) do
    user_agent =
      case List.keyfind(conn.req_headers, "user-agent", 0) do
        {_, value} -> value
        _ -> nil
      end

    Plug.Conn.assign(conn, :audit_context, %AuditLog{
      user_agent: user_agent,
      ip_address: get_ip(conn.req_headers),
      user: conn.assigns[:current_user]
    })
  end

  def put_audit_context(%Phoenix.LiveView.Socket{} = socket, _) do
    audit_context = %AuditLog{
      user: socket.assigns[:current_user]
    }

    extra =
      if info = Phoenix.LiveView.get_connect_info(socket) do
        ip = get_ip(info[:x_headers] || [])
        %{ip_address: ip, user_agent: info[:user_agent]}
      else
        %{}
      end

    Phoenix.LiveView.assign(socket, :audit_context, struct!(audit_context, extra))
  end

  defp get_ip(headers) do
    with {_, ip} <- List.keyfind(headers, "x-forwarded-for", 0),
          [ip | _] = String.split(ip, ","),
          {:ok, address} <- Bytepacked.Extensions.Ecto.IPAddress.cast(ip) do
      address
    else
      _ -> nil
    end
  end
end
