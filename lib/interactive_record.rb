require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true

        sql = "PRAGMA table_info('#{table_name}')"

        table_info = DB[:conn].execute(sql)
    #binding.pry
        column_names = []
        table_info.each do |row|
            column_names << row["name"]
        end
        column_names.compact
    end

    def initialize(options={})
        options.each do |property, value|
            self.send("#{property}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        values = []

    #self is an instance
    #self.class.method is a way to get the results of a method of the class of an instance
    #instance.col_name is a reader for that col_name, or attr

        self.class.column_names.each do |col_name|
            values << "'#{send(col_name)}'" unless send(col_name).nil?
        end
        values.join(", ")
    end

    def save
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
        DB[:conn].execute(sql)

        # Is it possible to use bound parameters?
        # sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (?)" 
        # DB[:conn].execute(sql, values_for_insert)

        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
        DB[:conn].execute(sql, name)
    end

    def self.find_by(att)
        att_key = att.keys.join
        att_value = att.values.join

        sql = "SELECT * FROM #{self.table_name} WHERE #{att_key} = ?"
        DB[:conn].execute(sql, att_value)
   end
    # def self.find_by(attribute_hash)
    #     value = attribute_hash.values.first
    #     formatted_value = value.class == Fixnum ? value : "'#{value}'"
    #     sql = "SELECT * FROM #{self.table_name} WHERE #{attribute_hash.keys.first} = #{formatted_value}"
    #     DB[:conn].execute(sql)
    # end
end