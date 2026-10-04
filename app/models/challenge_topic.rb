# One category a duel is restricted to. No categories at all means „anything",
# which is what every duel was before this existed.
class ChallengeTopic < ApplicationRecord
  belongs_to :challenge
  belongs_to :topic
end
