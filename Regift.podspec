Pod::Spec.new do |s|
  s.name             = "Regift"
  s.version          = "1.5.0"
  s.summary          = "Regift helps you easily convert a video to a GIF on iOS."
  s.description      = <<-DESC
                       Regift helps you easily convert a video to a GIF on iOS.
                       Create a gif from a given video URL, tweaking the frame count, delay time, and number of loops.
                       DESC
  s.homepage         = "https://github.com/matthewpalmer/Regift"
  s.license          = 'MIT'
  s.author           = { "matthewpalmer" => "matt@matthewpalmer.net" }
  s.source           = { :git => "https://github.com/matthewpalmer/Regift.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/_matthewpalmer'

  s.ios.deployment_target = '11.1'
  s.osx.deployment_target = '10.12'

  s.requires_arc = true

  s.source_files = 'Regift/*.{m,h,swift}'
end
