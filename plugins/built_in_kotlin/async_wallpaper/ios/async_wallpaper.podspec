#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint async_wallpaper.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'async_wallpaper'
  s.version          = '3.3.0'
  s.summary          = 'Flutter wallpaper plugin with Android apply and cross-platform download support.'
  s.description      = <<-DESC
A Flutter plugin for wallpaper operations. Android supports apply/live wallpaper flows,
while iOS supports wallpaper download to Photos.
                       DESC
  s.homepage         = 'https://github.com/codenameakshay/async_wallpaper'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'codenameakshay' => 'contact@hashstudios.dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'async_wallpaper/Sources/async_wallpaper/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.0'
end
