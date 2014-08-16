require 'rubygems'
require 'ideal'
require 'yaml'
require 'mocha'
require 'coveralls'

Coveralls.wear!

def strip_whitespace(str)
  str.gsub('/\s/m', '')
end

def strip_xml_whitespace(str)
  str.gsub('/\>(\s)*\</m', '').strip
end


class GeneralMethodTest
  describe Ideal do

    before(:all) do
      file = File.join(File.dirname(__FILE__), 'fixtures.yml')
      fixtures ||= YAML.load(File.read(file))
      @fixture = fixtures['default'] || raise(StandardError, 'No fixture data was found for key "default"')
      @fixture['private_key_file'] = File.join(File.dirname(__FILE__), @fixture['private_key_file'])
      @fixture['private_certificate_file'] = File.join(File.dirname(__FILE__), @fixture['private_certificate_file'])
      @fixture['ideal_certificate_file'] = File.join(File.dirname(__FILE__), @fixture['ideal_certificate_file'])
      # The passphrase needs to be set first, otherwise the key won't initialize properly
      if (passphrase = @fixture.delete('passphrase')) # Yes the = is intended, not ==
        Ideal::Gateway.passphrase = passphrase
      end
      @fixture.each { |key, value| Ideal::Gateway.send("#{key}=", value) }
      Ideal::Gateway.live_url = nil
    end

    describe '#merchant_id' do
      it 'returns the set merchant id' do
        expect(Ideal::Gateway.merchant_id).to eq('002054205')
      end
    end

    describe '#url' do
      it 'returns the set test url from the fixture' do
        expect(Ideal::Gateway.test_url).to eq('https://idealtest.rabobank.nl/ideal/iDEALv3')
      end
    end

    describe '#url' do
      it 'returns the ideal url for issuer ING' do
        Ideal::Gateway.acquirer = :ing
        expect(Ideal::Gateway.live_url).to eq('https://ideal.secure-ing.com/ideal/iDEALv3')
      end
    end

    describe '#url' do
      it 'returns the ideal url for issuer Rabobank' do
        Ideal::Gateway.acquirer = :rabobank
        expect(Ideal::Gateway.live_url).to eq('https://ideal.rabobank.nl/ideal/iDEALv3')
      end
    end

    describe '#url' do
      it 'returns the ideal url for issuer ABN Amro' do
        Ideal::Gateway.acquirer = :abnamro
        expect(Ideal::Gateway.live_url).to eq('https://abnamro.ideal-payment.de/ideal/iDeal')
      end
    end

    describe '#acquirer' do
      it 'throws an error if the acquirer is non existent' do
        expect { Ideal::Gateway.acquirer = :nonexistent }.to raise_error(ArgumentError)
      end
    end

    describe '#private_certificate' do
      it 'returns the currently loaded private certificate' do
        private_cert_file = File.read(@fixture['private_certificate_file'])
        private_cert = OpenSSL::X509::Certificate.new(private_cert_file)
        expect(Ideal::Gateway.private_certificate.to_text).to eq(private_cert.to_text)
      end
    end

    describe '#' do
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
      @fixture['private_key_file'] = File.join(File.dirname(__FILE__), @fixture['private_key_file'])
      @fixture['private_certificate_file'] = File.join(File.dirname(__FILE__), @fixture['private_certificate_file'])
      @fixture['ideal_certificate_file'] = File.join(File.dirname(__FILE__), @fixture['ideal_certificate_file'])
      # The passphrase needs to be set first, otherwise the key won't initialize properly
      if (passphrase = @fixture.delete('passphrase')) # Yes the = is intended, not ==
        Ideal::Gateway.passphrase = passphrase
      end
      @fixture.each { |key, value| Ideal::Gateway.send("#{key}=", value) }
      Ideal::Gateway.live_url = nil
      @gateway = Ideal::Gateway.new
    end

    describe '#initialize' do
      it 'has a sub_id of 0 when just initialized or picks the supplied value' do
        expect(Ideal::Gateway.new.sub_id).to eq(0)
        expect(Ideal::Gateway.new(:sub_id => 1).sub_id).to eq(1)
      end
    end

    describe '#send' do
      it 'returns the test_url if the test mode is active' do
        gateway = Ideal::Gateway.new
        Ideal::Gateway.acquirer = :rabobank
        Ideal::Gateway.environment = :test
        expect(gateway.send(:request_url)).to eq(Ideal::Gateway.test_url)
      end
    end

    describe '#send' do
      it 'returns the live_url if the test mode is inactive' do
        gateway = Ideal::Gateway.new
        Ideal::Gateway.acquirer = :rabobank
        Ideal::Gateway.environment = :live
        expect(gateway.send(:request_url)).to eq(Ideal::Gateway.live_url)
      end
    end

    describe '#send' do
      it 'sends the correct created at datestamp' do
        timestamp = '2011-11-28T16:30:00.000Z' # Exact time inventid was founded
        allow_any_instance_of(Time).to receive(:gmtime).and_return(DateTime.parse(timestamp))

        expect(@gateway.send(:created_at_timestamp)).to eq(timestamp)
      end
    end

    describe '#send' do
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

=begin
    describe '#send' do
      it 'generates a correct signature' do
        sha256 = OpenSSL::Digest::SHA256.new
        #allow_any_instance_of(OpenSSL::Digest::SHA256).to receive(:new).and_return(sha256)
        xml = Nokogiri::XML::Builder.new do |xml|
          xml.request do |innerxml|
            xml.content 'signature test'
            @gateway.send(:sign!, innerxml)
          end
        end
        signature_value = @gateway.send(:signature_value, xml.doc)
        signature = Ideal::Gateway.private_key.sign(sha256, xml.doc)
        expected_signature_value = strip_whitespace(Base64.encode64(signature))
        expect(signature_value).to eq(expected_signature_value)
      end
    end
=end

    describe '#send' do
      it 'generates a correct fingerprint' do
        certificate_file = File.read(@fixture['private_certificate_file'])
        expected_token = Digest::SHA1.hexdigest(OpenSSL::X509::Certificate.new(certificate_file).to_der)
        expect(@gateway.send(:fingerprint)).to eq(expected_token)
      end
    end

    describe '#send' do
      it 'performs an SSL POST and returns the correct response' do
        Ideal::Gateway.environment = :test
        allow_any_instance_of(Ideal::Response).to receive(:new).with('response', :test => true)
        allow(@gateway).to receive(:ssl_post).with(@gateway.request_url, 'data').and_return('<x>response</x>')
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
        expected_response = Nokogiri::XML.parse(File.read(File.join(File.dirname(__FILE__), 'expectationXml/transaction_request.xml')))
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
        expected_response = Nokogiri::XML.parse(File.read(File.join(File.dirname(__FILE__), 'expectationXml/status_request.xml')))
        actual_response = Nokogiri::XML.parse(xml)
        expect(actual_response.to_s).to eq(expected_response.to_s)
      end
    end

    describe Ideal do
      it 'creates a correct DirectoryRequestXml' do
        xml = @gateway.send(:build_directory_request)
        expected_response = Nokogiri::XML.parse(File.read(File.join(File.dirname(__FILE__), 'expectationXml/directory_request.xml')))
        actual_response = Nokogiri::XML.parse(xml)
        expect(actual_response.to_s).to eq(expected_response.to_s)
      end
    end
  end
end

class ErrorHandlingTest
  describe Ideal do

    before(:each) do
      @gateway = Ideal::Gateway.new
      allow(@gateway).to receive(:created_at_timestamp).and_return('created_at_timestamp')
      allow(@gateway).to receive(:digest_value).and_return('digest_value')
      allow(@gateway).to receive(:signature_value).and_return('signature_value')
      allow(@gateway).to receive(:fingerprint).and_return('fingerprint')

      @transaction_id = '1234567890123456'
    end

    describe '#send' do
      it 'accepts a valid request with valid options' do
        expect(@gateway.send(:build_transaction_request, 4321, VALID_PURCHASE_OPTIONS)).to be_truthy
      end
    end

    describe '#send' do
      it 'should error on erroneously long fields in a transaction request' do
        expect { @gateway.send(:build_transaction_request, 1234567890123, VALID_PURCHASE_OPTIONS) }.to raise_error(ArgumentError) # 13 chars

        [
            [:order_id, '12345678901234567'], # 17 chars,
            [:description, '123456789012345678901234567890123'], # 33 chars
            [:entrance_code, '12345678901234567890123456789012345678901'] # 41
        ].each do |key, value|
          options = VALID_PURCHASE_OPTIONS.dup
          options[key] = value

          expect { @gateway.send(:build_transaction_request, 4321, options) }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#send' do
      it 'should error on a missing required field in a transaction request' do
        options = VALID_PURCHASE_OPTIONS.dup
        options.keys.each do |key|
          options.delete(key)

          expect { @gateway.send(:build_transaction_request, 100, options) }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#send' do
      it 'should error on inappropriate characters for a transaction request' do
        expect { @gateway.send(:build_transaction_request, 'graphème', VALID_PURCHASE_OPTIONS) }.to raise_error(ArgumentError)

        [:order_id, :description, :entrance_code].each do |key, value|
          options = VALID_PURCHASE_OPTIONS.dup
          options[key] = 'graphème'

          expect { @gateway.send(:build_transaction_request, 4321, options) }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#send' do
      it 'should error on missing required options for a status request' do
        expect { @gateway.send(:build_status_request, {}) }.to raise_error(ArgumentError)
      end
    end

  end
end

class ResponseTest
  describe Ideal do

    before(:each) do
      file = File.join(File.dirname(__FILE__), 'testXml/large-directory-response.xml')
      @xml = File.read(file)
      @response = Ideal::Response.new(@xml)
    end

    describe '#test' do
      it 'should set the environment correctly on instantiation or use the default' do
        file = File.join(File.dirname(__FILE__), 'testXml/large-directory-response.xml')
        xml = File.read(file)
        expect(Ideal::Response.new(xml, :test => true).test?).to be true
        expect(Ideal::Response.new(xml, :test => false).test?).to be false
        expect(Ideal::Response.new(xml).test?).to be false
      end
    end

    describe 'response' do
      it 'return a correct response body' do
        file = File.join(File.dirname(__FILE__), 'testXml/large-directory-response.xml')
        xml = File.read(file)
        response = Ideal::Response.new(xml)
        expect(response.instance_variable_get(:@response).to_s).to eq(Nokogiri::XML.parse(xml).remove_namespaces!.root.to_s)
        expect(response.success?).to be true
        expect(response.error_message).to be nil
        expect(response.error_code).to be nil
      end
    end

    describe 'error' do
      it 'gives an error if the response is incorrect' do
        file = File.join(File.dirname(__FILE__), 'testXml/error-response.xml')
        xml = File.read(file)
        response = Ideal::Response.new(xml)

        expect(response.success?).to be false
        expect(response.error_message).to eq('Failure in system')
        expect(response.error_details).to eq('System generating error: issuer')
        expect(response.consumer_error_message).to eq('Betalen met iDEAL is nu niet mogelijk.')
        expect(response.error_code).to eq('SO1000')
        [
            ['IX1000', :xml],
            ['SO1000', :system],
            ['SE2000', :security],
            ['BR1200', :value],
            ['AP1000', :application]
        ].each do |code, type|
          allow(response).to receive(:error_code).and_return(code)
          expect(response.error_type).to eq(type)
        end

      end
    end

    describe 'directory' do
      it 'returns the list of issuers' do
        gateway = Ideal::Gateway.new

        file = File.join(File.dirname(__FILE__), 'testXml/small-directory-response.xml')
        xml = File.read(file)

        allow(gateway).to receive(:build_directory_request).and_return('the request body')
        expect(gateway).to receive(:ssl_post).with(gateway.request_url, 'the request body').and_return(xml)

        expected_issuers = [{:id => '1006', :name => 'ABN AMRO Bank'}]

        directory_response = gateway.issuers
        expect(directory_response).to be_a Ideal::DirectoryResponse
        expect(expected_issuers).to eq(directory_response.list)

        file = File.join(File.dirname(__FILE__), 'testXml/large-directory-response.xml')
        xml = File.read(file)

        expected_issuers = [
            {:id => '1006', :name => 'ABN AMRO Bank'},
            {:id => '1003', :name => 'Postbank'},
            {:id => '1005', :name => 'Rabobank'},
            {:id => '1017', :name => 'Asr bank'},
            {:id => '1023', :name => 'Van Lanschot'}
        ]

        expect(gateway).to receive(:ssl_post).with(gateway.request_url, 'the request body').and_return(xml)

        directory_response = gateway.issuers
        expect(directory_response).to be_a Ideal::DirectoryResponse
        expect(expected_issuers).to eq(directory_response.list)
      end
    end

    describe 'purchase' do
      it 'should return a valid transaction response' do
        gateway = Ideal::Gateway.new
        file = File.join(File.dirname(__FILE__), 'testXml/transaction-response.xml')
        xml = File.read(file)

        allow(gateway).to receive(:build_transaction_request).with(4321, VALID_PURCHASE_OPTIONS).and_return('the request body')
        expect(gateway).to receive(:ssl_post).with(gateway.request_url, 'the request body').and_return(xml)

        setup_purchase_response = gateway.setup_purchase(4321, VALID_PURCHASE_OPTIONS)

        expect(setup_purchase_response).to be_a Ideal::TransactionResponse

        expect(setup_purchase_response.service_url).to eq('https://ideal.example.com/long_service_url?X009=BETAAL&X010=20')

        expect(setup_purchase_response.transaction_id).to eq('0001023456789112')
        expect(setup_purchase_response.order_id).to eq('iDEAL-aankoop 21')
      end
    end

  end

  describe 'purchase' do
    it 'should start a transaction at the acquirer' do

      gateway = Ideal::Gateway.new
      file = File.join(File.dirname(__FILE__), 'testXml/transaction-response.xml')
      xml = File.read(file)

      allow(gateway).to receive(:build_transaction_request).with(4321, VALID_PURCHASE_OPTIONS).and_return('the request body')
      expect(gateway).to receive(:ssl_post).with(gateway.request_url, 'the request body').and_return(xml)

      setup_purchase_response = gateway.setup_purchase(4321, VALID_PURCHASE_OPTIONS)

      expect(setup_purchase_response).to be_a(Ideal::TransactionResponse)

      expect(setup_purchase_response.service_url).to eq('https://ideal.example.com/long_service_url?X009=BETAAL&X010=20')

      expect(setup_purchase_response.transaction_id).to eq('0001023456789112')
      expect(setup_purchase_response.order_id).to eq('iDEAL-aankoop 21')
    end
  end

  describe 'capturePurchase' do
    it 'should do something correctly and not wrong' do
      gateway = Ideal::Gateway.new

      allow(gateway).to receive(:build_status_request).
                            with(:transaction_id => '0001023456789112').and_return('the request body')

      allow(gateway).to receive(:ssl_post).with(gateway.request_url, 'the request body').and_return(File.read(File.join(File.dirname(__FILE__), 'testXml/status-response-succeeded.xml')))
      expect(gateway.capture('0001023456789112')).to be_a Ideal::StatusResponse

      allow_any_instance_of(Ideal::StatusResponse).to receive(:verified?).and_return(true)
      capture_response = gateway.capture('0001023456789112')
      expect(capture_response.success?).to be true
    end
  end

  describe 'capturePurchase' do
    it 'tololol' do

      gateway = Ideal::Gateway.new
      allow(gateway).to receive(:build_status_request).
                            with(:transaction_id => '0001023456789112').and_return('the request body')

      allow(gateway).to receive(:ssl_post).with(gateway.request_url, 'the request body').and_return(File.read(File.join(File.dirname(__FILE__), 'testXml/status-response-succeeded-incorrect.xml')))
      allow_any_instance_of(Ideal::StatusResponse).to receive(:verified?).and_return(false)
      capture_response = gateway.capture('0001023456789112')
      expect(capture_response.verified?).to be false
      expect(capture_response.success?).to be false
    end


  end
end

# Defaults

VALID_PURCHASE_OPTIONS = {
    :issuer_id => '99999IBAN',
    :expiration_period => 'PT10M',
    :return_url => 'https://example.inventid.net',
    :order_id => '1234567890',
    :description => 'A beautiful Eticket',
    :entrance_code => '1234'
}