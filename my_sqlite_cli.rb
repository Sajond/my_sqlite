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
  formatted_input = input.gsub(",", " , ").gsub(";", " ; ")
  tokens = formatted_input.split
  corrected_tokens = []
  correct_tokens(tokens, corrected_tokens)
  corrected_tokens
  
end 


def correct_tokens(tokens, corrected_tokens)
  inside_quote = false
  combined = nil
  
  tokens.each do |token|
    if token.start_with?("'") && !token.end_with?("'")
      combined = token.dup
      inside_quote = true
      
    elsif inside_quote == true && !token.start_with?("'") && !token.end_with?("'")
      combined << " " << token 
      
    elsif  inside_quote == true && token.end_with?("'")
      combined << " " << token
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
      
    when 'UPDATE'
      
    when 'INSERT'
      
    when 'SET'
      
    when 'DELETE'
      
    when 'ORDER' #by is +1 index
      
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
  
  #todo Add '*' handling
  #todo SQL validation for malformed input?
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


main()