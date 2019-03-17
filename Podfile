source 'https://github.com/grigorye/podspecs.git'
source 'https://github.com/CocoaPods/Specs.git'

install! 'cocoapods'#, :integrate_targets => false
plugin 'cocoapods-binary'

project "RSSReader/RSSReader.xcodeproj"
use_frameworks!
#all_binary!
keep_source_code_for_prebuilt_frameworks! 

def commonDeps
  pod 'Crashlytics', :binary => false
  pod 'Fabric', :binary => false
  pod 'Result', :binary => true
  pod 'PromisesSwift', :binary => true
  pod 'GoogleToolboxForMac/NSString+HTML', :binary => true

  pod 'GEAppConfig', :subspecs => ['Core', 'Crashlytics', 'Answers', 'iOS']#, :path => '../GEAppConfig'
  pod 'GETracing', :binary => true#, :path => '../GETracing'
  pod 'GEFoundation', :binary => true#, :path => '../GEFoundation'
  pod 'GECoreData', :binary => true#, :path => '../GECoreData'
  pod 'GEUIKit', :binary => true#, :path => '../GEUIKit'
  pod 'GEDebugKit', :binary => false#, :path => '../GEDebugKit'
end

# This "target" is used to produce the corresponding .xcconfig that is explicitly #included in the app .xcconfig.
target "RSSReader" do
  platform :ios, '11.0'
  commonDeps
  pod 'RSSReader', :path => 'RSSReader'
  pod 'R.swift', :binary => true
  pod 'Watchdog', :binary => true
  pod 'JGProgressHUD', :binary => true
  pod 'FTLinearActivityIndicator', :binary => true
  pod 'FBMemoryProfiler', :binary => true, :inhibit_warnings => true
  pod 'FBAllocationTracker', :binary => true, :inhibit_warnings => true
  pod 'FPSCounter', :binary => true
  pod 'RSSReaderData', :path => 'RSSReaderData'
  pod 'Loggy', :binary => true#, :path => '../LogExperiment'
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

def unitTestDeps
end

target "RSSReaderTests" do
  platform :ios, '9.0'
  unitTestDeps
end

target "RSSReaderUITests" do
  platform :ios, '11.0'
end

#target "tests-macOS" do
#  platform :osx, '10.11'
#  unitTestDeps
#end

#target "macOS" do
#  platform :osx, '10.11'
#end

swift_versions = {
  'R.swift.Library' => '4.2'
}

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      # http://www.mokacoding.com/blog/cocoapods-and-custom-build-configurations/
      if target.name == 'FBAllocationTracker'
        configuration.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = '$(inherited) ALLOCATION_TRACKER_ENABLED'
      end

      if !configuration.build_settings.key?('SWIFT_VERSION')
        custom_swift_version = swift_versions[target.name]
        target_swift_version = (custom_swift_version != nil) ? custom_swift_version : '4.2'
        puts "Setting SWIFT_VERSION for #{target.name}/#{configuration}: #{target_swift_version}"
        configuration.build_settings['SWIFT_VERSION'] = target_swift_version
      end

      #configuration.build_settings['CONFIGURATION_BUILD_DIR'] = '${PODS_CONFIGURATION_BUILD_DIR}'
      #configuration.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      #configuration.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'T6B3YCL946/'
      configuration.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
      configuration.build_settings['ENABLE_BITCODE'] = 'NO'
      configuration.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
      configuration.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
    end
  end
end
