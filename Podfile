install! 'cocoapods', :integrate_targets => false
use_frameworks!

target "iOS" do
	platform :ios, '8.0'
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
	pod 'Result'
	pod 'PromiseKit/CorePromise', :git => 'https://github.com/mxcl/PromiseKit', :branch => '4.0.0-beta1'
end
target "macOS" do
	platform :osx, '10.11'
	pod 'Crashlytics'
	pod 'Fabric'
	pod 'Result'
	pod 'PromiseKit/CorePromise', :git => 'https://github.com/mxcl/PromiseKit', :branch => '4.0.0-beta1'
	pod 'Result'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CONFIGURATION_BUILD_DIR'] = '${PODS_CONFIGURATION_BUILD_DIR}'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = '465NA5BW7E/'
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
