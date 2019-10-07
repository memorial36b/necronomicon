require 'discordrb'

# Adds a method to the Message class from discordrb that adds reaction controls to a message


class Discordrb::Message
  # Reaction control buttons, in order
  REACTION_CONTROL_BUTTONS = ['⏮', '◀', '⏹', '▶', '⏭'].freeze

  # Reacts to the message with reaction controls. Keeps track of an index that is yielded as a parameter to the given
  # block, which is executed each time the given user presses a reaction control button. The index cannot be outside
  # the given range. Accepts an optional timeout, calculated from the last time the user pressed a reaction button.
  # Additionally accepts an optional starting index (if not provided, defaults to the start of the given range).
  # This is a blocking function -- if user presses the stop button or if the timeout expires, all reactions are
  # deleted and the thread unblocks.
  # @param [User]           user           the user who these reaction controls pertain to
  # @param [Range]          index_range    the range that the given index is allowed to be
  # @param [Integer, Float] timeout        the length, in seconds, of the timeout
  #                                         (after these many seconds the controls are deleted)
  # @param [Integer]        starting_index the initial index
  #
  # For block { |index| ... }
  # @yield                      The given block is executed every time a reaction button (other than stop) is pressed.
  # @yieldparam [Integer] index the current index
  def reaction_controls(user, index_range, timeout = nil, starting_index = index_range.first, &block)
    raise NoPermissionError, "This message wasn't sent by the current bot!" unless self.from_bot?
    raise ArgumentError, 'The starting index must be within the given range!' unless index_range.include?(starting_index)

    # Reacts to self with each reaction button
    REACTION_CONTROL_BUTTONS.each { |s| self.react_unsafe(s) }

    # Defines index variable
    index = starting_index

    # Loops until stop button is pressed or timeout has passed
    loop do
      # Defines time when the controls should expire (timeout is measured from the time of the last press)
      expiry_time = timeout ? Time.now + timeout : nil

      # Awaits reaction from user and returns response (:first, :back, :forward, :last, or nil if stopped/timed out)
      response = loop do
        await_timeout = expiry_time - Time.now
        await_event = @bot.add_await!(Discordrb::Events::ReactionAddEvent,
                                      emoji: REACTION_CONTROL_BUTTONS,
                                      channel: self.channel,
                                      timeout: await_timeout)

        break nil unless await_event
        next unless await_event.message == self &&
            await_event.user == user
        break nil if await_event.emoji.name == '⏹'
        break await_event.emoji.name
      end

      # Cases response variable and changes the index accordingly (validating that it is within the
      # given index range), yielding to the given block with the index if it is changed;
      # removes all reactions and breaks loop if response is nil
      case response
      when '⏮'
        unless index_range.first == index
          index = index_range.first
          yield index
        end
        self.delete_reaction_unsafe(user, '⏮')
      when '◀'
        if index_range.include?(index - 1)
          index -= 1
          yield index
        end
        self.delete_reaction_unsafe(user, '◀')
      when '▶'
        if index_range.include?(index + 1)
          index += 1
          yield index
        end
        self.delete_reaction_unsafe(user, '▶')
      when '⏭'
        unless index_range.last == index
          index = index_range.last
          yield index
        end
        self.delete_reaction_unsafe(user, '⏭')
      when nil
        self.delete # this can be either #delete or #delete_all_reactions_unsafe
        break
      end
    end
  end

  # Alternative to the default `Message#create_reaction` method that allows for a custom rate limit to be set; unsafe,
  # as it can be set lower to the Discord minimum of 1/0.25
  # @param [String, #to_reaction] reaction   the `Emoji` object or unicode emoji to react with
  # @param [Integer, Float]       rate_limit the length of time to set as the rate limit
  def create_reaction_unsafe(reaction, rate_limit = 0.25)
    reaction = reaction.to_reaction if reaction.respond_to?(:to_reaction)
    encoded_reaction = URI.encode(reaction) unless reaction.ascii_only?
    RestClient.put(
        "#{Discordrb::API.api_base}/channels/#{self.channel.id}/messages/#{self.id}/reactions/#{encoded_reaction}/@me",
        nil, # empty payload
        Authorization: @bot.token
    )
    sleep rate_limit
  end
  alias_method :react_unsafe, :create_reaction_unsafe

  # Alternative to the default `Message#delete_reaction` method that allows for a custom rate limit to be set; unsafe,
  # as it can be set lower to the Discord minimum of 1/0.25
  # @param [User]                 user       the user whose reaction to remove
  # @param [String, #to_reaction] reaction   the `Emoji` object or unicode emoji to remove the reaction of
  # @param [Integer, Float]       rate_limit the length of time to set as the rate limit
  def delete_reaction_unsafe(user, reaction, rate_limit = 0.25)
    reaction = reaction.to_reaction if reaction.respond_to?(:to_reaction)
    encoded_reaction = URI.encode(reaction) unless reaction.ascii_only?
    RestClient.delete(
        "#{Discordrb::API.api_base}/channels/#{self.channel.id}/messages/#{self.id}/reactions/#{encoded_reaction}/#{user.id}",
        Authorization: @bot.token
    )
    sleep rate_limit
  end

  # Alternative to the default `Message#delete_all_reactions` method that allows for a custom rate limit to be set; unsafe,
  # as it can be set lower to the Discord minimum of 1/0.25
  # @param [Integer, Float] rate_limit the length of time to set as the rate limit
  def delete_all_reactions_unsafe(rate_limit = 0.25)
    RestClient.delete(
        "#{Discordrb::API.api_base}/channels/#{self.channel.id}/messages/#{self.id}/reactions",
        Authorization: @bot.token
    )
    sleep rate_limit
  end
end
