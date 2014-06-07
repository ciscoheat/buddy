# Buddy

Your friendly BDD testing library for Haxe!

## Quickstart

1) Install the lib: 

`haxelib install buddy`

2) Create a test file:

**Main .hx**

```actionscript
package ;
import buddy.*;
using buddy.Should;

// "implements Buddy" is only required for the Main class.
class Main extends BuddySuite implements Buddy {
    public function new() {
        // A test suite:
        describe("Using Buddy", {
            var experience = "?";
            var mood = "?";

            // Executed before each "it":
            before({ 
                experience = "great";
            });
    
            it("should be a great testing experience", {
                experience.should.equal("great");
            });
          	
            it("should really make the tester happy", {
                mood.should.equal("happy");
            });
          	
            // Executed after each "it":
            after({
                mood = "happy";
            });
        });
    }
}
```

3) Make a quick test in Neko, and see the results right away:

`haxe -lib buddy -main Main -x Buddy.n`

```
..
Using Buddy
  should be a great testing experience (Passed)
  should really make the tester happy (Passed)
2 specs, 0 failures, 0 pending
```

But of course you shouldn't stop there. Try using it on other targets than Neko, Buddy supports them all!

## Asynchronous support

Buddy was built from the ground up to have great support for async testing, so it's fully compatible with NodeJS and handles ajax requests with ease. To use it, you just create the specification with a function that takes one argument (targeting javascript now):

```actionscript
package ;
import buddy.*;
using buddy.Should;

class AsyncTest extends BuddySuite {
    public function new() {
        describe("Using Buddy asynchronously", {
            var mood = "?";
            
            before(function(done) {
                haxe.Timer.delay(function() { 
                    mood = "thrilled"; 
                    done(); // Call the done() function when the async operation is complete.
                }, 100);
            });

            it("cannot really be described in one sentence", {
                mood.should.equal("thrilled");
            });
        });
    }
}
```

## Where's main() ?

Ok, you noticed that it was missing! Using some macro magic, you only need to implement `buddy.Buddy` on your Main class and it will create a `main()` method, autodetect all existing subclasses of `buddy.BuddySuite` and run them automatically at startup. Static entrypoints are so 2013, don't you think? :)

At this early point there is no ultra-convenient way of customizing how the tests are run, but if you really want to run your tests manually, use the `buddy.internal.SuitesRunner` class together with a `buddy.reporting.ConsoleReporter`, or make your own reporter by implementing the [buddy.reporting.Reporter](https://github.com/ciscoheat/buddy/blob/master/src/buddy/reporting/Reporter.hx) interface.

## The story behind Buddy

After my speech about Contracts at [WWX2014](wwx.silexlabs.org/2014/), I concluded that one does not simply bash unit testing without providing a nice alternative! Having used [Jasmine](http://jasmine.github.io/2.0/introduction.html) before, I borrowed some if its nice features, and found the perfect aid to implementing async support with the [promhx](https://github.com/jdonaldson/promhx) library.

The [HaxeContracts](https://github.com/ciscoheat/HaxeContracts) library is a nice complement to BDD, so check it out for more information about why most unit testing is waste, and why BDD is a better alternative...!

## Upcoming features

- [ ] More assertions for "should". 
- [ ] Ways to customize running and reporting of test suites.
- [ ] Nicer reporters (especially for the browser) with stack traces for failures.
- [ ] Tutorial for general guidelines when doing BDD.
- [ ] Your choice! Send me a gmail (ciscoheat) or create an issue here.

Have a good time and much productivity with your new Buddy! :)
