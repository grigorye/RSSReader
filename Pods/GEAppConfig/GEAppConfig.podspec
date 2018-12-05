Pod::Spec.new do |s|

  s.name = "GEAppConfig"
  s.version = "0.0.1"
  s.summary = "Application configuration related stuff"

  s.description  = <<~END
    A few components shared between applications, related to the configuration.
  END

  s.homepage = "https://github.com/grigorye/GEAppConfig"
  s.license = 'MIT'
  s.author = { "Grigory Entin" => "grigory.entin@gmail.com" }

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source = { :git => "https://github.com/grigorye/GEAppConfig.git", :tag => "#{s.version}" }
  
  s.swift_version = "4.2"

  s.ios.source_files = "GEAppConfig/iOS"
  s.osx.source_files = "GEAppConfig/macOS"

  s.default_subspec = 'Core'
  
  s.static_framework = true

  s.subspec 'Core' do |ss|
    ss.source_files = "GEAppConfig/Core/Shared"
    ss.ios.source_files = "GEAppConfig/Core/Platform/iOS"
    ss.osx.source_files = "GEAppConfig/Core/Platform/macOS"
    ss.resource_bundles = { 'GEAppConfig-Sources' => 'GEAppConfig' }
  end

  s.subspec 'Analytics' do |ss|
    ss.source_files = "GEAppConfig/Analytics/*.swift"
    ss.xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'GEAPPCONFIG_ANALYTICS_ENABLED'
    }
  end

  s.subspec 'Crashlytics' do |ss|
    ss.dependency 'GEAppConfig/Analytics'
    ss.source_files = 'GEAppConfig/Analytics/Crashlytics/*.swift'
    ss.xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'GEAPPCONFIG_CRASHLYTICS_ENABLED'
    }
    ss.dependency 'Fabric'
    ss.dependency 'Crashlytics'
  end

  s.subspec 'Answers' do |ss|
    ss.dependency 'GEAppConfig/Analytics'
    ss.source_files = 'GEAppConfig/Analytics/Answers/*.swift'
    ss.xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'GEAPPCONFIG_ANSWERS_ENABLED'
    }
    ss.dependency 'Fabric'
    ss.dependency 'Crashlytics'
  end

  s.subspec 'CoreData' do |ss|
    ss.source_files = 'GEAppConfig/CoreData/*.swift'
    ss.xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'GEAPPCONFIG_COREDATA_ENABLED'
    }
    ss.dependency 'GECoreData'
  end

  s.subspec 'iOS' do |ss|
    ss.ios.source_files = 'GEAppConfig/iOS/*.swift'
  end

  s.ios.dependency 'GEDebugKit'
  s.ios.dependency 'GEUIKit'
  s.dependency 'GEFoundation'
  s.dependency 'GETracing'

  s.ios.dependency 'FTLinearActivityIndicator'
  s.ios.dependency 'JGProgressHUD'
  s.ios.dependency 'Watchdog'

end
