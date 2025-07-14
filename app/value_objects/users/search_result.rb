# frozen_string_literal: true

module Users
  class SearchResult
    def initialize(query:, total_count:, page:, per_page:)
      @query = query
      @total_count = total_count
      @page = normalize_page(page)
      @per_page = normalize_per_page(per_page)
    end

    def paginated_users
      query.offset(offset).limit(per_page)
    end

    def total_pages
      (total_count.to_f / per_page).ceil
    end

    def has_next_page?
      page < total_pages
    end

    def has_previous_page?
      page > 1
    end

    def metadata
      {
        total_count: total_count,
        page: page,
        per_page: per_page,
        total_pages: total_pages,
        has_next_page: has_next_page?,
        has_previous_page: has_previous_page?
      }
    end

    def to_h
      {
        users: paginated_users.map(&:as_json_response),
        meta: metadata
      }
    end

    private

    attr_reader :query, :total_count, :page, :per_page

    def offset
      (page - 1) * per_page
    end

    def normalize_page(page_param)
      page_param.to_i.positive? ? page_param.to_i : 1
    end

    def normalize_per_page(per_page_param)
      per_page_value = per_page_param.to_i
      return per_page_value if per_page_value.between?(1, 100)
      
      10
    end
  end
end 