#!/usr/bin/env ruby
require_relative 'my_sqlite_request'
require 'readline'


def main()
  usage_message()
  validate_file()
  cli_loop()
  
end

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
    input = Readline.readline('my_sqlite_cli>', true)
    break if input.nil? || input.strip == "quit"
    next if input.strip.empty?
    tokens = tokenise_input(input)
    p tokens
    request = build_request()
    
    success = parse_tokens(tokens, request)
    if success != true 
      puts 'Parsing failed'
      next 
    end 
    
    result = request.run
  end 
end

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
  
  tokens.each do |token|
    if token.start_with?("'", '"') && !token.end_with?("'",'"')
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
      corrected_tokens << combined
      inside_quote = false
    else 
      corrected_tokens << token
    end
  end
end

def build_request()
  request = MySqliteRequest.new
end 

def parse_tokens(tokens, request)
  index = 0
  current_command = nil #SELECT, UP, DEL 
  parsing_stage = nil
  
  while index < tokens.length
    #p [index, tokens[index], current_command, parsing_stage]
    case tokens[index]
      
    when 'SELECT'
      if current_command.nil? 
        current_command = 'SELECT'
        parsing_stage = 'SELECT'
      else 
        return false
      end 
      
      result = process_select(request, tokens, index)
      return false if result == false 
      index = result
      
    when 'WHERE'
      if((current_command == 'SELECT' || current_command == 'DELETE') && parsing_stage == 'FROM' || parsing_stage == 'JOIN') ||
        (current_command == 'UPDATE' && parsing_stage == 'SET')
        
        #process where
        result = process_where(request, tokens, index)
        return false if result == false
        parsing_stage = 'WHERE'
        index = result
      else 
        return false
      end 
      
    when 'FROM'
      if (current_command == 'SELECT' || current_command == 'DELETE')  && 
        parsing_stage == current_command 
        result = process_from(request, tokens, index)
        return false if result == false 
        parsing_stage = 'FROM'
        index = result
        
      else 
        return false 
      end 
      
    when 'JOIN'
      #JOIN table ON column_ a = column_b (only comes from SELECT)
      if current_command == 'SELECT' && parsing_stage == 'FROM'
        result = process_join(request, tokens, index)
        return false if result == false
        parsing_stage = 'JOIN'
        index = result
      else 
        return false 
      end 

      
    when 'UPDATE'
      if current_command.nil? 
        current_command = 'UPDATE'
        parsing_stage = 'UPDATE'
        result = process_update(request, tokens, index)
        return false if result == false 
        index = result 
      else 
        return false
      end 
      
    when 'INSERT'
      if current_command.nil? 
        current_command = 'INSERT'
        parsing_stage = 'INSERT'
        result = process_insert(request, tokens, index)
        return false if result == false
        index = result
      else 
        return false 
      end 
      
    when 'SET'
      if current_command == 'UPDATE'
        result = process_set(request, tokens, index)
        return false if result == false
        parsing_stage = 'SET'
        index = result 
      else 
        return false 
      end 

      
    when 'DELETE'
      if current_command.nil? 
        current_command = 'DELETE'
        parsing_stage = 'DELETE'
        result = process_delete(request, tokens, index)
        return false if result == false 
        index = result
      else 
        return false
      end 
      
      #todo: Test order by functionality
    when 'ORDER' #by is +1 index
      if current_command == 'SELECT' && (parsing_stage == 'FROM' || parsing_stage == 'WHERE' || parsing_stage == 'JOIN')
        parsing_stage = ' ORDER'
        result = process_order(request, tokens, index)
        return false if result == false
        index = result
      else 
        return false
      end 


    when 'VALUES'
      if current_command == 'INSERT' && parsing_stage == 'INSERT'
        result = process_values(request, tokens, index)
        return false if result == false 
        parsing_stage = 'VALUES'
        index = result
      else 
        return false
      end 
        
    when ';'
      #todo add completeness check for the semicolon, but now end of statement 
      if index + 1 == tokens.length 
        break
      end 
    end
  end 
  true 
end 



def process_select(request, tokens, index)
  column_names = []
  index += 1 
  if tokens[index] == 'FROM'
    puts 'Select value invalid'
    return false 
  end 
  
  while tokens[index] != 'FROM'
    if tokens[index] == ','
      #do nothing
    elsif tokens[index].nil? || tokens[index] == ';'
      return false
    else
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
    puts 'Expected FROM'
    return false
  end 
  
  if tokens[index].nil? || tokens[index] == ';'
    return false 
  else 
    request.from(tokens[index])
    index += 1
  end
  index
end 

def process_where(request, tokens, index)
  #for value after = the '' prefix and suffix must be .delete_suf/pref to be passed correctly
  #fixed value of 3 indexes so return 4th for next arg
  return false if tokens[index] != 'WHERE'
  return false if tokens[index + 1] == nil || tokens[index + 1] == ';'
  return false if tokens[index + 2] != '='
  return false if tokens[index + 3] == nil || tokens[index + 3] == ';'
  return false if !valid_word_format(tokens[index + 3])
  filter_column = tokens[index + 1]
  filter_value = tokens[index + 3]
  filter_value = filter_value.delete_prefix("'").delete_suffix("'")
  request.where(filter_column, filter_value)
  index += 4
  index
  #todo current acceptance of index 3 value without " ' " check and add
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

  if tokens[index].nil? || tokens[index] == ';'
    return false 
  else 
    request.update(tokens[index])
    index += 1
  end
  index
end 

def process_set(request, tokens, index)
  if tokens[index] == 'SET' && tokens[index + 1] != ','
    index += 1 
  else 
    puts 'Expected: SET <value name>'
    return false
  end 

  if tokens[index].nil? || tokens[index] == ';'
    return false 
  end 

  set_values = {}
  result = collect_data_values(set_values, tokens, index)
  return false if result == false
  request.set(set_values)
  index = result 
  index
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

    if tokens[index + 2].nil? || tokens[index + 2] == ';'
      return false 
    elsif !valid_word_format(tokens[index + 2]) 
      return false 
    else 
      set_values[tokens[index]] = tokens[index + 2].delete_prefix("'").delete_suffix("'")
      index += 3
    end 
    
  end
  index
end 

def valid_word_format(input)
  if !input.start_with?("'") || !input.end_with?("'")
    puts 'values must be surrounded by single quotes'
    return false 
  else 
    return true 
  end 
end 
#check this indexing
def process_insert(request, tokens, index)
  if tokens[index] == 'INSERT' && tokens[index + 1] == 'INTO'
  index += 2
  else 
    puts 'Usage: INSERT INTO'
    return false
  end 
  #insert body 
  if tokens[index] == nil || tokens[index] == ';'
    return false 
  else 
  request.insert(tokens[index])
  index += 1 
  end 
end 


def process_values(request, tokens, index)
  if tokens[index] == 'VALUES' && tokens[index + 1] == '('
    index += 1 #pointing now to (
  else 
    puts 'Expected: VALUES ( '
    return false
  end 
  return false if tokens[index] == nil || tokens[index] == ';'
  
  values = []
  result = collect_insert_values(values, tokens, index)
  p values
  return false if result == false 
  request.values(values)
  index = result 
  index
end 


def collect_insert_values(values, tokens, index)
  while tokens[index] != ')'
    if tokens[index] == nil || tokens[index] == ';'
      return false
    end 

    if tokens[index] != '(' && tokens[index] != ','
      values << tokens[index]
    end 
    index += 1
  end 
  index += 1 #else parser hangs on ')'
end 

def process_order(request, tokens, index)
  order_direction = nil
  column_name = nil

  if tokens[index] == 'ORDER' && tokens[index + 1] = 'BY'
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

#JOIN table ON column_ a = column_b (only comes from SELECT)

def process_join(request, tokens, index)
  if tokens[index] == 'JOIN' && tokens[index + 2] == 'ON' && tokens[index + 4] == '='
    index += 1 
  else 
    puts 'USAGE: JOIN <table_name_b> ON <column_db_a> = <column_db_b>'
    return false
  end 

  table_name_b = is_valid_data(tokens[index])
  return false if table_name_b == false 
  index += 2

  column_db_a = is_valid_data(tokens[index])
  return false if column_db_a == false 
  index += 2

  column_db_b = is_valid_data(tokens[index])
  return false if column_db_b == false 
  index += 1
  request.join(column_db_a, table_name_b, column_db_b)
  index
end 

  def is_valid_data(position)
    if position.nil? || position == ';'
      return false 
    else 
      return position
    end 
  end 
main()