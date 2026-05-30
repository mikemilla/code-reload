Pod::Spec.new do |s|
  s.name             = 'bunbu'
  s.version          = '0.1.0'
  s.summary          = 'On-device AI coding assistant for Flutter.'
  s.description      = <<-DESC
Bunbu provides an on-device AI coding assistant with a native sheet presentation.
                       DESC
  s.homepage         = 'https://github.com/build-context/bunbu'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Build Context' => 'hello@buildcontext.dev' }
  s.source           = { :http => 'https://github.com/build-context/bunbu' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '16.0'
  s.swift_version    = '5.0'
end
