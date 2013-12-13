notify_user
===========


TODO:
- Add indexes on notifications to migration generator.
- Test for presence of Sidekiq dependency. Disable aggregation if it's not there but otherwise work OK.
- Controller for listing notifications

TODO Later:
- aggregate based on an arbitrary key, so we can aggregate notifications of different types.
- read state

How to test aggregation?

Just create one having just sent.

LovedPostNotification.to().params().send
NotifyUser.type('').to('').params().send

What can we customise on each?
- Various messages: all view level
- Aggregation period
- Aggregation key
- Email layout?
- Email subject?

To run the tests:
```
rspec spec
```

To run the tests like Travis:
```
gem install wwtd
wwtd
```