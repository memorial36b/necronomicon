# Migration: AddAssignableRoleGroupsTableToDatabase
Sequel.migration do
  change do
    create_table(:assignable_role_groups) do
      primary_key :id
      String :name
      String :key
      TrueClass :is_exclusive
    end
  end
end