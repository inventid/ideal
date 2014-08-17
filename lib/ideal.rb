# encoding: utf-8

require 'nokogiri'
require 'rest'

require 'ideal/acquirers'
require 'ideal/gateway'
require 'ideal/response'
require 'ideal/version'

require "nokogiri"
require "openssl"
require "base64"
require 'xmldsig'

module Ideal
NAMESPACES = {
      "ds" => "http://www.w3.org/2000/09/xmldsig#",
      "ec" => "http://www.w3.org/2001/10/xml-exc-c14n#"
  }
end