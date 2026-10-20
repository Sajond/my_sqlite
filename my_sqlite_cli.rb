#!/usr/bin/env ruby
require_relative 'my_sqlite_request'
require 'readline'

#--------------------------------------------- MAIN ---------------------------

def main()
  usage_message()
  validate_file()
  cli_loop()
end
#--------------------------------------------- MAIN CONTROL METHODS ---------------------------

def usage_message()
  if ARGV.empty?
    puts 'Usage: ./my_sqlite.rb <csv db file'
    exit
  end
end

def print_welcome_message()
  puts 'MySQLite version 0.1 2026-09-22'
end

def validate_file()
  if File.file?(ARGV[0])
    print_welcome_message()
  else 
    puts 'no such file exists'
    exit
  end
end 

def cli_loop()
  loop do
    begin   
      
      input = Readline.readline('my_sqlite_cli>', true)
      break if input.nil? || input.strip == "quit"
      next if input.strip.empty?
      tokens = tokenise_input(input)
      request = build_request()
      
      #todo parse tokens no longer needs a true/false check BUT we need to change returning false to propogate errors
      success = parse_tokens(tokens, request)
      if success != true 
        puts 'Parsing failed'
        next 
      end 
      result = request.run
      
    rescue ArgumentError => e 
      puts "Error: #{e.message}"
    end
  end 
end

#--------------------------------------------- TOKENISER & HELPER ---------------------------

def tokenise_input(input)
  formatted_input = input.gsub(",", " , ").gsub(";", " ; ").gsub("(", " ( ").gsub(")", " ) ")
  tokens = formatted_input.split
  corrected_tokens = []
  correct_tokens(tokens, corrected_tokens)
  corrected_tokens
  
end 

#handles quoted data""
def correct_tokens(tokens, corrected_tokens)
  inside_quote = false
  combined = nil
  opening_char = nil
  tokens.each do |token|
    if token.start_with?("'", '"') && !token.end_with?("'",'"')
      opening_char = token[0]
      combined = token.dup.delete_prefix('"').delete_prefix("'")
      inside_quote = true
      #middle token branch
    elsif inside_quote == true && !token.start_with?("'",'"') && !token.end_with?("'",'"')
      if token == ","
        combined << token
      else  
        combined << " " << token
      end 
      
    elsif  inside_quote == true && token.end_with?("'",'"')
      combined << " " << token.delete_suffix('"').delete_suffix("'")
      corrected_tokens << "#{opening_char}#{combined}#{opening_char}"
      inside_quote = false
    else 
      corrected_tokens << token
    end
  end
end
#--------------------------------------------- REQUEST ---------------------------

def build_request()
  request = MySqliteRequest.new
end 
#---------------------------------------------PARSER (TOKENS)---------------------------

def parse_tokens(tokens, request)
  index = 0
  current_command = nil #SELECT, UPD, DEL 
  parsing_stage = nil
  
  
  while index < tokens.length
    case tokens[index]
      #todo DONE
    when 'SELECT'
      result = select(current_command, request, tokens, index)
      current_command = 'SELECT'
      parsing_stage = 'SELECT'
      index = result
      
      #DONE
    when 'WHERE'
      result = where(current_command, parsing_stage, request, tokens, index)
      index = result 
      parsing_stage = 'WHERE'

      #todo change error path to raise exception instead
    when 'FROM'
      result = from(current_command, parsing_stage, request, tokens, index)
      index = result 
      parsing_stage = 'FROM'
      
      #todo change error path to raise exception instead
    when 'JOIN'
      #JOIN table ON column_ a = column_b (only comes from SELECT)
      result = join(current_command, parsing_stage, request, tokens, index)
      return false if result == false 
      index = result 
      parsing_stage = 'JOIN'

      #todo change error path to raise exception instead
    when 'UPDATE'
      result = update(current_command, request, tokens, index)
      return false if result == false 
      index = result 
      current_command = 'UPDATE'
      parsing_stage = 'UPDATE'

      #todo change error path to raise exception instead
    when 'INSERT'
      result = insert(current_command, request, tokens, index)
      return false if result == false 
      index = result
      current_command = 'INSERT'
      parsing_stage = 'INSERT'

      #todo change error path to raise exception instead
    when 'SET'
      result = set(current_command, request, tokens, index)
      return false if result == false 
      index = result
      parsing_stage = 'SET'
      
      #todo change error path to raise exception instead
    when 'DELETE'
      result = delete(current_command, request, tokens, index)
      return false if result == false 
      index = result
      current_command = 'DELETE'
      parsing_stage = 'DELETE'
      
      #todo change error path to raise exception instead
    when 'ORDER' #by is +1 index
      result = order(current_command, parsing_stage, request, tokens, index)
      return false if result == false 
      index = result
      parsing_stage = 'ORDER'

      #todo change error path to raise exception instead
    when 'VALUES'
      result = values(current_command, parsing_stage, request, tokens, index)
      return false if result == false 
      index = result
      parsing_stage = 'VALUES'
      
    when ';'
      if index + 1 == tokens.length 
        break
      end 
    end
    if index+ 1 == tokens.length 
      break 
    end 
  end 
  true 
end 

#---------------------------------------------PROCESS COMMAND METHODS & HELPERS ---------------------------

#TODOD FINISH THIS TO RAISE EXCEPTION
def process_select(request, tokens, index)
  column_names = []
  index += 1 
  if tokens[index] == 'FROM'
    raise ArgumentError, "Expected: SELECT <column_name> FROM <file>"
  end 
  
  while tokens[index] != 'FROM'
    if tokens[index] == ','
      #do nothing
    elsif is_valid_data(tokens[index]) != true
      raise ArgumentError, "Expected: SELECT <column_name> FROM <file>"
    else
      raise ArgumentError, "Invalid SELECT column: #{tokens[index]}" unless valid_select_column?(tokens[index])
      column_names << tokens[index]
    end 
    index += 1
  end 
  request.select(column_names) 
  index
end 

def process_from(request, tokens, index)
  if tokens[index] == 'FROM'
    index += 1
  else 
    raise ArgumentError, "Expected FROM" 
  end 
  
  request.from(tokens[index])
  index += 1
  
  index
end 

def process_where(request, tokens, index)
  #for value after = the '' prefix and suffix must be .delete_suf/pref to be passed correctly
  #fixed value of 3 indexes so return 4th for next arg
  if valid_where_syntax(tokens, index) != true
    raise ArgumentError, "WHERE syntax, EXPECTED: WHERE <valid column name> = <valid column value>."
  end 
  filter_column = tokens[index + 1]
  filter_value = tokens[index + 3]
  filter_value = filter_value.delete_prefix("'").delete_suffix("'")
  request.where(filter_column, filter_value)
  index += 4
  index
end 

def valid_where_syntax(tokens, index)
  return false if tokens[index] != 'WHERE'
  return false if tokens[index + 1] == nil || tokens[index + 1] == ';'
  return false if tokens[index + 2] != '='
  return false if tokens[index + 3] == nil || tokens[index + 3] == ';'
  return false if !valid_word_format(tokens[index + 3])
  true 
end 

def process_delete(request, tokens, index)
  return false if tokens[index] != 'DELETE'
  return false if tokens[index + 1] != 'FROM'
  request.delete
  index + 1
end 

def process_update(request, tokens, index )
  if tokens[index] == 'UPDATE'
    index += 1
  else 
    puts 'Expected: UPDATE'
    return false
  end 
  
  return false unless is_valid_data(tokens[index])
  
  request.update(tokens[index])
  index += 1
  
  index
end 

def process_set(request, tokens, index)
  if tokens[index] == 'SET' && tokens[index + 1] != ','
    index += 1 
  else 
    puts 'Expected: SET <value name>'
    return false
  end 
  
  return false unless is_valid_data(tokens[index])
  
  set_values = {}
  result = collect_data_values(set_values, tokens, index)
  return false if result == false
  request.set(set_values)
  index = result 
  index
end 

def process_insert(request, tokens, index)
  if tokens[index] == 'INSERT' && tokens[index + 1] == 'INTO'
    index += 2
  else 
    puts 'Usage: INSERT INTO'
    return false
  end 
  
  if !is_valid_data(tokens[index]) || tokens[index + 1] != 'VALUES'
    return false 
  else 
    request.insert(tokens[index])
    index += 1 
  end 
  index
end 

def process_values(request, tokens, index)
  #cuyrrent index VALUES -1 = table name 
  table_name = tokens[index - 1]
  table_name += '.csv' unless table_name.end_with?('.csv')
  
  if tokens[index] == 'VALUES' && tokens[index + 1] == '('
    index += 1 #pointing now to (
  else 
    puts 'Expected: VALUES ( '
    return false
  end 
  return false if tokens[index] == nil || tokens[index] == ';'
  
  values = []
  result = collect_insert_values(values, tokens, index)
  return false if result == false 
  
  #match headers to collected data
  headers = CSV.foreach(table_name).first
  hash = {}
  headers.each_with_index do |column_name, index|
    hash[column_name] = values[index]
  end 
  
  request.values(hash)
  index = result 
  index
end 

def process_order(request, tokens, index)
  order_direction = nil
  column_name = nil
  
  if tokens[index] == 'ORDER' && tokens[index + 1] == 'BY'
    index +=2 
  else 
    puts 'Expected: ORDER BY <column name> <ASC/DESC>'
    return false
  end 
  
  #checks column name 
  if tokens[index] == nil || tokens[index] == ';'
    return false
  else 
    column_name = tokens[index]
    index +=1
  end 
  
  if tokens[index] == 'ASC'
    order_direction = :asc
  elsif tokens[index] == 'DESC'
    order_direction = :desc
  else 
    puts 'Expected: ORDER BY <column name> <ASC/DESC>'
    return false
  end 
  
  request.order(order_direction, column_name); 
  index += 1
  index
  
end 

def process_join(request, tokens, index)
  if tokens[index] == 'JOIN' && tokens[index + 2] == 'ON' && tokens[index + 4] == '='
    index += 1 
  else 
    puts 'USAGE: JOIN <table_name_b> ON <column_db_a> = <column_db_b>'
    return false
  end 
  
  return false unless is_valid_data(tokens[index])
  table_name_b = tokens[index]
  index += 2 
  
  return false unless is_valid_data(tokens[index])
  column_db_a = tokens[index]
  index += 2
  
  return false unless is_valid_data(tokens[index])
  column_db_b = tokens[index]
  index += 1
  
  request.join(column_db_a, table_name_b, column_db_b)
  index
end 

#---------------------------------------------PROCESS COMMAND HELPERS ---------------------------

def valid_word_format(input)
  if !input.start_with?("'") || !input.end_with?("'")
    puts 'values after = must be surrounded by single quotes'
    return false 
  else 
    return true 
  end 
end 

def collect_insert_values(values, tokens, index)
  while tokens[index] != ')'
    if tokens[index] == nil || tokens[index] == ';'
      return false
    end 
    
    if tokens[index] != '(' && tokens[index] != ','
      values << tokens[index].delete_prefix("'").delete_suffix("'").delete_prefix('"').delete_suffix('"')
    end 
    index += 1
  end 
  index += 1 #else parser hangs on ')'
end 

def collect_data_values(set_values,tokens, index)
  while tokens[index] != 'WHERE' && tokens[index] != ';'
    #collect the data into a hash 
    if tokens[index].nil? 
      return false
    end
    
    if tokens[index] == ','
      index += 1
    end 
    
    if tokens[index + 1 ] != '='
      puts 'Expected; Column = value'
      return false
    end 
    return false unless is_valid_data(tokens[index + 2])
    return false unless valid_word_format(tokens[index + 2])
    
    set_values[tokens[index]] = tokens[index + 2].delete_prefix("'").delete_suffix("'")
    index += 3
    
  end
  index
end 

def is_valid_data(position)
  if position.nil? || position == ';'
    return false 
  else 
    return true
  end 
end 
 
def valid_select_column?(token)
  invalid = ['WHERE', 'ORDER', 'JOIN', 'UPDATE', 'DELETE', 'INSERT', 'SET', 'VALUES']
  !invalid.include?(token)
end

#--------------------------------------------- CLEANED UP BRANCHES FOR CASE ---------------------------

def select(current_command, request, tokens, index)
  if current_command.nil? 
    result = process_select(request, tokens, index)
    result
  else 
    raise ArgumentError, "SELECT must always be first argument if called"
  end 
end

def where(current_command, parsing_stage, request, tokens, index)
  if ((current_command == 'SELECT' || current_command == 'DELETE') && parsing_stage == 'FROM') ||
    (current_command == 'SELECT' && parsing_stage == 'JOIN') ||
    (current_command == 'UPDATE' && parsing_stage == 'SET')
    result = process_where(request, tokens, index)
    return false if result == false
    result
  else 
    raise ArgumentError, "WHERE cannot be called after preceding/no command."
  end 
end

def from(current_command, parsing_stage, request, tokens, index)
  if (current_command == 'SELECT' || current_command == 'DELETE')  && 
    parsing_stage == current_command 
    result = process_from(request, tokens, index)
    result
  end 
end 

def join(current_command, parsing_stage, request, tokens, index)
  if current_command == 'SELECT' && parsing_stage == 'FROM'
    result = process_join(request, tokens, index)
    return false if result == false
    result
  else 
    return false 
  end 
end 

def update(current_command, request, tokens, index)
  if current_command.nil? 
    result = process_update(request, tokens, index)
    return false if result == false 
    result 
  else 
    return false
  end 
end 

def insert(current_command, request, tokens, index)
  if current_command.nil? 
    result = process_insert(request, tokens, index)
    return false if result == false
    result
  else 
    return false 
  end 
end 

def set(current_command, request, tokens, index)
  if current_command == 'UPDATE'
    result = process_set(request, tokens, index)
    return false if result == false
    result
  else 
    return false 
  end 
end 

def delete(current_command, request, tokens, index)
  if current_command.nil? 
    result = process_delete(request, tokens, index)
    return false if result == false 
    result
  else 
    return false
  end 
end 

def order(current_command, parsing_stage, request, tokens, index)
  if current_command == 'SELECT' && (parsing_stage == 'FROM' || parsing_stage == 'WHERE' || parsing_stage == 'JOIN')
    result = process_order(request, tokens, index)
    return false if result == false
    result
  else 
    return false
  end 
end 

def values(current_command, parsing_stage, request, tokens, index)
  if current_command == 'INSERT' && parsing_stage == 'INSERT'
    result = process_values(request, tokens, index)
    return false if result == false 
    result
  else 
    return false
  end 
end 


main()

