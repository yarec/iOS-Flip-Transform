Pod::Spec.new do |s|
  s.name     = 'iOS-Flip-Transform'
  s.version  = '0.0.1'
  s.license  = 'MIT'
  s.summary  = 'Core Animation framework for navigating data by flipping.'
  s.homepage = 'https://github.com/yarec/iOS-Flip-Transform'
  s.author   = { 'yarec' => 'yarec' }
  s.source   = { :git => 'https://github.com/yarec/iOS-Flip-Transform.git' }
  s.platform = :ios  
  s.source_files = 'transform/framework/*.{h,m}'
  s.framework = 'QuartzCore'
  s.requires_arc = true
end
