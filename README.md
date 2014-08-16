[![inventid logo](https://s3-eu-west-1.amazonaws.com/static-inventid-nl/content/img/logo.png)](http://opensource.inventid.nl)

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

_I need to elaborate on this once I acutally built something_

### Certificates

````bash
openssl genrsa -aes128 -out bestandsnaam.key -passout pass:wachtwoord 2048
openssl req -x509 -new -key bestandsnaam.key -passin pass:wachtwoord -days 1825 -out bestandsnaam.cer
````

### How to suggest improvements?

We are still actively developing Ideal for our internal use, but we would already love to hear your feedback. In case you have some great ideas, you may just [open an issue](https://github.com/inventid/ideal/issues/new). Be sure to check beforehand whether the same issue does not already exist.

### How can I contribute?

We feel contributions from the community are extremely worthwhile. If you use Ideal in production and make some modification, please share it back to the community. You can simply [fork the repository](https://github.com/inventid/ideal/fork), commit your changes to your code and create a pull request back to this repository.

If there are any issues related to your changes, be sure to reference to those. Additionally we use the `develop` branch, so create a pull request to that branch and not to `master`.

Additionally we always use [vagrant](http://www.vagrantup.com) for our development. To do the same, you can do the following:

1. Make sure to have [vagrant](http://www.vagrantup.com) installed.
1. Clone the repository
1. Open a terminal / shell script and nagivate to the place where you cloned the repository
1. Simply enter `vagrant up`
1. The Vagrant machine provisions and you can easily work with us. Enter `vagrant ssh` to get shell access to the machine. In case you are done with it, simply enter `vagrant destroy`. You won't lose any changes to your git repository when this happens.

### Collaborators

We would like to thank the developers which contributed to Ideal, both big and small.

- [rogierslag](https://github.com/rogierslag) (Lead developer of Ideal @ [inventid](https://www.inventid.nl))
