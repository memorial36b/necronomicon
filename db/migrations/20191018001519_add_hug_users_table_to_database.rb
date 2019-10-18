# Migration: AddHugUsersTableToDatabase
Sequel.migration do
  change do
    create_table(:hug_users) do
      primary_key :id
      Integer :given
      Integer :received
    end
  end
end