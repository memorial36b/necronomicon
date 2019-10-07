# Migration: AddAssignableRolesTableToDatabase
Sequel.migration do
  change do
    create_table(:assignable_roles) do
      primary_key :id
      String :key
      String :description
      foreign_key :assignable_role_group_id, :assignable_role_groups
    end
  end
end