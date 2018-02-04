#!/usr/bin/env ruby
# 
# file: rsscache.rb

require 'dynarex'
require 'open-uri'
require 'simple-rss'
require 'fileutils'
require 'timeout'


class RSScache
  
  attr_reader :err_report

  def initialize(rsslist, feedsfilepath='.', debug: true)

    @dx = open_dynarex(rsslist)
    @rsslist, @feedsfilepath = rsslist, feedsfilepath
    FileUtils.mkdir_p feedsfilepath
    
    @err_report = []
    @debug = debug

  end
  
  # Import a list of URLs into the Dynarex document. 
  # URLs which already exist are ignored.
  #
  def import(raw_s)
    
    s, _ = RXFHelper.read(raw_s)
    
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
    
    save_dynarex()
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
    save_dynarex()

  end

  alias update refresh

  def open_dynarex(x)

    if x.lines.length == 1 and File.exists?(x) and \
                                      File.extname(x) == '.txt' then
      Dynarex.new.import x
    else
      Dynarex.new x
    end
  end

  def save_dynarex()

    if @rsslist.lines.length == 1 and File.exists?(@rsslist)

      if File.extname(@rsslist) == '.txt'then

        File.write @rsslist, @dx.to_s

      else

        @dx.save

      end

    end
  end

  # checks for any updates and saves the latest RSS file to 
  #                                       the cache if there is
  #
  def updates?(feed)

    if @debug then
      puts 'inside updates?' 
      puts 'feed: ' + feed.inspect
    end
    
    # fetch the feeds from the web
    buffer, code = fetch(feed.url)

    if code == 200 then
      rss = SimpleRSS.parse(buffer)
    else
      @err_report << [feed.url, code]
      return false
    end

    if feed.filename.empty? then
      
      filename = feed.url[6..-1].gsub(/\W+/,'').\
                          reverse.slice(0,40).reverse.downcase + '.xml'
      feed.filename = filename

    end
    
    rssfile = File.join(@feedsfilepath, feed.filename)

    if File.exists? rssfile then

      rss_cache = SimpleRSS.parse File.read(rssfile)
      new_rss_items = rss.items - rss_cache.items
      (File.write rssfile, rss.source; return true) if new_rss_items.any?
      
    else

      File.write rssfile, rss.source
      feed.title = rss.title if feed.title.empty?

      return true
      
    end
    
    return false
  end
  
  private
  
  def fetch(url, timeout: 2)

    begin
      Timeout::timeout(timeout){

        buffer = open(url).read
        return [buffer, 200]
      }
    rescue Timeout::Error => e
      ['connection timed out', 408]
    rescue OpenURI::HTTPError => e
      ['400 bad request', 400]
    end    
    
  end
  
end
