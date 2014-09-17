# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ideal/version"

Gem::Specification.new do |s|
  s.name 	 = %q{ideal-payment}
  s.version      = Ideal::VERSION
  s.authors      = ["Rogier Slag"]
  s.description  = %q{iDEALv3 payment gateway (see http://www.ideal.nl)}
  s.summary      = %q{iDEALv3 payment gateway}
  s.email        = %q{rogier@inventid.nl}
  s.licenses    = ['MIT']
  s.homepage     = %q{http://opensource.inventid.nl/ideal}

  s.extra_rdoc_files = [
     "LICENSE",
     "README.md"
   ]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency             "nokogiri"
  s.add_dependency             "nap"
  s.add_development_dependency "mocha"
  s.add_development_dependency "rspec"

end
