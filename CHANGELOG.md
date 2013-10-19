0.6.1
=====

#### Features

* [#475](https://github.com/intridea/grape/pull/475): Added support for the `:jsonapi`, `application/vnd.api+json` media type registered at http://jsonapi.org - [@bcm](https://github.com/bcm).
* [#471](https://github.com/intridea/grape/issues/471): Added parameter validator for a list of allowed values - [@vickychijwani](https://github.com/vickychijwani).
* [#488](https://github.com/intridea/grape/issues/488): Upgraded to Virtus 1.0 - [@dblock](https://github.com/dblock).

#### Fixes

* [#477](https://github.com/intridea/grape/pull/477): Fixed `default_error_formatter` which takes a format symbol - [@vad4msiu](https://github.com/vad4msiu).

#### Development

* Implemented Rubocop, a Ruby code static code analyzer - [@dblock](https://github.com/dblock).

0.6.0 (9/16/2013)
=================

#### Features

* Grape is no longer tested against Ruby 1.8.7.
* [#442](https://github.com/intridea/grape/issues/442): Enable incrementally building on top of a previous API version - [@dblock](https://github.com/dblock).
* [#442](https://github.com/intridea/grape/issues/442): API `version` can now take an array of multiple versions - [@dblock](https://github.com/dblock).
* [#444](https://github.com/intridea/grape/issues/444): Added `:en` as fallback locale for I18n - [@aew](https://github.com/aew).
* [#448](https://github.com/intridea/grape/pull/448): Adding POST style parameters for DELETE requests - [@dquimper](https://github.com/dquimper).
* [#450](https://github.com/intridea/grape/pull/450): Added option to pass an exception handler lambda as an argument to `rescue_from` - [@robertopedroso](https://github.com/robertopedroso).
* [#443](https://github.com/intridea/grape/pull/443): Let `requires` and `optional` take blocks that initialize new scopes - [@asross](https://github.com/asross).
* [#452](https://github.com/intridea/grape/pull/452): Added `with` as a hash option to specify handlers for `rescue_from` and `error_formatter` [@robertopedroso](https://github.com/robertopedroso).
* [#433](https://github.com/intridea/grape/issues/433), [#462](https://github.com/intridea/grape/issues/462): API change: validation errors are now collected and `Grape::Exceptions::ValidationErrors` is raised - [@stevschmid](https://github.com/stevschmid).

#### Fixes

* [#428](https://github.com/intridea/grape/issues/428): Removes memoization from `Grape::Request` params to prevent middleware from freezing parameter values before `Formatter` can get them - [@mbleigh](https://github.com/mbleigh).

0.5.0 (6/14/2013)
=================

#### Features

* [#344](https://github.com/intridea/grape/pull/344): Added `parser :type, nil` which disables input parsing for a given content-type - [@dblock](https://github.com/dblock).
* [#381](https://github.com/intridea/grape/issues/381): Added `cascade false` option at API level to remove the `X-Cascade: true` header from the API response - [@dblock](https://github.com/dblock).
* [#392](https://github.com/intridea/grape/pull/392): Extracted headers and params from `Endpoint` to `Grape::Request` - [@niedhui](https://github.com/niedhui).
* [#376](https://github.com/intridea/grape/pull/376): Added `route_param`, syntax sugar for quick declaration of route parameters - [@mbleigh](https://github.com/mbleigh).
* [#390](https://github.com/intridea/grape/pull/390): Added default value for an `optional` parameter - [@oivoodoo](https://github.com/oivoodoo).
* [#403](https://github.com/intridea/grape/pull/403): Added support for versioning using the `Accept-Version` header - [@politician](https://github.com/politician).
* [#407](https://github.com/intridea/grape/issues/407): Specifying `default_format` will also set the default POST/PUT data parser to the given format - [@dblock](https://github.com/dblock).
* [#241](https://github.com/intridea/grape/issues/241): Present with multiple entities using an optional Symbol - [@niedhui](https://github.com/niedhui).

#### Fixes

* [#378](https://github.com/intridea/grape/pull/378): Fix: stop rescuing all exceptions during formatting - [@kbarrette](https://github.com/kbarrette).
* [#380](https://github.com/intridea/grape/pull/380): Fix: `Formatter#read_body_input` when transfer encoding is chunked - [@paulnicholon](https://github.com/paulnicholson).
* [#347](https://github.com/intridea/grape/issues/347): Fix: handling non-hash body params - [@paulnicholon](https://github.com/paulnicholson).
* [#394](https://github.com/intridea/grape/pull/394): Fix: path version no longer overwrites a `version` parameter - [@tmornini](https://github.com/tmornini).
* [#412](https://github.com/intridea/grape/issues/412): Fix: specifying `content_type` will also override the selection of the data formatter - [@dblock](https://github.com/dblock).
* [#383](https://github.com/intridea/grape/issues/383): Fix: Mounted APIs aren't inheriting settings (including `before` and `after` filters) - [@seanmoon](https://github.com/seanmoon).
* [#408](https://github.com/intridea/grape/pull/408): Fix: Goliath passes request header keys as symbols not strings - [@bobek](https://github.com/bobek).
* [#417](https://github.com/intridea/grape/issues/417): Fix: Rails 4 does not rewind input, causes POSTed data to be empty - [@dblock](https://github.com/dblock).
* [#423](https://github.com/intridea/grape/pull/423): Fix: `Grape::Endpoint#declared` now correctly handles nested params (ie. declared with `group`) - [@jbarreneche](https://github.com/jbarreneche).
* [#427](https://github.com/intridea/grape/issues/427): Fix: `declared(params)` breaks when `params` contains array - [@timhabermaas](https://github.com/timhabermaas)

0.4.1 (4/1/2013)
================

* [#375](https://github.com/intridea/grape/pull/375): Fix: throwing an `:error` inside a middleware doesn't respect the `format` settings - [@dblock](https://github.com/dblock).

0.4.0 (3/17/2013)
=================

* [#356](https://github.com/intridea/grape/pull/356): Fix: presenting collections other than `Array` (eg. `ActiveRecord::Relation`) - [@zimbatm](https://github.com/zimbatm).
* [#352](https://github.com/intridea/grape/pull/352): Fix: using `Rack::JSONP` with `Grape::Entity` responses - [@deckchair](https://github.com/deckchair).
* [#347](https://github.com/intridea/grape/issues/347): Grape will accept any valid JSON as PUT or POST, including strings, symbols and arrays - [@qqshfox](https://github.com/qqshfox), [@dblock](https://github.com/dblock).
* [#347](https://github.com/intridea/grape/issues/347): JSON format APIs always return valid JSON, eg. strings are now returned as `"string"` and no longer `string` - [@dblock](https://github.com/dblock).
* Raw body input from POST and PUT requests (`env['rack.input'].read`) is now available in `api.request.input` - [@dblock](https://github.com/dblock).
* Parsed body input from POST and PUT requests is now available in `api.request.body` - [@dblock](https://github.com/dblock).
* [#343](https://github.com/intridea/grape/pull/343): Fix: return `Content-Type: text/plain` with error 405 - [@gustavosaume](https://github.com/gustavosaume), [@wyattisimo](https://github.com/wyattisimo).
* [#357](https://github.com/intridea/grape/pull/357): Grape now requires Rack 1.3.0 or newer - [@jhecking](https://github.com/jhecking).
* [#320](https://github.com/intridea/grape/issues/320): API `namespace` now supports `requirements` - [@niedhui](https://github.com/niedhui).
* [#353](https://github.com/intridea/grape/issues/353): Revert to standard Ruby logger formatter, `require active_support/all` if you want old behavior - [@rhunter](https://github.com/rhunter), [@dblock](https://github.com/dblock).
* Fix: `undefined method 'call' for nil:NilClass` for an API method implementation without a block, now returns an empty string - [@dblock](https://github.com/dblock).

0.3.2 (2/28/2013)
=================

* [#355](https://github.com/intridea/grape/issues/355): Relax dependency constraint on Hashie - [@reset](https://github.com/reset).

0.3.1 (2/25/2013)
=================

* [#351](https://github.com/intridea/grape/issues/351): Compatibility with Ruby 2.0 - [@mbleigh](https://github.com/mbleigh).

0.3.0 (02/21/2013)
==================

* [#294](https://github.com/intridea/grape/issues/294): Extracted `Grape::Entity` into a [grape-entity](https://github.com/agileanimal/grape-entity) gem - [@agileanimal](https://github.com/agileanimal).
* [#340](https://github.com/intridea/grape/pull/339), [#342](https://github.com/intridea/grape/pull/342): Added `:cascade` option to `version` to allow disabling of rack/mount cascade behavior - [@dieb](https://github.com/dieb).
* [#333](https://github.com/intridea/grape/pull/333): Added support for validation of arrays in `params` - [@flyerhzm](https://github.com/flyerhzm).
* [#306](https://github.com/intridea/grape/issues/306): Added I18n support for all Grape exceptions - [@niedhui](https://github.com/niedhui).
* [#309](https://github.com/intridea/grape/pull/309): Added XML support to the entity presenter - [@johnnyiller](https://github.com/johnnyiller), [@dblock](http://github.com/dblock).
* [#131](https://github.com/intridea/grape/issues/131): Added instructions for Grape API reloading in Rails - [@jyn](http://github.com/jyn), [@dblock](http://github.com/dblock).
* [#317](https://github.com/intridea/grape/issues/317): Added `headers` that returns a hash of parsed HTTP request headers - [@dblock](http://github.com/dblock).
* [#332](https://github.com/intridea/grape/pull/332): `Grape::Exceptions::Validation` now contains full nested parameter names - [@alovak](https://github.com/alovak).
* [#328](https://github.com/intridea/grape/issues/328): API version can now be specified as both String and Symbol - [@dblock](http://github.com/dblock).
* [#190](https://github.com/intridea/grape/issues/190): When you add a `GET` route for a resource, a route for the `HEAD` method will also be added automatically. You can disable this behavior with `do_not_route_head!` - [@dblock](http://github.com/dblock).
* Added `do_not_route_options!`, which disables the automatic creation of the `OPTIONS` route - [@dblock](http://github.com/dblock).
* [#309](https://github.com/intridea/grape/pull/309): An XML format API will return an error instead of returning a string representation of the response if the latter cannot be converted to XML - [@dblock](http://github.com/dblock).
* A formatter that raises an exception will cause the API to return a 500 error - [@dblock](http://github.com/dblock).
* [#322](https://github.com/intridea/grape/issues/322): When returning a 406 status, Grape will include the requested format or content-type in the response body - [@dblock](http://github.com/dblock).
* [#60](https://github.com/intridea/grape/issues/60): Fix: mounting of a Grape API onto a path - [@dblock](http://github.com/dblock).
* [#335](https://github.com/intridea/grape/pull/335): Fix: request body parameters from a `PATCH` request not available in `params` - [@FreakenK](http://github.com/FreakenK).

0.2.6 (01/11/2013)
==================

* Fix: support content-type with character set when parsing POST and PUT input - [@dblock](http://github.com/dblock).
* Fix: CVE-2013-0175, multi_xml parse vulnerability, require multi_xml 0.5.2 - [@dblock](http://github.com/dblock).

0.2.5 (01/10/2013)
==================

* Added support for custom parsers via `parser`, in addition to built-in multipart, JSON and XML parsers - [@dblock](http://github.com/dblock).
* Removed `body_params`, data sent via a POST or PUT with a supported content-type is merged into `params` - [@dblock](http://github.com/dblock).
* Setting `format` will automatically remove other content-types by calling `content_type` - [@dblock](http://github.com/dblock).
* Setting `content_type` will prevent any input data other than the matching content-type or any Rack-supported form and parseable media types (`application/x-www-form-urlencoded`, `multipart/form-data`, `multipart/related` and `multipart/mixed`) from being parsed - [@dblock](http://github.com/dblock).
* [#305](https://github.com/intridea/grape/issues/305): Fix: presenting arrays of objects via `represent` or when auto-detecting an `Entity` constant in the objects being presented - [@brandonweiss](https://github.com/brandonweiss).
* [#306](https://github.com/intridea/grape/issues/306): Added i18n support for validation error messages - [@niedhui](https://github.com/niedhui).

0.2.4 (01/06/2013)
==================

* [#297](https://github.com/intridea/grape/issues/297): Added `default_error_formatter` - [@dblock](https://github.com/dblock).
* [#297](https://github.com/intridea/grape/issues/297): Setting `format` will automatically set `default_error_formatter` - [@dblock](https://github.com/dblock).
* [#295](https://github.com/intridea/grape/issues/295): Storing original API source block in endpoint's `source` attribute - [@dblock](https://github.com/dblock).
* [#293](https://github.com/intridea/grape/pull/293): Added options to `cookies.delete`, enables passing a path - [@inst](https://github.com/inst).
* [#174](https://github.com/intridea/grape/issues/174): The value of `env['PATH_INFO']` is no longer altered with `path` versioning - [@dblock](https://github.com/dblock).
* [#296](https://github.com/intridea/grape/issues/296): Fix: ArgumentError with default error formatter - [@dblock](https://github.com/dblock).
* [#298](https://github.com/intridea/grape/pull/298): Fix: subsequent calls to `body_params` would fail due to IO read - [@justinmcp](https://github.com/justinmcp).
* [#301](https://github.com/intridea/grape/issues/301): Fix: symbol memory leak in cookie and formatter middleware - [@dblock](https://github.com/dblock).
* [#300](https://github.com/intridea/grape/issues/300): Fix `Grape::API.routes` to include mounted api routes - [@aiwilliams](https://github.com/aiwilliams).
* [#302](https://github.com/intridea/grape/pull/302): Fix: removed redundant `autoload` entries - [@ugisozols](https://github.com/ugisozols).
* [#172](https://github.com/intridea/grape/issues/172): Fix: MultiJson deprecated methods warnings - [@dblock](https://github.com/dblock).
* [#133](https://github.com/intridea/grape/issues/133): Fix: header-based versioning with use of `prefix` - [@seanmoon](https://github.com/seanmoon), [@dblock](https://github.com/dblock).
* [#280](https://github.com/intridea/grape/issues/280): Fix: grouped parameters mangled in `route_params` hash - [@marcusg](https://github.com/marcusg), [@dblock](https://github.com/dblock).
* [#304](https://github.com/intridea/grape/issues/304): Fix: `present x, :with => Entity` returns class references with `format :json` - [@dblock](https://github.com/dblock).
* [#196](https://github.com/intridea/grape/issues/196): Fix: root requests don't work with `prefix` - [@dblock](https://github.com/dblock).

0.2.3 (24/12/2012)
==================

* [#179](https://github.com/intridea/grape/issues/178): Using `content_type` will remove all default content-types - [@dblock](https://github.com/dblock).
* [#265](https://github.com/intridea/grape/issues/264): Fix: Moved `ValidationError` into `Grape::Exceptions` - [@thepumpkin1979](https://github.com/thepumpkin1979).
* [#269](https://github.com/intridea/grape/pull/269): Fix: `LocalJumpError` will not be raised when using explict return in API methods - [@simulacre](https://github.com/simulacre).
* [#86](https://github.com/intridea/grape/issues/275): Fix Path-based versioning not recognizing `/` route - [@walski](https://github.com/walski).
* [#273](https://github.com/intridea/grape/pull/273): Disabled formatting via `serializable_hash` and added support for `format :serializable_hash` - [@dblock](https://github.com/dblock).
* [#277](https://github.com/intridea/grape/pull/277): Added a DSL to declare `formatter` in API settings - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* [#284](https://github.com/intridea/grape/pull/284): Added a DSL to declare `error_formatter` in API settings - [@dblock](https://github.com/dblock).
* [#285](https://github.com/intridea/grape/pull/285): Removed `error_format` from API settings, now matches request format - [@dblock](https://github.com/dblock).
* [#290](https://github.com/intridea/grape/pull/290): The default error format for XML is now `error/message` instead of `hash/error` - [@dpsk](https://github.com/dpsk).
* [#44](https://github.com/intridea/grape/issues/44): Pass `env` into formatters to enable templating - [@dblock](https://github.com/dblock).

0.2.2
=====

#### Features

* [#201](https://github.com/intridea/grape/pull/201), [#236](https://github.com/intridea/grape/pull/236), [#221](https://github.com/intridea/grape/pull/221): Added coercion and validations support to `params` DSL - [@schmurfy](https://github.com/schmurfy), [@tim-vandecasteele](https://github.com/tim-vandecasteele), [@adamgotterer](https://github.com/adamgotterer).
* [#204](https://github.com/intridea/grape/pull/204): Added ability to declare shared `params` at `namespace` level - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* [#234](https://github.com/intridea/grape/pull/234): Added a DSL for creating entities via mixin - [@mbleigh](https://github.com/mbleigh).
* [#240](https://github.com/intridea/grape/pull/240): Define API response format from a query string `format` parameter, if specified - [@neetiraj](https://github.com/neetiraj).
* Adds Endpoint#declared to easily filter out unexpected params. - [@mbleigh](https://github.com/mbleigh)

#### Fixes

* [#248](https://github.com/intridea/grape/pull/248): Fix: API `version` returns last version set - [@narkoz](https://github.com/narkoz).
* [#242](https://github.com/intridea/grape/issues/242): Fix: permanent redirect status should be `301`, was `304` - [@adamgotterer](https://github.com/adamgotterer).
* [#211](https://github.com/intridea/grape/pull/211): Fix: custom validations are no longer triggered when optional and parameter is not present - [@adamgotterer](https://github.com/adamgotterer).
* [#210](https://github.com/intridea/grape/pull/210): Fix: `Endpoint#body_params` causing undefined method 'size' - [@adamgotterer](https://github.com/adamgotterer).
* [#205](https://github.com/intridea/grape/pull/205): Fix: Corrected parsing of empty JSON body on POST/PUT - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* [#181](https://github.com/intridea/grape/pull/181): Fix: Corrected JSON serialization of nested hashes containing `Grape::Entity` instances - [@benrosenblum](https://github.com/benrosenblum).
* [#203](https://github.com/intridea/grape/pull/203): Added a check to `Entity#serializable_hash` that verifies an entity exists on an object - [@adamgotterer](https://github.com/adamgotterer).
* [#208](https://github.com/intridea/grape/pull/208): `Entity#serializable_hash` must also check if attribute is generated by a user supplied block - [@ppadron](https://github.com/ppadron).
* [#252](https://github.com/intridea/grape/pull/252): Resources that don't respond to a requested HTTP method return 405 (Method Not Allowed) instead of 404 (Not Found) - [@simulacre](https://github.com/simulacre)

0.2.1 (7/11/2012)
=================

* [#186](https://github.com/intridea/grape/issues/186): Fix: helpers allow multiple calls with modules and blocks - [@ppadron](https://github.com/ppadron).
* [#188](https://github.com/intridea/grape/pull/188): Fix: multi-method routes append '(.:format)' only once - [@kainosnoema](https://github.com/kainosnoema).
* [#64](https://github.com/intridea/grape/issues/64), [#180](https://github.com/intridea/grape/pull/180): Added support to `GET` request bodies as parameters - [@bobbytables](https://github.com/bobbytables).
* [#175](https://github.com/intridea/grape/pull/175): Added support for API versioning based on a request parameter - [@jackcasey](https://github.com/jackcasey).
* [#168](https://github.com/intridea/grape/pull/168): Fix: Formatter can parse symbol keys in the headers hash - [@netmask](https://github.com/netmask).
* [#169](https://github.com/intridea/grape/pull/169): Silence multi_json deprecation warnings - [@whiteley](https://github.com/whiteley).
* [#166](https://github.com/intridea/grape/pull/166): Added support for `redirect`, including permanent and temporary - [@allenwei](https://github.com/allenwei).
* [#159](https://github.com/intridea/grape/pull/159): Added `:requirements` to routes, allowing to use reserved characters in paths - [@gaiottino](https://github.com/gaiottino).
* [#156](https://github.com/intridea/grape/pull/156): Added support for adding formatters to entities - [@bobbytables](https://github.com/bobbytables).
* [#183](https://github.com/intridea/grape/pull/183): Added ability to include documentation in entities - [@flah00](https://github.com/flah00).
* [#189](https://github.com/intridea/grape/pull/189): `HEAD` requests no longer return a body - [@stephencelis](https://github.com/stephencelis).
* [#97](https://github.com/intridea/grape/issues/97): Allow overriding `Content-Type` - [@dblock](https://github.com/dblock).

0.2.0 (3/28/2012)
=================

* Added support for inheriting exposures from entities - [@bobbytables](https://github.com/bobbytables).
* Extended formatting with `default_format` - [@dblock](https://github.com/dblock).
* Added support for cookies - [@lukaszsliwa](https://github.com/lukaszsliwa).
* Added support for declaring additional content-types - [@joeyAghion](https://github.com/joeyAghion).
* Added support for HTTP PATCH - [@LTe](https://github.com/LTe).
* Added support for describing, documenting and reflecting APIs - [@dblock](https://github.com/dblock).
* Added support for anchoring and vendoring - [@jwkoelewijn](https://github.com/jwkoelewijn).
* Added support for HTTP OPTIONS - [@grimen](https://github.com/grimen).
* Added support for silencing logger - [@evansj](https://github.com/evansj).
* Added support for helper modules - [@freelancing-god](https://github.com/freelancing-god).
* Added support for Accept header-based versioning - [@jch](https://github.com/jch), [@rodzyn](https://github.com/rodzyn).
* Added support for mounting APIs and other Rack applications within APIs - [@mbleigh](https://github.com/mbleigh).
* Added entities, multiple object representations - [@mbleigh](https://github.com/mbleigh).
* Added ability to handle XML in the incoming request body - [@jwillis](https://github.com/jwillis).
* Added support for a configurable logger - [@mbleigh](https://github.com/mbleigh).
* Added support for before and after filters - [@mbleigh](https://github.com/mbleigh).
* Extended `rescue_from`, which can now take a block - [@dblock](https://github.com/dblock).


0.1.5 (6/14/2011)
==================

* Extended exception handling to all exceptions - [@dblock](https://github.com/dblock).
* Added support for returning JSON objects from within error blocks - [@dblock](https://github.com/dblock).
* Added support for handling incoming JSON in body - [@tedkulp](https://github.com/tedkulp).
* Added support for HTTP digest authentication - [@daddz](https://github.com/daddz).

0.1.4 (4/8/2011)
==================

* Allow multiple definitions of the same endpoint under multiple versions - [@chrisrhoden](https://github.com/chrisrhoden).
* Added support for multipart URL parameters - [@mcastilho](https://github.com/mcastilho).
* Added support for custom formatters - [@spraints](https://github.com/spraints).

0.1.3 (1/10/2011)
==================

* Added support for JSON format in route matching - [@aiwilliams](https://github.com/aiwilliams).
* Added suport for custom middleware - [@mbleigh](https://github.com/mbleigh).

0.1.1 (11/14/2010)
==================

* Endpoints properly reset between each request - [@mbleigh](https://github.com/mbleigh).

0.1.0 (11/13/2010)
==================

* Initial public release - [@mbleigh](https://github.com/mbleigh).
