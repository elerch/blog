---
title: "PKCS 11, OpenPGP, Yubikeys/Solokeys, and Windows AMIs"
date: 2019-12-02T16:16:48-07:00
draft: false
---

# Using single key for both PKCS#11 (PIV app on Yubikey) and OpenPGP/GnuPG

I was looking at creating a Windows instance on AWS EC2 over the weekend, and
I started thinking about the administrator password. In AWS on Linux and likely
other Unix-like OS's on EC2, you can provide a public SSH key and through the
magic of [cloud-init](https://cloud-init.io/), the public key is placed in the
.ssh directory of the user, [which varies based on the AMI chosen](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connection-prereqs.html#connection-prereqs-get-info-about-instance).

Windows on EC2, however, follows a different process. Here, the SSH public key
is used a generic public key. When the Administrator process is [set by EC2Launch](https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2launch.html#ec2launch-tasks),
That password is encrypted using the public key provided, then you can decrypt
the data with your private key. This can be done through the console, or with
the command line `aws ec2 get-password-data`. The console, however, requires
that you upload your private key, while the CLI version only encourages it.

In my setup, pretty much the only key pair I use is generated via
[gpg](https://gnupg.org/) on an airgapped machine running [Tails](https://tails.boum.org/).
The private key is copied to two USB sticks (primary and backup), then imported
onto a Yubikey NEO, which is still somewhat open source (Sorry, Yubico, but I
respectfully [disagree](https://www.yubico.com/2016/05/secure-hardware-vs-open-source/)).
I'm pretty happy with this arrangement, but it means that I can't provide my
private ssh key to an API or a console (nor would I want to).

I started thinking about how retrieval of this data could work in an environment
with a Yubikey or an HSM. GPG is strict about the data it decrypts - it must be
in the PGP format, which is **not** how [get-password-data](https://docs.aws.amazon.com/cli/latest/reference/ec2/get-password-data.html#examples)
provides it's data. Generally, the idea here is that if the private key is not
provided, the data will be returned encrypted and base 64 encoded. The idea
then is to base 64 decode the data, write a file out, and issue a command like
`openssl rsautil -decrypt -inkey mykey <mypassword.bin` to
decrypt it. That command may not work - it's just an example.

Without direct access to the private key, using a command such as the above is
not possible. Nor is the use of GPG. The solution, then, is to use the Yubikey's
support for [PKCS#11](https://en.wikipedia.org/wiki/PKCS_11). This is provided
by the [PIV](https://developers.yubico.com/PIV/) applet on the key. This applet,
however, has completely separate storage from the OpenPGP applet, so the keys,
PINs, etc are all managed separately, even if the concepts are shared between
OpenPGP (accessed by GPG) and PKCS#11 (accessed by PKCS client tools like
pkcs11_tool).

In an ideal world, then, what I'd like to have is a single key, loaded into
both OpenPGP and PIV applets, used for SSH access (via gpg-agent) and Windows
passwords (accessed via pkcs11_tool). If it were just a question of SSH, we
could remove GPG entirely, but I also use the GPG key for
[commit signing](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work),
so I'm in a GPG world anyway. The GPG key has separate subkeys for signing,
authentication and encryption, so that's good separation of duties. It's worth
considering that I'm breaking this separation with the procedure below and it
might be best to have two EC2 KeyPairs, one for Windows and one for SSH, but
the differences in the procedure amount to the selection of a different subkey,
and the rest is just discipline. GPG does the enforcement, and we're explicitly
taking out that enforcement.

Generally, what I was looking to do is the following:

* Export the gpg private and public key
* Convert the gpg private key to PEM format
* Load the private key into the PIV applet on the Yubikey
* Use PKCS#11 interface to decrypt the password data

## Step 0: Getting started

If you're like me and set up a GPG key with an expiration that needs to
periodically be extended, this process will need to repeat. However, this
particular step will only need to be done once. For that reason along with
the fact that [numbering should start at zero](https://www.cs.utexas.edu/users/EWD/transcriptions/EWD08xx/EWD831.html),
this one time only process will be step 0.

First things last: I had significant confusion when working with Yubikey and
PKCS#11. Nothing I did worked. I found that GPG agent (probably) was blocking
all PKCS#11 access. Simply removing and reinserting the key was able to unblock
me.

So we basically have a default key. Even if it was configured previously, none
of that has anything to do with PIV, so forget that. You'll need the
[yubico-piv-tool](https://developers.yubico.com/yubico-piv-tool/) to configure
the key. Even though it speaks PKCS#11, the configuration is unique to Yubikey.
[This gist](https://gist.github.com/faun/20b292ed2ccc36d7e4733d7329148dca)
does a good job describing the steps, however, it's focused on on-key generated
keys, which is a problem if the key is lost. For now, we'll just get the
Yubikey initialized, changing the three management pins to something other than
their default values:

```sh
  # Set the managment key: must be exactly 48 characters
  yubico-piv-tool -a set-mgm-key

  # Set the device PIN (user pin - default 123456)
  # Since this default is well known, it's ok to pass it on the command line
  yubico-piv-tool -a change-pin -P123456

  # Please set the device PUK (Admin pin - default 12345678)
  # Since this default is well known, it's ok to pass it on the command line
  yubico-piv-tool -a change-puk -P12345678
```

## Step 1: Export the gpg private and public key

This step is easy, but has it's nuances. Private keys should be handled with
extreme care. For me, that means the key is stored on a physically secured
USB key (with a secondary backup key), and all key operations are on an
airgapped computer running [Tails](https://tails.boum.org/). Since these
files are only used for this process, they can be managed from on the tails
filesystem, which will be wiped on shutdown.

```sh
  # Replace mykey with the uid of your key. This is often your email address.
  # It can be seen in the command gpg --list-keys on one of the uid lines
  # If you have multiple uid lines, any one of them will work
  gpg --export-secret-key mykey > mykey.gpg # OpenPGP format secret key
  gpg --export-ssh-key mykey > mykey.pub    # OpenSSH format public key
```

At this stage, we'll have the public key in OpenSSH format documented in
[RFC 4253](https://tools.ietf.org/html/rfc4253#section-6.6). This will work
for our needs. However, the GPG private key is in the [OpenPGP Message Format
for key material](https://tools.ietf.org/html/rfc4880#section-5.5) and as such
needs a conversion to [PEM format](https://en.wikipedia.org/wiki/Privacy-enhanced_Electronic_Mail)
to be useful.

## Step 2: Convert the GPG private key

At this stage, we need another tool. The [MonkeySphere project](https://web.monkeysphere.info/)
is focused on expanding GPG to other uses, and the packages they provide
allow for conversion of keys among other things. So, we can just use the
tool they provide to do the conversion. However, there is one caveat: the tool
cannot convert password-protected keys. If you've been managing keys securely
you certainly have a password protected key, so we need to remove this. It is for
this reason you really want to do this on an ephemeral file system. We'll use
the `gpg --homedir` option to override the normal home directory. Choose
something that will self-destruct, remove the passwords from the key, do another
export, and the conversion can work. This looks like the following:

```sh
  # Replacements:
  #
  # * ephemeralDirectory: your ephemeral directory name
  # * mykey.gpg: your exported file from Step 1
  # * mykey: key uid, which will be output during the gpg import command
  #          when it says key <keyid> public key "your uid" imported
  # * DD53AC86: This is the key id from the authentication subkey of your
  #             key. Get this id from the command
  #             gpg --list-keys --with-subkey-fingerprint
  #             Look for the line that says something like
  #             sub rsa2048 <date> [A]
  #             A is for Authentication, and is what is used for SSH
  #             The key id is the **last** 8 characters of the next line
  gpgtemphome=myephemeralDirectory
  mkdir $gpgtemphome
  chmod 700 $gpgtemphome
  cd $gpgtemphome
  gpg --homedir $gpgtemphome --import mykey.gpg # you will be prompted for the password here
  gpg --homedir $gpgtemphome --passwd mykey     # At this point, you will be prompted
                                                # for new passwords, leave them
                                                # blank, then confirm that you want
                                                # a blank password. This will likely
                                                # happen 3 times, once for each
                                                # of the subkeys of the imported key
  gpg --homedir $gpgtemphome --export-secret-key mykey > "mykey.gpg.nopass"
  openpgp2ssh DD53AC86 < "mykey.gpg.nopass" >mykey.pem # pem format secret key
```

If you were successful, you'll have a PEM format secret key file in
`$gpgtemphome/mykey.pem` that can be now be loaded onto the Yubikey. The
hard part is now done.

## Step 3: Load the private key into the PIV applet on the Yubikey

All PKCS#11 operations on the Yubikey work in [slot 9a](https://www.yubico.com/smart-card/).
So, we need to load the key into slot 9a of the PIV applet. It's almost, but not
quite, that simple. For this to operate correctly, we need a self-signed cert
rather than just the key. The following commands will import the key, create
the cert, and load it. Most of these commands will also require the management
key to operate successfully. Anytime you see `-k` below, you'll be prompted.

Note that pin-policy and touch-policy parameters only apply to Yubikey 4. I'm
working with the (sort of) open source Yubikey Neo. You may want to adjust
these to your taste. The `-v` turns on verbose mode, which I found helpful
when the terminal wasn't pasting the management key.

```sh
  # This will prompt for the management key, without which you cannot import the key
  # Replace mykey.pem as appropriate
  yubico-piv-tool -s 9a -a import-key -i mykey.pem -k --pin-policy=once --touch-policy=always -v

  # Generate the the certificate to load. Replace mykey.pub with the file
  # exported in Step 1
  ssh-keygen -e -f mykey.pub -m PKCS8 > mykey.pub.pkcs8

  # Replace mykey.pub.pkcs8 name as appropriate from the command above. This creates a "mykey-cert.pem" file
  # Yubikey piv tool requires the file to be named with a pem suffix, so don't get fancy with the file sufix above
  yubico-piv-tool -a verify -a selfsign-certificate -s 9a -S "/CN=SSH" -i mykey.pub.pkcs8 -o mykey-cert.pem

  # Finally, we can import the certificate we generated into slot 9a.
  # This will ask for the management key
  # Yubikey piv tool requires the file to be named with a pem suffix, so don't get fancy with the file sufix above
  yubico-piv-tool -a verify -a import-certificate -s 9a -i mykey-cert.pem -k
```

At this point, you should be able to verify the key is properly loaded on the
Yubikey. Your gpg exported ssh public key (in my example, "mykey.pub") should
match what comes off the Yubikey via PKCS#11. The ssh key from gpg will have a
comment - the command below uses the Unix command cut to strip that out.
As usual, replace the mykey.pub name with the name you used:

```sh
[ "$(cut -f1-2 -d' ' <mykey.pub)" = "$(ssh-keygen -D /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so -e)" ] && \
  echo 'File and smartcard match'
```

With any luck, you should see the output ```File and smartcard match```. If you
don't, something went wrong. You can also test encrypt/decrypt operations with
something like this:

```sh
echo 'it worked' | openssl pkeyutl -encrypt -inkey mykey.pem -pubin > encrypted.bin
pkcs11-tool --decrypt -v -l --input-file encrypted.bin  -m RSA-PKCS # Prints 'it worked'
```

That should execute without errors and print 'it worked'. From the first test
we know that the ssh key is properly loaded in slot 9a, and the second proves
that decryption from the Yubikey using PKCS#11 works properly.

We're done, and you can now delete the files we've been generating along the
way. In my example, that's:

* mykey.pub
* mykey-cert.pem
* mykey.pub.pkcs8
* mykey.pem
* mykey.gpg.nopass
* mykey.gpg
* encrypted.bin (if you ran the last test)

Assuming you're doing this on an airgapped computer, go ahead and shut down and
remove the Yubikey.

## Step 4: Use PKCS#11 interface to decrypt the password data

We're loaded up. If you're doing all this for the same reasons as I, go ahead
and [launch an EC2 Windows instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/LaunchingAndUsingInstances.html).
You'll need to establish an [EC2 keypair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws)
if you don't already have one, and specify that key pair when you launch the
instance.

Once the instance has launched, we'll use the CLI command [get-password-data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws)
to retrieve our data. It comes in a JSON format, base64 encoded, so the
command will look like the below. Note we need a file as the pkcs11_tool does
not read from stdin (as it needs to prompt for the user PIN). Also,
the password is not established immediately, so you may need to wait a bit
for the data to appear.

```sh
aws ec2 get-password-data --instance-id <blah> --query PasswordData --output text| base64 -d > encrypted-adminpass.bin
pkcs11-tool --decrypt -v -l --input-file encrypted-adminpass.bin -m RSA-PKCS
```

## Connecting to the Windows instance.

There may be an issue connecting, as newer Windows AMIs enable NLA by default.
[Simple Systems Manager](https://docs.aws.amazon.com/systems-manager/index.html)
has an agent installed by default, so in these cases you can attach an appropriate
IAM role and issue the following command, replacing the instance id below
with yours:

```sh
aws ssm start-automation-execution --document-name "AWSSupport-ManageRDPSettings" --parameters "InstanceId=i-03033520993ddf97f,NLASettingAction=Disable"
```

## But wait, what does all this have to do with Solokeys?!

The [Solokey](https://solokeys.com/) is a truly open source security key. For
now, it handles only Fido2 and U2F. However, they're working on [OpenPGP](https://github.com/solokeys/openpgp)
support. PKCS#11 would be over and above, but it's possible with something like
[scute](www.scute.org) that PKCS#11 support could be provided via OpenPGP.
In this process, however, I've heard rumblings that scute is somewhat unstable.
It's also unclear whether the authentication subkey would be allowed to work
for decryption in this particular use case.

## More information

The following posts/links helped me immensely on this journey:

* https://gist.github.com/faun/20b292ed2ccc36d7e4733d7329148dca
* https://medium.com/google-cloud/google-cloud-ssh-with-os-login-with-yubikey-opensc-pkcs11-and-trusted-platform-module-tpm-based-86fa22a30f8d
* http://gnupg.10057.n7.nabble.com/Private-key-export-for-SSH-td49236.html
* https://blog.rchapman.org/posts/Import_an_existing_ssh_key_into_Yubikey_NEO_applet/
