require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name             = "code-reload"
  s.version          = package["version"]
  s.summary          = package["description"]
  s.homepage         = "https://github.com/mikemilla/code-reload"
  s.license          = { :type => "MIT" }
  s.author           = { "Build Context" => "hello@buildcontext.dev" }
  s.source           = { :git => "https://github.com/mikemilla/code-reload.git", :tag => s.version }

  s.source_files     = "ios/**/*.{swift,h,m}"
  s.platform         = :ios, "16.0"
  s.swift_version    = "5.0"

  install_modules_dependencies(s)
end
