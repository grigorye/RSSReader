platform :ios, '8.0'
install! 'cocoapods', :integrate_targets => false
use_frameworks!

target "RSSReader" do
	pod 'AFMInfoBanner'
	pod 'UXCam'
	pod 'TUSafariActivity'
	pod 'DZReadability'
	pod 'HTMLReader', :inhibit_warnings => true
	pod 'Crashlytics'
	pod 'Fabric'
	pod 'Appsee'
	pod 'Flurry-iOS-SDK/FlurrySDK'
	pod 'FBMemoryProfiler'
	pod 'LayoutKit', :git => 'https://github.com/linkedin/LayoutKit', :branch => 'swift3'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CONFIGURATION_BUILD_DIR'] = '${PODS_CONFIGURATION_BUILD_DIR}'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = '465NA5BW7E/'
    end
  end
end