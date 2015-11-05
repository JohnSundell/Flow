Pod::Spec.new do |s|
  s.name         = "Flow"
  s.version      = "0.0.1"
  s.summary      = "Operation Oriented Programming in Swift"
  s.description  = <<-DESC
    Easily structure your code base into operations and chain them into logical sequences.
  DESC
  s.homepage     = "https://github.com/JohnSundell/Flow"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "John Sundell" => "john@sundell.co" }
  s.social_media_url   = "https://twitter.com/johnsundell"
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "2.0"
  s.source       = { :git => "https://github.com/JohnSundell/Flow.git", :tag => "0.0.1" }
  s.source_files  = "Flow.swift"
  s.framework  = "Foundation"
end
