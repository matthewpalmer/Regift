Pod::Spec.new do |s|
  s.name             = "Regift"
  s.version          = "1.0.0"
  s.summary          = "Regift helps you easily convert a video to a GIF on iOS."
  s.description      = <<-DESC
                       Regift helps you easily convert a video to a GIF on iOS.
                       Create a gif from a given video URL, tweaking the frame count, delay time, and number of loops.
                       DESC
  s.homepage         = "https://github.com/matthewpalmer/Regift"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "matthewpalmer" => "matt@matthewpalmer.net" }
  s.source           = { :git => "https://github.com/matthewpalmer/Regift.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/_matthewpalmer'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Regift/*.{m,h,swift}'
  s.resource_bundles = {
    'Regift' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
end
