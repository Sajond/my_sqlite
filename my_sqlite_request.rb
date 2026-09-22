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
    #---------------------------------------
    def insert(table_name)
        @type_of_request = :insert
        @source_table = table_name
        self
    end 
    
    def values(data)
        @insert_values = data
        self
    end 
    #---------------------------------------
    
    def update(table_name)
        @type_of_request = :update
        @source_table = table_name
        self 
    end 
    
    def set(data)
        @update_values = data
        self
    end 
    #-----------------------------------------
    def delete
        @type_of_request = :delete
        self
    end 
    
    def run 
        case @type_of_request
        when :select
            
            result = run_select()
            
            #todo debugging print to see ouput remove before testing 
            result.each do |line| 
                puts "#{line}"
            end 
            
        when :insert 
            run_insert()
            
        when :update
            run_update()
            
        when :delete
            run_delete()
        end 
        
    end 
    
end

def _main()
    #request = MySqliteRequest.new
    #------------------------select---------------------
    #request = request.from('test.csv')
    #request = request.select('*')
    #request = request.where('weight', '300')
    
    #------------------------join---------------------
    # request = request.order('asc', 'name') #use :ac or :desc for now NOT STRING
    #request = request.join('name','nba_players.csv', 'Player' )
    
    #------------------------insert---------------------
    #request = request.insert('test.csv')
    #request = request.values({"name" => "Sam", "year_start" => "120", "position" => "Missionary"})
    
    #------------------------update---------------------
    #request = request.update('small_test.csv')
    #request = request.set( "name" => "voldemort")
    #request = request.where('year_start', '2024')
    
    #------------------------delete---------------------
    #request = request.from('small_test.csv')
    #request = request.where('college', 'Duke University')
    #request = request.delete()
    #result = request.run

    #chain test
    MySqliteRequest.new
    .from('test.csv')
    .select('*')
    .where('name', 'Test Player')
    .run
    
end 

def build_requested_results(rows)
    result = []
    puts "Asked for #{@filter_column} and #{@filter_value}" 
    rows.each do |row|
        if @filter_column == nil || row[@filter_column] == @filter_value
            matching_row = {}
            
            if @selected_columns[0] == '*'
                row.each do |column, value|
                    matching_row[column] = value
                end
            else
                @selected_columns.each do |column| 
                    matching_row[column] = row[column]
                end 
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

def join_sources()
    joined_result = []
    join_rows = CSV.read(@join_table, headers: true)
    join_lookup = {}
    
    join_rows.each do |join_row|
        join_lookup[join_row[@join_target_column]] = join_row
    end
    
    CSV.foreach(@source_table, headers: true) do |source_row|
        join_row = join_lookup[source_row[@join_source_column]]
        
        if join_row != nil
            
            joined_row = {}
            source_row.each do |column, value| 
                joined_row[column] = value
            end
            join_row.each do |column, value|
                joined_row[column] = value
            end 
            joined_result << joined_row
        end
    end
    joined_result
end 


def run_select()
    if @join_table != nil
        rows = join_sources()
    else 
        rows = CSV.read(@source_table, headers: true)
    end 
    
    result = build_requested_results(rows)
    if @order_column != nil
        result = order_results(result)
    end
    
    result
end

#TODO decide what happens when the CSV has a header that is missing from the input Hash.
#table name can be any csv we have
def build_new_row()
    data_to_insert= @insert_values
    new_row = []
    
    headers = CSV.foreach(@source_table).first
    headers.each do |current_header|
        new_row << data_to_insert[current_header]
    end
    new_row
end

def append_new_row(new_row)
    CSV.open(@source_table, "a") do |csv_to_insert| 
        csv_to_insert << new_row
    end
end 

def run_insert()
    row_to_append = build_new_row()
    append_new_row(row_to_append)
end 

#returns modified rows based on the set(data)insert values
def update_rows()
    data_for_update = @update_values
    rows = CSV.read(@source_table, headers: true)
    #change all or change row
    rows.each do |row|
        if @filter_column == nil || row[@filter_column] == @filter_value
            #change row logic
            data_for_update.each do |column, value| 
                row[column] = value
            end
            
        end 
    end
    rows
end 

def run_update()
    updated_rows = update_rows()
    rewrite_csv_rows(updated_rows)
end 

def rewrite_csv_rows(updated_rows)
    CSV.open(@source_table, "w") do |new_csv|
        new_csv << updated_rows.headers
        updated_rows.each do |row|
            new_csv << row.fields
        end
    end
end



def build_preserved_rows()
    rows = CSV.read(@source_table, headers: true)
    preserved_rows = []
    rows.each do |row| 
        #rows marked for deletion 
        if @filter_column == nil || row[@filter_column] == @filter_value
        else 
            #not marked for deletion = add to preservation 
            preserved_rows << row
        end
    end
    preserved_rows
end

#! header preservation wont work, check update method
def write_preserved_rows(preserved_rows)
    headers = CSV.foreach(@source_table).first
    CSV.open(@source_table, "w") do |new_csv|
        new_csv << headers
        preserved_rows.each do |row|
            new_csv << row.fields
        end
    end
end

def run_delete()
    preserved_rows = build_preserved_rows()
    write_preserved_rows(preserved_rows)
end

if __FILE__ == $PROGRAM_NAME
    _main
end
#? UPDATE
#? can change multiple columns in a single update, no where = all, where/ specific

=begin read the existing CSV rows.

For each row, determine whether it matches WHERE. If there is no WHERE, every row matches.

For each matching row, apply the column/value pairs from set(data). Preserve all unspecified columns.

Write the resulting rows back to the CSV.
#hash[key] = value


MySQLite TODO
Clean/test SELECT
Add SELECT *
Finish/test JOIN
Implement INSERT
Implement UPDATE
Implement DELETE
Test all Part 00 methods
Clean up code
Build Part 01 CLI
Final testing

@source_table       → String        → "nba_player_data.csv"

@selected_columns   → Array         → ["name", "height"]

@filter_column      → String / nil  → "college"

@filter_value       → String / nil  → "University of Kansas"

rows                → collection    → many CSV rows

row                 → CSV::Row      → one player's row

matching_row        → Hash          → {"name"=>"...", "height"=>"..."}

result              → Array         → many matching_row hashes

=end
#todo project states each row must have an ID? -to check