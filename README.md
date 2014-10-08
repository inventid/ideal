[![inventid logo](https://s3-eu-west-1.amazonaws.com/static-inventid-nl/content/img/logo.png)](http://opensource.inventid.nl)

[![Gem Version](https://badge.fury.io/rb/ideal-payment.svg)](http://badge.fury.io/rb/ideal-payment)

# Ideal
| Branch | Build status | Code coverage |
|---|---|---|
| Master |[![Build Status](https://travis-ci.org/inventid/ideal.svg?branch=master)](https://travis-ci.org/inventid/ideal)|[![Coverage Status](http://img.shields.io/coveralls/inventid/ideal/master.svg)](https://coveralls.io/r/inventid/ideal?branch=master)|
| Develop |[![Build Status](https://travis-ci.org/inventid/ideal.svg?branch=develop)](https://travis-ci.org/inventid/ideal)|[![Coverage Status](http://img.shields.io/coveralls/inventid/ideal/develop.svg)](https://coveralls.io/r/inventid/ideal?branch=develop)|

## What is it?

Ideal is a simple Ruby 2.1 compliant gateway to contact any banks using the Dutch iDeal protocol.
Since there was no decent one available, we decided to develop our own.
And now you can use it too!

## How to use it?

Using it is quite simple, you can simply clone the code and then require it (_we plan to release a gem later_).

### Preparing certificates

iDeal requires client certificates.
You have to generate these yourself (or buy one from a Certificate Authority, but that's just wasting money in this case).
Additionally you need the certificate from your acquirer, which is supplied through their dashboard.

The following code generates the certificate and key.
Replace _PASSWORD_ with your actual password.

````bash
openssl genrsa -aes128 -out private.key -passout pass:PASSWORD 2048
openssl req -x509 -new -key private.key -passin pass:PASSWORD -days 1825 -out certificate.cer
````

### Using a fixture

Fixtures are a great way not to have all these constants in your code, a server administrator may even override them with tools as Puppet.

The fixture is equal to the one in the test.

````yaml
default:
  acquirer: rabobank
  merchant_id: '002054205'
  passphrase: wachtwoord
  private_key_file: ../certs/bestandsnaam.key
  private_certificate_file: ../certs/bestandsnaam.cer
  ideal_certificate_file: ../certs/ideal.cer
````

which can be later loaded with the following code

````ruby
file = File.join(File.dirname(__FILE__), 'fixtures.yml')
fixtures ||= YAML.load(File.read(file))
fixture = fixtures[key] || raise(StandardError, "No fixture data was found for key '#{key}'")
if passphrase = fixture.delete('passphrase')
  Ideal::Gateway.passphrase = passphrase
end
fixture.each { |key, value| Ideal::Gateway.send("#{key}=", value) }
````

### Not using a fixture

Well, also an option.
Codewise it might even be a bit cleaner :wink: although deployment is harder

````ruby
# Other banks preloaded are :abnamro and :rabobank
Ideal::Gateway.acquirer = :ing
Ideal::Gateway.merchant_id = '00123456789'

# Maybe you'd like another location
ideal_directory = Rails.root + 'config/ideal'
Ideal::Gateway.passphrase = 'the_passphrase'
Ideal::Gateway.private_key_file         = ideal_directory + 'private_key.pem'
Ideal::Gateway.private_certificate_file = ideal_directory + 'private_certificate.cer'
Ideal::Gateway.ideal_certificate_file   = ideal_directory + 'ideal.cer'
````

### Getting a list of issuers

This does the explicit call to your acquirer.
Since the list of issuers hardly ever changes, you could better (performance-wise) cache the result for 48 hours.

````ruby
Ideal::Gateway.new.issuers.list
````

### Requesting a payment

For this we need to send a Transaction Request to our acquirer with the following code

````ruby
attributes = {
  # The customer has 30 minutes to complete the iDeal transaction (ISO 8601)
  :expiration_period => "PT30M",
  :issuer_id         => issuer_id,
  :return_url        => return_url,
  :order_id          => '14',
  :description       => 'Probably awesomeness',
  :entrance_code     => 'secretCode'
}
response = ideal.setup_purchase(5.00 , ideal_attributes)
if response.success?
  # Save the data, then redirect
  redirect_to response.service_url
else
  # Log something
end
````

### Requesting the payment status

The merchant has the obligation to request a final status once the timeout has expired.

````ruby
status = ideal.capture(transaction_id)
if status.success?
  # Save the data as paid
end
````

## How to suggest improvements?

We are still actively developing Ideal for our internal use, but we would already love to hear your feedback. In case you have some great ideas, you may just [open an issue](https://github.com/inventid/ideal/issues/new). Be sure to check beforehand whether the same issue does not already exist.

## How can I contribute?

We feel contributions from the community are extremely worthwhile. If you use Ideal in production and make some modification, please share it back to the community. You can simply [fork the repository](https://github.com/inventid/ideal/fork), commit your changes to your code and create a pull request back to this repository.

If there are any issues related to your changes, be sure to reference to those. Additionally we use the `develop` branch, so create a pull request to that branch and not to `master`.

Additionally we always use [vagrant](http://www.vagrantup.com) for our development. To do the same, you can do the following:

1. Make sure to have [vagrant](http://www.vagrantup.com) installed.
1. Clone the repository
1. Open a terminal / shell script and nagivate to the place where you cloned the repository
1. Simply enter `vagrant up`
1. Provisioning takes around 5 minutes on my PC. If you want it to be faster you can use the `userConfig.json` file in the root and override the specific settings for memory and CPU.
1. The Vagrant machine provisions and you can easily work with us. Enter `vagrant ssh` to get shell access to the machine. In case you are done with it, simply enter `vagrant destroy`. You won't lose any changes to your git repository when this happens.

## Collaborators

We would like to thank the developers which contributed to Ideal, both big and small.

- [rogierslag](https://github.com/rogierslag) (Lead developer of Ideal @ [inventid](https://www.inventid.nl))
- [joostverdoorn](https://github.com/joostverdoorn) (Developer of Ideal @ [inventid](https://www.inventid.nl))
