# Introducing RSScache

The following example shows how to enter RSS feeds into a Dynarex file, and cache the RSS feeds to a directory called */tmp/cache2*.


First of all we create a new Dynarex file to save the information about the RSS feeds, as shown below:

    s =<<EOF
    <?dynarex schema="rsscache[title]/feed(title, url, refresh_rate, next_refresh, filename)"?>
    title: RSS Feeds to be cached

    --+

    url: http://feeds.bbci.co.uk/news/rss.xml?edition=uk
    uid: 1

    url: http://rss.slashdot.org/Slashdot/slashdot
    uid: 2

    EOF
    File.write '/tmp/feeds.txt', s


Then we check for new RSS feeds.

    require 'rsscache'

    cache = RSScache.new '/tmp/feeds.txt', '/tmp/cache2'
    cache.update

Notice in the output from the RSS feeds file that it has saved some additional information:

<pre>
&lt;?dynarex schema="rsscache[title]/feed(title, url, refresh_rate, next_refresh, filename)"?&gt;
title: RSS Feeds to be cached

--+

title: BBC News - Home
url: http://feeds.bbci.co.uk/news/rss.xml?edition=uk
refresh_rate: 10
next_refresh: 2015-11-06 14:42:27 +0000

title: Slashdot
url: http://rss.slashdot.org/Slashdot/slashdot
refresh_rate: 10
</pre>

Observe it has saved the cached RSS files in the */tmp/cache2* directory.

Notes: 

1. If the RSScache#update method is called again, there will be no change to either the feeds.txt file or the cached RSS files while the time is less than the *next_refresh* time.
2. If the time is greater than the *next refresh* time and there is no change to the feed, then the *refresh_rate* will be incremented by 10 minutes.
3. If the time is greater than the *next refresh* time and there is a change to the feed, then the *refresh_rate* will be reduced by 10 minutes if the it's already greater than 10 minutes.


# Resources

* rsscache https://rubygems.org/gems/rsscache

rsscache

