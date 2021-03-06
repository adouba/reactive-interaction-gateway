defmodule RIG.Session.Connection do
  @moduledoc """
  Associate a connection to a session, and terminate sessions along with their associated connections.
  """
  require Logger

  @group_prefix "rig::session::"

  @doc "Associates a connection process with a session name."
  @spec associate_session(pid :: pid(), session_id :: String.t()) :: :ok
  def associate_session(pid, session_id) when is_pid(pid) and byte_size(session_id) > 0 do
    group = @group_prefix <> session_id

    # Ensure the session (group) exists:
    :ok = :pg2.create(group)

    # PG2 does not prevent subscribing multiple times, so we do it here:
    member? = :pg2.get_members(group) |> Enum.member?(pid)

    if not member? do
      :ok = :pg2.join(group, pid)
    end
  end

  @doc "Tells all connection processes associated with a session name to terminate."
  @spec terminate_all_associated_to(session_id :: String.t()) :: :ok
  def terminate_all_associated_to(session_id) when byte_size(session_id) > 0 do
    group = @group_prefix <> session_id

    case :pg2.get_members(group) do
      {:error, {:no_such_group, ^group}} ->
        :ok

      members ->
        for pid <- members, do: send(pid, {:session_killed, session_id})
        :ok = :pg2.delete(group)
    end
  end
end
