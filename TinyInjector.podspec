Pod::Spec.new do |s|
  s.name             = 'TinyInjector'
  s.version          = '0.1.0'
  s.summary          = 'Super light weight of Dependency Manager.'

  s.description      = <<-DESC
An implementation of Service Locator but forcus only dependency management and dependency injection.
                       DESC

  s.homepage         = 'https://github.com/congncif/tiny-injector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'congncif' => 'congnc.if@gmail.com' }
  s.source           = { :git => 'https://github.com/congncif/tiny-injector.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'Sources/TinyInjector/*.swift'
end
