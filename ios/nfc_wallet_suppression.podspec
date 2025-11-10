#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint nfc_wallet_suppression.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'nfc_wallet_suppression'
  s.version          = '0.0.1'
  s.summary          = 'iOS implementation for suppressing Apple Wallet NFC presentation'
  s.description      = <<-DESC
iOS implementation of the nfc_wallet_suppression Flutter plugin. Uses PassKit to suppress 
automatic Apple Wallet presentation when detecting NFC readers.
                       DESC
  s.homepage         = 'https://github.com/teklund/nfc_wallet_suppression'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'TEklund' => 'teklund@users.noreply.github.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'nfc_wallet_suppression_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
