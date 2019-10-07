# This file contains the schema for the database.
# Under most circumstances, you shouldn't need to run this file directly.
require 'sequel'

module Schema
  Sequel.sqlite(ENV['DB_PATH']) do |db|
    db.create_table?(:assignable_roles) do
      primary_key :id
      String :key, :size=>255
      String :description, :size=>255
      foreign_key :assignable_role_group_id, :assignable_role_groups
    end

    db.create_table?(:assignable_role_groups) do
      primary_key :id
      String :name, :size=>255
      String :key, :size=>255
      TrueClass :is_exclusive
      String :description, :size=>255
    end
  end
end