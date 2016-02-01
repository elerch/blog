Cloudfront isn't particularly cloudformation friendly. We'll do some CLI stuff too.

Step 1 - Create an origin access identity

`
aws cloudfront create-cloud-front-origin-access-identity --cloud-front-origin-access-identity-config CallerReference=yomama,Comment=newstuff
`

We'll take the output of this and put it in the Cloudformation template.
Note that you need to turn on cloudfront preview commands on for this to
work.

Step 2 - Run cloudformation

`
aws cloudformation create-stack --stack-name blog-distribution --template-body file://cfn-cloudfront.json
`

Step 3 - Setup the SSL certificates via Amazon Certificate Manager

This is best done through the console with email setup. Renewals will
be handled automatically so it's probably better off than letsencrypt.org

Step 4 - Enable compression through the console

This is located on the behaviors tab

Step 5 - Select ACM certificate through the console

This option might be grayed out since it takes a while for the certificate
to propagate.