# frozen_string_literal: true

class UserQuery
  def initialize(relation = User.all)
    @relation = relation
  end

  def search_by_name(name)
    return self unless name.present?

    UserQuery.new(relation.where(build_ilike_condition('name', name)))
  end

  def search_by_email(email)
    return self unless email.present?

    UserQuery.new(relation.where(build_ilike_condition('email', email)))
  end

  def search_by_role(role)
    return self unless role.present?

    UserQuery.new(relation.where(role: role).where.not(active: false))
  end

  def search_by_active(active)
    UserQuery.new(relation.where(active: normalize_boolean(active)))
  end

  def search_global(query)
    return self unless query.present?

    name_condition = build_ilike_condition('name', query)
    email_condition = build_ilike_condition('email', query)
    
    UserQuery.new(relation.where(name_condition.or(email_condition)))
  end

  def order_by_name(direction = 'asc')
    normalized_direction = normalize_direction(direction)
    UserQuery.new(relation.order("name #{normalized_direction}"))
  end

  def order_by_email(direction = 'asc')
    normalized_direction = normalize_direction(direction)
    UserQuery.new(relation.order("email #{normalized_direction}"))
  end

  def order_by_role(direction = 'asc')
    normalized_direction = normalize_direction(direction)
    UserQuery.new(relation.order("role #{normalized_direction}"))
  end

  def order_by_created_at(direction = 'desc')
    normalized_direction = normalize_direction(direction)
    UserQuery.new(relation.order("created_at #{normalized_direction}"))
  end

  def active_users
    UserQuery.new(relation.where(active: true))
  end

  def admin_users
    UserQuery.new(relation.where(role: 'admin'))
  end

  def employee_users
    UserQuery.new(relation.where(role: 'employee'))
  end

  def recent_users
    UserQuery.new(relation.order(created_at: :desc))
  end

  def to_relation
    relation
  end

  def method_missing(method_name, *args, &block)
    return super unless relation.respond_to?(method_name)

    relation.send(method_name, *args, &block)
  end

  def respond_to_missing?(method_name, include_private = false)
    relation.respond_to?(method_name, include_private) || super
  end

  private

  attr_reader :relation

  def build_ilike_condition(field, value)
    User.arel_table[field].matches("%#{sanitize_query(value)}%")
  end

  def sanitize_query(value)
    value.to_s.strip
  end

  def normalize_boolean(value)
    return true if value.to_s.downcase == 'true'
    return false if value.to_s.downcase == 'false'

    value
  end

  def normalize_direction(direction)
    direction.downcase == 'desc' ? 'DESC' : 'ASC'
  end
end 