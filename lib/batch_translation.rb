module ActionView
  module Helpers
    class FormBuilder
      #
      # Helper that renders globalize_translations fields
      # on a per-locale basis, so you can use them separately
      # in the same form and still saving them all at once
      # in the same request.
      #
      # Use it like this:
      #
      # <h1>Editing post</h1> 
      #
      # <% form_for(@post) do |f| %>
      #   <%= f.error_messages %>
      #
      #   <h2>English (default locale)</h2>
      #   <p><%= f.text_field :title %></p>
      #   <p><%= f.text_field :teaser %></p>
      #   <p><%= f.text_field :body %></p>
      #
      #   <hr/>
      #
      #   <h2>Spanish translation</h2>
      #   <% f.globalize_fields_for :es do |g| %>
      #     <p><%= g.text_field :title %></p>
      #     <p><%= g.text_field :teaser %></p>
      #     <p><%= g.text_field :body %></p>
      #   <% end %>
      #
      #   <hr/>
      #
      #   <h2>French translation</h2>
      #   <% f.globalize_fields_for :fr do |g| %>
      #     <p><%= g.text_field :title %></p>
      #     <p><%= g.text_field :teaser %></p>
      #     <p><%= g.text_field :body %></p>
      #   <% end %>
      #  
      # <% end %>
      #
      def globalize_fields_for(locale, *args, &proc)
        raise ArgumentError, "Missing block" unless block_given?
        @index = @index ? @index + 1 : 1
        object_name = "#{@object_name}[globalize_translations_attributes][#{@index}]"
        object = @object.globalize_translations.find_by_locale locale.to_s
        @template.concat @template.hidden_field_tag("#{object_name}[id]", object ? object.id : ""), proc.binding
        @template.concat @template.hidden_field_tag("#{object_name}[locale]", locale), proc.binding
        @template.fields_for(object_name, object, *args, &proc)
      end
    end
  end
end

module Globalize
  module Model
    module ActiveRecord
      module Translated
        module Callbacks
          def enable_nested_attributes
            accepts_nested_attributes_for :globalize_translations
          end
        end
        module InstanceMethods
          def after_save
            init_translations
          end
          # Builds an empty translation for each available 
          # locale not in use after creation
          def init_translations
            I18n.available_locales.reject{|key| key == :root }.each do |locale|
              translation = self.globalize_translations.find_by_locale locale.to_s
              if translation.nil?
                # logger.debug "Building empty translation with locale '#{locale}'"
                globalize_translations.build :locale => locale
                save
              end
            end
          end
        end
      end
    end
  end
end