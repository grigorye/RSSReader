Pod::Spec.new do |s|
  s.name          = "CwlUtils"
  s.version       = "1.0.2"
  s.summary       = "A Swift framework for reactive programming."
  s.description   = <<-DESC
    A collection of Swift utilities as documented on cocoawithlove.com
  DESC
  s.homepage      = "https://github.com/mattgallagher/CwlUtils"
  s.license       = { :type => "ISC", :file => "LICENSE.txt" }
  s.author        = "Matt Gallagher"
  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.12"
  s.source        = { :git => "https://github.com/mattgallagher/CwlUtils.git", :tag => "#{s.version}" }
  s.source_files  = "Sources/**/*.{swift,h,c}"
end
