require 'rubygems'
require 'ideal'
require 'yaml'
require 'mocha'
require 'coveralls'

Coveralls.wear!

def strip_whitespace(str)
  str.gsub('/\s/m','')
end

def strip_xml_whitespace(str)
  str.gsub('/\>(\s)*\</m','').strip
end



class GeneralMethodTest
  describe Ideal do

    before(:all) do
      file = File.join(File.dirname(__FILE__), 'fixtures.yml')
      fixtures ||= YAML.load(File.read(file))
      @fixture = fixtures['default'] || raise(StandardError, 'No fixture data was found for key "default"')
      @fixture['private_key_file'] = File.join(File.dirname(__FILE__),@fixture['private_key_file'])
      @fixture['private_certificate_file'] = File.join(File.dirname(__FILE__),@fixture['private_certificate_file'])
      @fixture['ideal_certificate_file'] = File.join(File.dirname(__FILE__),@fixture['ideal_certificate_file'])
      # The passphrase needs to be set first, otherwise the key won't initialize properly
      if (passphrase = @fixture.delete('passphrase')) # Yes the = is intended, not ==
        Ideal::Gateway.passphrase = passphrase
      end
      @fixture.each { |key, value| Ideal::Gateway.send("#{key}=", value) }
      Ideal::Gateway.live_url = nil
    end

    describe Ideal, '#merchant_id' do
      it 'returns the set merchant id' do
        expect(Ideal::Gateway.merchant_id).to eq('002054205')
      end
    end

    describe Ideal, '#url' do
      it 'returns the set test url from the fixture' do
        expect(Ideal::Gateway.test_url).to eq('https://idealtest.rabobank.nl/ideal/iDEALv3')
      end
    end

    describe Ideal, '#url' do
      it 'returns the ideal url for issuer ING' do
        Ideal::Gateway.acquirer = :ing
        expect(Ideal::Gateway.live_url).to eq('https://ideal.secure-ing.com/ideal/iDEALv3')
      end
    end

    describe Ideal, '#url' do
      it 'returns the ideal url for issuer Rabobank' do
        Ideal::Gateway.acquirer = :rabobank
        expect(Ideal::Gateway.live_url).to eq('https://ideal.rabobank.nl/ideal/iDEALv3')
      end
    end

    describe Ideal, '#url' do
      it 'returns the ideal url for issuer ABN Amro' do
        Ideal::Gateway.acquirer = :abnamro
        expect(Ideal::Gateway.live_url).to eq('https://abnamro.ideal-payment.de/ideal/iDeal')
      end
    end

    describe Ideal, '#acquirer' do
      it 'throws an error if the acquirer is non existent' do
        expect { Ideal::Gateway.acquirer = :nonexistent }.to raise_error(ArgumentError)
      end
    end

    describe Ideal, '#private_certificate' do
      it 'returns the currently loaded private certificate' do
        private_cert_file = File.read(@fixture['private_certificate_file'])
        private_cert = OpenSSL::X509::Certificate.new(private_cert_file)
        expect(Ideal::Gateway.private_certificate.to_text).to eq(private_cert.to_text)
      end
    end

    describe Ideal, '#' do
      it 'returns the private key' do
        private_key_file = File.read(@fixture['private_key_file'])
        private_key = OpenSSL::PKey::RSA.new(private_key_file, Ideal::Gateway.passphrase)
        expect(Ideal::Gateway.private_key.to_text).to eq(private_key.to_text)
      end
    end

  end
end

class GeneralTest
  describe Ideal do

    before(:each) do
      file = File.join(File.dirname(__FILE__), 'fixtures.yml')
      fixtures ||= YAML.load(File.read(file))
      @fixture = fixtures['default'] || raise(StandardError, 'No fixture data was found for key "default"')
      @fixture['private_key_file'] = File.join(File.dirname(__FILE__),@fixture['private_key_file'])
      @fixture['private_certificate_file'] = File.join(File.dirname(__FILE__),@fixture['private_certificate_file'])
      @fixture['ideal_certificate_file'] = File.join(File.dirname(__FILE__),@fixture['ideal_certificate_file'])
      # The passphrase needs to be set first, otherwise the key won't initialize properly
      if (passphrase = @fixture.delete('passphrase')) # Yes the = is intended, not ==
        Ideal::Gateway.passphrase = passphrase
      end
      @fixture.each { |key, value| Ideal::Gateway.send("#{key}=", value) }
      Ideal::Gateway.live_url = nil
      @gateway = Ideal::Gateway.new
    end

    describe Ideal, '#initialize' do
      it 'has a sub_id of 0 when just initialized or picks the supplied value' do
        expect(Ideal::Gateway.new.sub_id).to eq(0)
        expect(Ideal::Gateway.new(:sub_id => 1).sub_id).to eq(1)
      end
    end

    describe Ideal, '#send' do
      it 'returns the test_url if the test mode is active' do
        gateway = Ideal::Gateway.new
        Ideal::Gateway.acquirer = :rabobank
        Ideal::Gateway.environment = :test
        expect(gateway.send(:request_url)).to eq(Ideal::Gateway.test_url)
      end
    end

    describe Ideal, '#send' do
      it 'returns the live_url if the test mode is inactive' do
        gateway = Ideal::Gateway.new
        Ideal::Gateway.acquirer = :rabobank
        Ideal::Gateway.environment = :live
        expect(gateway.send(:request_url)).to eq(Ideal::Gateway.live_url)
      end
    end

    describe Ideal, '#send' do
      it 'sends the correct created at datestamp' do
        timestamp = '2011-11-28T16:30:00.000Z'    # Exact time inventid was founded
        allow_any_instance_of(Time).to receive(:gmtime).and_return(DateTime.parse(timestamp))

        expect(@gateway.send(:created_at_timestamp)).to eq(timestamp)
      end
    end

    describe Ideal, '#send' do
      it 'generates a correct digest' do
        sha256 = OpenSSL::Digest::SHA256.new
        allow_any_instance_of(OpenSSL::Digest::SHA256).to receive(:new).and_return(sha256)
        xml = Nokogiri::XML::Builder.new do |xml|
          xml.request do |innerxml|
            xml.content 'digest test'
            @gateway.send(:sign!, innerxml)
          end
        end
        digest_value = xml.doc.at_xpath('//xmlns:DigestValue', 'xmlns' => 'http://www.w3.org/2000/09/xmldsig#').text
        xml.doc.at_xpath('//xmlns:Signature', 'xmlns' => 'http://www.w3.org/2000/09/xmldsig#').remove
        canonical = xml.doc.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
        digest = sha256.digest canonical
        expected_digest_value = strip_whitespace(Base64.encode64(digest.strip)) # .strip does not remove the \n
        expect(expected_digest_value).to eq(digest_value)
      end
    end

    describe Ideal, '#send' do
      it 'generates a correct signature' do
        sha256 = OpenSSL::Digest::SHA256.new
        allow_any_instance_of(OpenSSL::Digest::SHA256).to receive(:new).and_return(sha256)
        signature_value = @gateway.send(:signature_value, 'Test')
        signature = Ideal::Gateway.private_key.sign(sha256, 'Test')
        expected_signature_value = strip_whitespace(Base64.encode64(strip_whitespace(signature)))
        expect(expected_signature_value).to eq(signature_value)
      end
    end

    describe Ideal, '#send' do
      it 'generates a correct fingerprint' do
        certificate_file = File.read(@fixture['private_certificate_file'])
        expected_token = Digest::SHA1.hexdigest(OpenSSL::X509::Certificate.new(certificate_file).to_der)
        expect(@gateway.send(:fingerprint)).to eq(expected_token)
      end
    end

    describe Ideal, '#send' do
      it 'performs an SSL POST and returns the correct response' do
        Ideal::Gateway.environment = :test
        allow_any_instance_of(Ideal::Response).to receive(:new).with('response', :test => true)
        allow(@gateway).to receive(:ssl_post).with(@gateway.request_url, 'data').and_return('response')
        @gateway.send(:post_data, @gateway.request_url, 'data', Ideal::Response)
      end
    end

  end
end

class XmlTest
  describe Ideal do

    before(:each) do
      @gateway = Ideal::Gateway.new
      allow(@gateway).to receive(:created_at_timestamp).and_return('created_at_timestamp')
      allow(@gateway).to receive(:digest_value).and_return('digest_value')
      allow(@gateway).to receive(:signature_value).and_return('signature_value')
      allow(@gateway).to receive(:fingerprint).and_return('fingerprint')
    end

    describe Ideal do
      it 'creates a correct TransactionRequestXml' do
        options = {
            issuer_id: 'issuer_id',
            return_url: 'return_url',
            order_id: 'purchase_id',
            expiration_period: 'expiration_period',
            description: 'description',
            entrance_code: 'entrance_code'
        }
        xml = @gateway.send(:build_transaction_request, 'amount', options)
        expected_response = Nokogiri::XML.parse(File.read(File.join(File.dirname(__FILE__),'expectationXml/transaction_request.xml')))
        actual_response = Nokogiri::XML.parse(xml)
        expect(actual_response.to_s).to eq(expected_response.to_s)
      end
    end

    describe Ideal do
      it 'creates a correct StatusRequestXml' do
        options = {
            transaction_id: 'transaction_id'
        }
        xml = @gateway.send(:build_status_request, options)
        expected_response = Nokogiri::XML.parse(File.read(File.join(File.dirname(__FILE__),'expectationXml/status_request.xml')))
        actual_response = Nokogiri::XML.parse(xml)
        expect(actual_response.to_s).to eq(expected_response.to_s)
      end
    end

    describe Ideal do
      it 'creates a correct DirectoryRequestXml' do
        xml = @gateway.send(:build_directory_request)
        expected_response = Nokogiri::XML.parse(File.read(File.join(File.dirname(__FILE__),'expectationXml/directory_request.xml')))
        actual_response = Nokogiri::XML.parse(xml)
        expect(actual_response.to_s).to eq(expected_response.to_s)
      end
    end
  end
end