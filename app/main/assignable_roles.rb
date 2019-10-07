# Crystal: AssignableRoles


# Allows users to give and remove certain assignable roles to themselves.
module Bot::AssignableRoles
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  include Bot::Models

  include Constants

  module_function


  # Companion function to the !roles command used to generate the embeds for each group
  # @param  [Integer]                    index the index to generate the embed for
  #                                            (0 for ungrouped roles, 1+ for groups)
  # @return [Discordrb::Webhooks::Embed]       the generated embed
  def generate_embed(index)
    embed = Discordrb::Webhooks::Embed.new
    embed.color = 0xFFD700

    # If index for a role group is given, generate embed for that group
    if index > 0
      group = AssignableRoleGroup.all[index - 1]
      embed.author = {
          name:     "Group: #{group.name}",
          icon_url: BOT_AVATAR_URL
      }
      embed.description = <<~DESC.strip
        #{group.description}

        #{group.is_exclusive ? '**This group is exclusive; you can only have one role from it at a time.**' : nil}
      DESC
      roles_text = if group.roles.any?
                     group.roles.map do |role|
                       if role.description
                         "• `!#{role.key}` **#{SERVER.role(role.id).name}** - *#{role.description}*"
                       else
                         "• `!#{role.key}` **#{SERVER.role(role.id).name}**"
                       end
                     end.join("\n")
                   else
                     'No roles found.'
                   end
      embed.add_field(
          name:  'Roles',
          value: roles_text
      )
      embed.footer = {text: "Group key: #{group.key}"}

    # Otherwise, generate an embed for ungrouped roles
    else
      roles = AssignableRole.all.reject { |r| r.group }

      embed.author = {
          name:     "Ungrouped Roles",
          icon_url: BOT_AVATAR_URL
      }
      embed.description = <<~DESC_DICHADO.strip
          This is a list of all assignable roles that do not have a group.
          Use a role's command to assign it to you, and use it again to remove it.
      DESC_DICHADO
      roles_text = if roles.any?
                     roles.map do |role|
                       if role.description
                         "• `!#{role.key}` **#{SERVER.role(role.id).name}** - *#{role.description}*"
                       else
                         "• `!#{role.key}` **#{SERVER.role(role.id).name}**"
                       end
                     end.join("\n")
                   else
                     'No roles found.'
                   end
      embed.add_field(
          name:  'Roles',
          value: roles_text
      )
      embed.footer = {text: "Use the reaction buttons to scroll through the groups."}
    end

    embed
  end


  # Display all assignable roles
  command :roles, description: 'Displays a list of all assignable roles and their commands.',
                  usage:       '!roles <optional group key>' do |event, arg|
    # If argument exists but no group with given key was found, respond to user and break
    if arg && !AssignableRoleGroup[key: arg]
      event.send_temp('No role group with that key was found.', 5)
      break
    end

    groups = AssignableRoleGroup.all
    selected_index = arg ? groups.find_index { |g| g.key == arg.downcase } + 1 : 0

    # Send embed containing role info and add reaction controls
    msg = event.respond('', false, generate_embed(selected_index))
    msg.reaction_controls(event.user, 0..(groups.size), 30, selected_index) do |index|
      msg.edit('', generate_embed(index))
    end
  end


  # Detect assignable role commands and add/remove respective role
  message start_with: '!' do |event|
    # Skip unless command matches a role's key
    next unless (role = AssignableRole[key: event.message.content[1..-1]])

    # If user already has role, remove role and respond to user
    if event.user.role?(role.id)
      event.user.remove_role(role.id)
      event.respond "**#{event.user.mention}**, your **#{SERVER.role(role.id).name}** role has been removed."

    # Otherwise:
    else
      # If the role is in an exclusive group, add role, remove all other roles in the group and respond to user
      if role.group && role.group.is_exclusive
        added_roles = [role.id]
        removed_roles = role.group.roles.map(&:id) - [role.id]
        event.user.modify_roles(added_roles, removed_roles)
        event.respond <<~RESPONSE.strip
          **#{event.user.mention}**, you have been given the **#{SERVER.role(role.id).name}** role.
          - Removed all other roles from the **#{role.group.name}** role group.
        RESPONSE

      # Otherwise, add role and respond to user
      else
        event.user.add_role(role.id)
        event.respond "**#{event.user.mention}**, you have been given the #{SERVER.role(role.id).name}** role."
      end
    end
  end


  # Add a role to the assignable role database
  command :addrole, permission_level: 3,
                    description:      'Add a role to the database by its key, making it assignable by users.',
                    usage:            '!addrole <key>',
                    min_args:         1,
                    max_args:         1 do |event, arg|
    # Break unless argument exists
    break unless arg

    # Respond to user and break if role with given key already exists
    if AssignableRole[key: arg.downcase]
      event.send_temp('A role with that key already exists.', 5)
      break
    end

    # Prompt user for name or ID of the assignable role, validating that a role with the given name or ID can be found
    # before returning prompt response
    response = event.message.prompt(
        <<~CONTENT.strip,
          **Which role would you like to assign to this key?** You can provide the role name or ID.
          Press ❌ to cancel.
        CONTENT
        timeout:  30,
        reaction: '❌',
        clean:    true
    ) do |msg|
      unless (is_valid = SERVER.role(msg.content.to_i) ||
                         SERVER.roles.any? { |r| r.name.downcase == msg.content.downcase})
        event.send_temp('That role could not be found.', 5)
      end
      is_valid
    end

    # Respond to user and break if role addition was canceled
    break '**Role addition canceled.**' if response.nil?

    role = SERVER.role(response.content.to_i) ||
           SERVER.roles.find { |r| r.name.downcase == response.content.downcase }

    # Prompt user for optional description
    response = event.message.prompt(
        <<~CONTENT.strip,
          **What should this role's description be?**
          Press 🚫 to have no description.
        CONTENT
        reaction: '🚫',
        clean:    true
    )
    description = response.content if response

    # Prompt user for optional role group, validating that the group can be found
    response = event.message.prompt(
        <<~CONTENT.strip,
          **Which group should this role belong to?**
          Press 🚫 for no group.
        CONTENT
        embed:    {
            author:      {
                name:     'Assignable Role Groups',
                icon_url: BOT_AVATAR_URL
            },
            description: AssignableRoleGroup.all.map { |g| "• `#{g.key}` - **#{g.name}**" }.join("\n"),
            color:       0xFFD700
        },
        reaction: '🚫',
        clean:    true
    ) { |msg| AssignableRoleGroup[key: msg.content.downcase] }
    group = AssignableRoleGroup[key: response.content.downcase] if response

    # Create assignable role and save to database
    assignable_role = AssignableRole.create(
        id:          role.id,
        key:         arg.downcase,
        description: description
    )
    assignable_role.group = group
    assignable_role.save

    # Respond to user
    event << "**Made role #{role.name} assignable with key `#{arg.downcase}`.**"
    event << "- Set description to `#{description.ellipsify(32)}`." if description
    event << "- Set role group to **#{group.name}**." if group
  end


  # Edit a role in the database
  command :editrole, permission_level: 3,
                     description:      'Edit the key, description or group of an assignable role.',
                     usage:            '!editrole <key>',
                     min_args:         1,
                     max_args:         1,
                     aliases:          [:modifyrole] do |event, arg|
    # Break unless argument exists and role with given key exists
    break unless arg && (role = AssignableRole[key: arg.downcase])

    # Prompt user for whether they would like to edit role key, description or group, ensuring a valid option is given
    response = event.message.prompt(
        <<~CONTENT.strip,
          **Now editing role with key `#{arg.downcase}`! What would you like to edit?**
          *Options:* **`k`**ey, **`d`**escription, **`g`**roup
          Press ❌ to cancel.
        CONTENT
        timeout:  30,
        reaction: '❌',
        clean:    true
    ) { |msg| 'kdg'.include?(msg.content[0].downcase) }

    # Respond to user and break if prompt was canceled or timed out
    break '**Role edit canceled.**' unless response

    case response.content[0].downcase
    # When user wants to edit key:
    when 'k'
      # Prompt user for what the new key should be, validating that the key is a single word and does not already
      # exist
      response = event.message.prompt('**What should the new key be?**', clean: true) do |message|
        if message.content =~ /\W/
          event.send_temp('Key cannot have any spaces!', 5)
        elsif AssignableRole[key: message.content.downcase]
          event.send_temp('A role with that key already exists.')
        else
          true
        end
      end
      key = response.content.downcase

      # Update assignable role and save to database
      role.key = key
      role.save

      # Respond to user
      event << "**Changed role key to `#{role.key}`.**"

    # When user wants to edit description:
    when 'd'
      # Prompt user for what the new description should be
      response = event.message.prompt(
          <<~CONTENT.strip,
            **What should the new description be?**
            Press 🚫 to have no description.
          CONTENT
          reaction: '🚫',
          clean:    true
      )
      description = response ? response.content.downcase : nil

      # Update assignable role and save to database
      role.description = description
      role.save

      # Respond to user
      if description
        event << "**Changed role description to `#{description.ellipsify(32)}`.**"
      else
        event << "**Removed role description.**"
      end

    # When user wants to edit role group:
    when 'g'
      # Prompt user for what the new description should be, validating that the group exists
      response = event.message.prompt(
          <<~CONTENT.strip,
            **What should the role's new group be?**
            Press 🚫 for no group.
          CONTENT
          embed:    {
              author:      {
                  name:     'Assignable Role Groups',
                  icon_url: BOT_AVATAR_URL
              },
              description: AssignableRoleGroup.all.map { |g| "• `#{g.key}` - **#{g.name}**" }.join("\n"),
              color:       0xFFD700
          },
          reaction: '🚫',
          clean:    true
      ) { |msg| AssignableRoleGroup[key: msg.content.downcase] }
      group = response ? AssignableRoleGroup[key: response.content.downcase] : nil

      # Associate role with new group and save to database
      role.group = group
      role.save

      # Respond to user
      if group
        event << "**Set role's group to #{group.name}.**"
      else
        event << "**Removed role from group.**"
      end
    end
  end


  # Delete role from the database
  command :deleterole, permission_level: 3,
                       description:      'Delete an assignable role from the database.',
                       usage:            '!deleterole <key>',
                       min_args:         1,
                       max_args:         1,
                       aliases:          [:removerole] do |event, arg|
    # Break unless argument exists and role with given key exists
    break unless arg && (role = AssignableRole[key: arg.downcase])

    # Delete role from database
    role.destroy

    # Respond to user
    event << "**Deleted role from assignable roles database.**"
  end


  # Add role group to database
  command :addgroup, permission_level: 3,
                     description:      'Creates an assignable role group and adds it to the database.',
                     usage:            '!addrole <key>',
                     min_args:         1,
                     max_args:         1 do |event, arg|
    # Break unless argument exists
    break unless arg

    # Respond to user and break if group with given key already exists
    if AssignableRoleGroup[key: arg.downcase]
      event.send_temp('A role group with that key already exists.', 5)
      break
    end

    # Prompt user for group name
    response = event.message.prompt(
        <<~CONTENT.strip,
          **What should the group's name be?**
          Press ❌ to cancel.
        CONTENT
        timeout:  30,
        reaction: '❌',
        clean:    true
    )

    # Break if group creation was canceled
    break '**Group creation canceled.**' if response.nil?

    name = response.content

    # Prompt user for optional description
    response = event.message.prompt(
        <<~CONTENT.strip,
          **What should this role group's description be?**
          Press 🚫 to have no description.
        CONTENT
        reaction: '🚫',
        clean:    true
    )
    description = response.content if response

    # Prompt user for whether the group is exclusive
    response = event.message.prompt(
        <<~CONTENT.strip,
          **Should this group be marked exclusive?** Only one role from an exclusive group can be held at a time.
          *Options:* `y`es, `n`o
        CONTENT
        clean: true
    ) { |msg| 'yn'.include?(msg.content[0].downcase) }
    is_exclusive = response.content[0].downcase == 'y'

    # Create assignable role group and save to database
    group = AssignableRoleGroup.create(
        key:          arg.downcase,
        name:         name,
        description:  description,
        is_exclusive: is_exclusive
    )
    group.save

    # Respond to user
    event << "**Created assignable role group #{group.name} with key `#{arg.downcase}`.**"
    event << "- Set description to `#{description.ellipsify(32)}`." if description
    event << "- Made role group exclusive." if is_exclusive
  end


  # Edit a role group in the database
  command :editgroup, permission_level: 3,
          description:      'Edit the key, name, description or role exclusivity of an assignable role group.',
          usage:            '!editgroup <key>',
          min_args:         1,
          max_args:         1,
          aliases:          [:modifygroup] do |event, arg|
    # Break unless argument exists and group with given key exists
    break unless arg && (group = AssignableRoleGroup[key: arg.downcase])

    # Prompt user for whether they would like to edit group key, name description or exclusivity,
    # ensuring a valid option is given
    response = event.message.prompt(
        <<~CONTENT.strip,
          **Now editing role group with key `#{arg.downcase}`! What would you like to edit?**
          *Options:* **`k`**ey, **`n`**ame, **`d`**escription, role **`e`**xclusivity
          Press ❌ to cancel.
        CONTENT
        timeout:  30,
        reaction: '❌',
        clean:    true
    ) { |msg| 'knde'.include?(msg.content[0].downcase) }

    # Respond to user and break if prompt was canceled or timed out
    break '**Group edit canceled.**' unless response

    case response.content[0].downcase
    # When user wants to edit key:
    when 'k'
      # Prompt user for what the new key should be, validating that the key is a single word and does not already
      # exist
      response = event.message.prompt('**What should the new key be?**', clean: true) do |message|
        if message.content =~ /\W/
          event.send_temp('Key cannot have any spaces!', 5)
        elsif AssignableRoleGroup[key: message.content.downcase]
          event.send_temp('A group with that key already exists.')
        else
          true
        end
      end
      key = response.content.downcase

      # Update role group and save to database
      group.key = key
      group.save

      # Respond to user
      event << "**Changed role group key to `#{group.key}`.**"

    # When user wants to edit group name:
    when 'n'
      # Prompt user for what the new name should be
      response = event.message.prompt(
          '**What should the new name be?**',
          clean: true
      )
      name = response.content

      # Update role group and save to database
      group.name = name
      group.save

      # Respond to user
      event << "**Changed role group name to #{group.name}.**"

    # When user wants to edit description:
    when 'd'
      # Prompt user for what the new description should be
      response = event.message.prompt(
          <<~CONTENT.strip,
            **What should the new description be?**
            Press 🚫 to have no description.
          CONTENT
          reaction: '🚫',
          clean:    true
      )
      description = response ? response.content.downcase : nil

      # Update role group and save to database
      group.description = description
      group.save

      # Respond to user
      if description
        event << "**Changed role group description to `#{description.ellipsify(32)}`.**"
      else
        event << "**Removed role group description.**"
      end

    # When user wants to edit group exclusivity:
    when 'e'
      # Toggle group exclusivity and save to database
      group.is_exclusive = !group.is_exclusive
      group.save

      # Respond to user
      if group.is_exclusive
        event << '**Made role group exclusive.**'
      else
        event << '**Disabled role group exclusivity.'
      end
    end
  end

  # Delete role from the database
  command :deletegroup, permission_level: 3,
          description:      'Delete a role group from the database.',
          usage:            '!deletegroup <key>',
          min_args:         1,
          max_args:         1,
          aliases:          [:removegroup] do |event, arg|
    # Break unless argument exists and role with given key exists
    break unless arg && (group = AssignableRoleGroup[key: arg.downcase])

    # Delete group from database
    group.destroy

    # Respond to user
    event << <<~RESPONSE.strip
      **Deleted role group from database.**
      All roles formerly in the group are now ungrouped.
    RESPONSE
  end
end