require 'sequel'
Sequel.extension :inflector
require_relative 'constants'

# Contains miscellaneous scripts that don't particularly require their own file.


# Sets the command permission levels for roles and users
module Permissions
  include Constants

  Bot::BOT.set_role_permission(WILDCARD_ID, 3)
  Bot::BOT.set_user_permission(MY_ID, 3)
end

# Contains a method that returns a pluralized string if the integer given is not 1,
# and a singularized string otherwise
module Pluralizer
  module_function

  # Returns pluralized form if the given int is not 1; return singularized form otherwise
  # @param  [Integer] int the integer to test
  # @param  [String]  str the word to pluralize
  # @return [String]      singular form (i.e. 1 squid) if int is 1, plural form (8 squids) otherwise
  def plural(int, str)
    return "#{int} #{str.pluralize}" unless int == 1
    "#{int} #{str.singularize}"
  end
  alias_method(:pl, :plural)
end

class String
  # Shortens string to one of the given length or lower, adding an ellipse to the end unless the string is already
  # lower than the given length
  # @param  [Integer] length the length of the string to output
  # @return [String]         the string, with an ellipse added as necessary
  def ellipsify(length)
    if self.length > length
      self[0...(length - 3)].strip + '...'
    else
      self.strip
    end
  end
end