# Migration: AddDescriptionTableToAssignableRoleGroup
Sequel.migration do
  change do
    alter_table :assignable_role_groups do
      add_column :description, String
    end
  end
end