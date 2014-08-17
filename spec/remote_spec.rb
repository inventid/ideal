# encoding: utf-8
require 'coveralls'

Coveralls.wear!

require 'rubygems'
require 'ideal'
require 'yaml'
require 'mocha'

class Idealtest
  describe Ideal do

    before(:each) do
      setup_ideal_gateway(fixtures('default'))
      Ideal::Gateway.environment = :test

      @gateway = Ideal::Gateway.new

      @@issuer ||= {id: 'RABONL2U'}

      @valid_options = {
          :issuer_id => @@issuer[:id],
          :expiration_period => 'PT10M',
          :return_url => 'http://return_to.example.com',
          :order_id => '123456789012',
          :currency => 'EUR',
          :description => 'A classic Dutch windmill',
          :entrance_code => '1234'
      }
    end


    describe 'requests' do
      it 'should go to the test environment' do
        expect(@gateway.issuers.test?).to be true
      end
    end

    describe 'valid requests' do
      it 'should proceed' do
        response = @gateway.setup_purchase(550, @valid_options)
        expect(response.success?).to be true
        expect(response.service_url).not_to be nil
        expect(response.transaction_id).not_to be nil
        expect(response.order_id).to eq(@valid_options[:order_id])
        expect(response.verified?).to be true
      end
    end

    describe 'invalid requests' do
      it 'should be rejected' do
        response = @gateway.setup_purchase('0;5', @valid_options)

        expect(response.success?).to eq false
        expect(response.error_code).to eq('BR1210')
        expect(response.error_message).not_to be nil
        expect(response.consumer_error_message).not_to be nil
      end
    end

    describe 'valid requests but incorrectly signed' do
      it 'should be rejected' do
        allow_any_instance_of(Xmldsig::SignedDocument).to receive(:validate).and_return(false)
        response = capture_transaction(:success)

        expect(response.verified?).to be false
      end
    end

    ###
    #
    # These are the 7 integration tests of ING which need to be ran sucessfuly
    # _before_ you'll get access to the live environment.
    #
    # See test_transaction_id for info on how the remote tests are ran.
    #

    describe '#issuers' do
      it 'return a list of iDeal issuers' do
        issuer_list = @gateway.issuers.list
        expect(issuer_list.length).to eq(2)
        expect(issuer_list[0][:id]).to eq('INGBNL2A')
      end
    end


    describe 'successful transaction' do
      it 'should be successful' do
        res = capture_transaction(:success)
        expect(res.success?).to be true
        expect(res.status).to eq(:success)
        expect(res.verified?).to be true
        expect(res.consumer_iban).to eq('NL17RABO0213698412')
        expect(res.consumer_name).to eq('Hr E G H Küppers en/of MW M.J. Küppers-Veeneman')
        expect(res.consumer_bic).to eq('RABONL2U')
      end
    end

    describe 'cancelled transaction' do
      it 'should be cancelled' do
        res = capture_transaction(:cancelled)
        expect(res.success?).to be false
        expect(res.status).to eq(:cancelled)
        expect(res.verified?).to be true
      end
    end

    describe 'expired transaction' do
      it 'should be expired' do
        res = capture_transaction(:expired)
        expect(res.success?).to be false
        expect(res.status).to eq(:expired)
        expect(res.verified?).to be true
      end
    end

    describe 'open transaction' do
      it 'should be open' do
        res = capture_transaction(:open)
        expect(res.success?).to be false
        expect(res.status).to eq(:open)
        expect(res.verified?).to be true
      end
    end

    describe 'failed transaction' do
      it 'should be failure' do
        res = capture_transaction(:failure)
        expect(res.success?).to be false
        expect(res.status).to eq(:failure)
        expect(res.verified?).to be true
      end
    end

    describe 'server_error transaction' do
      it 'should be server_error' do
        res = capture_transaction(:server_error)
        expect(res.success?).to be false
        expect(res.verified?).to be true
      end
    end

    private

    # Shortcut method which does a #setup_purchase through #test_transaction and
    # captures the resulting transaction and returns the capture response.
    def capture_transaction(type)
      @gateway.capture test_transaction(type).transaction_id
    end

    # Calls #setup_purchase with the amount corresponding to the named test and
    # returns the response. Before returning an assertion will be ran to test
    # whether or not the transaction was successful.
    def test_transaction(type)
      amount = case type
                 when :success then
                   1.00
                 when :cancelled then
                   2.00
                 when :expired then
                   3.00
                 when :open then
                   4.00
                 when :failure then
                   5.00
                 when :server_error then
                   7.00
               end

      response = @gateway.setup_purchase(amount, @valid_options)
      expect(response.success?).to be true

      log('RESP', response.service_url)

      response
    end

    def fixtures(key)
      file = File.join(File.dirname(__FILE__), 'fixtures.yml')
      fixtures ||= YAML.load(File.read(file))
      @fixture = fixtures[key] || raise(StandardError, "No fixture data was found for key '#{key}'")
      @fixture['private_key_file'] = File.join(File.dirname(__FILE__), @fixture['private_key_file'])
      @fixture['private_certificate_file'] = File.join(File.dirname(__FILE__), @fixture['private_certificate_file'])
      @fixture['ideal_certificate_file'] = File.join(File.dirname(__FILE__), @fixture['ideal_certificate_file'])
      @fixture
    end

    # Setup the gateway by providing a hash of attributes and values.
    def setup_ideal_gateway(fixture)
      fixture = fixture.dup
      # The passphrase needs to be set first, otherwise the key won't initialize properly
      if passphrase = fixture.delete('passphrase')
        Ideal::Gateway.passphrase = passphrase
      end
      fixture.each { |key, value| Ideal::Gateway.send("#{key}=", value) }
      Ideal::Gateway.live_url = nil
    end

  end
end

def log(a, b)
  #$stderr.write("#{a}: #{b}")
end