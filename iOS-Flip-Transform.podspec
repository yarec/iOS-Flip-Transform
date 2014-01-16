Pod::Spec.new do |s|
  s.name     = 'iOS-Flip-Transform'
  s.version  = '0.0.1'
  s.license  = 'MIT'
  s.summary  = 'Core Animation framework for navigating data by flipping.'
  s.homepage = 'https://github.com/Dillion/iOS-Flip-Transform'
  s.author   = { 'Dillion' => 'Dillion' }
  s.source   = { :git => 'https://github.com/jcon5294/iOS-Flip-Transform.git', :tag => '0.0.1' }
  s.platform = :ios  
  s.source_files = 'transform/framework/*.{h,m}'
  s.framework = 'QuartzCore'
  s.requires_arc = true
end
