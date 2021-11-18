Gem::Specification.new do |s|
  s.name = 'rsscache'
  s.version = '0.2.3'
  s.summary = 'This gem helps reduce unnecessary requests to webservers by ' \
      + 'caching RSS feeds where the RSS feeds are updated infrequently'
  s.authors = ['James Robertson']
  s.files = Dir['lib/rsscache.rb']
  s.add_runtime_dependency('dynarex', '~> 1.8', '>=1.8.27')
  s.add_runtime_dependency('simple-rss', '~> 1.3', '>=1.3.3')
  s.signing_key = '../privatekeys/rsscache.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/rsscache'
end
