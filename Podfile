install! 'cocoapods', :integrate_targets => false
use_frameworks!

target "iOS" do
  platform :ios, '8.0'
  pod 'PromiseKit/CorePromise'
  pod 'R.swift'
  pod 'Crashlytics'
  pod 'Fabric'
  pod 'Watchdog'
  pod 'GoogleToolboxForMac/NSString+HTML'
  pod 'JGProgressHUD'
  pod 'CwlPreconditionTesting', :git => 'https://github.com/mattgallagher/CwlPreconditionTesting.git'
  pod 'CwlCatchException', :git => 'https://github.com/mattgallagher/CwlCatchException.git'
    #pod 'AFMInfoBanner'
  #pod 'UXCam'
  #pod 'TUSafariActivity'
  #pod 'DZReadability'
  #pod 'HTMLReader'
  #pod 'ReadabilityKit'
  #pod 'Ji', :git => 'https://github.com/andykingway/Ji'
  #pod 'Appsee'
  #pod 'Flurry-iOS-SDK/FlurrySDK'
  #pod 'Mixpanel-swift'
  #pod 'Optimizely-iOS-SDK'
  #pod 'Firebase/Core'
end
target "macOS" do
  platform :osx, '10.11'
  pod 'Crashlytics'
  pod 'Fabric'
  pod 'PromiseKit/CorePromise'
end

target "GEDebugKit" do
  platform :ios, '8.0'
  pod 'FBMemoryProfiler'
  pod 'FBAllocationTracker', :git => 'https://github.com/grigorye/FBAllocationTracker.git'
  #pod 'FPSCounter', :path => '../fps-counter'
  #pod 'FPSCounter', :git => 'https://github.com/grigorye/fps-counter.git'
  pod 'FPSCounter'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      # http://www.mokacoding.com/blog/cocoapods-and-custom-build-configurations/
      if target.name == 'FBAllocationTracker'
        configuration.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = '$(inherited) ALLOCATION_TRACKER_ENABLED'
      end
      configuration.build_settings['CONFIGURATION_BUILD_DIR'] = '${PODS_CONFIGURATION_BUILD_DIR}'
      #configuration.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      #configuration.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'T6B3YCL946/'
      configuration.build_settings['SWIFT_VERSION'] = '3.0'
      configuration.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
      configuration.build_settings['ENABLE_BITCODE'] = 'NO'
      configuration.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
      configuration.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
      xcconfig_path = configuration.base_configuration_reference.real_path
      xcconfig = Xcodeproj::Config.new(xcconfig_path).to_hash
      
      #
      # Remove framework search paths not existing when building (dynamic) frameworks
      #
      frameworkSearchPaths = xcconfig['FRAMEWORK_SEARCH_PATHS']
      if frameworkSearchPaths != nil
        frameworkSearchPaths = frameworkSearchPaths.gsub(/"\$PODS_CONFIGURATION_BUILD_DIR\/[.a-zA-Z0-9_-]+"( |$)/, '')
        xcconfig['FRAMEWORK_SEARCH_PATHS'] = frameworkSearchPaths
      end
      
      File.open(xcconfig_path, "w") { |file|
        xcconfig.each do |key,value|
          file.puts "#{key} = #{value}"
        end
      }
    end
  end
end
