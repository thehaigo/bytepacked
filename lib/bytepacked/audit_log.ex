defmodule Bytepacked.AuditLog do
  @moduledoc """
  The audit log struct.

  The audit log has `audit_context`, `action`, and `params`.

  If `audit_context` contains a user, their email address will be
  automatically written to the log as `:user_email`. After building
  the log, the params are automatically validated according to the
  @params module attribute.
  """

  use Bytepacked.Schema
  import Ecto.Query

  alias Bytepacked.{Accounts, Repo}

  defmodule InvalidParameterError do
    defexception [:message]
  end

  @foreign_key_type :binary_id
  schema "audit_logs" do
    field :action, :string
    field :ip_address, Bytepacked.Extensions.Ecto.IPAddress
    field :user_agent, :string
    field :user_email, :string
    field :params, :map, default: %{}

    belongs_to :user, Accounts.User

    timestamps(updated_at: false)
  end

  # Listing of all known actions and their parameters
  @params %{
    "accounts.login" => ~w(email),
    "accounts.register_user" => ~w(email),
    "accounts.reset_password.init" => ~w(user_id),
    "accounts.reset_password.finish" => ~w(user_id),
    "accounts.update_email.init" => ~w(user_id email),
    "accounts.update_email.finish" => ~w(user_id email),
    "accounts.update_password" => ~w(user_id),
  }

  @doc """
  Returns a system audit log
  """
  def system() do
    %__MODULE__{ user: nil }
  end
  @doc """
  Creats an audit log.
  """
  def audit!(audit_context, action, params) do
    Repo.insert!(build!(audit_context, action, params))
  end

  @doc """
  Adds an audit log to the `multi`.

  It can receive a function or parameters as the 4th argument.

  In case it receives a function, it will have an `audit_context`
  and Ecto multi results so far, and it must return an (possibly
  updated) audit log.

  The parameters needs to be passed directly into `audit_context`
  inside the function.

  In case it receives a map with the parameters, those parameters
  will be validated in a lazy way, inside a Multi.run/3 function.
  It may raise an exception in case of invalid params.
  """
  def multi(multi, audit_context, action, fun) when is_function(fun, 2) do
    Ecto.Multi.run(multi, :audit, fn repo, results ->
      audit_log = build!(fun.(audit_context, results), action, %{})
      {:ok, repo.insert!(audit_log)}
    end)
  end

  def multi(multi, audit_context, action, params) when is_map(params) do
    Ecto.Multi.insert(multi, :audit, fn _ ->
      build!(audit_context, action, params)
    end)
  end

  @doc """
  Lists audits for `user`.
  """
  def list_by_user(%Accounts.User{} = user, clauses \\ []) do
    Repo.all(from(__MODULE__, where: [user_id: ^user.id], where: ^clauses, order_by: [asc: :id]))
  end

  def list_all_from_system(clauses \\ []) do
    Repo.all(
      from(
        a in __MODULE__,
        where: is_nil(a.user_id),
        where: ^clauses,
        order_by: [asc: :id]
      )
    )
  end

  ## Building
  defp build!(%__MODULE__{} = audit_context, action, params)
      when is_binary(action) and is_map(params) do
    %{audit_context | action: action, params: Map.merge(audit_context.params, params)}
    |> Map.replace(:user_email, audit_context.user && audit_context.user.email)
    |> validate_params!()
  end

  defp validate_params!(struct) do
    action = struct.action
    params = struct.params

    expected_keys = Map.fetch!(@params, action)

    actual_keys =
      params
      |> Map.keys()
      |> Enum.map(&to_string/1)

    case {expected_keys -- actual_keys, actual_keys -- expected_keys} do
      {[], []} ->
        :ok

      {_, [_ | _] = extra_keys} ->
        raise InvalidParameterError,
              "extra keys #{inspect(extra_keys)} for action #{action} in #{inspect(params)}"

      {missing_keys, _} ->
        raise InvalidParameterError,
              "missing keys #{inspect(missing_keys)} for action #{action} in #{inspect(params)}"
    end

    struct
  end
end
