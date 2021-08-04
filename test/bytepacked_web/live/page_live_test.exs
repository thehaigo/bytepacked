defmodule BytepackedWeb.PageLiveTest do
  use BytepackedWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Welcome to Bytepacked"
    assert render(page_live) =~ "Welcome to Bytepacked"
  end
end
