Pod::Spec.new do |s|

  s.name = "GETracing"
  s.version = "0.1.2"
  s.summary = "Seamless tracing for Swift."

  s.description  = <<~END
    Trace bar in `x = foo(bar)` as `x = foo(x$(bar)).`
  END

  s.homepage = "https://github.com/grigorye/GETracing"
  s.license = 'MIT'

  s.author = { "Grigory Entin" => "grigory.entin@gmail.com" }

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.10'
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source = { :git => "https://github.com/grigorye/GETracing.git", :tag => "#{s.version}" }

  s.source_files = "GETracing/*.swift"
  s.exclude_files = "GETracing/ModuleExports-*.swift"

  s.preserve_paths = "Tools/*"

  s.swift_version = '4.2'

  s.xcconfig = {
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'GE_TRACE_ENABLED'
  }

  s.user_target_xcconfig = { 'GETRACING_TOOLS' => '$(GETRACING_POD_ROOT)/Tools' }

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'GETracingTests/**/*.swift'
    test_spec.resource_bundles = {
      'GETracingTests-Sources' => ['GETracingTests']
    }
    test_spec.dependency 'CwlPreconditionTesting'
    test_spec.dependency 'CwlCatchException'
  end

end
