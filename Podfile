# Podfile for swiftcompress
# macOS CLI tool for file compression using Apple's Compression framework

platform :osx, '12.0'

target 'swiftcompress' do
  # Use frameworks for Swift projects
  use_frameworks!

  # CLI argument parsing
  # Using ArgumentParser via CocoaPods
  pod 'swift-argument-parser', '~> 1.3'

  target 'swiftcompressTests' do
    inherit! :search_paths
    # Test-specific dependencies can be added here if needed
  end
end

# Post-install hook to ensure proper build settings
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Set minimum deployment target
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
