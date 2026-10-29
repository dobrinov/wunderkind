# The admin's people list, by household rather than by row. A family is
# everybody parent_links connects — two parents of one child are one family,
# shown once with the child under both of them — plus every parent who has not
# linked anybody yet, alone, because „signed up and stopped" is exactly the
# family worth finding. A student nobody is linked to is not a family; the
# list has a tab of its own for them.
#
# The grouping is SQL (a recursive walk over parent_links, so a chain of
# step-parents and half-siblings is still one family), which is what lets the
# list paginate *families* and filter them on any member without loading the
# whole table: a family matches a search when any one of its people does.
module Families
  PER_PAGE = 20

  # „Активни тази седмица", „Неподвърден имейл", „С отворен тикет",
  # „Нови (7 дни)" — the chips over the list, combined with AND.
  FILTERS = %w[active unverified tickets new].freeze

  # How recently somebody did anything: a page seen, a sign-in, or signing up
  # at all. GREATEST skips NULLs, so somebody who never came back still sorts
  # by the day they arrived.
  ACTIVITY_SQL = "GREATEST(users.last_seen_at, users.last_login_at, users.created_at)"

  # user_id → family_id, the family named after its smallest user id. Every
  # node reaches itself, then walks the links both ways; UNION (not UNION ALL)
  # is what stops the walk once a family has been seen whole.
  MEMBERS_SQL = <<~SQL.squish.freeze
    WITH RECURSIVE edges(a, b) AS (
      SELECT parent_id, child_id FROM parent_links
      UNION ALL
      SELECT child_id, parent_id FROM parent_links
    ),
    reach(node, root) AS (
      SELECT a, a FROM edges
      UNION
      SELECT e.b, r.root FROM reach r JOIN edges e ON e.a = r.node
    )
    SELECT node AS user_id, MIN(root) AS family_id FROM reach GROUP BY node
    UNION ALL
    SELECT id, id FROM users
    WHERE role = #{User.roles[:parent]} AND NOT EXISTS (SELECT 1 FROM parent_links WHERE parent_links.parent_id = users.id)
  SQL

  Family = Data.define(:id, :parents, :children, :active_at) do
    def solo? = children.empty?
  end

  module_function

  # One page of families, newest activity first, as a Kaminari-paginated
  # array so the view's paginator works unchanged.
  def page(query: nil, filters: [], family: nil, page: 1, per: PER_PAGE)
    conditions = member_conditions(query, filters)
    having = conditions.map { |condition| "bool_or(#{condition})" }
    having << sanitize("bool_or(m.family_id = ?)", family.to_i) if family.present?

    grouped = <<~SQL.squish
      SELECT m.family_id, MAX(#{ACTIVITY_SQL}) AS active_at
      FROM (#{MEMBERS_SQL}) m JOIN users ON users.id = m.user_id
      GROUP BY m.family_id
      #{"HAVING #{having.join(" AND ")}" if having.any?}
    SQL

    total = connection.select_value("SELECT COUNT(*) FROM (#{grouped}) families").to_i
    offset = ([ page.to_i, 1 ].max - 1) * per
    rows = connection.select_rows(
      "#{grouped} ORDER BY active_at DESC NULLS LAST, m.family_id DESC LIMIT #{per.to_i} OFFSET #{offset.to_i}"
    )

    Kaminari.paginate_array(build(rows), total_count: total).page(page).per(per)
  end

  def count(query: nil, filters: []) = page(query:, filters:, per: 1).total_count

  # The family one person belongs to, or nil for a student nobody is linked to
  # (and an admin with no children).
  def of(user)
    id = connection.select_value(sanitize("SELECT family_id FROM (#{MEMBERS_SQL}) m WHERE m.user_id = ?", user.id))
    id && page(family: id, per: 1).first
  end

  # Students no parent is linked to, filtered the same way, newest activity
  # first. A relation, so it paginates like any other.
  def orphans(query: nil, filters: [])
    scope = filter(User.student.where.not(id: ParentLink.select(:child_id)), query:, filters:)
    scope.order(Arel.sql("#{ACTIVITY_SQL} DESC NULLS LAST"), id: :desc)
  end

  # The same filters over single rows, for the flat list.
  def filter(scope, query: nil, filters: [])
    member_conditions(query, filters).each { |condition| scope = scope.where(condition) }
    scope
  end

  # One SQL condition per filter, over the users table.
  def member_conditions(query, filters)
    conditions = []

    if query.present?
      like = "%#{User.sanitize_sql_like(query.strip)}%"
      code = query.strip.upcase
      conditions << sanitize(
        "(users.name ILIKE :like OR users.nickname ILIKE :like OR users.email ILIKE :like OR users.link_code = :code OR users.friend_code = :code)",
        like:, code:
      )
    end

    filters = Array(filters) & FILTERS
    conditions << sanitize("GREATEST(users.last_seen_at, users.last_login_at) >= ?", Leaderboards.week_start) if filters.include?("active")
    # A student's address is never sent a confirmation (UsersController), so
    # only a grown-up's unconfirmed address is one somebody is waiting on.
    conditions << "(users.role <> #{User.roles[:student]} AND users.email IS NOT NULL AND users.verified_at IS NULL)" if filters.include?("unverified")
    if filters.include?("tickets")
      conditions << "EXISTS (SELECT 1 FROM question_reports r WHERE r.user_id = users.id AND r.status IN (#{QuestionReport.statuses.values_at(*QuestionReport::ACTIVE).join(", ")}))"
    end
    conditions << sanitize("users.created_at >= ?", 7.days.ago) if filters.include?("new")
    conditions
  end

  # Turns [family_id, active_at] rows into families, with every member loaded
  # in three queries for the whole page.
  def build(rows)
    return [] if rows.empty?

    family_ids = rows.map(&:first)
    members = connection.select_rows(
      "SELECT user_id, family_id FROM (#{MEMBERS_SQL}) m WHERE m.family_id IN (#{family_ids.map(&:to_i).join(", ")})"
    ).group_by(&:last).transform_values { |pairs| pairs.map(&:first) }
    users = User.where(id: members.values.flatten).includes(:managed_by).index_by(&:id)
    parent_ids = ParentLink.where(parent_id: users.keys).distinct.pluck(:parent_id).to_set

    rows.map do |family_id, active_at|
      people = members.fetch(family_id, []).filter_map { users[it] }
      # A parent is anybody who links to somebody, or a lone grown-up with
      # nobody yet; everybody else in the family is somebody's child.
      parents, children = people.partition { |person| parent_ids.include?(person.id) || !person.student? }
      Family.new(id: family_id, parents: parents.sort_by(&:created_at), children: children.sort_by(&:name), active_at:)
    end
  end

  def sanitize(*args) = ActiveRecord::Base.sanitize_sql_array(args)

  def connection = ActiveRecord::Base.connection
end
