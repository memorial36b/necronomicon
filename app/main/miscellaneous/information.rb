# Crystal: Information


# Contains a command that gives information on the bot and myself.
module Bot::Miscellaneous::Information
  extend Discordrb::Commands::CommandContainer

  command :info do |event|
    event.send_embed do |embed|
      embed.author = {
          name:     'Necronomicon: Info',
          icon_url: Constants::BOT_AVATAR_URL
      }
      embed.add_field(
          name:   'About Necronomicon',
          value:  <<~CONTENT.strip,
            *"No illusions shall deceive you any longer."*

            Necronomicon is a Discord bot designed for this server, used for various miscellaneous functions.
            It is coded in the Ruby language, using the discordrb API and the Geode bot framework.
            It is run on a private Scaleway VPS.
            GitHub link can be found [here](https://github.com/hecksalmonids/necronomicon)
            If you would like to help support Necronomicon or myself, please **donate to my Ko-fi below!**
          CONTENT
          inline: true
      )
      embed.add_field(
          name:   'FAQ',
          value:  <<~CONTENT.strip,
            To be added
          CONTENT
          inline: true
      )
      embed.add_field(
          name:   'About Me',
          value:  <<~CONTENT.strip,
            Hello! My name's Katie (she/they). I'm 19 and very queer.
            I've been making Discord bots for three years, and have grown as a person and a programmer since I began.
            I'm a fan of Splatoon, Kingdom Hearts, and Persona 5 and will happily go on about those for hours.
            My hobbies include programming, showering, supporting queer folks and throwing hands at homo/transphobes.
          CONTENT
          inline: true
      )
      embed.add_field(
          name:   'Links',
          value:  <<~CONTENT.strip,
            **Discord:** <@220509153985167360>
            **Twitter:** [@HECKSALMONIDS](https://twitter.com/hecksalmonids)
            **GitHub:** [hecksalmonids](https://github.com/hecksalmonids)
            **Ko-fi:** [heck_salmonids](https://ko-fi.com/heck_salmonids)
          CONTENT
      )
      embed.color = 0xFFD700
      embed.footer = {text: 'Futaba says trans rights 💙'}
    end
  end
end