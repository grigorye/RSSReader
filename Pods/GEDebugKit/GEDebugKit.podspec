Pod::Spec.new do |s|

  s.name = "GEDebugKit"
  s.version = "0.0.2"
  s.summary = "Debugging related extensions"

  s.description  = <<~END
    Debugging related stuff shared between applications.
  END

  s.homepage = "https://github.com/grigorye/GEDebugKit"
  s.license = 'MIT'
  s.author = { "Grigory Entin" => "grigory.entin@gmail.com" }

  s.ios.deployment_target = '11.0'
  #s.osx.deployment_target = '10.10'
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source = { :git => "https://github.com/grigorye/GEDebugKit.git", :tag => "#{s.version}" }
  
  s.swift_version = "4.0"

  s.source_files  = "GEDebugKit/*.swift"
  s.resource_bundle = { 'GEDebugKit-Sources' => 'GEDebugKit' }

  s.dependency 'GEUIKit'
  s.dependency 'GEFoundation'
  s.dependency 'GETracing'

  s.dependency 'FBMemoryProfiler'
  s.dependency 'FBAllocationTracker'
  s.dependency 'FPSCounter'

end
