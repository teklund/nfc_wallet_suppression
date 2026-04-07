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
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Privacy Manifest: This plugin includes a PrivacyInfo.xcprivacy file that declares
  # no tracking, no data collection, and no required reason API usage. The PassKit APIs
  # used for NFC wallet suppression (requestAutomaticPassPresentationSuppression and
  # endAutomaticPassPresentationSuppression) do not fall under Apple's required reason
  # APIs and do not access sensitive user data. The privacy manifest is included as a
  # best practice but does not need to be bundled as a resource. It serves as
  # documentation that this plugin:
  # - Does not track users (NSPrivacyTracking: false)
  # - Does not collect any data (NSPrivacyCollectedDataTypes: empty)
  # - Does not access required reason APIs (NSPrivacyAccessedAPITypes: empty)
  # - Does not connect to tracking domains (NSPrivacyTrackingDomains: empty)
end
