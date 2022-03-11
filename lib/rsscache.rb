#!/usr/bin/env ruby

# file: rsscache.rb

require 'dynarex'
require 'open-uri'
require 'simple-rss'
require 'timeout'
require 'rxfreadwrite'


class RSScache
  include RXFReadWriteModule

  attr_reader :err_report, :dx

  def initialize(rsslist=nil, filepath: '.', debug: false)

    rsslist ||= File.join(filepath, 'rsscache.xml')
    @dx = open_dynarex(rsslist)
    @filepath = filepath
    @cache_filepath = File.join(filepath, 'rsscache')
    FileX.mkdir_p @cache_filepath

    @err_report = []
    @debug = debug

  end

  # Import a list of URLs into the Dynarex document.
  # URLs which already exist are ignored.
  #
  def import(raw_s)

    s, _ = RXFReader.read(raw_s)

    s.strip.lines.each do |raw_url|

      url = raw_url.chomp
      puts 'url : '  + url.inspect if @debug
      r = @dx.find_by_url url.chomp

      if r then
        puts 'exists' if @debug
      else
        puts 'new URL found' if @debug
        @dx.create url: url
      end

    end

    save()
  end

  # refresh each RSS feed
  #
  def refresh

    @err_report = []

    puts '@dx.to_xml'  + @dx.to_xml(pretty: true)  if @debug

    @dx.all.each do |feed|

      puts 'feed:' + feed.inspect if @debug

      if feed.next_refresh.empty? or \
                             Time.now >= Time.parse(feed.next_refresh) then

        any_new_items = updates? feed

        feed.refresh_rate = if feed.refresh_rate.empty? then

          10

        else

          if Time.now > Time.parse(feed.next_refresh) + \
                          feed.refresh_rate.to_i and not any_new_items then
            feed.refresh_rate.to_i + 10
          end

        end


        feed.next_refresh = Time.now + feed.refresh_rate.to_i * 60


      else

        feed.refresh_rate = feed.refresh_rate.to_i - 10 if feed.refresh_rate.to_i > 10

      end
    end

    puts '@dx: ' + @dx.to_xml(pretty: true) if @debug
    save()

  end

  alias update refresh

  def save()

    @dx.save File.join(@filepath, 'rsscache.xml')
    FileX.write File.join(@filepath, 'rsscache.txt'), @dx.to_s

  end


  private

  def raw_doc(s)

    heading = '<?dynarex schema="rsscache[title]/feed(uid, title, ' +
      'url, refresh_rate, next_refresh, filename)"?>'

raw_dx=<<EOF
#{heading}
title: RSS Feeds to be cached

--+

#{s.strip.lines.map {|x| 'url: ' + x }.join }
EOF

  end

  def fetch(url, timeout: 2)

    puts 'inside fetch: url: '  + url.inspect if @debug

    begin
      Timeout::timeout(timeout){

        buffer = URI.open(url).read.force_encoding("utf-8")
        return [buffer, 200]
      }
    rescue Timeout::Error => e
      ['connection timed out', 408]
    rescue OpenURI::HTTPError => e
      ['400 bad request', 400]
    end

  end

  def open_dynarex(raw_s)

    s, _ = RXFReader.read(raw_s)
    puts 'inside open_dynarex s: ' + s.inspect if @debug

    case s
    when /^<?dynarex/
      Dynarex.new.import s
    when /^</
      Dynarex.new s
    else
      Dynarex.new.import raw_doc(s)
    end

  end

  # checks for any updates and save the
  # latest RSS file to the cache if there are updates
  #
  def updates?(feed)

    if @debug then
      puts 'inside updates?'
      puts 'feed: ' + feed.inspect
    end

    # fetch the feeds from the web
    begin
      buffer, code = fetch(feed.url)
    rescue
      puts 'RSScache::updates?: fetch() warning for feed ' + feed.url \
          + ' ' + ($!).inspect
      return
    end

    if code == 200 then
      begin
        rss = SimpleRSS.parse(buffer)
      rescue
        puts 'RSScache::updates?: err: 100 SimpleRSS warning for feed ' \
            + feed.url + ' ' + ($!).inspect
        return
      end
    else
      @err_report << [feed.url, code]
      return false
    end

    if feed.filename.empty? then

      filename = feed.url[6..-1].gsub(/\W+/,'').\
                          reverse.slice(0,40).reverse.downcase + '.xml'
      feed.filename = filename

    end

    rssfile = File.join(@cache_filepath, feed.filename)

    if FileX.exists? rssfile then

      begin
        rss_cache = SimpleRSS.parse FileX.read(rssfile)
      rescue
        puts 'RSScache::updates?: err: 200 SimpleRSS warning for feed ' \
            + feed.url + ' ' + ($!).inspect
        FileX.rm rssfile
        return false
      end
      new_rss_items = rss.items - rss_cache.items
      (FileX.write rssfile, rss.source; return true) if new_rss_items.any?

    else

      FileX.write rssfile, rss.source
      feed.title = rss.title if feed.title.empty?

      return true

    end

    return false
  end


end
