# Model: HeadpatUser


# A user who has given or received headpats. Contains fields for the user's ID (primary key) and the headpats they've
# given and received.
class Bot::Models::HeadpatUser < Sequel::Model
  unrestrict_primary_key
end