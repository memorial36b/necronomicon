# Crystal: Hugs


# Lets users give hugs.
module Bot::Fun::Hugs
  extend Discordrb::Commands::CommandContainer
  include Bot::Models

  extend Pluralizer
  include Constants

  command :hug,
          description: 'Gives a hug to a user.',
          usage: '!hug <user>' do |event, *args|
    # Break unless given user is valid and is not event user
    break unless (user = SERVER.get_user(args.join(' '))) &&
                 user.id != event.user.id

    hugging_user = HugUser[event.user.id] || HugUser.create(id: event.user.id)
    hugged_user = HugUser[user.id] || HugUser.create(id: user.id)

    # Add one to the given and received hugs of the hugging and hugged users respectively
    hugging_user.given += 1
    hugged_user.received += 1

    # Save to database
    hugging_user.save
    hugged_user.save

    # Respond to user
    event.respond(
        ":hugging: | **#{event.user.name}** *gives* #{user.mention} *a warm hug.*",
        false, # tts
        {
            author: {
                name:     "#{pl(hugging_user.given, 'hugs')} given - #{pl(hugging_user.received, 'hugs')} received",
                icon_url: event.user.avatar_url
            },
            color: 0xFFD700
        }
    )
  end
end