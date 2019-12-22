require 'discordrb'
require 'rufus-scheduler'
ENV['TZ'] = 'GMT'

# Contains utility constants that are useful to many crystals across the bot.
module Constants
  Bot::BOT.ready do
    # TiP5 server constant
    SERVER = Bot::BOT.server(590639364141350969)
    # Bot avatar URL
    BOT_AVATAR_URL = Bot::BOT.profile.avatar_url
  end
  # My user ID
  MY_ID = 220509153985167360
  # Wild Card (admin) ID
  WILDCARD_ID = 611758269614129179
  # Velvet Attendant (mod) ID
  ATTENDANT_ID = 635596317904732160
  # Muted role ID
  MUTED_ID = 640802114444197888
  # Scheduler constant
  SCHEDULER = Rufus::Scheduler.new
end