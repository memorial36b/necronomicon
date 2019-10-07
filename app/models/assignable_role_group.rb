# Model: AssignableRoleGroup

require_relative 'assignable_role'


# A group for an assignable role. Has fields for the group's name, key, and whether the group is "exclusive"
# (only one role from the group can be assigned at a time)
class Bot::Models::AssignableRoleGroup < Sequel::Model
  one_to_many :roles, class: 'Bot::Models::AssignableRole', key: :assignable_role_group_id

  def before_destroy
    Bot::Models::AssignableRole.where(assignable_role_group_id: self.id).update(assignable_role_group_id: nil)
  end
end