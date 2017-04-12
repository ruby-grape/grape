### 0.19.2 (4/12/2017)

#### Features

* [#1555](https://github.com/ruby-grape/grape/pull/1555): Added code coverage w/Coveralls - [@dblock](https://github.com/dblock).
* [#1568](https://github.com/ruby-grape/grape/pull/1568): Add `proc` option to `values` validator to allow custom checks - [@jlfaber](https://github.com/jlfaber).
* [#1575](https://github.com/ruby-grape/grape/pull/1575): Include nil values for missing nested params in declared - [@thogg4](https://github.com/thogg4).
* [#1585](https://github.com/ruby-grape/grape/pull/1585): Bugs in declared method - make sure correct options var is used and respect include missing for non children params - [@thogg4](https://github.com/thogg4).

#### Fixes

* [#1570](https://github.com/ruby-grape/grape/pull/1570): Make versioner consider the mount destination path - [@namusyaka](https://github.com/namusyaka).
* [#1579](https://github.com/ruby-grape/grape/pull/1579): Fix delete status with a return value - [@eproulx-petalmd](https://github.com/eproulx-petalmd).
* [#1559](https://github.com/ruby-grape/grape/pull/1559): You can once again pass `nil` to optional attributes with `values` validation set - [@ghiculescu](https://github.com/ghiculescu).
* [#1562](https://github.com/ruby-grape/grape/pull/1562): Fix rainbow gem installation failure above ruby 2.3.3 on travis-ci - [@brucehsu](https://github.com/brucehsu).
* [#1561](https://github.com/ruby-grape/grape/pull/1561): Fix performance issue introduced by duplicated calls in StackableValue#[] - [@brucehsu](https://github.com/brucehsu).
* [#1564](https://github.com/ruby-grape/grape/pull/1564): Fix declared params bug with nested namespaces - [@bmarini](https://github.com/bmarini).
* [#1567](https://github.com/ruby-grape/grape/pull/1567): Fix values validator when value is empty array and apply except to input array - [@jlfaber](https://github.com/jlfaber).
* [#1569](https://github.com/ruby-grape/grape/pull/1569), [#1511](https://github.com/ruby-grape/grape/issues/1511): Upgrade mustermann-grape to 1.0.0 - [@namusyaka](https://github.com/namusyaka).
* [#1589](https://github.com/ruby-grape/grape/pull/1589): [#726](https://github.com/ruby-grape/grape/issues/726): Use default_format when Content-type is missing and respond with 406 when Content-type is invalid - [@inclooder](https://github.com/inclooder).

### 0.19.1 (1/9/2017)

#### Features

* [#1536](https://github.com/ruby-grape/grape/pull/1536): Updates `invalid_versioner_option` translation - [@Lavode](https://github.com/Lavode).
* [#1543](https://github.com/ruby-grape/grape/pull/1543): Support ruby 2.4 - [@LeFnord](https://github.com/LeFnord), [@namusyaka](https://github.com/namusyaka).

#### Fixes

* [#1548](https://github.com/ruby-grape/grape/pull/1548): Avoid failing even if given path does not match with prefix - [@thomas-peyric](https://github.com/thomas-peyric), [@namusyaka](https://github.com/namusyaka).
* [#1550](https://github.com/ruby-grape/grape/pull/1550): Use 200 as default status for deletes that reply with content - [@jthornec](https://github.com/jthornec).

### 0.19.0 (12/18/2016)

#### Features

* [#1503](https://github.com/ruby-grape/grape/pull/1503): Allow to use regexp validator with arrays - [@akoltun](https://github.com/akoltun).
* [#1507](https://github.com/ruby-grape/grape/pull/1507): Add group attributes for parameter definitions - [@304](https://github.com/304).
* [#1532](https://github.com/ruby-grape/grape/pull/1532): Sets 204 as default status for delete - [@LeFnord](https://github.com/LeFnord).

#### Fixes

* [#1505](https://github.com/ruby-grape/grape/pull/1505): Run `before` and `after` callbacks, but skip the rest when handling OPTIONS - [@jlfaber](https://github.com/jlfaber).
* [#1517](https://github.com/ruby-grape/grape/pull/1517), [#1089](https://github.com/ruby-grape/grape/pull/1089): Fix: priority of ANY routes - [@namusyaka](https://github.com/namusyaka), [@wagenet](https://github.com/wagenet).
* [#1512](https://github.com/ruby-grape/grape/pull/1512): Fix: deeply nested parameters are included within `#declared(params)` - [@krbs](https://github.com/krbs).
* [#1510](https://github.com/ruby-grape/grape/pull/1510): Fix: inconsistent validation for multiple parameters - [@dgasper](https://github.com/dgasper).
* [#1526](https://github.com/ruby-grape/grape/pull/1526): Reduce warnings caused by instance variables not initialized - [@cpetschnig](https://github.com/cpetschnig).
* [#1531](https://github.com/ruby-grape/grape/pull/1531): Updates gem dependencies - [@LeFnord](https://github.com/LeFnord).

### 0.18.0 (10/7/2016)

#### Features

* [#1480](https://github.com/ruby-grape/grape/pull/1480): Use the ruby-grape-danger gem for PR linting - [@dblock](https://github.com/dblock).
* [#1486](https://github.com/ruby-grape/grape/pull/1486): Implemented except in values validator - [@jonmchan](https://github.com/jonmchan).
* [#1470](https://github.com/ruby-grape/grape/pull/1470): Drop support for ruby-2.0 - [@namusyaka](https://github.com/namusyaka).
* [#1490](https://github.com/ruby-grape/grape/pull/1490): Switch to Ruby-2.x+ syntax - [@namusyaka](https://github.com/namusyaka).
* [#1499](https://github.com/ruby-grape/grape/pull/1499): Support fail_fast param validation option - [@dgasper](https://github.com/dgasper).

#### Fixes

* [#1498](https://github.com/ruby-grape/grape/pull/1498): Skip validations in inactive given blocks - [@jlfaber](https://github.com/jlfaber).
* [#1479](https://github.com/ruby-grape/grape/pull/1479): Support inserting middleware before/after anonymous classes in the middleware stack - [@rosa](https://github.com/rosa).
* [#1488](https://github.com/ruby-grape/grape/pull/1488): Ensure calling before filters when receiving OPTIONS request - [@namusyaka](https://github.com/namusyaka), [@jlfaber](https://github.com/jlfaber).
* [#1493](https://github.com/ruby-grape/grape/pull/1493): Coercion and lambda fails params validation - [@jonmchan](https://github.com/jonmchan).

### 0.17.0 (7/29/2016)

#### Features

* [#1393](https://github.com/ruby-grape/grape/pull/1393): Middleware can be inserted before or after default Grape middleware - [@ridiculous](https://github.com/ridiculous).
* [#1390](https://github.com/ruby-grape/grape/pull/1390): Allow inserting middleware at arbitrary points in the middleware stack - [@rosa](https://github.com/rosa).
* [#1366](https://github.com/ruby-grape/grape/pull/1366): Store `message_key` on `Grape::Exceptions::Validation` - [@mkou](https://github.com/mkou).
* [#1398](https://github.com/ruby-grape/grape/pull/1398): Add `rescue_from :grape_exceptions` - allow Grape to use the built-in `Grape::Exception` handing and use `rescue :all` behavior for everything else - [@mmclead](https://github.com/mmclead).
* [#1443](https://github.com/ruby-grape/grape/pull/1443): Extend `given` to receive a `Proc` - [@glaucocustodio](https://github.com/glaucocustodio).
* [#1455](https://github.com/ruby-grape/grape/pull/1455): Add an automated PR linter - [@orta](https://github.com/orta).

#### Fixes

* [#1463](https://github.com/ruby-grape/grape/pull/1463): Fix array indicies in error messages - [@ffloyd](https://github.com/ffloyd).
* [#1465](https://github.com/ruby-grape/grape/pull/1465): Fix 'before' being called twice when using not allowed method - [@jsteinberg](https://github.com/jsteinberg).
* [#1446](https://github.com/ruby-grape/grape/pull/1446): Fix for `env` inside `before` when using not allowed method - [@leifg](https://github.com/leifg).
* [#1438](https://github.com/ruby-grape/grape/pull/1439): Try to dup non-frozen default params with each use - [@jlfaber](https://github.com/jlfaber).
* [#1430](https://github.com/ruby-grape/grape/pull/1430): Fix for `declared(params)` inside `route_param` - [@Arkanain](https://github.com/Arkanain).
* [#1405](https://github.com/ruby-grape/grape/pull/1405): Fix priority of `rescue_from` clauses applying - [@hedgesky](https://github.com/hedgesky).
* [#1365](https://github.com/ruby-grape/grape/pull/1365): Fix finding exception handler in error middleware - [@ktimothy](https://github.com/ktimothy).
* [#1380](https://github.com/ruby-grape/grape/pull/1380): Fix `allow_blank: false` for `Time` attributes with valid values causes `NoMethodError` - [@ipkes](https://github.com/ipkes).
* [#1384](https://github.com/ruby-grape/grape/pull/1384): Fix parameter validation with an empty optional nested `Array` - [@ipkes](https://github.com/ipkes).
* [#1414](https://github.com/ruby-grape/grape/pull/1414): Fix multiple version definitions for path versioning - [@304](https://github.com/304).
* [#1415](https://github.com/ruby-grape/grape/pull/1415): Fix `declared(params, include_parent_namespaces: false)` - [@304](https://github.com/304).
* [#1421](https://github.com/ruby-grape/grape/pull/1421): Avoid polluting `Grape::Middleware::Error` - [@namusyaka](https://github.com/namusyaka).
* [#1422](https://github.com/ruby-grape/grape/pull/1422): Concat parent declared params with current one - [@plukevdh](https://github.com/plukevdh), [@rnubel](https://github.com/rnubel), [@namusyaka](https://github.com/namusyaka).

### 0.16.2 (4/12/2016)

#### Features

* [#1348](https://github.com/ruby-grape/grape/pull/1348): Fix global functions polluting Grape::API scope - [@dblock](https://github.com/dblock).
* [#1357](https://github.com/ruby-grape/grape/pull/1357): Expose Route#options - [@namusyaka](https://github.com/namusyaka).

#### Fixes

* [#1357](https://github.com/ruby-grape/grape/pull/1357): Don't include fixed named captures as route params - [@namusyaka](https://github.com/namusyaka).
* [#1359](https://github.com/ruby-grape/grape/pull/1359): Avoid evaluating the same route twice - [@namusyaka](https://github.com/namusyaka), [@dblock](https://github.com/dblock).
* [#1361](https://github.com/ruby-grape/grape/pull/1361): Return 405 correctly even if version is using as header and wrong request method - [@namusyaka](https://github.com/namusyaka), [@dblock](https://github.com/dblock).

### 0.16.1 (4/3/2016)

#### Features

* [#1276](https://github.com/ruby-grape/grape/pull/1276): Replace rack-mount with new router - [@namusyaka](https://github.com/namusyaka).
* [#1321](https://github.com/ruby-grape/grape/pull/1321): Serve files without using FileStreamer-like object - [@lfidnl](https://github.com/lfidnl).
* [#1339](https://github.com/ruby-grape/grape/pull/1339): Implement Grape::API.recognize_path - [@namusyaka](https://github.com/namusyaka).

#### Fixes

* [#1325](https://github.com/ruby-grape/grape/pull/1325): Params: Fix coerce_with helper with Array types - [@ngonzalez](https://github.com/ngonzalez).
* [#1326](https://github.com/ruby-grape/grape/pull/1326): Fix wrong behavior for OPTIONS and HEAD requests with catch-all - [@ekampp](https://github.com/ekampp), [@namusyaka](https://github.com/namusyaka).
* [#1330](https://github.com/ruby-grape/grape/pull/1330): Add `register` keyword for adding customized parsers and formatters - [@namusyaka](https://github.com/namusyaka).
* [#1336](https://github.com/ruby-grape/grape/pull/1336): Do not modify Hash argument to `error!` - [@tjwp](https://github.com/tjwp).

### 0.15.0 (3/8/2016)

#### Features

* [#1227](https://github.com/ruby-grape/grape/pull/1227): Store `message_key` on `Grape::Exceptions::Validation` - [@stjhimy](https://github.com/sthimy).
* [#1232](https://github.com/ruby-grape/grape/pull/1232): Helpers are now available inside `rescue_from` - [@namusyaka](https://github.com/namusyaka).
* [#1237](https://github.com/ruby-grape/grape/pull/1237): Allow multiple parameters in `given`, which behaves as if the scopes were nested in the inputted order - [@ochagata](https://github.com/ochagata).
* [#1238](https://github.com/ruby-grape/grape/pull/1238): Call `after` of middleware on error - [@namusyaka](https://github.com/namusyaka).
* [#1243](https://github.com/ruby-grape/grape/pull/1243): Add `header` support for middleware - [@namusyaka](https://github.com/namusyaka).
* [#1252](https://github.com/ruby-grape/grape/pull/1252): Allow default to be a subset or equal to allowed values without raising IncompatibleOptionValues - [@jeradphelps](https://github.com/jeradphelps).
* [#1255](https://github.com/ruby-grape/grape/pull/1255): Allow param type definition in `route_param` - [@namusyaka](https://github.com/namusyaka).
* [#1257](https://github.com/ruby-grape/grape/pull/1257): Allow Proc, Symbol or String in `rescue_from with: ...` - [@namusyaka](https://github.com/namusyaka).
* [#1280](https://github.com/ruby-grape/grape/pull/1280): Support `Rack::Sendfile` middleware - [@lfidnl](https://github.com/lfidnl).
* [#1285](https://github.com/ruby-grape/grape/pull/1285): Add a warning for errors appearing in `after` callbacks - [@gregormelhorn](https://github.com/gregormelhorn).
* [#1295](https://github.com/ruby-grape/grape/pull/1295): Add custom validation messages for parameter exceptions - [@railsmith](https://github.com/railsmith).

#### Fixes

* [#1216](https://github.com/ruby-grape/grape/pull/1142): Fix JSON error response when calling `error!` with non-Strings - [@jrforrest](https://github.com/jrforrest).
* [#1225](https://github.com/ruby-grape/grape/pull/1225): Fix `given` with nested params not returning correct declared params - [@JanStevens](https://github.com/JanStevens).
* [#1249](https://github.com/ruby-grape/grape/pull/1249): Don't fail even if invalid type value is passed to default validator - [@namusyaka](https://github.com/namusyaka).
* [#1266](https://github.com/ruby-grape/grape/pull/1266): Fix `Allow` header including `OPTIONS` when `do_not_route_options!` is active - [@arempe93](https://github.com/arempe93).
* [#1270](https://github.com/ruby-grape/grape/pull/1270): Fix `param` versioning with a custom parameter - [@wshatch](https://github.com/wshatch).
* [#1282](https://github.com/ruby-grape/grape/pull/1282): Fix specs circular dependency - [@304](https://github.com/304).
* [#1283](https://github.com/ruby-grape/grape/pull/1283): Fix 500 error for xml format when method is not allowed - [@304](https://github.com/304).
* [#1197](https://github.com/ruby-grape/grape/pull/1290): Fix using JSON and Array[JSON] as groups when parameter is optional - [@lukeivers](https://github.com/lukeivers).

### 0.14.0 (12/07/2015)

#### Features

* [#1218](https://github.com/ruby-grape/grape/pull/1218): Provide array index context in errors - [@towanda](https://github.com/towanda).
* [#1196](https://github.com/ruby-grape/grape/pull/1196): Allow multiple `before_each` blocks - [@huynhquancam](https://github.com/huynhquancam).
* [#1190](https://github.com/ruby-grape/grape/pull/1190): Bypass formatting for statuses with no entity-body - [@tylerdooling](https://github.com/tylerdooling).
* [#1188](https://github.com/ruby-grape/grape/pull/1188): Allow parameters with more than one type - [@dslh](https://github.com/dslh).
* [#1179](https://github.com/ruby-grape/grape/pull/1179): Allow all RFC6838 valid characters in header vendor - [@suan](https://github.com/suan).
* [#1170](https://github.com/ruby-grape/grape/pull/1170): Allow dashes and periods in header vendor - [@suan](https://github.com/suan).
* [#1167](https://github.com/ruby-grape/grape/pull/1167): Convenience wrapper `type: File` for validating multipart file parameters - [@dslh](https://github.com/dslh).
* [#1167](https://github.com/ruby-grape/grape/pull/1167): Refactor and extend coercion and type validation system - [@dslh](https://github.com/dslh).
* [#1163](https://github.com/ruby-grape/grape/pull/1163): First-class `JSON` parameter type - [@dslh](https://github.com/dslh).
* [#1161](https://github.com/ruby-grape/grape/pull/1161): Custom parameter coercion using `coerce_with` - [@dslh](https://github.com/dslh).

#### Fixes

* [#1194](https://github.com/ruby-grape/grape/pull/1194): Redirect as plain text with message - [@tylerdooling](https://github.com/tylerdooling).
* [#1185](https://github.com/ruby-grape/grape/pull/1185): Use formatters for custom vendored content types - [@tylerdooling](https://github.com/tylerdooling).
* [#1156](https://github.com/ruby-grape/grape/pull/1156): Fixed `no implicit conversion of Symbol into Integer` with nested `values` validation - [@quickpay](https://github.com/quickpay).
* [#1153](https://github.com/ruby-grape/grape/pull/1153): Fixes boolean declaration in an external file - [@towanda](https://github.com/towanda).
* [#1142](https://github.com/ruby-grape/grape/pull/1142): Makes #declared unavailable to before filters - [@jrforrest](https://github.com/jrforrest).
* [#1114](https://github.com/ruby-grape/grape/pull/1114): Fix regression which broke identical endpoints with different versions - [@suan](https://github.com/suan).
* [#1109](https://github.com/ruby-grape/grape/pull/1109): Memoize Virtus attribute and fix memory leak - [@marshall-lee](https://github.com/marshall-lee).
* [#1101](https://github.com/ruby-grape/grape/pull/1101): Fix: Incorrect media-type `Accept` header now correctly returns 406 with `strict: true` - [@elliotlarson](https://github.com/elliotlarson).
* [#1108](https://github.com/ruby-grape/grape/pull/1039): Raise a warning when `desc` is called with options hash and block - [@rngtng](https://github.com/rngtng).

### 0.13.0 (8/10/2015)

#### Features

* [#1039](https://github.com/ruby-grape/grape/pull/1039): Added support for custom parameter types - [@rnubel](https://github.com/rnubel).
* [#1047](https://github.com/ruby-grape/grape/pull/1047): Adds `given` to DSL::Parameters, allowing for dependent params - [@rnubel](https://github.com/rnubel).
* [#1064](https://github.com/ruby-grape/grape/pull/1064): Add public `Grape::Exception::ValidationErrors#full_messages` - [@romanlehnert](https://github.com/romanlehnert).
* [#1079](https://github.com/ruby-grape/grape/pull/1079): Added `stream` method to take advantage of `Rack::Chunked` - [@zbelzer](https://github.com/zbelzer).
* [#1086](https://github.com/ruby-grape/grape/pull/1086): Added `ActiveSupport::Notifications` instrumentation - [@wagenet](https://github.com/wagenet).

#### Fixes

* [#1062](https://github.com/ruby-grape/grape/issues/1062): Fix: `Grape::Exceptions::ValidationErrors` will include headers set by `header` - [@yairgo](https://github.com/yairgo).
* [#1038](https://github.com/ruby-grape/grape/pull/1038): Avoid dup-ing the `String` class when used in inherited params - [@rnubel](https://github.com/rnubel).
* [#1042](https://github.com/ruby-grape/grape/issues/1042): Fix coercion of complex arrays - [@dim](https://github.com/dim).
* [#1045](https://github.com/ruby-grape/grape/pull/1045): Do not convert `Rack::Response` to `Rack::Response` in middleware - [@dmitry](https://github.com/dmitry).
* [#1048](https://github.com/ruby-grape/grape/pull/1048): Only dup `InheritableValues`, remove support for `deep_dup` - [@toddmazierski](https://github.com/toddmazierski).
* [#1052](https://github.com/ruby-grape/grape/pull/1052): Reset `description[:params]` when resetting validations - [@marshall-lee](https://github.com/marshall-lee).
* [#1088](https://github.com/ruby-grape/grape/pull/1088): Support ActiveSupport 3.x by explicitly requiring `Hash#except` - [@wagenet](https://github.com/wagenet).
* [#1096](https://github.com/ruby-grape/grape/pull/1096): Fix coercion on booleans - [@towanda](https://github.com/towanda).

### 0.12.0 (6/18/2015)

#### Features

* [#995](https://github.com/ruby-grape/grape/issues/995): Added support for coercion to Set or Set[Other] - [@jordansexton](https://github.com/jordansexton) [@u2](https://github.com/u2).
* [#980](https://github.com/ruby-grape/grape/issues/980): Grape is now eager-loaded - [@u2](https://github.com/u2).
* [#956](https://github.com/ruby-grape/grape/issues/956): Support `present` with `Grape::Presenters::Presenter`  - [@u2](https://github.com/u2).
* [#974](https://github.com/ruby-grape/grape/pull/974): Added `error!` to `rescue_from` blocks - [@whatasunnyday](https://github.com/whatasunnyday).
* [#950](https://github.com/ruby-grape/grape/pull/950): Status method can now accept one of Rack::Utils status code symbols (:ok, :found, :bad_request, etc.) - [@dabrorius](https://github.com/dabrorius).
* [#952](https://github.com/ruby-grape/grape/pull/952): Status method now raises error when called with invalid status code - [@dabrorius](https://github.com/dabrorius).
* [#957](https://github.com/ruby-grape/grape/pull/957): Regexp validator now supports `allow_blank`, `nil` value behavior changed - [@calfzhou](https://github.com/calfzhou).
* [#962](https://github.com/ruby-grape/grape/pull/962): The `default` attribute with `false` value is documented now - [@ajvondrak](https://github.com/ajvondrak).
* [#1026](https://github.com/ruby-grape/grape/pull/1026): Added `file` method, explicitly setting a file-like response object - [@dblock](https://github.com/dblock).

#### Fixes

* [#994](https://github.com/ruby-grape/grape/pull/994): Fixed optional Array params default to Hash - [@u2](https://github.com/u2).
* [#988](https://github.com/ruby-grape/grape/pull/988): Fixed duplicate identical endpoints - [@u2](https://github.com/u2).
* [#936](https://github.com/ruby-grape/grape/pull/936): Fixed default params processing for optional groups - [@dm1try](https://github.com/dm1try).
* [#942](https://github.com/ruby-grape/grape/pull/942): Fixed forced presence for optional params when based on a reused entity that was also required in another context - [@croeck](https://github.com/croeck).
* [#1001](https://github.com/ruby-grape/grape/pull/1001): Fixed calling endpoint with specified format with format in its path - [@hodak](https://github.com/hodak).
* [#1005](https://github.com/ruby-grape/grape/pull/1005): Fixed the Grape::Middleware::Globals - [@urkle](https://github.com/urkle).
* [#1012](https://github.com/ruby-grape/grape/pull/1012): Fixed `allow_blank: false` with a Boolean value of `false` - [@mfunaro](https://github.com/mfunaro).
* [#1023](https://github.com/ruby-grape/grape/issues/1023): Fixes unexpected behavior with `present` and an object that responds to `merge` but isn't a Hash - [@dblock](https://github.com/dblock).
* [#1017](https://github.com/ruby-grape/grape/pull/1017): Fixed `undefined method stringify_keys` with nested mutual exclusive params - [@quickpay](https://github.com/quickpay).

### 0.11.0 (2/23/2015)

* [#925](https://github.com/ruby-grape/grape/pull/925): Fixed `toplevel constant DateTime referenced by Virtus::Attribute::DateTime` - [@u2](https://github.com/u2).
* [#916](https://github.com/ruby-grape/grape/pull/916): Added `DateTime/Date/Numeric/Boolean` type support `allow_blank` - [@u2](https://github.com/u2).
* [#871](https://github.com/ruby-grape/grape/pull/871): Fixed `Grape::Middleware::Base#response` - [@galathius](https://github.com/galathius).
* [#559](https://github.com/ruby-grape/grape/issues/559): Added support for Rack 1.6.0, which parses requests larger than 128KB - [@myitcv](https://github.com/myitcv).
* [#876](https://github.com/ruby-grape/grape/pull/876): Call to `declared(params)` now returns a `Hashie::Mash` - [@rodzyn](https://github.com/rodzyn).
* [#879](https://github.com/ruby-grape/grape/pull/879): The `route_info` value is no longer included in `params` Hash - [@rodzyn](https://github.com/rodzyn).
* [#881](https://github.com/ruby-grape/grape/issues/881): Fixed `Grape::Validations::ValuesValidator` support for `Range` type - [@ajvondrak](https://github.com/ajvondrak).
* [#901](https://github.com/ruby-grape/grape/pull/901): Fix: callbacks defined in a version block are only called for the routes defined in that block - [@kushkella](https://github.com/kushkella).
* [#886](https://github.com/ruby-grape/grape/pull/886): Group of parameters made to require an explicit type of Hash or Array - [@jrichter1](https://github.com/jrichter1).
* [#912](https://github.com/ruby-grape/grape/pull/912): Extended the `:using` feature for param documentation to `optional` fields - [@croeck](https://github.com/croeck).
* [#906](https://github.com/ruby-grape/grape/pull/906): Fix: invalid body parse errors are not rescued by handlers - [@croeck](https://github.com/croeck).
* [#913](https://github.com/ruby-grape/grape/pull/913): Fix: Invalid accept headers are not processed by rescue handlers - [@croeck](https://github.com/croeck).
* [#913](https://github.com/ruby-grape/grape/pull/913): Fix: Invalid accept headers cause internal processing errors (500) when http_codes are defined - [@croeck](https://github.com/croeck).
* [#917](https://github.com/ruby-grape/grape/pull/917): Use HTTPS for rubygems.org - [@O-I](https://github.com/O-I).

### 0.10.1 (12/28/2014)

* [#868](https://github.com/ruby-grape/grape/pull/868), [#862](https://github.com/ruby-grape/grape/pull/862), [#861](https://github.com/ruby-grape/grape/pull/861): Fixed `version`, `prefix`, and other settings being overridden or changing scope when mounting API - [@yesmeck](https://github.com/yesmeck).
* [#864](https://github.com/ruby-grape/grape/pull/864): Fixed `declared(params, include_missing: false)` now returning attributes with `nil` and `false` values - [@ppadron](https://github.com/ppadron).

### 0.10.0 (12/19/2014)

* [#803](https://github.com/ruby-grape/grape/pull/803), [#820](https://github.com/ruby-grape/grape/pull/820): Added `all_or_none_of` parameter validator - [@loveltyoic](https://github.com/loveltyoic), [@natecj](https://github.com/natecj).
* [#774](https://github.com/ruby-grape/grape/pull/774): Extended `mutually_exclusive`, `exactly_one_of`, `at_least_one_of` to work inside any kind of group: `requires` or `optional`, `Hash` or `Array` - [@ShPakvel](https://github.com/ShPakvel).
* [#743](https://github.com/ruby-grape/grape/pull/743): Added `allow_blank` parameter validator to validate non-empty strings - [@elado](https://github.com/elado).
* [#745](https://github.com/ruby-grape/grape/pull/745): Removed `atom+xml`, `rss+xml`, and `jsonapi` content-types - [@akabraham](https://github.com/akabraham).
* [#745](https://github.com/ruby-grape/grape/pull/745): Added `:binary, application/octet-stream` content-type - [@akabraham](https://github.com/akabraham).
* [#757](https://github.com/ruby-grape/grape/pull/757): Changed `desc` can now be used with a block syntax - [@dspaeth-faber](https://github.com/dspaeth-faber).
* [#779](https://github.com/ruby-grape/grape/pull/779): Fixed using `values` with a `default` proc - [@ShPakvel](https://github.com/ShPakvel).
* [#799](https://github.com/ruby-grape/grape/pull/799): Fixed custom validators with required `Hash`, `Array` types - [@bwalex](https://github.com/bwalex).
* [#784](https://github.com/ruby-grape/grape/pull/784): Fixed `present` to not overwrite the previously added contents of the response body whebn called more than once - [@mfunaro](https://github.com/mfunaro).
* [#809](https://github.com/ruby-grape/grape/pull/809): Removed automatic `(.:format)` suffix on paths if you're using only one format (e.g., with `format :json`, `/path` will respond with JSON but `/path.xml` will be a 404) - [@ajvondrak](https://github.com/ajvondrak).
* [#816](https://github.com/ruby-grape/grape/pull/816): Added ability to filter out missing params if params is a nested hash with `declared(params, include_missing: false)` - [@georgimitev](https://github.com/georgimitev).
* [#819](https://github.com/ruby-grape/grape/pull/819): Allowed both `desc` and `description` in the params DSL - [@mzikherman](https://github.com/mzikherman).
* [#821](https://github.com/ruby-grape/grape/pull/821): Fixed passing string value when hash is expected in params - [@rebelact](https://github.com/rebelact).
* [#824](https://github.com/ruby-grape/grape/pull/824): Validate array params against list of acceptable values - [@dnd](https://github.com/dnd).
* [#813](https://github.com/ruby-grape/grape/pull/813): Routing methods dsl refactored to get rid of explicit `paths` parameter - [@AlexYankee](https://github.com/AlexYankee).
* [#826](https://github.com/ruby-grape/grape/pull/826): Find `coerce_type` for `Array` when not specified - [@manovotn](https://github.com/manovotn).
* [#645](https://github.com/ruby-grape/grape/issues/645): Invoking `body false` will return `204 No Content` - [@dblock](https://github.com/dblock).
* [#801](https://github.com/ruby-grape/grape/issues/801): Only evaluate permitted parameter `values` and `default` lazily on each request when declared as a proc - [@dblock](https://github.com/dblock).
* [#679](https://github.com/ruby-grape/grape/issues/679): Fixed `OPTIONS` method returning 404 when combined with `prefix` - [@dblock](https://github.com/dblock).
* [#679](https://github.com/ruby-grape/grape/issues/679): Fixed unsupported methods returning 404 instead of 405 when combined with `prefix` - [@dblock](https://github.com/dblock).

### 0.9.0 (8/27/2014)

#### Features

* [#691](https://github.com/ruby-grape/grape/issues/691): Added `at_least_one_of` parameter validator - [@dblock](https://github.com/dblock).
* [#698](https://github.com/ruby-grape/grape/pull/698): `error!` sets `status` for `Endpoint` too - [@dspaeth-faber](https://github.com/dspaeth-faber).
* [#703](https://github.com/ruby-grape/grape/pull/703): Added support for Auth-Middleware extension - [@dspaeth-faber](https://github.com/dspaeth-faber).
* [#703](https://github.com/ruby-grape/grape/pull/703): Removed `Grape::Middleware::Auth::Basic` - [@dspaeth-faber](https://github.com/dspaeth-faber).
* [#703](https://github.com/ruby-grape/grape/pull/703): Removed `Grape::Middleware::Auth::Digest` - [@dspaeth-faber](https://github.com/dspaeth-faber).
* [#703](https://github.com/ruby-grape/grape/pull/703): Removed `Grape::Middleware::Auth::OAuth2` - [@dspaeth-faber](https://github.com/dspaeth-faber).
* [#719](https://github.com/ruby-grape/grape/pull/719): Allow passing options hash to a custom validator - [@elado](https://github.com/elado).
* [#716](https://github.com/ruby-grape/grape/pull/716): Calling `content-type` will now return the current content-type - [@dblock](https://github.com/dblock).
* [#705](https://github.com/ruby-grape/grape/pull/705): Errors can now be presented with a `Grape::Entity` class - [@dspaeth-faber](https://github.com/dspaeth-faber).

#### Fixes

* [#687](https://github.com/ruby-grape/grape/pull/687): Fix: `mutually_exclusive` and `exactly_one_of` validation error messages now label parameters as strings, consistently with `requires` and `optional` - [@dblock](https://github.com/dblock).

### 0.8.0 (7/10/2014)

#### Features

* [#639](https://github.com/ruby-grape/grape/pull/639): Added support for blocks with reusable params - [@mibon](https://github.com/mibon).
* [#637](https://github.com/ruby-grape/grape/pull/637): Added support for `exactly_one_of` parameter validation - [@Morred](https://github.com/Morred).
* [#626](https://github.com/ruby-grape/grape/pull/626): Added support for `mutually_exclusive` parameters - [@oliverbarnes](https://github.com/oliverbarnes).
* [#617](https://github.com/ruby-grape/grape/pull/617): Running tests on Ruby 2.1.1, Rubinius 2.1 and 2.2, Ruby and JRuby HEAD - [@dblock](https://github.com/dblock).
* [#397](https://github.com/ruby-grape/grape/pull/397): Adds `Grape::Endpoint.before_each` to allow easy helper stubbing - [@mbleigh](https://github.com/mbleigh).
* [#673](https://github.com/ruby-grape/grape/pull/673): Avoid requiring non-existent fields when using Grape::Entity documentation - [@qqshfox](https://github.com/qqshfox).

#### Fixes

* [#671](https://github.com/ruby-grape/grape/pull/671): Allow required param with predefined set of values to be nil inside optional group - [@dm1try](https://github.com/dm1try).
* [#651](https://github.com/ruby-grape/grape/pull/651): The `rescue_from` keyword now properly defaults to rescuing subclasses of exceptions - [@xevix](https://github.com/xevix).
* [#614](https://github.com/ruby-grape/grape/pull/614): Params with `nil` value are now refused by `RegexpValidator` - [@dm1try](https://github.com/dm1try).
* [#494](https://github.com/ruby-grape/grape/issues/494): Fixed performance issue with requests carrying a large payload - [@dblock](https://github.com/dblock).
* [#619](https://github.com/ruby-grape/grape/pull/619): Convert specs to RSpec 3 syntax with Transpec - [@danielspector](https://github.com/danielspector).
* [#632](https://github.com/ruby-grape/grape/pull/632): `Grape::Endpoint#present` causes ActiveRecord to make an extra query during entity's detection - [@fixme](https://github.com/fixme).

### 0.7.0 (4/2/2014)

#### Features

* [#558](https://github.com/ruby-grape/grape/pull/558): Support lambda-based values for params - [@wpschallenger](https://github.com/wpschallenger).
* [#510](https://github.com/ruby-grape/grape/pull/510): Support lambda-based default values for params - [@myitcv](https://github.com/myitcv).
* [#511](https://github.com/ruby-grape/grape/pull/511): Added `required` option for OAuth2 middleware - [@bcm](https://github.com/bcm).
* [#520](https://github.com/ruby-grape/grape/pull/520): Use `default_error_status` to specify the default status code returned from `error!` - [@salimane](https://github.com/salimane).
* [#525](https://github.com/ruby-grape/grape/pull/525): The default status code returned from `error!` has been changed from 403 to 500 - [@dblock](https://github.com/dblock).
* [#526](https://github.com/ruby-grape/grape/pull/526): Allowed specifying headers in `error!` - [@dblock](https://github.com/dblock).
* [#527](https://github.com/ruby-grape/grape/pull/527): The `before_validation` callback is now a distinct one - [@myitcv](https://github.com/myitcv).
* [#530](https://github.com/ruby-grape/grape/pull/530): Added ability to restrict `declared(params)` to the local endpoint with `include_parent_namespaces: false` - [@myitcv](https://github.com/myitcv).
* [#531](https://github.com/ruby-grape/grape/pull/531): Helpers are now available to auth middleware, executing in the context of the endpoint - [@joelvh](https://github.com/joelvh).
* [#540](https://github.com/ruby-grape/grape/pull/540): Ruby 2.1.0 is now supported - [@salimane](https://github.com/salimane).
* [#544](https://github.com/ruby-grape/grape/pull/544): The `rescue_from` keyword now handles subclasses of exceptions by default - [@xevix](https://github.com/xevix).
* [#545](https://github.com/ruby-grape/grape/pull/545): Added `type` (`Array` or `Hash`) support to `requires`, `optional` and `group` - [@bwalex](https://github.com/bwalex).
* [#550](https://github.com/ruby-grape/grape/pull/550): Added possibility to define reusable params - [@dm1try](https://github.com/dm1try).
* [#560](https://github.com/ruby-grape/grape/pull/560): Use `Grape::Entity` documentation to define required and optional parameters with `requires using:` - [@reynardmh](https://github.com/reynardmh).
* [#572](https://github.com/ruby-grape/grape/pull/572): Added `documentation` support to `requires`, `optional` and `group` parameters - [@johnallen3d](https://github.com/johnallen3d).

#### Fixes

* [#600](https://github.com/ruby-grape/grape/pull/600): Don't use an `Entity` constant that is available in the namespace as presenter - [@fuksito](https://github.com/fuksito).
* [#590](https://github.com/ruby-grape/grape/pull/590): Fix issue where endpoint param of type `Integer` cannot set values array - [@xevix](https://github.com/xevix).
* [#586](https://github.com/ruby-grape/grape/pull/586): Do not repeat the same validation error messages - [@kiela](https://github.com/kiela).
* [#508](https://github.com/ruby-grape/grape/pull/508): Allow parameters, such as content encoding, in `content_type` - [@dm1try](https://github.com/dm1try).
* [#492](https://github.com/ruby-grape/grape/pull/492): Don't allow to have nil value when a param is required and has a list of allowed values - [@Antti](https://github.com/Antti).
* [#495](https://github.com/ruby-grape/grape/pull/495): Fixed `ParamsScope#params` for parameters nested inside arrays - [@asross](https://github.com/asross).
* [#498](https://github.com/ruby-grape/grape/pull/498): Dry'ed up options and headers logic, allow headers to be passed to OPTIONS requests - [@karlfreeman](https://github.com/karlfreeman).
* [#500](https://github.com/ruby-grape/grape/pull/500): Skip entity auto-detection when explicitely passed - [@yaneq](https://github.com/yaneq).
* [#503](https://github.com/ruby-grape/grape/pull/503): Calling declared(params) from child namespace fails to include parent namespace defined params - [@myitcv](https://github.com/myitcv).
* [#512](https://github.com/ruby-grape/grape/pull/512): Don't create `Grape::Request` multiple times - [@dblock](https://github.com/dblock).
* [#538](https://github.com/ruby-grape/grape/pull/538): Fixed default values for grouped params - [@dm1try](https://github.com/dm1try).
* [#549](https://github.com/ruby-grape/grape/pull/549): Fixed handling of invalid version headers to return 406 if a header cannot be parsed - [@bwalex](https://github.com/bwalex).
* [#557](https://github.com/ruby-grape/grape/pull/557): Pass `content_types` option to `Grape::Middleware::Error` to fix the content-type header for custom formats - [@bernd](https://github.com/bernd).
* [#585](https://github.com/ruby-grape/grape/pull/585): Fix after boot thread-safety issue - [@etehtsea](https://github.com/etehtsea).
* [#587](https://github.com/ruby-grape/grape/pull/587): Fix oauth2 middleware compatibility with [draft-ietf-oauth-v2-31](http://tools.ietf.org/html/draft-ietf-oauth-v2-31) spec - [@etehtsea](https://github.com/etehtsea).
* [#610](https://github.com/ruby-grape/grape/pull/610): Fixed group keyword was not working with type parameter - [@klausmeyer](https://github.com/klausmeyer).

### 0.6.1 (10/19/2013)

#### Features

* [#475](https://github.com/ruby-grape/grape/pull/475): Added support for the `:jsonapi`, `application/vnd.api+json` media type registered at http://jsonapi.org - [@bcm](https://github.com/bcm).
* [#471](https://github.com/ruby-grape/grape/issues/471): Added parameter validator for a list of allowed values - [@vickychijwani](https://github.com/vickychijwani).
* [#488](https://github.com/ruby-grape/grape/issues/488): Upgraded to Virtus 1.0 - [@dblock](https://github.com/dblock).

#### Fixes

* [#477](https://github.com/ruby-grape/grape/pull/477): Fixed `default_error_formatter` which takes a format symbol - [@vad4msiu](https://github.com/vad4msiu).

#### Development

* Implemented Rubocop, a Ruby code static code analyzer - [@dblock](https://github.com/dblock).

### 0.6.0 (9/16/2013)

#### Features

* Grape is no longer tested against Ruby 1.8.7 - [@dblock](https://github.com/dblock).
* [#442](https://github.com/ruby-grape/grape/issues/442): Enable incrementally building on top of a previous API version - [@dblock](https://github.com/dblock).
* [#442](https://github.com/ruby-grape/grape/issues/442): API `version` can now take an array of multiple versions - [@dblock](https://github.com/dblock).
* [#444](https://github.com/ruby-grape/grape/issues/444): Added `:en` as fallback locale for I18n - [@aew](https://github.com/aew).
* [#448](https://github.com/ruby-grape/grape/pull/448): Adding POST style parameters for DELETE requests - [@dquimper](https://github.com/dquimper).
* [#450](https://github.com/ruby-grape/grape/pull/450): Added option to pass an exception handler lambda as an argument to `rescue_from` - [@robertopedroso](https://github.com/robertopedroso).
* [#443](https://github.com/ruby-grape/grape/pull/443): Let `requires` and `optional` take blocks that initialize new scopes - [@asross](https://github.com/asross).
* [#452](https://github.com/ruby-grape/grape/pull/452): Added `with` as a hash option to specify handlers for `rescue_from` and `error_formatter` - [@robertopedroso](https://github.com/robertopedroso).
* [#433](https://github.com/ruby-grape/grape/issues/433), [#462](https://github.com/ruby-grape/grape/issues/462): Validation errors are now collected and `Grape::Exceptions::ValidationErrors` is raised - [@stevschmid](https://github.com/stevschmid).

#### Fixes

* [#428](https://github.com/ruby-grape/grape/issues/428): Removes memoization from `Grape::Request` params to prevent middleware from freezing parameter values before `Formatter` can get them - [@mbleigh](https://github.com/mbleigh).

### 0.5.0 (6/14/2013)

#### Features

* [#344](https://github.com/ruby-grape/grape/pull/344): Added `parser :type, nil` which disables input parsing for a given content-type - [@dblock](https://github.com/dblock).
* [#381](https://github.com/ruby-grape/grape/issues/381): Added `cascade false` option at API level to remove the `X-Cascade: true` header from the API response - [@dblock](https://github.com/dblock).
* [#392](https://github.com/ruby-grape/grape/pull/392): Extracted headers and params from `Endpoint` to `Grape::Request` - [@niedhui](https://github.com/niedhui).
* [#376](https://github.com/ruby-grape/grape/pull/376): Added `route_param`, syntax sugar for quick declaration of route parameters - [@mbleigh](https://github.com/mbleigh).
* [#390](https://github.com/ruby-grape/grape/pull/390): Added default value for an `optional` parameter - [@oivoodoo](https://github.com/oivoodoo).
* [#403](https://github.com/ruby-grape/grape/pull/403): Added support for versioning using the `Accept-Version` header - [@politician](https://github.com/politician).
* [#407](https://github.com/ruby-grape/grape/issues/407): Specifying `default_format` will also set the default POST/PUT data parser to the given format - [@dblock](https://github.com/dblock).
* [#241](https://github.com/ruby-grape/grape/issues/241): Present with multiple entities using an optional Symbol - [@niedhui](https://github.com/niedhui).

#### Fixes

* [#378](https://github.com/ruby-grape/grape/pull/378): Fix: stop rescuing all exceptions during formatting - [@kbarrette](https://github.com/kbarrette).
* [#380](https://github.com/ruby-grape/grape/pull/380): Fix: `Formatter#read_body_input` when transfer encoding is chunked - [@paulnicholon](https://github.com/paulnicholson).
* [#347](https://github.com/ruby-grape/grape/issues/347): Fix: handling non-hash body params - [@paulnicholon](https://github.com/paulnicholson).
* [#394](https://github.com/ruby-grape/grape/pull/394): Fix: path version no longer overwrites a `version` parameter - [@tmornini](https://github.com/tmornini).
* [#412](https://github.com/ruby-grape/grape/issues/412): Fix: specifying `content_type` will also override the selection of the data formatter - [@dblock](https://github.com/dblock).
* [#383](https://github.com/ruby-grape/grape/issues/383): Fix: Mounted APIs aren't inheriting settings (including `before` and `after` filters) - [@seanmoon](https://github.com/seanmoon).
* [#408](https://github.com/ruby-grape/grape/pull/408): Fix: Goliath passes request header keys as symbols not strings - [@bobek](https://github.com/bobek).
* [#417](https://github.com/ruby-grape/grape/issues/417): Fix: Rails 4 does not rewind input, causes POSTed data to be empty - [@dblock](https://github.com/dblock).
* [#423](https://github.com/ruby-grape/grape/pull/423): Fix: `Grape::Endpoint#declared` now correctly handles nested params (ie. declared with `group`) - [@jbarreneche](https://github.com/jbarreneche).
* [#427](https://github.com/ruby-grape/grape/issues/427): Fix: `declared(params)` breaks when `params` contains array - [@timhabermaas](https://github.com/timhabermaas).

### 0.4.1 (4/1/2013)

* [#375](https://github.com/ruby-grape/grape/pull/375): Fix: throwing an `:error` inside a middleware doesn't respect the `format` settings - [@dblock](https://github.com/dblock).

### 0.4.0 (3/17/2013)

* [#356](https://github.com/ruby-grape/grape/pull/356): Fix: presenting collections other than `Array` (eg. `ActiveRecord::Relation`) - [@zimbatm](https://github.com/zimbatm).
* [#352](https://github.com/ruby-grape/grape/pull/352): Fix: using `Rack::JSONP` with `Grape::Entity` responses - [@deckchair](https://github.com/deckchair).
* [#347](https://github.com/ruby-grape/grape/issues/347): Grape will accept any valid JSON as PUT or POST, including strings, symbols and arrays - [@qqshfox](https://github.com/qqshfox), [@dblock](https://github.com/dblock).
* [#347](https://github.com/ruby-grape/grape/issues/347): JSON format APIs always return valid JSON, eg. strings are now returned as `"string"` and no longer `string` - [@dblock](https://github.com/dblock).
* Raw body input from POST and PUT requests (`env['rack.input'].read`) is now available in `api.request.input` - [@dblock](https://github.com/dblock).
* Parsed body input from POST and PUT requests is now available in `api.request.body` - [@dblock](https://github.com/dblock).
* [#343](https://github.com/ruby-grape/grape/pull/343): Fix: return `Content-Type: text/plain` with error 405 - [@gustavosaume](https://github.com/gustavosaume), [@wyattisimo](https://github.com/wyattisimo).
* [#357](https://github.com/ruby-grape/grape/pull/357): Grape now requires Rack 1.3.0 or newer - [@jhecking](https://github.com/jhecking).
* [#320](https://github.com/ruby-grape/grape/issues/320): API `namespace` now supports `requirements` - [@niedhui](https://github.com/niedhui).
* [#353](https://github.com/ruby-grape/grape/issues/353): Revert to standard Ruby logger formatter, `require active_support/all` if you want old behavior - [@rhunter](https://github.com/rhunter), [@dblock](https://github.com/dblock).
* Fix: `undefined method 'call' for nil:NilClass` for an API method implementation without a block, now returns an empty string - [@dblock](https://github.com/dblock).

### 0.3.2 (2/28/2013)

* [#355](https://github.com/ruby-grape/grape/issues/355): Relax dependency constraint on Hashie - [@reset](https://github.com/reset).

### 0.3.1 (2/25/2013)

* [#351](https://github.com/ruby-grape/grape/issues/351): Compatibility with Ruby 2.0 - [@mbleigh](https://github.com/mbleigh).

### 0.3.0 (02/21/2013)

* [#294](https://github.com/ruby-grape/grape/issues/294): Extracted `Grape::Entity` into a [grape-entity](https://github.com/agileanimal/grape-entity) gem - [@agileanimal](https://github.com/agileanimal).
* [#340](https://github.com/ruby-grape/grape/pull/339), [#342](https://github.com/ruby-grape/grape/pull/342): Added `:cascade` option to `version` to allow disabling of rack/mount cascade behavior - [@dieb](https://github.com/dieb).
* [#333](https://github.com/ruby-grape/grape/pull/333): Added support for validation of arrays in `params` - [@flyerhzm](https://github.com/flyerhzm).
* [#306](https://github.com/ruby-grape/grape/issues/306): Added I18n support for all Grape exceptions - [@niedhui](https://github.com/niedhui).
* [#309](https://github.com/ruby-grape/grape/pull/309): Added XML support to the entity presenter - [@johnnyiller](https://github.com/johnnyiller), [@dblock](https://github.com/dblock).
* [#131](https://github.com/ruby-grape/grape/issues/131): Added instructions for Grape API reloading in Rails - [@jyn](https://github.com/jyn), [@dblock](https://github.com/dblock).
* [#317](https://github.com/ruby-grape/grape/issues/317): Added `headers` that returns a hash of parsed HTTP request headers - [@dblock](https://github.com/dblock).
* [#332](https://github.com/ruby-grape/grape/pull/332): `Grape::Exceptions::Validation` now contains full nested parameter names - [@alovak](https://github.com/alovak).
* [#328](https://github.com/ruby-grape/grape/issues/328): API version can now be specified as both String and Symbol - [@dblock](https://github.com/dblock).
* [#190](https://github.com/ruby-grape/grape/issues/190): When you add a `GET` route for a resource, a route for the `HEAD` method will also be added automatically. You can disable this behavior with `do_not_route_head!` - [@dblock](https://github.com/dblock).
* Added `do_not_route_options!`, which disables the automatic creation of the `OPTIONS` route - [@dblock](https://github.com/dblock).
* [#309](https://github.com/ruby-grape/grape/pull/309): An XML format API will return an error instead of returning a string representation of the response if the latter cannot be converted to XML - [@dblock](https://github.com/dblock).
* A formatter that raises an exception will cause the API to return a 500 error - [@dblock](https://github.com/dblock).
* [#322](https://github.com/ruby-grape/grape/issues/322): When returning a 406 status, Grape will include the requested format or content-type in the response body - [@dblock](https://github.com/dblock).
* [#60](https://github.com/ruby-grape/grape/issues/60): Fix: mounting of a Grape API onto a path - [@dblock](https://github.com/dblock).
* [#335](https://github.com/ruby-grape/grape/pull/335): Fix: request body parameters from a `PATCH` request not available in `params` - [@FreakenK](https://github.com/FreakenK).

### 0.2.6 (01/11/2013)

* Fix: support content-type with character set when parsing POST and PUT input - [@dblock](https://github.com/dblock).
* Fix: CVE-2013-0175, multi_xml parse vulnerability, require multi_xml 0.5.2 - [@dblock](https://github.com/dblock).

### 0.2.5 (01/10/2013)

* Added support for custom parsers via `parser`, in addition to built-in multipart, JSON and XML parsers - [@dblock](https://github.com/dblock).
* Removed `body_params`, data sent via a POST or PUT with a supported content-type is merged into `params` - [@dblock](https://github.com/dblock).
* Setting `format` will automatically remove other content-types by calling `content_type` - [@dblock](https://github.com/dblock).
* Setting `content_type` will prevent any input data other than the matching content-type or any Rack-supported form and parseable media types (`application/x-www-form-urlencoded`, `multipart/form-data`, `multipart/related` and `multipart/mixed`) from being parsed - [@dblock](https://github.com/dblock).
* [#305](https://github.com/ruby-grape/grape/issues/305): Fix: presenting arrays of objects via `represent` or when auto-detecting an `Entity` constant in the objects being presented - [@brandonweiss](https://github.com/brandonweiss).
* [#306](https://github.com/ruby-grape/grape/issues/306): Added i18n support for validation error messages - [@niedhui](https://github.com/niedhui).

### 0.2.4 (01/06/2013)

* [#297](https://github.com/ruby-grape/grape/issues/297): Added `default_error_formatter` - [@dblock](https://github.com/dblock).
* [#297](https://github.com/ruby-grape/grape/issues/297): Setting `format` will automatically set `default_error_formatter` - [@dblock](https://github.com/dblock).
* [#295](https://github.com/ruby-grape/grape/issues/295): Storing original API source block in endpoint's `source` attribute - [@dblock](https://github.com/dblock).
* [#293](https://github.com/ruby-grape/grape/pull/293): Added options to `cookies.delete`, enables passing a path - [@inst](https://github.com/inst).
* [#174](https://github.com/ruby-grape/grape/issues/174): The value of `env['PATH_INFO']` is no longer altered with `path` versioning - [@dblock](https://github.com/dblock).
* [#296](https://github.com/ruby-grape/grape/issues/296): Fix: ArgumentError with default error formatter - [@dblock](https://github.com/dblock).
* [#298](https://github.com/ruby-grape/grape/pull/298): Fix: subsequent calls to `body_params` would fail due to IO read - [@justinmcp](https://github.com/justinmcp).
* [#301](https://github.com/ruby-grape/grape/issues/301): Fix: symbol memory leak in cookie and formatter middleware - [@dblock](https://github.com/dblock).
* [#300](https://github.com/ruby-grape/grape/issues/300): Fix `Grape::API.routes` to include mounted api routes - [@aiwilliams](https://github.com/aiwilliams).
* [#302](https://github.com/ruby-grape/grape/pull/302): Fix: removed redundant `autoload` entries - [@ugisozols](https://github.com/ugisozols).
* [#172](https://github.com/ruby-grape/grape/issues/172): Fix: MultiJson deprecated methods warnings - [@dblock](https://github.com/dblock).
* [#133](https://github.com/ruby-grape/grape/issues/133): Fix: header-based versioning with use of `prefix` - [@seanmoon](https://github.com/seanmoon), [@dblock](https://github.com/dblock).
* [#280](https://github.com/ruby-grape/grape/issues/280): Fix: grouped parameters mangled in `route_params` hash - [@marcusg](https://github.com/marcusg), [@dblock](https://github.com/dblock).
* [#304](https://github.com/ruby-grape/grape/issues/304): Fix: `present x, :with => Entity` returns class references with `format :json` - [@dblock](https://github.com/dblock).
* [#196](https://github.com/ruby-grape/grape/issues/196): Fix: root requests don't work with `prefix` - [@dblock](https://github.com/dblock).

### 0.2.3 (24/12/2012)

* [#179](https://github.com/ruby-grape/grape/issues/178): Using `content_type` will remove all default content-types - [@dblock](https://github.com/dblock).
* [#265](https://github.com/ruby-grape/grape/issues/264): Fix: Moved `ValidationError` into `Grape::Exceptions` - [@thepumpkin1979](https://github.com/thepumpkin1979).
* [#269](https://github.com/ruby-grape/grape/pull/269): Fix: `LocalJumpError` will not be raised when using explict return in API methods - [@simulacre](https://github.com/simulacre).
* [#86](https://github.com/ruby-grape/grape/issues/275): Fix Path-based versioning not recognizing `/` route - [@walski](https://github.com/walski).
* [#273](https://github.com/ruby-grape/grape/pull/273): Disabled formatting via `serializable_hash` and added support for `format :serializable_hash` - [@dblock](https://github.com/dblock).
* [#277](https://github.com/ruby-grape/grape/pull/277): Added a DSL to declare `formatter` in API settings - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* [#284](https://github.com/ruby-grape/grape/pull/284): Added a DSL to declare `error_formatter` in API settings - [@dblock](https://github.com/dblock).
* [#285](https://github.com/ruby-grape/grape/pull/285): Removed `error_format` from API settings, now matches request format - [@dblock](https://github.com/dblock).
* [#290](https://github.com/ruby-grape/grape/pull/290): The default error format for XML is now `error/message` instead of `hash/error` - [@dpsk](https://github.com/dpsk).
* [#44](https://github.com/ruby-grape/grape/issues/44): Pass `env` into formatters to enable templating - [@dblock](https://github.com/dblock).

### 0.2.2 (12/10/2012)

#### Features

* [#201](https://github.com/ruby-grape/grape/pull/201), [#236](https://github.com/ruby-grape/grape/pull/236), [#221](https://github.com/ruby-grape/grape/pull/221): Added coercion and validations support to `params` DSL - [@schmurfy](https://github.com/schmurfy), [@tim-vandecasteele](https://github.com/tim-vandecasteele), [@adamgotterer](https://github.com/adamgotterer).
* [#204](https://github.com/ruby-grape/grape/pull/204): Added ability to declare shared `params` at `namespace` level - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* [#234](https://github.com/ruby-grape/grape/pull/234): Added a DSL for creating entities via mixin - [@mbleigh](https://github.com/mbleigh).
* [#240](https://github.com/ruby-grape/grape/pull/240): Define API response format from a query string `format` parameter, if specified - [@neetiraj](https://github.com/neetiraj).
* Adds Endpoint#declared to easily filter out unexpected params - [@mbleigh](https://github.com/mbleigh).

#### Fixes

* [#248](https://github.com/ruby-grape/grape/pull/248): Fix: API `version` returns last version set - [@narkoz](https://github.com/narkoz).
* [#242](https://github.com/ruby-grape/grape/issues/242): Fix: permanent redirect status should be `301`, was `304` - [@adamgotterer](https://github.com/adamgotterer).
* [#211](https://github.com/ruby-grape/grape/pull/211): Fix: custom validations are no longer triggered when optional and parameter is not present - [@adamgotterer](https://github.com/adamgotterer).
* [#210](https://github.com/ruby-grape/grape/pull/210): Fix: `Endpoint#body_params` causing undefined method 'size' - [@adamgotterer](https://github.com/adamgotterer).
* [#205](https://github.com/ruby-grape/grape/pull/205): Fix: Corrected parsing of empty JSON body on POST/PUT - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* [#181](https://github.com/ruby-grape/grape/pull/181): Fix: Corrected JSON serialization of nested hashes containing `Grape::Entity` instances - [@benrosenblum](https://github.com/benrosenblum).
* [#203](https://github.com/ruby-grape/grape/pull/203): Added a check to `Entity#serializable_hash` that verifies an entity exists on an object - [@adamgotterer](https://github.com/adamgotterer).
* [#208](https://github.com/ruby-grape/grape/pull/208): `Entity#serializable_hash` must also check if attribute is generated by a user supplied block - [@ppadron](https://github.com/ppadron).
* [#252](https://github.com/ruby-grape/grape/pull/252): Resources that don't respond to a requested HTTP method return 405 (Method Not Allowed) instead of 404 (Not Found) - [@simulacre](https://github.com/simulacre).

### 0.2.1 (7/11/2012)

* [#186](https://github.com/ruby-grape/grape/issues/186): Fix: helpers allow multiple calls with modules and blocks - [@ppadron](https://github.com/ppadron).
* [#188](https://github.com/ruby-grape/grape/pull/188): Fix: multi-method routes append '(.:format)' only once - [@kainosnoema](https://github.com/kainosnoema).
* [#64](https://github.com/ruby-grape/grape/issues/64), [#180](https://github.com/ruby-grape/grape/pull/180): Added support to `GET` request bodies as parameters - [@bobbytables](https://github.com/bobbytables).
* [#175](https://github.com/ruby-grape/grape/pull/175): Added support for API versioning based on a request parameter - [@jackcasey](https://github.com/jackcasey).
* [#168](https://github.com/ruby-grape/grape/pull/168): Fix: Formatter can parse symbol keys in the headers hash - [@netmask](https://github.com/netmask).
* [#169](https://github.com/ruby-grape/grape/pull/169): Silence multi_json deprecation warnings - [@whiteley](https://github.com/whiteley).
* [#166](https://github.com/ruby-grape/grape/pull/166): Added support for `redirect`, including permanent and temporary - [@allenwei](https://github.com/allenwei).
* [#159](https://github.com/ruby-grape/grape/pull/159): Added `:requirements` to routes, allowing to use reserved characters in paths - [@gaiottino](https://github.com/gaiottino).
* [#156](https://github.com/ruby-grape/grape/pull/156): Added support for adding formatters to entities - [@bobbytables](https://github.com/bobbytables).
* [#183](https://github.com/ruby-grape/grape/pull/183): Added ability to include documentation in entities - [@flah00](https://github.com/flah00).
* [#189](https://github.com/ruby-grape/grape/pull/189): `HEAD` requests no longer return a body - [@stephencelis](https://github.com/stephencelis).
* [#97](https://github.com/ruby-grape/grape/issues/97): Allow overriding `Content-Type` - [@dblock](https://github.com/dblock).

### 0.2.0 (3/28/2012)

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

### 0.1.5 (6/14/2011)

* Extended exception handling to all exceptions - [@dblock](https://github.com/dblock).
* Added support for returning JSON objects from within error blocks - [@dblock](https://github.com/dblock).
* Added support for handling incoming JSON in body - [@tedkulp](https://github.com/tedkulp).
* Added support for HTTP digest authentication - [@daddz](https://github.com/daddz).

### 0.1.4 (4/8/2011)

* Allow multiple definitions of the same endpoint under multiple versions - [@chrisrhoden](https://github.com/chrisrhoden).
* Added support for multipart URL parameters - [@mcastilho](https://github.com/mcastilho).
* Added support for custom formatters - [@spraints](https://github.com/spraints).

### 0.1.3 (1/10/2011)

* Added support for JSON format in route matching - [@aiwilliams](https://github.com/aiwilliams).
* Added suport for custom middleware - [@mbleigh](https://github.com/mbleigh).

### 0.1.1 (11/14/2010)

* Endpoints properly reset between each request - [@mbleigh](https://github.com/mbleigh).

### 0.1.0 (11/13/2010)

* Initial public release - [@mbleigh](https://github.com/mbleigh).
