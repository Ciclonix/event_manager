require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone)
  phone.gsub!(/[^\d]/, '')
  return phone[-10..-1] if phone.length == 10 || (phone.length == 11 && phone[0] == "1")
  return "Wrong number"
end

def most_active_hour(reg_date)
  hours = reg_date.map { |x| DateTime.strptime(x, '%m/%d/%y %H:%M').hour }
  return hours.max_by { |i| hours.count(i) }
end

def most_active_day(reg_date)
  days = reg_date.map { |x| Date.strptime(x, '%m/%d/%y %H:%M').wday }
  week_days = { 0 => "Sunday",
                1 => "Monday", 
                2 => "Tuesday",
                3 => "Wednesday",
                4 => "Thursday",
                5 => "Friday",
                6 => "Saturday" }
  return week_days[ days.max_by { |i| days.count(i) } ]
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
reg_date = Array.new

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone_number(row[:homephone])
  reg_date << row[:regdate]
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

puts "The most active hour: #{most_active_hour(reg_date)}"
puts "The most active day: #{most_active_day(reg_date)}"