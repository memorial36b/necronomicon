# Model: AssignableRole


# An assignable role object. Contains fields for the role ID (primary key), role key, role description, and references
# an AssignableRoleGroup.
class Bot::Models::AssignableRole < Sequel::Model
  unrestrict_primary_key
  many_to_one :group, class: 'Bot::Models::AssignableRoleGroup', key: :assignable_role_group_id
end