Pod::Spec.new do |s|
  s.name         = "FlowOperations"
  s.version      = "2.0"
  s.summary      = "Operation Oriented Programming in Swift"
  s.description  = <<-DESC
     A lightweight Swift library for doing operation oriented programming. Easily define your own, atomic operations, and/or use an exensive library of ready-to-use operations that can be grouped, sequenced, queued and repeated.
  DESC
  s.homepage     = "https://github.com/JohnSundell/Flow"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "John Sundell" => "john@sundell.co" }
  s.social_media_url   = "https://twitter.com/johnsundell"
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "2.0"
  s.source       = { :git => "https://github.com/JohnSundell/Flow.git", :tag => "2.0" }
  s.source_files  = "Sources/Flow.swift"
  s.framework  = "Foundation"
end
