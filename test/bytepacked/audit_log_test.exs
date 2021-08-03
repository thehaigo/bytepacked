defmodule Bytepacked.AuditLogTest do
  use Bytepacked.DataCase, async: true

  import Bytepacked.AccountsFixtures
  alias Bytepacked.AuditLog
  alias Bytepacked.Accounts.User

  describe "audit!/3" do
    test "sets user_email from user" do
      user = user_fixture()
      audit_log = AuditLog.audit!(%{system() | user: user}, "accounts.login", %{email: user.email})

      assert audit_log.action == "accounts.login"
      assert audit_log.user_email
      assert audit_log.user_email == user.email
    end

    test "validates params" do
      message = "extra keys [\"extra\"] for action accounts.login in %{extra: \"\"}"

      assert_raise AuditLog.InvalidParameterError, message, fn ->
        AuditLog.audit!(system(), "accounts.login", %{extra: ""})
      end

      message = "missing keys [\"email\"] for action accounts.login in %{}"

      assert_raise AuditLog.InvalidParameterError, message, fn ->
        AuditLog.audit!(system(), "accounts.login", %{})
      end
    end
  end

  describe "multi/4" do
    test "creats an ecto multi operation with params" do
      multi = AuditLog.multi(Ecto.Multi.new(), system(), "accounts.register_user", %{email: "test@bytepacked.com" })
      assert %Ecto.Multi{} = multi

      assert {:ok, %{audit: audit_log}} = Bytepacked.Repo.transaction((multi))

      assert audit_log.action == "accounts.register_user"
      assert audit_log.params == %{email: "test@bytepacked.com"}
    end

    test "creates an ecto multi opeation with a function" do
      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :user,
          User.registration_changeset(%User{}, %{
            email: "test@bytepacked.com",
            password: "testpassword"
          })
        )
        |> AuditLog.multi(system(), "accounts.register_user", fn audit_context, changes_so_far ->
          assert %AuditLog{} = audit_context
          assert %{user: %User{}} = changes_so_far

          %{audit_context | params: %{email: "test@bytepacked"}}
        end)

      assert {:ok, %{audit: audit_log}} = Bytepacked.Repo.transaction(multi)
      assert audit_log.action == "accounts.register_user"
      assert audit_log.params == %{email: "test@bytepacked"}
    end

    test "raises error with invalid params inside transaction" do
      multi =
        Ecto.Multi.new()
        |> AuditLog.multi(system(), "accounts.register_user", fn audit_context, _ ->
          %{audit_context | params: %{invalid_params: "invalid"}}
        end)

      assert_raise AuditLog.InvalidParameterError, ~r/extra key/, fn ->
        Repo.transaction(multi)
      end

      multi = AuditLog.multi(Ecto.Multi.new(), system(), "accounts.register_user", %{})
      assert_raise AuditLog.InvalidParameterError, ~r/missing key/, fn ->
        Repo.transaction(multi)
      end
    end
  end

  describe "queries" do
    setup do
      user = user_fixture()
      AuditLog.audit!(system(), "accounts.register_user", %{email: "test@bytepacked.com"})
      AuditLog.audit!(%{system() | user: user}, "accounts.update_password", %{user_id: user.id})
      {:ok, %{user: user}}
    end

    test "list_by_user/2 returns audit logs related to user", %{user: user} do
      assert [audit_log] = AuditLog.list_by_user(user, action: "accounts.update_password")
      assert audit_log.params == %{"user_id" => user.id}

      assert [] = AuditLog.list_by_user(user, action: "accounts.update_email.finish")

      assert [register_log, ^audit_log] = AuditLog.list_by_user(user)
      assert register_log.action == "accounts.register_user"
    end

    test "list_all_from_system/1" do
      assert [audit_log] = AuditLog.list_all_from_system(action: "accounts.register_user")
      assert audit_log.params == %{"email" => "test@bytepacked.com"}
      refute audit_log.user_id

      assert [] = AuditLog.list_all_from_system(action: "accounts.login")
      assert [^audit_log] = AuditLog.list_all_from_system()
    end
  end
end
