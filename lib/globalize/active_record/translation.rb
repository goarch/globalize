module Globalize
  module ActiveRecord
    class Translation < ::ActiveRecord::Base

      belongs_to :translator

      delegate :language, to: :translator
      validates_presence_of :translator_id


      class << self
        # Sometimes ActiveRecord queries .table_exists? before the table name
        # has even been set which results in catastrophic failure.
        def table_exists?
          table_name.present? && super
        end

        def with_languages(*languages)
          # Avoid using "IN" with SQL queries when only using one locale.
          languages = languages.flatten.map(&:to_s)
          languages = languages.first if languages.one?
          where :languages => languages
        end
        alias with_language with_languages

        def with_locales(*locales)
          # Avoid using "IN" with SQL queries when only using one locale.
          locales = locales.flatten.map(&:to_s)
          locales = locales.first if locales.one?
          where :locale => locales
        end
        alias with_locale with_locales

        def translated_locales
          select('DISTINCT locale').order(:locale).map(&:locale)
        end

        def translated_languages
          #select('DISTINCT langauge').order(:langauge).map(&:langauge)
          #map(&:language).uniq.order(:langauge)
          map {|t| t.language.code}.uniq
        end
      end

      def locale
        _locale = read_attribute :locale
        _locale.present? ? _locale.to_sym : _locale
      end

      def locale=(locale)
        write_attribute :locale, locale.to_s
      end
    end
  end
end

# Setting this will force polymorphic associations to subclassed objects
# to use their table_name rather than the parent object's table name,
# which will allow you to get their models back in a more appropriate
# format.
#
# See http://www.ruby-forum.com/topic/159894 for details.
Globalize::ActiveRecord::Translation.abstract_class = true
