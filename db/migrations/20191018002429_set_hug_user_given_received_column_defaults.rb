# Migration: SetHugUserGivenReceivedColumnDefaults
Sequel.migration do
  change do
    alter_table :hug_users do
      set_column_default :given, 0
      set_column_default :received, 0
    end
  end
end