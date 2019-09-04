require 'kimurai'

class Spider < Kimurai::Base
  @name = "github_spider"
  @engine = :selenium_chrome
  @start_urls = [
    "https://www.pcc.edu/schedule/default.cfm?fa=dspTopic&thisTerm=201904"
  ]
  @config = {
    user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.84 Safari/537.36",
    before_request: { delay: 4..7 }
  }

  # https://github.com/vifreefly/kimuraframework/issues/26
  def absolute_url(url, base:, skip_url_escape: false)
    super(url, base: base) unless skip_url_escape

    return unless url

    URI.join(base, url).to_s
  end

  def parse(response, url:, data: {})
    response.css(".indexlist a").each do |a|
      topic_url = absolute_url(a[:href], base: url)
      request_to :parse_topic_page, url: topic_url
    end
  end

  def parse_topic_page(response, url:, data: {})
    response.css(".course-list a").each do |a|
      course_url = absolute_url(a[:href], base: url)
      request_to :parse_course_page, url: course_url
    end
  end

  def parse_course_page(response, url:, data: {})
    course = {}

    course[:url] = url
    course[:topic] = response.css("#page-title h2").text.squish
    course[:description] = response.css("#content p").text.squish

    headers = response.css("#content .jxScheduleSortable thead th")
    course_classes = response.css("#content .jxScheduleSortable tbody tr").map do |r|
      course_class = {}

      r.css("th,td").each_with_index do |c, i|
        h = headers[i]
        course_class[h.text.squish] = c.text.squish
      end

      course_class
    end

    course[:classes] = course_classes

    save_to "results/results.json", course, format: :pretty_json
  end
end
