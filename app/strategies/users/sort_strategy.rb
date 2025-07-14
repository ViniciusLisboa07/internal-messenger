# frozen_string_literal: true

module Users
  class SortStrategy
    VALID_SORT_FIELDS = %w[name email role created_at].freeze
    VALID_ORDERS = %w[asc desc].freeze
    DEFAULT_SORT_FIELD = 'name'
    DEFAULT_ORDER = 'asc'

    def initialize(query, sort_params)
      @query = query
      @sort_field = normalize_sort_field(sort_params[:sort_by])
      @order = normalize_order(sort_params[:order])
    end

    def execute
      return default_sort unless valid_sort_field?

      apply_sort
    end

    private

    attr_reader :query, :sort_field, :order

    def normalize_sort_field(sort_by)
      return DEFAULT_SORT_FIELD unless sort_by.present?
      return sort_by if VALID_SORT_FIELDS.include?(sort_by.to_s)

      DEFAULT_SORT_FIELD
    end

    def normalize_order(order_param)
      return DEFAULT_ORDER unless order_param.present?
      return order_param.downcase if VALID_ORDERS.include?(order_param.downcase)

      DEFAULT_ORDER
    end

    def valid_sort_field?
      VALID_SORT_FIELDS.include?(sort_field)
    end

    def apply_sort
      sort_method = "order_by_#{sort_field}"
      return query unless query.respond_to?(sort_method)

      query.send(sort_method, order)
    end

    def default_sort
      query.order_by_name(DEFAULT_ORDER)
    end
  end
end 