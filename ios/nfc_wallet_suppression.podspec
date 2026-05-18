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
  s.source_files = 'nfc_wallet_suppression/Sources/nfc_wallet_suppression/**/*.swift'
  s.resource_bundles = {
    'nfc_wallet_suppression_privacy' => ['nfc_wallet_suppression/Sources/nfc_wallet_suppression/PrivacyInfo.xcprivacy'],
  }
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Privacy Manifest: PrivacyInfo.xcprivacy is bundled so Xcode can aggregate it
  # into the consuming app's privacy manifest at build time. The manifest declares
  # no tracking, no data collection, no tracking domains, and no required-reason
  # API usage. The PassKit APIs used here (requestAutomaticPassPresentationSuppression
  # and endAutomaticPassPresentationSuppression) are not on Apple's required-reason
  # API list, so NSPrivacyAccessedAPITypes is intentionally empty.
end
