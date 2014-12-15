# PointHQ 2 Route53

Simple scripts that migrates domains from [PointHQ](https://pointhq.com) to [Amazon Route 53](http://aws.amazon.com/route53/).

## Usage

```
git clone https://github.com/prograils/pointhq2route53.git
cd pointhq2route53
bundle install
POINTHQ_USERNAME=__username__ POINTHQ_APITOKEN=__api_token__ ROUTE53_ACCESS_KEY=__aws_access_key__  ROUTE53_SECRET_KEY=__aws_secret_key__ bundle exec ./pointhq2route53.rb
```

Add additional environment variable `ROUTE53_DELETE_ZONES=1` if you want to delete ALL zones from your AWS Route53 account prior to migrating data.