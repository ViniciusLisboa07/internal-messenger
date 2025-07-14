# frozen_string_literal: true

module Users
  class SearchService
    def initialize(params = {})
      @params = sanitize_params(params)
    end

    def call
      query = build_base_query
      query = apply_filters(query)
      query = apply_sorting(query)
      
      Users::SearchResult.new(
        query: query.to_relation,
        total_count: query.to_relation.count,
        page: current_page,
        per_page: items_per_page
      )
    end

    private

    attr_reader :params

    def build_base_query
      UserQuery.new
    end

    def apply_filters(query)
      Users::FilterStrategy.new(query, filter_params).execute
    end

    def apply_sorting(query)
      Users::SortStrategy.new(query, sort_params).execute
    end

    def filter_params
      params.slice(:q, :name, :email, :role, :active)
    end

    def sort_params
      params.slice(:sort_by, :order)
    end

    def current_page
      params[:page] || 1
    end

    def items_per_page
      params[:per_page] || 10
    end

    def sanitize_params(raw_params)
      raw_params.to_h.with_indifferent_access
    end
  end
end 