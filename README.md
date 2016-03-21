# Buddy

Your friendly BDD testing library for Haxe!

## Quickstart

1) Install the lib:

`haxelib install buddy`

2) Create a test file called **Main.hx**:

```haxe
import buddy.*;
using buddy.Should;

// Add test classes within the brackets
class Main implements Buddy<[Tests]> {}

// Test classes should extend BuddySuite
class Tests extends BuddySuite {
    public function new() {
        // A test suite:
        describe("Using Buddy", {
            var experience = "?";
            var mood = "?";

            beforeEach({
                experience = "great";
            });

            it("should be a great testing experience", {
                experience.should.be("great");
            });

            it("should make the tester really happy", {
                mood.should.be("happy");
            });

            afterEach({
                mood = "happy";
            });
        });
    }
}
```

3) Make a quick test:

`haxe -x Main -lib buddy`

```
..
Using Buddy
  should be a great testing experience (Passed)
  should make the tester really happy (Passed)
2 specs, 0 failures, 0 pending
```

But please don't stop there. Try using it on other targets than Neko, Buddy supports them all on both Windows and Linux! The only thing you need to remember is to add `-D nodejs` to your hxml, if you're targeting Node.js.

## Asynchronous support

Buddy was built from the ground up to have great support for async testing, so it's fully compatible with Node.js and handles ajax requests with ease. To use it, just create the specification with a function that takes one argument (targeting javascript now):

```haxe
import buddy.*;
using buddy.Should;

class Main implements Buddy<[AsyncTest]> {}

class AsyncTest extends BuddySuite {
    public function new() {
        describe("Using Buddy asynchronously", {
            var mood = "?";

            // Add function(done) here to enable async testing:
            beforeAll(function(done) {
                haxe.Timer.delay(function() {
                    mood = "thrilled";
                    done(); // Call the done() function when the async operation is complete.
                }, 100);
            });

            // Can be added to "it" and "after" as well if needed.
            it("can be described in a certain word", {
                mood.should.be("thrilled");
            });
        });
    }
}
```

The default timeout is 5000 ms, after which the spec will automatically fail if `done()` hasn't been called, or in the case of synchronous tests, if it hasn't returned. If you want to change the timeout, set the property `timeoutMs` in the `BuddySuite` **before** the actual `it()` specification, or in the before/after block. Here's an example:

```haxe
import buddy.*;
using buddy.Should;

class Main implements Buddy<[AsyncTest]> {}

class AsyncTest extends BuddySuite {
    public function new() {
        describe("Using Buddy asynchronously", {
            timeoutMs = 100;
            it("should fail specs after a timeout set before it()", function(done) {
                // This test will fail after 100 ms.
                haxe.Timer.delay(done, 200);
            });
        });
    }
}
```

You can set `timeoutMs` to 0 to disable the timeout check. **Note:** Timeouts and asynchronous behavior aren't supported when targeting PHP.

## Before/After

To setup tests, you can use `beforeAll`, `beforeEach`, `afterEach` and `afterAll`:

```haxe
class BeforeAfterTest extends BuddySuite {
    public function new() {
        describe("Using before/after", {
            var test = 0;

            // Will run once as the first thing in the current describe block
            beforeAll({
                test++;
            });

            // Will run before each "it" in the current and before each "it" in any nested describes.
            beforeEach({
                test++;
            });

            it("should be a convenient way to set up tests", {
                test.should.be(2);
            });

			describe("When nesting describes", {
				beforeEach({
					test++;
				});
				
				it("should run all before/afterEach defined here or above", {
					test.should.be(3);
				});
				
				afterEach({
					test--;
				});
			});
			
			it("should run in correct order too", {
				test.should.be(2);
			});

            // Will run after each "it" in the current and before each "it" in any nested describes.
            afterEach({
                test--;
            });

            // Will run once as the last thing in the current describe block
            afterAll({
                test--;
            });
        });
    }
}
```

## "Should" assertions

As you've seen in the examples, testing if specifications are correct is as simple as adding `using Buddy.should` to the package and then use the `should` extension for the identifier you want to test. The following assertions are supported:

### All types

`a.should.be(b)` - Tests equality for value types (`Bool`, `Float`, `Int` and the special `String`) and identity for the other (reference) types.

`a.should.beType(b)` - Tests if `a` is of type `b`. Basically a wrapper around `Std.is`.

### Int

`a.should.beLessThan(b)`

`a.should.beGreaterThan(b)`

### Float

Same as Int plus

`a.should.beCloseTo(b, p = 2)` - `a` should be close to `b` with `p` decimals precision, so you can easily compare floats without worrying about precision issues.

### String

`a.should.contain(substr)` - Test if `a` contains a given substring.

`a.should.match(regexp)` - Test if `a` matches a regular expression (`EReg`).

### Date

`a.should.beOn(date)` - Test if `a` is on a given date

`a.should.beOnStr(string)` - Test if `a` is on a date specified by a string in the [Date.fromString](http://api.haxe.org/Date.html#fromString) accepted formats.

`a.should.beBefore(date)` - Test if `a` is before a given date.

`a.should.beBeforeStr(string)` - Same as above, but specified by a string.

`a.should.beAfter(date)` - Test if `a` is after a given date.

`a.should.beAfterStr(string)` - Same as above, but specified by a string.
    
### Iterable<T>

`a.should.contain(b)` - Test if an Iterable contains `b`.

`a.should.containAll(b)` - Test if an Iterable contains all objects in Iterable `b`.

`a.should.containExactly(b)` - Test if an Iterable contains exactly the same objects as in Iterable `b` and in the same order.

### Exceptions

Testing if a function throws an exception is made easy using the special `bind` field which exists for every function.

If the function signature is `String -> Void` then apply the string argument like this:

`a.bind("test").should.throwValue("error")`

`a.bind("test").should.throwType(String)`

`throwValue` and `throwType` will return the exception object, so it can be tested further. This works synchonously only.

### Inverting assertions

Every assertion can be negated using `not` which is present on all `should` fields:

`a.should.not.contain("test")`

## Failing tests

A test can be failed using the `fail(o : Dynamic) : Void` method available in a `BuddySuite`. The test will fail with the string value of `o` as a message. If you're testing asynchronously you can pass the `fail` method to the error handler. Here are some examples:

```haxe
it("should fail manually when using fail()", {
    fail("Totally on purpose.");
});

it("should fail if a promise fails", function(done) {
    request.getJson("/some/url")
    .then(function(r) {
        r.statusCode.should.be(200);
        done();
    })
    .catchError(fail);
});

it("should also fail when throwing an exception", {
    throw "But only synchronously!";
});
```

## General error handling

Exceptions in `it` will be handled as above, but if something goes wrong in a `before/after` section, Buddy will stop executing the whole `BuddySuite`, and move to the next one. This is in case there are many large test suites. It will also count as a failure.

## Pending tests

Since BDD is also made for non-programmers to use, a common development style is to write empty, or *pending* tests, and let a programmer implement them later. To do this, just write a string in the `it` methods, nothing else. Our previous test class would then look like this:

**Main.hx**

```haxe
import buddy.*;

// Combining extends and implements this time
class Main extends BuddySuite implements Buddy<[Main]>
{
    public function new() {
        describe("Using Buddy", {
            it("should be a great testing experience");
            it("should really make the tester happy");
        });
    }
}
```

And the output would be:

```
PP
Using Buddy
  should be a great testing experience (Pending)
  should really make the tester happy (Pending)
2 specs, 0 failures, 2 pending
```

There is also a `pending` method available to make a spec pending, similar to `fail`.

## Including and excluding tests

Classes, suites and specs can all be marked with `@include` and `@exclude`. `@include` will only run the tests that are marked, `@exclude` does the opposite, it prevents the marked ones from running. If you have a huge test suite, it can be convenient to mark the suite you're currently working on with `@include`. You can also use `xit()` and `xdescribe()` to exclude specs and suites from running.

## Customizing reporting

If the default console reporter isn't to your liking, you can make your own reporter by implementing the [buddy.reporting.Reporter](https://github.com/ciscoheat/buddy/blob/master/src/buddy/reporting/Reporter.hx) interface. Then there are two ways to use it:

### Metadata

```haxe
@reporter("path.to.your.Reporter")
class Main implements Buddy<[Tests]> {}
```

### Compilation flag

`-D reporter=path.to.your.Reporter`

The compilation flag will override the metadata, if both are set.

### List of built-in Reporters

`buddy.reporting.ConsoleReporter` is the default reporter.

`buddy.reporting.TraceReporter` outputs to `trace()`, and is especially useful for CI in Flash together with the `-D fdb-ci` compiler flag. See the [travis flash script](https://github.com/ciscoheat/buddy/blob/master/flash-travis-setup.sh) and the [flash hxml](https://github.com/ciscoheat/buddy/blob/master/buddy.flash.hxml), hopefully you can get some help from there.

`buddy.reporting.TravisHxReporter` is made for [travis-hx](https://github.com/waneck/travis-hx) which is a standardized solution for using [Travis](https://travis-ci.org/) with Haxe. Very nice!

## FAQ

### Where's main()?

Ok, you noticed that it was missing! Using some macro magic, you only need to implement `buddy.Buddy` on your Main class and specify an array of test suites within the type brackets like so: 

```haxe
class Main implements buddy.Buddy<[
    path.to.YourBuddySuite,
    AnotherTestSuite,
    new SpecialSuite("Constant value", 123)
]> {}
```

The advantage of implementing `Buddy` is that platform-specific code for waiting until the tests are finished will be generated. On all server platforms, exit code 0 will be returned for "all tests passed" and 1 if not, so you can easily use Buddy in CI tools.

### Autocompletion sometimes doesn't work for "x.should." or numbers.

The compiler seems to be a bit too good at optimizing sometimes, especially at the beginning of functions, though this seems to have improved greatly in 3.2. If you have this problem, add a parenthesis after "should", and wrap numbers in parenthesis too.

`x.should.be("ok")` -> `x.should().be("ok")`

`123.should.beGreaterThan(100)` -> `(123).should.beGreaterThan(100)`

### Can I use other assertion libraries than the built-in 'should'?

Yes, there is special support for [utest](http://code.google.com/p/utest/) and general support for all libraries that throws an exception on failure (like [mockatoo](https://github.com/misprintt/mockatoo) ). To use utest, just call any `utest.Assert` method inside a spec, no need to set up anything else.

### There's an exception thrown in an asynchronous method, but Buddy won't catch it and fail the test?

It's not possible to do that, since the program has already passed the exception handling code when the exception is thrown. You need to handle asynchronous exceptions yourself and test if something went wrong before calling `done` in the spec, or use the `fail` method as described in the section "Failing tests".

### I'm having problem compiling with C++

This usually happens if you're not linking in the correct `.ndll` files. An easy fix is to add `-lib hxcpp` to your hxml. Another problem could be fixed by adding `-D HXCPP_M64` if you're targeting C++ on a 64bit platform (seems to vary between Linux and Win).

## The story behind Buddy

After my [speech about HaxeContracts](http://www.silexlabs.org/wwx2014-speech-andreas-soderlund-dci-how-to-get-ahead-in-system-architecture/) at WWX2014, I concluded that one does not simply bash unit testing without providing a nice alternative! Having used [Jasmine](http://jasmine.github.io/2.0/introduction.html) before, I borrowed some if its nice features, and found the perfect aid to implementing async support with the [promhx](https://github.com/jdonaldson/promhx) library.

The [HaxeContracts](https://github.com/ciscoheat/HaxeContracts) library is a nice complement to BDD, so check it out for more information about why most unit testing is waste, and why BDD is a better alternative...!

## Upcoming features

- [ ] Nicer reporters (especially for the browser) with stack traces for failures.
- [ ] Your choice! Send me a gmail (ciscoheat) or create an issue here.

Have a good time and much productivity with your new Buddy! :)

[![Build Status](https://travis-ci.org/ciscoheat/buddy.svg?branch=master)](https://travis-ci.org/ciscoheat/buddy)
