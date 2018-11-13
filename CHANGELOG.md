0.9.4
-----

* `servant-0.15` support

0.9.3
-------

* Remove check of responseType in vanilla backend
  ([#13](https://github.com/haskell-servant/servant-js/pull/13), [#14](https://github.com/haskell-servant/servant-js/issues/14))

0.9.2
-----

* Fix code generation for query flag
  ([#11](https://github.com/haskell-servant/servant-js/issues/11))
* Improve error handling in vanilla backend
  ([#9](https://github.com/haskell-servant/servant-js/pull/9))

0.9.1
-----

* Fix javascript function name generation
* Allow servant-0.10

0.5
----

* Extract javascript-obvlious types and helpers to *servant-foreign*
* Use `text` package instead of `String`
* Provide new targets for code generation along with the old jQuery one: vanilla Javascript and Angular.js
* Greatly simplify usage of this library by reducing down the API to just 2 functions: `jsForAPI` and `writeJSForAPI` + the choice of a code generator
* Support for the `HttpVersion`, `IsSecure`, `RemoteHost` and `Vault` combinators
* Remove matrix params.

0.4
---
* `Delete` now is like `Get`, `Post`, `Put`, and `Patch` and returns a response body
* Extend `HeaderArg` to support more advanced HTTP header handling (https://github.com/haskell-servant/servant-jquery/pull/6)
* Support content-type aware combinators (but require that endpoints support JSON)
* Add support for Matrix params (https://github.com/haskell-servant/servant-jquery/pull/11)
* Add functions that directly generate the Javascript code from the API type without having to manually pattern match on the result.

0.2.2
-----

* Fix an issue where toplevel Raw endpoints would generate a JS function with no name (https://github.com/haskell-servant/servant-jquery/issues/2)
* Replace dots by _ in paths (https://github.com/haskell-servant/servant-jquery/issues/1)
