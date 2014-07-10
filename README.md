# Buddy

Your friendly BDD testing library for Haxe!

## Quickstart

1) Install the lib:

`haxelib install buddy`

2) Create a test file:

**Main.hx**

```haxe
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
                experience.should.be("great");
            });

            it("should really make the tester happy", {
                mood.should.be("happy");
            });

            // Executed after each "it":
            after({
                mood = "happy";
            });
        });
    }
}
```

3) Make a quick test:

`haxe -lib buddy -main Main --interp`

```
..
Using Buddy
  should be a great testing experience (Passed)
  should really make the tester happy (Passed)
2 specs, 0 failures, 0 pending
```

But of course you shouldn't stop there. Try using it on other targets than Neko, Buddy supports them all on both Windows and Linux! The only thing you need to remember is to add `-D nodejs` if you're targeting Node.js, and `-D HXCPP_M64` if you're targeting C++ on a 64bit platform (that one seems to vary between Linux and Win though).

## Asynchronous support

Buddy was built from the ground up to have great support for async testing, so it's fully compatible with Node.js and handles ajax requests with ease. To use it, just create the specification with a function that takes one argument (targeting javascript now):

```haxe
package ;
import buddy.*;
using buddy.Should;

class AsyncTest extends BuddySuite {
    public function new() {
        describe("Using Buddy asynchronously", {
            var mood = "?";

            // Add function(done) here to enable async testing:
            before(function(done) {
                haxe.Timer.delay(function() {
                    mood = "thrilled";
                    done(); // Call the done() function when the async operation is complete.
                }, 100);
            });

			// Can be added to "it" and "after" as well if needed.
            it("cannot really be described in one sentence", {
                mood.should.be("thrilled");
            });
        });
    }
}
```

The default timeout is 5000 ms, after which the spec will automatically fail if `done()` hasn't been called. If you want to change the timeout, set the property `timeoutMs` in the `BuddySuite` **before** the actual `it()` specification, or in the before/after block. Here's an example:

```haxe
package ;
import buddy.*;
using buddy.Should;

class AsyncTest extends BuddySuite {
    public function new() {
        describe("Using Buddy asynchronously", {
            this.timeoutMs = 100;
            it("should fail specs after a timeout set before it()", function(done) {
                // This test will fail after 100 ms.
                haxe.Timer.delay(done, 200);
            });
        });
    }
}
```

## Should assertions

As you've seen in the examples, testing if the specifications are correct is as simple as adding `using Buddy.should` to the package and then use the `should` extension for the identifier you want to test. The following assertions are supported:

### All types

`a.should.be(b)` - Tests for equality for value types (`Bool`, `Float`, `Int`) and identity for the other (reference) types.

### Int

`a.should.beLessThan(b)`

`a.should.beGreaterThan(b)`

### Float

Same as Int plus

`a.should.beCloseTo(b, p = 2)` - `a` should be close to `b` with `p` decimals precision, so you can easily compare floats without worrying about precision issues.

### String

`a.should.contain(substr)` - Test if `a` contains a given substring.

`a.should.match(regexp)` - Test if `a` matches a regular expression (`EReg`).

### Iterable<T>

`a.should.contain(b)` - Test if an Iterable contains `b`.

`a.should.containAll(b)` - Test if an Iterable contains all objects in Iterable `b`.

`a.should.containExactly(b)` - Test if an Iterable contains exactly the same objects as in Iterable `b` and in the same order.

### Exceptions

Testing if a function throws an exception is made easy using the special `bind` field which exists for every function.

If the function signature is `String -> Void` then apply the string argument like this:

`a.bind("test").should.throwValue("error")`

`a.bind("test").should.throwType(String)`

### Inverting assertions

Every assertion can be negated using `not` which is present on all `should` fields:

`a.should.not.contain("test")`

## Pending tests

Since BDD is also made for non-programmers to use, a common development style is to write empty, or *pending* tests, and let a programmer implement them later. To do this, just write the string in the `describe` and `it` methods. Our previous test class would then look like this:

**Main.hx**

```haxe
package ;
import buddy.*;

class Main extends BuddySuite
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

If good domain terms are used that matches the system architecture, the programmer should be able to implement system or integration tests that matches the users mental model of the system. (See [haxedci](https://github.com/ciscoheat/haxedci-example) for more details how to achieve this using the DCI architecture!)

## Including and excluding tests

Classes, suites and specs can all be marked with `@include` and `@exclude`. `@include` will only run the tests that are marked, `@exclude` does the opposite, it prevents the marked ones from running. If you have a huge test suite, it can be convenient to mark the suite you're currently working on with `@include`. You can also use `xit()` and `xdescribe()` to exclude specs and suites from running.

## FAQ

### Where's main() ?

Ok, you noticed that it was missing! Using some macro magic, you only need to implement `buddy.Buddy` on your Main class and it will create a `main()` method, autodetect all existing subclasses of `buddy.BuddySuite` and run them automatically at startup. Static entrypoints are so 2013, don't you think? :) On all server platforms, exit code 0 will be returned for "all tests passed" and 1 if not, so you can use Buddy in CI tools.

At this early point there is no ultra-convenient way of customizing how the tests are run, but if you really want to run your tests manually, use the `buddy.SuitesRunner` class together with a `buddy.reporting.ConsoleReporter`, or make your own reporter by implementing the [buddy.reporting.Reporter](https://github.com/ciscoheat/buddy/blob/master/src/buddy/reporting/Reporter.hx) interface.

### Can I include only specific packages?

The build macro used will by default include all `.hx` files in the class path so it can find the relevant subclasses of `buddy.BuddySuite` without you having to import them manually. If you would prefer to control which packages are imported, you can call the build macro manually:

```haxe
@:build(buddy.GenerateMain.build(["pack1","pack2.subpack"]))
class Tests extends BuddySuite {}
```

### Why do I get strange compilation errors not related to my project?

Sometimes, 3:rd party libraries included with `-cp` will have some issues that won't show up unless a class is explicitly referenced, but when including all classpaths automatically like Buddy does, the compiler will detect those problems and fail compilation. The solution is to only specify the classpaths you want included, using a second parameter of the build macro:

```haxe
@:build(buddy.GenerateMain.build(null, ["src"]))
class Tests extends BuddySuite {}
```

### Autocompletion sometimes doesn't work for "x.should." or numbers.

The compiler seems to be a bit too good at optimizing sometimes, especially at the beginning of functions, so if you get this problem add a parenthesis after "should" and wrap numbers in parenthesis too.

`x.should.be("ok")` -> `x.should().be("ok")`

`123.should.beGreaterThan(100)` -> `(123).should.beGreaterThan(100)`

### Can I use other assertion libraries than the built-in 'should'?

Yes, there is special support for [utest](http://code.google.com/p/utest/) and general support for all libraries that throws an exception on failure (like [mockatoo](https://github.com/misprintt/mockatoo) ). To use utest, just call any `utest.Assert` method inside a spec, no need to set up anything else.

### There's an exception thrown in an asynchronous method, but Buddy won't catch it and fail the test?

It's not possible to do that, since the program has already passed the exception handling code when the exception is thrown. You need to handle asynchronous exceptions yourself and test if something went wrong before calling `done()` in the spec.

## The story behind Buddy

After my speech about Contracts at [WWX2014](wwx.silexlabs.org/2014/), I concluded that one does not simply bash unit testing without providing a nice alternative! Having used [Jasmine](http://jasmine.github.io/2.0/introduction.html) before, I borrowed some if its nice features, and found the perfect aid to implementing async support with the [promhx](https://github.com/jdonaldson/promhx) library.

The [HaxeContracts](https://github.com/ciscoheat/HaxeContracts) library is a nice complement to BDD, so check it out for more information about why most unit testing is waste, and why BDD is a better alternative...!

## Upcoming features

- [x] Tutorial for general guidelines when doing BDD.
- [x] More assertions for "should".
- [x] Ways to customize running and reporting of specific test suites.
- [ ] Nicer reporters (especially for the browser) with stack traces for failures.
- [ ] Your choice! Send me a gmail (ciscoheat) or create an issue here.

Have a good time and much productivity with your new Buddy! :)
