class TopicPrerequisite < ApplicationRecord
  belongs_to :topic
  belongs_to :prerequisite, class_name: "Topic"

  validates :prerequisite_id, uniqueness: { scope: :topic_id }
  validate :not_self_referential
  validate :no_cycle

  # Every topic that cannot become a prerequisite of `topic` because it already
  # requires it, directly or through others — keyed by id, each with the chain
  # of names that leads from it back to `topic` (the reason the editor shows
  # beside a disabled candidate). The whole graph is a few dozen edges, so it
  # is walked in memory from one query.
  def self.blocked_for(topic, edges = pluck(:topic_id, :prerequisite_id))
    return {} unless topic&.id

    dependents = edges.group_by(&:last).transform_values { |pairs| pairs.map(&:first) }
    names = Topic.pluck(:id, :name).to_h
    chains = { topic.id => [] }
    queue = [ topic.id ]

    while (current = queue.shift)
      dependents.fetch(current, []).each do |dependent|
        next if chains.key?(dependent)

        chains[dependent] = [ names[current], *chains[current] ]
        queue << dependent
      end
    end

    chains.except(topic.id)
  end

  private

  def not_self_referential
    errors.add(:prerequisite, :invalid) if topic_id == prerequisite_id
  end

  def no_cycle
    return if topic.nil? || prerequisite_id.nil?

    errors.add(:prerequisite, :cycle) if self.class.blocked_for(topic).key?(prerequisite_id)
  end
end
