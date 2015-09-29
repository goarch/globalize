module Globalize
  module ActiveRecord
    module ClassMethods
      delegate :translated_languages, :set_translations_table_name, :to => :translation_class

      def with_languages(*languages)
        all.merge translation_class.with_languages(*languages)
      end

      def with_locales(*locales)
        all.merge translation_class.with_locales(*locales)
      end

      def with_translations(*languages)
        languages = translated_languages if languages.empty?
        preload(:translations).joins(:translations).readonly(false).with_languages(languages)
      end

      def with_translated_attribute(name, value, locales = Globalize.fallbacks)
        with_translations.where(
          translated_column_name(name)    => value,
          translated_column_name(:locale) => Array(locales).map(&:to_s)
        )
      end

      def translated?(name)
        translated_attribute_names.include?(name.to_sym)
      end

      def translation_class
        @translation_class ||= begin
          if self.const_defined?(:Translation, false)
            klass = self.const_get(:Translation, false)
          else
            klass = self.const_set(:Translation, Class.new(Globalize::ActiveRecord::Translation))
          end

          klass.belongs_to :globalized_model, :class_name => self.name, :foreign_key => translation_options[:foreign_key]
          klass
        end
      end

      def translations_table_name
        translation_class.table_name
      end

      def translated_column_name(name)
        "#{translation_class.table_name}.#{name}"
      end

      private

      # Override the default relation method in order to return a subclass
      # of ActiveRecord::Relation with custom finder methods for translated
      # attributes.
      def relation
        super.extending!(QueryMethods)
      end

      protected

      def define_translated_attr_reader(name)
        define_method(name) do |*args|
          Globalize::Interpolation.interpolate(name, self, args)
        end
        alias_method :"#{name}_before_type_cast", name
      end

      def define_translated_attr_writer(name)
        define_method(:"#{name}=") do |value|
          write_attribute(name, value)
        end
      end

      def define_translated_attr_accessor(name)
        define_translated_attr_reader(name)
        define_translated_attr_writer(name)
      end

      def define_translations_reader(name)
        define_method(:"#{name}_translations") do
          #hash = translated_attribute_by_locale(name)
          hash = translated_attribute_by_langauge(name)
          globalize.stash.keys.each_with_object(hash) do |language, result|
            result[language] = globalize.fetch_stash(language, name) if globalize.stash_contains?(language, name)
          end
        end
      end

      def define_translations_writer(name)
        define_method(:"#{name}_translations=") do |value|
          #value.each do |(locale, value)|
          value.each do |(language, value)|
            write_attribute name, value, :language => langauge
          end
        end
      end

      def define_translations_accessor(name)
        define_translations_reader(name)
        define_translations_writer(name)
      end
    end
  end
end
