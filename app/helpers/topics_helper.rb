# The admin's topic pages (Overseer::TopicsController).
module TopicsHelper
  # A link that opens a topic in the tree's side panel. Only the panel's frame
  # is replaced, and the address follows, so a reload or a shared link opens
  # the same topic; without JavaScript it is an ordinary link to the page with
  # the panel filled in.
  def topic_panel_link(topic, view: params[:view], **options, &)
    data = { turbo_frame: Overseer::TopicsController::PANEL_FRAME, turbo_action: "advance",
             action: "topic-tree#select", topic_id: topic.id }
    link_to(overseer_topics_path(view: view.presence, selected: topic.id),
            **options.except(:data), data: data.merge(options.fetch(:data, {})), &)
  end

  # Where a topic's problems sit on the bank's scale, as the left edge and the
  # width of its bar.
  def topic_range_style(row, bank_range)
    return "display:none" if row.min_elo.nil?

    low, high = bank_range
    span = (high - low).to_f
    left = ((row.min_elo - low) / span * 100).clamp(0, 100)
    width = [ ((row.max_elo - row.min_elo) / span * 100), 1.5 ].max.clamp(0, 100 - left)
    "left:#{left.round(1)}%;width:#{width.round(1)}%"
  end

  def topic_percent(share)
    share.nil? ? "—" : number_to_percentage(share * 100, precision: 0)
  end

  def topic_skip_class(share)
    class_names("topic-skip", "is-high": share && share >= TopicStats::HIGH_SKIP_SHARE)
  end

  def topic_elo(value) = number_with_delimiter(value, delimiter: " ")
end
