Pod::Spec.new do |s|

  s.name = "GEUIKit"
  s.version = "0.0.2"
  s.summary = "UIKit related extensions"

  s.description  = <<~END
    UIKit related stuff shared between applications.
  END

  s.homepage = "https://github.com/grigorye/GEUIKit"
  s.license = 'MIT'
  s.author = { "Grigory Entin" => "grigory.entin@gmail.com" }

  s.ios.deployment_target = '11.0'
  #s.osx.deployment_target = '10.10'
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source = { :git => "https://github.com/grigorye/GEUIKit.git", :tag => "#{s.version}" }
  s.resource_bundle = { 'GEUIKit-Sources' => 'GEUIKit' }

  s.swift_version = "4.0"

  s.source_files  = "GEUIKit/*.swift"

  s.dependency "GECoreData", "~> 0.0.1"
  s.dependency "GEFoundation", "~> 0.1"
  s.dependency "GETracing", "~> 0.1"

end
