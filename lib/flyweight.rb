module Flyweight
  module Base
    def self.included base
      base.extend Flyweight::Base::ClassMethods
    end
    
    module ClassMethods
      def flyweight field, args={}
        collection = args[:with] || field.to_s.pluralize
        values     = I18n::t(collection).keys
        values.map!(&:to_s) if values.first.is_a?(Symbol)
        
        instance_eval """
          def #{collection}_values
            #{values.inspect}
          end
          def #{collection}_translations
            I18n::t('#{collection}')
          end
          def #{collection}_collection # For use with simple_form
            #{collection}_translations.invert
          end
        """
          
        class_eval """
          def #{field}_to_s
            if #{field}.is_a?(Symbol)
              I18n::t(\"#{collection}.\#{#{field}}\")
            else
              I18n::t(\"#{collection}\")[#{field}]
            end
          end
        """
        
        @flyweights ||= {}
        @flyweights[field] = collection
        
        validates field, :inclusion=>{:in=>values, :allow_blank=>true}
      end
    end
  end
  
  module Builder
    def input_with_flyweight field, args={}
      collection = @object.class.instance_variable_get("@flyweights")[field]
      if @object.class.respond_to? :"#{collection}_collection"
        options = @object.class.send :"#{collection}_collection"
        input_without_flyweight field, {:collection=>options}.merge(args)
      else
        input_without_flyweight field, args
      end
    end
  end
end

ActiveRecord::Base.send :include, Flyweight::Base

if defined?(SimpleForm)
  SimpleForm::FormBuilder.send :include, Flyweight::Builder
  SimpleForm::FormBuilder.send :alias_method_chain, :input, :flyweight
end