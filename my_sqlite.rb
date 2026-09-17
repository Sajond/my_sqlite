=begin 

# SELECT Query 
# INSERT Query 
# UPDATE
# DELETE 

:none
:select
:insert
:update
:delete


=end 
require 'csv'

class MySqliteRequest
    def initialize
        @type_of_request = :none 
        @selected_columns = []
        @filter_column = nil
        @filter_value = nil
        @source_table = nil 
        @join_source_column = nil
        @join_target_column = nil 
        @join_table = nil
        @order_direction = :asc
        @order_column = nil
        @insert_values = {}
        @update_values = {}
    end 
    #select types 
    def from(table_name)
        @source_table = table_name
        self
    end 

    def select(column_name)
        @type_of_request = :select
        @selected_columns = Array(column_name)
        self
    end 

    def where(column_name, criteria)
        @filter_column = column_name
        @filter_value = criteria
        self
    end 

    def join(column_on_db_a, filename_db_b, column_on_db_b)
        @join_source_column = column_on_db_a
        @join_table = filename_db_b
        @join_target_column = column_on_db_b
        self
    end 
    def order(order, column_name)
        @order_direction = order 
        @order_column = column_name
        self
    end 
#INSERT 
    def insert(table_name)
        @type_of_request = :insert
        @source_table = table_name
        self
    end 

    def values(data)
        @insert_values = data
        self
    end 

    def update(table_name)
        @type_of_request = :update
        @source_table = table_name
        self 
    end 

    def set(data)
        @update_values = data
        self
    end 

    def delete
        @type_of_request = :delete
        self
    end 

    def run 
        case @type_of_request
        when :select
            result = build_requested_results()
            #order || ORDER BY @order_column in @order_direction
            if @order_column != nil
                result = order_results(result)
            end

        result

        when :insert 

        when :update

        when :delete
        end 

    end 

end

def _main()
    request = MySqliteRequest.new
    request = request.from('nba_player_data.csv')
    request = request.select('name')
    request = request.where('college', 'University of Kansas')
    request = request.order('hello', 'name') #use :ac or :desc for now NOT STRING
    result = request.run
    result.each do |line| 
        puts "#{line}"
    end 
end 

def build_requested_results()
    result = []
        puts "Asked for #{@filter_column} and #{@filter_value}" 
        CSV.foreach(@source_table, headers: true) do |row|
            if @filter_column == nil || row[@filter_column] == @filter_value
            matching_row = {}
            @selected_columns.each do |column| 
            matching_row[column] = row[column]
            end
            result << matching_row
        end
    end 
  result
end

#typo in qwasar? order to be ASC or Description? (DESC)
def order_results(result)
    
    sorted_result = result.sort_by do |row|
        row[@order_column]
    end

     if @order_direction == :desc || @order_direction == :description
        sorted_result = sorted_result.reverse 
     end

        sorted_result
end

_main()

