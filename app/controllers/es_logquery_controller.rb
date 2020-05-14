class EsLogqueryController < ApplicationController
  before_action :set_client

  # params
  # index 要查询的索引
  # keywords_in     arry []  查询要匹配的字符串
  # keywords_not_in arry []  查询要排除的字符串
  # begin_date 需要查询的开始日期
  # end_date 需要查询的结束日期
  def create
    index = params[:index].blank? ? '_all' : params[:index]

    # 需要匹配的值 可以多个
    keywords_in = params[:keywords_in].blank? ? [] : params[:keywords_in]
    must_hash = keywords_in.map { |v| { match: v } }

    # 不需要匹配的值 可以多个
    keywords_not_in = params[:keywords_not_in].blank? ? [] : params[:keywords_not_in]
    must_not_hash = keywords_not_in.map { |v| { match: v } }

    # 开始时间
    start_time = params[:start_time].present?  ? params[:start_time] : Time.now.beginning_of_day.strftime('%Y-%m-%dT%H:%M:%S')
    # 结束时间
    end_time = params[:end_time].present?  ? params[:end_time] : Time.now.end_of_day.strftime('%Y-%m-%dT%H:%M:%S')

    # 返回的个数
    number = params[:number].present? ? params[:number].to_i : 5

    result = @client.search index: index, body: {
        query: {
            bool: {
                # 多个match的写法
                must: must_hash,
                must_not: must_not_hash,
                filter: {
                    range: {
                        "@timestamp": {
                            "gte": start_time,
                            "lt": end_time
                        }
                    }
                }
            }
        },
        size: number,
        _source: ["kubernetes", "@timestamp"]
    }
    render plain: result.to_json
  end

  private

  def set_client
    @client = Elasticsearch::Client.new url: 'http://192.168.10.50:9200', log: true
  end
end
