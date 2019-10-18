# Model: HugUser


# A user who has given or received hugs. Contains fields for the user's ID (primary key) and the hugs they've given
# and received.
class Bot::Models::HugUser < Sequel::Model
  unrestrict_primary_key
end