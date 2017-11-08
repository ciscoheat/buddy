# Buddy

Your friendly BDD testing library for Haxe!

## Quickstart

1) Install the lib:

`haxelib install buddy`

2) Create a test file called **Main.hx**:

```haxe
using buddy.Should;

class Main extends buddy.SingleSuite {
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
using buddy.Should;

class Main extends buddy.SingleSuite {
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

The default timeout is 5000 ms, after which the spec will automatically fail if `done()` hasn't been called. If you want to change the timeout, set the property `timeoutMs` in the `BuddySuite` **before** the actual `it()` specification, or in the before/after block. Here's an example:

```haxe
using buddy.Should;

class Main extends buddy.SingleSuite {
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

You can set `timeoutMs` to 0 to disable the timeout check. **Note:** When using `function(done)`, on some targets the timeout check will run in a separate thread. Also, timeouts and asynchronous behavior aren't supported when targeting PHP or interp.

## Before/After

To setup tests, you can use `beforeAll`, `beforeEach`, `afterEach` and `afterAll`:

```haxe
using buddy.Should;

class BeforeAfterTest extends buddy.SingleSuite {
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

`a.should.be(b)` - Tests equality for value types (`Bool`, `Float`, `Int`, `Int64`, and the immutable `String`) and identity for the other (reference) types.

`a.should.beType(b)` - Tests if `a` is of type `b`. Basically a wrapper around `Std.is`.

### Int / Int64

`a.should.beLessThan(b)`

`a.should.beGreaterThan(b)`

### Float

Same as Int plus

`a.should.beCloseTo(b, p = 2)` - `a` should be close to `b` with `p` decimals precision, so you can easily compare floats without worrying about precision issues.

### String

`a.should.contain(substr)` - Test if `a` contains a given substring.

`a.should.match(regexp)` - Test if `a` matches a regular expression (`EReg`).

`a.should.startWith(substr)` - Test if `a` starts with a given substring.

`a.should.endWith(substr)` - Test if `a` ends with a given substring.

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

### Enum

`a.should.equal(b)` - Makes a deep equality check, using `Type.enumEq`. A warning will be given when enums are compared by `should.be`, since the result of that comparison is undefined.

### Exceptions

Testing if a function throws an exception is made easy using the special `bind` field which exists for every function.

If the function signature is `String -> Void` then apply the string argument like this:

`a.bind("test").should.throwValue("error")`

`a.bind("test").should.throwType(String)`

`a.bind("test").should.throwAnything()`

You can also test an anonymous function directly:
    
`(function() { throw "error"; }).should.throwType(String)`

The throw methods will return the exception object, so it can be tested further. This works synchonously only.

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

## Testing compilation failures

If you want to test if some part of your code fails to compile, guess what, there is a macro for that:

```haxe
import buddy.CompilationShould;

class Main extends buddy.SingleSuite
{
    public function new() {
        describe("Using CompilationShould", {
            it("should pass if an expression won't compile", {
                CompilationShould.failFor(this.will.not.compile);
            });
        });
    }
}
```

The method will return a string representation of the compilation failure, or an empty string if compilation succeded, in case you want to test it further.

## General error handling

Exceptions in `it` will be handled as above, but if something goes wrong in a `before/after` section, Buddy will stop executing the whole suite. It will also count as a failure.

If you're getting an early runtime error, you might want to disable the trace capture that buddy uses. You can do that globally by putting `BuddySuite.useDefaultTrace = true` in the beginning of a test class. Then you'll see the traces immediately instead of in the reporter.

Please note that putting code that should be tested outside a `describe`, `it` or any `before/after` block can result in undefined behavior.

## Pending tests

Since BDD is also made for non-programmers to use, a common development style is to write empty, or *pending* tests, and let a programmer implement them later. To do this, just write a string in the `it` methods, nothing else. Our previous test class would then look like this:

**Main.hx**

```haxe
using buddy.Should;

class Main extends buddy.SingleSuite
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

There is also a `pending(reason : String)` method available to make a spec pending, similar to `fail`.

## Including and excluding tests

Classes, suites and specs can all be marked with `@include` and `@exclude` metadata.

* `@include` will only run the tests that are marked, removing everything else.
* `@exclude` does the opposite, it removes the marked ones.

If you have a huge test suite, it can be convenient to mark the suite you're currently working on with `@include`.

## Multiple test suites

Extending `buddy.SingleSuite` is nice and simple, but you can have multiple test classes, and separate them from the main class if you like. Here's how to do it:

**Main.hx**

```haxe
import buddy.*;
using buddy.Should;

// Implement "Buddy" and define an array of classes within the brackets:
class Main implements Buddy<[
    Tests,
    path.to.YourBuddySuite,
    AnotherTestSuite,
    new SpecialSuite("Constant value", 123)
]> {}

// All test classes should now extend BuddySuite (not SingleSuite)
class Tests extends BuddySuite
{
    public function new() {
        describe("Using Buddy", {
            it("should be a great testing experience");
            it("should really make the tester happy");
        });
    }
}
```

## Customizing output and reporting

### Adding colors

Enable ANSI color output is easy:

```haxe
@colorize
class Main extends buddy.SingleSuite {
    // ...
}
```

Or you can do it when compiling with `-D buddy-colors`, or disallow it with `-D buddy-no-colors`.

The compilation flag will override the metadata, if both are set.

### Creating a custom reporter

You can make your own reporter by implementing the [buddy.reporting.Reporter](https://github.com/ciscoheat/buddy/blob/master/src/buddy/reporting/Reporter.hx) interface. Then there are two ways to use it:

```haxe
@reporter("path.to.your.Reporter")
class Main extends buddy.SingleSuite {
    // ...
}
```

Or do it when compiling with `-D reporter=path.to.your.Reporter`.

The compilation flag will override the metadata, if both are set.

### List of built-in Reporters

`buddy.reporting.ConsoleReporter` is the default reporter.

`buddy.reporting.ConsoleFileReporter` splits the test progress meter per file, in case you have many test suites in different files.

`buddy.reporting.TraceReporter` outputs to `trace()`, and is especially useful for CI with flash. If you define `-D flash-exit`, the default reporter will be the TraceReporter, and flash will exit if the correct permissions are set. This is tricky to get right, so the easiest way is to use [travix](https://github.com/back2dos/travix/).

## FAQ

### Where's main()?

Ok, you noticed that it was missing! Using some macro magic, you only need to extend `buddy.SingleSuite`, or alternatively implement `buddy.Buddy` on your Main class. Then platform-specific code will be generated for waiting until the tests are finished. On all server platforms, exit code 0 will be returned for "all tests passed" and 1 if not, so you can use Buddy in CI tools.

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

### Can I run the tests manually, without generating main?

Yes, but make sure you know what you're doing, for example some targets requires a wait loop if you have asynchronous tests... Here's a minimal setup for synchronous execution:

```haxe
import buddy.reporting.ConsoleColorReporter;

class Main {
    public static function main() {
        var reporter = new ConsoleReporter();

        var runner = new buddy.SuitesRunner([
            new FirstTestSuite(),
            new AnotherTestSuite()
        ], reporter);

        runner.run();
        
        #if sys
        Sys.exit(runner.statusCode());
        #end
    }
}
```

Please make sure that the auto-generated version doesn't work in your case, before doing this.

## The story behind Buddy

After my [speech about HaxeContracts](http://www.silexlabs.org/wwx2014-speech-andreas-soderlund-dci-how-to-get-ahead-in-system-architecture/) at WWX2014, I concluded that one does not simply bash unit testing without providing a nice alternative! Having used [Jasmine](http://jasmine.github.io/2.0/introduction.html) before, I borrowed some if its nice features, and found the perfect aid to implementing async support with the [promhx](https://github.com/jdonaldson/promhx) library.

The [HaxeContracts](https://github.com/ciscoheat/HaxeContracts) library is a nice complement to BDD, so check it out for more information about why most unit testing is waste, and why BDD is a better alternative...!

## Upcoming features

- [ ] Nicer browser reporter
- [ ] Your choice! Send me a gmail (ciscoheat) or create an issue here.

Have a good time and much productivity with your new Buddy! :)

[![Build Status](https://travis-ci.org/ciscoheat/buddy.svg?branch=master)](https://travis-ci.org/ciscoheat/buddy)
