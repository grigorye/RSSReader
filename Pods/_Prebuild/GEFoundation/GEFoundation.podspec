Pod::Spec.new do |s|

  s.name = "GEFoundation"
  s.version = "0.1.1"
  s.summary = "A few utilities."

  s.description  = <<~END
    Utilties that might be used by any app.
  END

  s.homepage = "https://github.com/grigorye/GEFoundation"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Grigory Entin" => "grigory.entin@gmail.com" }

  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.11"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source = { :git => "https://github.com/grigorye/GEFoundation.git", :tag => "#{s.version}" }

  s.source_files  = "GEFoundation/*.swift", "GEFoundation/*.{m,h}"
  s.exclude_files = "GEFoundation/ModuleExports-*.swift"

  s.resource_bundle = { 'GEFoundation-Sources' => 'GEFoundation' }

  s.swift_version = '4.2'
  
  s.dependency "GETracing", "~> 0.1"

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'GEFoundationTests/**/*.swift'
  end

end
