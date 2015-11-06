Gem::Specification.new do |s|
  s.name = 'rsscache'
  s.version = '0.2.0'
  s.summary = 'This gem helps reduce unnessecary requests to webservers by caching RSS feeds where the RSS feeds are updated infrequently'
  s.authors = ['James Robertson']
  s.files = Dir['lib/rsscache.rb']
  s.add_runtime_dependency('dynarex', '~> 1.2', '>=1.2.90')
  s.add_runtime_dependency('simple-rss', '~> 1.3', '>=1.3.1')
  s.signing_key = '../privatekeys/rsscache.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/rsscache'
end
