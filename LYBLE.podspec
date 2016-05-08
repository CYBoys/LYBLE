Pod::Spec.new do |s|
  s.name         = "LYBLE"
  s.version      = "1.0.0"
  s.summary      = "The package of useful tools, include categories and classes"
  s.license      = "MIT"
  s.homepage     = "http://user.qzone.qq.com/1306992.com"
  s.authors      = { 'tangjr' => '15923456720@163.com'}
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/CYBoys/LYBLE.git", :tag => s.version }
  s.source_files = 'LYBLE', 'LYBLE/**/*.{h,m}'
  s.requires_arc = true
end