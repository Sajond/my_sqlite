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
    tokens.each do |token| 
      puts "#{token}"
    end 
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
main()


