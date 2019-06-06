Pod::Spec.new do |spec|
  spec.name = 'PathTemplate'
  spec.version = '1.1.0'
  spec.summary = 'Swift library for turning path strings like `/user/:id` into regular expressions'
  spec.homepage = 'https://github.com/gjeck/PathTemplate.swift'
  spec.license = { :type => 'MIT', :file => 'LICENSE' }
  spec.author = { 'Greg Jeckell' => '' }
  spec.social_media_url = 'https://twitter.com/GJeckell'
  spec.source = { :git => 'https://github.com/gjeck/PathTemplate.swift.git', :tag => "#{spec.version}" }
  spec.source_files = 'Sources/**/*.{h,swift}'
  spec.ios.deployment_target = '8.0'
  spec.osx.deployment_target = '10.9'
  spec.watchos.deployment_target = '2.0'
  spec.tvos.deployment_target = '9.0'
  spec.requires_arc = true
  spec.swift_version = '4.0'
end
