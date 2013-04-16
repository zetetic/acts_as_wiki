module ActsAsWiki::Markable
	module Core
		def self.included(base)
			require 'redcloth'
      require 'red_cloth_custom'
			
			base.send :include, ActsAsWiki::Markable::Core::InstanceMethods
			base.extend ActsAsWiki::Markable::Core::ClassMethods
			
			base.class_eval do 
				before_update :cache_wiki_html
			end
			
			base.initialize_acts_as_wiki_core
		end
		
		module ClassMethods
			
			def initialize_acts_as_wiki_core
				class_eval do 
					has_many :wiki_markups, :as => :markable, :class_name => "ActsAsWiki::WikiMarkup", :dependent => :destroy
					accepts_nested_attributes_for :wiki_markups, :reject_if => :all_blank
				end
			end
			
		end
		
		module InstanceMethods
		  
		  def dump
		    pp "-" * 8
		    pp ActsAsWiki::WikiMarkup.all
		    pp "-" * 8
		  end
			
			def allow_markup!
				if self.wiki_markups.present?
          self.wiki_markups.each do |wm|
            val = self.send(wm.column).to_s
            wm.destroy if val.blank? # Note: model must be reloaded to detect destroyed associations
          end
				else
          self.wiki_columns.each do |col|
            val = self.send(col).to_s
            if val.present?
              puts "inserting via allow_markup:#{col}:{val} "
              self.wiki_markups << ActsAsWiki::WikiMarkup.new(:markup => val, :column => col.to_s)
              dump
            end
          end
				end
        self.wiki_markups
			end
			
			def clone_markups(cloned_markable)
        self.wiki_markups.map do |wm|
          puts "inserting via clone_markups:#{wm.inspect}"
          cloned_markable.wiki_markups.build(:markup => wm.markup, :column => wm.column)
          dump
        end
			end
			
			def dissallow_markup!
				if !self.wiki_markups.empty?
					self.wiki_markups.each(&:destroy)
					self.wiki_markups = []
				end
			end
			
			def has_markup?
				!self.wiki_markups.empty?
			end
			
			def preview_text(column=nil)
				if self.has_markup? 
					column.nil? ? self.wiki_markups.first.markup : self.wiki_markup(column)
				else
					column.nil? ? self.send(wiki_columns.first) : self.send(column)
				end
			end
			
			def preview_markup(column=nil)
				self.has_markup? ? (self.wiki_markup(column || 'text').text rescue self.send("#{column || 'text'}")) : self.send("#{column || 'text'}")
			end

			def wiki_markup(column=nil)
				if self.wiki_markups.all?(&:new_record?)
					self.wiki_markups.select { |wm| wm.column == column }.first
				else
					column.nil? ? self.wiki_markups.first : self.wiki_markups.where(:column => column.to_s).first
				end
			end
			
			def cache_wiki_html
				if has_markup?
					wiki_columns.each do |col|
						if self.wiki_markup(col).nil?
              val = self.send(col)
              if val.present?
                wm = ActsAsWiki::WikiMarkup.new(:markup => val, :column => col.to_s)
                puts "inserting via cache_wiki_html:#{wm.inspect}"
                self.wiki_markups << wm
                dump
                self.send "#{col}=", wm.text
              end
						else
							self.send "#{col}=", self.wiki_markup(col).text
						end
					end
				end
				return true
			end
						
		end
	end
end
