# Crystal: Fun::Headpats


# Allows users to pat each other on the head.
module Bot::Fun::Headpats
  extend Discordrb::Commands::CommandContainer
  include Bot::Models

  extend Pluralizer
  include Constants

  command :headpat,
          description: 'Pats a user on the head.',
          usage: '!headpat <user>',
          aliases: [:pat] do |event, *args|
    # Break unless given user is valid and is not event user
    break unless (user = SERVER.get_user(args.join(' '))) &&
                 user.id != event.user.id

    patting_user = HeadpatUser[event.user.id] || HeadpatUser.create(id: event.user.id)
    patted_user = HeadpatUser[user.id] || HeadpatUser.create(id: user.id)

    # Add one to the given and received hugs of the hugging and hugged users respectively
    patting_user.given += 1
    patted_user.received += 1

    # Save to database
    patting_user.save
    patted_user.save

    # Respond to user
    event.respond(
        ":hand_splayed: | **#{event.user.name}** *pats* #{user.mention} *on the head.*",
        false, # tts
        {
            author: {
                name:     "#{pl(patting_user.given, 'headpats')} given - #{pl(patting_user.received, 'headpats')} received",
                icon_url: event.user.avatar_url
            },
            color: 0xFFD700
        }
    )
  end
end