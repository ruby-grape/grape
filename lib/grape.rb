require 'logger'
require 'rack'
require 'rack/mount'
require 'rack/builder'
require 'rack/accept'
require 'rack/auth/basic'
require 'rack/auth/digest/md5'
require 'hashie'
require 'set'
require 'active_support/version'
require 'active_support/core_ext/hash/indifferent_access'

if ActiveSupport::VERSION::MAJOR >= 4
  require 'active_support/core_ext/object/deep_dup'
else
  require_relative 'backports/active_support/deep_dup'
end

require 'active_support/ordered_hash'
require 'active_support/core_ext/object/conversions'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/dependencies/autoload'
require 'grape/util/content_types'
require 'multi_json'
require 'multi_xml'
require 'virtus'
require 'i18n'
require 'thread'

I18n.load_path << File.expand_path('../grape/locale/en.yml', __FILE__)

module Grape
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :API
    autoload :Endpoint

    autoload :Route
    autoload :Namespace

    autoload :Path

    autoload :Cookies
    autoload :Validations
    autoload :Request, 'grape/http/request'
  end

  module Http
    extend ActiveSupport::Autoload
    eager_autoload do
      autoload :Headers
    end
  end

  module Exceptions
    extend ActiveSupport::Autoload
    autoload :Base
    autoload :Validation
    autoload :ValidationErrors
    autoload :MissingVendorOption
    autoload :MissingMimeType
    autoload :MissingOption
    autoload :InvalidFormatter
    autoload :InvalidVersionerOption
    autoload :UnknownValidator
    autoload :UnknownOptions
    autoload :InvalidWithOptionForRepresent
    autoload :IncompatibleOptionValues
    autoload :MissingGroupTypeError,          'grape/exceptions/missing_group_type'
    autoload :UnsupportedGroupTypeError,      'grape/exceptions/unsupported_group_type'
    autoload :InvalidMessageBody
    autoload :InvalidAcceptHeader
  end

  module ErrorFormatter
    extend ActiveSupport::Autoload
    autoload :Base
    autoload :Json
    autoload :Txt
    autoload :Xml
  end

  module Formatter
    extend ActiveSupport::Autoload
    autoload :Base
    autoload :Json
    autoload :SerializableHash
    autoload :Txt
    autoload :Xml
  end

  module Parser
    extend ActiveSupport::Autoload
    autoload :Base
    autoload :Json
    autoload :Xml
  end

  module Middleware
    extend ActiveSupport::Autoload
    autoload :Base
    autoload :Versioner
    autoload :Formatter
    autoload :Error
    autoload :Globals

    module Auth
      extend ActiveSupport::Autoload
      autoload :Base
      autoload :DSL
      autoload :StrategyInfo
      autoload :Strategies
    end

    module Versioner
      extend ActiveSupport::Autoload
      autoload :Path
      autoload :Header
      autoload :Param
      autoload :AcceptVersionHeader
    end
  end

  module Util
    extend ActiveSupport::Autoload
    autoload :InheritableValues
    autoload :StackableValues
    autoload :InheritableSetting
    autoload :StrictHashConfiguration
  end

  module DSL
    extend ActiveSupport::Autoload
    eager_autoload do
      autoload :API
      autoload :Callbacks
      autoload :Settings
      autoload :Configuration
      autoload :InsideRoute
      autoload :Helpers
      autoload :Middleware
      autoload :Parameters
      autoload :RequestResponse
      autoload :Routing
      autoload :Validations
    end
  end

  class API
    extend ActiveSupport::Autoload
    autoload :Helpers
  end

  module Presenters
    extend ActiveSupport::Autoload
    autoload :Presenter
  end
end

require 'grape/validations/validators/base'
require 'grape/validations/attributes_iterator'
require 'grape/validations/validators/allow_blank'
require 'grape/validations/validators/at_least_one_of'
require 'grape/validations/validators/coerce'
require 'grape/validations/validators/default'
require 'grape/validations/validators/exactly_one_of'
require 'grape/validations/validators/mutual_exclusion'
require 'grape/validations/validators/presence'
require 'grape/validations/validators/regexp'
require 'grape/validations/validators/values'
require 'grape/validations/params_scope'
require 'grape/validations/validators/all_or_none'

require 'grape/version'
