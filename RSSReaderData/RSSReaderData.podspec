Pod::Spec.new do |s|

  s.name = "RSSReaderData"
  s.version = "0.1"
  s.summary = "Data module for RSSReader."

  s.description  = <<~END
    Persistence, networking related stuff for RSSReader
  END

  s.homepage = "https://github.com/grigorye/RSSReader"
  s.license = 'MIT'

  s.author = { "Grigory Entin" => "grigory.entin@gmail.com" }

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source = { :git => "https://github.com/grigorye/RSSReader.git", :tag => "#{s.version}" }

  s.source_files = "RSSReaderData/*.swift"
  s.resources = ['RSSReaderData/*.xcdatamodeld']

  s.swift_version = '4.2'
  s.dependency 'GECoreData'
  s.dependency 'PromisesSwift'
  s.dependency 'GoogleToolboxForMac/NSString+HTML'
  s.dependency 'Result'
  
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'RSSReaderDataTests/**/*.swift', "RSSReaderData/ImportedExports.swift"
    test_spec.resources = ['RSSReaderDataTests/*-Secrets.plist']
    
    test_spec.resource_bundles = {
      'RSSReaderDataTests-Sources' => ['RSSReaderDataTests']
    }
  end

end
