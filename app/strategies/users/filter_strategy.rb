# frozen_string_literal: true

module Users
  class FilterStrategy
    def initialize(query, filter_params)
      @query = query
      @filter_params = filter_params
    end

    def execute
      filtered_query = query
      
      filter_params.each do |filter_type, value|
        filtered_query = apply_filter(filtered_query, filter_type, value)
      end

      filtered_query
    end

    private

    attr_reader :query, :filter_params

    def apply_filter(current_query, filter_type, value)
      return current_query unless filter_value_present?(value)

      filter_method = "apply_#{filter_type}_filter"
      return current_query unless respond_to?(filter_method, true)

      send(filter_method, current_query, value)
    end

    def filter_value_present?(value)
      value.present?
    end

    def apply_q_filter(query, value)
      query.search(value)
    end

    def apply_name_filter(query, value)
      query.search_by_name(value)
    end

    def apply_email_filter(query, value)
      query.search_by_email(value)
    end

    def apply_role_filter(query, value)
      query.search_by_role(value)
    end

    def apply_active_filter(query, value)
      query.search_by_active(value)
    end
  end
end 