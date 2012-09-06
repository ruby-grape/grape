require 'pry'

module Grape
  module Validations

    class PermissionValidator < Validator

      def permissions
        true
      end

      def validate!(request_params)
        forbidden = false
        forbidden_keys = []

        request_params.keys.each do |param|
          unless @attrs.include? param.to_sym
            forbidden = true
            forbidden_keys << param
          end
        end

        if forbidden
          throw :error, :status => 400, :message => "forbidden parameter: #{forbidden_keys.join(',')}"
          # throw :error, :status => 400, :message => "#{@attrs} |||| #{forbidden_keys.join(',')}"
        end
      end
        # @attrs.each do |attr_name|
        #   if @required || params.has_key?(attr_name)
        #     validate_param!(attr_name, params)
        #   end
        # end



      # def validate_param!(attr_name, params)
      #   @params = params
      #   params.keys.each do |key|
      #     puts "Key=" + key.to_s
      #   end

      #   unless params.has_key?(attr_name)
      #     throw :error, :status => 400, :message => "forbidden parameter: #{attr_name}"
      #   end

      # end
    end

  end
end
