module ActsAsWiki::Markable
	module Core
		def self.included(base)
			base.send :include, ActsAsWiki::Markable::Core::InstanceMethods
			base.extend ActsAsWiki::Markable::Core::ClassMethods
			
			base.class_eval do 
				before_save :cache_wiki_html
			end
			
			base.initialize_acts_as_wiki_core
		end
		
		module ClassMethods
			
			def initialize_acts_as_wiki_core
				class_eval do 
					has_one :wiki_markup, :as => :markable, :class_name => "ActsAsWiki::WikiMarkup"
					accepts_nested_attributes_for :wiki_markup
					
					alias_attribute :wiki_text_column, acts_as_wiki_options[:column].to_sym
				end
				
			end
			
		end
		
		module InstanceMethods
			
			def allow_markup!
				if self.wiki_markup
					return self.wiki_markup
				else
					self.wiki_markup = ActsAsWiki::WikiMarkup.create
				end
			end
			
			def dissallow_markup!
				if self.wiki_markup
					self.wiki_markup.destroy
					self.wiki_markup = nil
				end
			end
			
			def has_markup?
				!self.wiki_markup.nil?
			end
			
			protected
			
			def cache_wiki_html
				if has_markup?
					self.wiki_text_column = self.wiki_markup.text
				end
				return true
			end
			
		end
	end
end