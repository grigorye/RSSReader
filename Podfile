install! 'cocoapods', :integrate_targets => false
use_frameworks!

target "iOS" do
	platform :ios, '8.0'
#	pod 'AFMInfoBanner'
	pod 'SwiftMessages'
#	pod 'UXCam'
#	pod 'TUSafariActivity'
#	pod 'DZReadability'
#	pod 'HTMLReader'
#	pod 'ReadabilityKit'
#	pod 'Ji', :git => 'https://github.com/andykingway/Ji'
	pod 'Crashlytics'
	pod 'Fabric'
#	pod 'Appsee'
#	pod 'Flurry-iOS-SDK/FlurrySDK'
	pod 'FBMemoryProfiler'
	pod 'PromiseKit/CorePromise'
	pod 'Mixpanel-swift'
	pod 'Optimizely-iOS-SDK'
	pod 'Firebase/Core'
end
target "macOS" do
	platform :osx, '10.11'
	pod 'Crashlytics'
	pod 'Fabric'
	pod 'PromiseKit/CorePromise'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      configuration.build_settings['CONFIGURATION_BUILD_DIR'] = '${PODS_CONFIGURATION_BUILD_DIR}'
      configuration.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      configuration.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = '465NA5BW7E/'
      configuration.build_settings['SWIFT_VERSION'] = '3.0'
      configuration.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
      configuration.build_settings['ENABLE_BITCODE'] = 'NO'
      configuration.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
      xcconfig_path = configuration.base_configuration_reference.real_path
      xcconfig = Xcodeproj::Config.new(xcconfig_path).to_hash
      File.open(xcconfig_path, "w") { |file|
        xcconfig.each do |key,value|
          file.puts "#{key} = #{value}"
        end
      }
    end
  end
end
