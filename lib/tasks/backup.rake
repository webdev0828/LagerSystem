# encoding: utf-8
require 'yaml'

rails_root = Rails.root.to_s
rails_env  = Rails.env
dbc = YAML.load_file("#{rails_root}/config/database.yml")[rails_env]

backup_dir = File.join(rails_root, 'backup')
temp_dir   = File.join(rails_root, 'tmp')

namespace :db do

  backup_time_utc = Time.now.utc

  desc "Backup the database. Options: RAILS_ENV=production"
  task :backup => :environment do

    # forbereder filer og mapper
    source_name = "backup_#{rails_env}_#{backup_time_utc.strftime("%Y-%m-%d_%H-%M-%S")}.sql"
    target_name = "backup_#{rails_env}_#{backup_time_utc.strftime("%Y-%m-%d_%H-%M-%S")}.sql.gz"
    source = File.join(temp_dir, source_name)
    target = File.join(backup_dir, target_name)

    puts "Backup started: #{Time.now}"

    puts "  Dumping database"

    # laver mysql dump
    system("mysqldump -u #{dbc['username']} #{dbc['database']} -Q --add-drop-table --add-locks=FALSE --lock-tables=TRUE > \"#{source}\"")

    puts "  Compressing file"

    # zipper fil
    File.open(source,"r") do |s|
      Zlib::GzipWriter.open(target) do |gz|
        gz.write(s.read)
      end
    end

    # cleanup
    FileUtils.rm_f(source)

    # sletter gamle filer
    count = cleanup_local(backup_dir, /^backup_#{rails_env}/, 30)

    # sender backup fil
    puts "  Sending backup via mail"
    SystemMailer.backup_mail(target, backup_time_utc).deliver

    puts "Backup finished: #{Time.now}"

  end

  desc "Retrieve the backups from external not preasent in local folder. Options: RAILS_ENV=production LOCAL=false"
  task :restore => :environment do

    # Advarsel hvis det ikke er development env
    if rails_env != 'development'
      puts
      puts "Du er ved at gendanne et miljø som ikke er development."
      print "Er du sikker? (y,n) "
      choice = STDIN.gets.chomp
      unless choice == 'y' || choice == 'yes'
        puts "Gendannelsen er annuleret"
        exit
      end
    end

    # forbereder filer og mapper
    temp_sql = File.join(temp_dir, "backup.sql")

    # henter valgt fil
    files = Dir.open(backup_dir, &:entries).grep(/^backup.*/)
    file  = choose_from_array(files)

    if file.nil?
      puts "Gendannelsen er annuleret"
      exit
    end

    puts "  dekomprimerer fil"
    # udpakker
    File.open(temp_sql, 'w') do |t|
      Zlib::GzipReader.open(File.join(backup_dir, file)) do |gz|
        t.write(gz.read)
      end
    end

    puts "  gendanner databasen"
    # restoring the database
    system("mysql --user=#{dbc["username"]} --password=#{dbc["password"]} --execute=\"source #{temp_sql}\" #{dbc["database"]}")

    puts "  fjerner midlertidige filer"

    # cleanup
    FileUtils.rm_f(temp_sql)

    puts
    puts "Gendannelsen er afsluttet"

  end

end

# Sletter de ældste filer fra en lokal mappe
def cleanup_local(dir, pattern, max=20)
  files = Dir.open(dir) { |d| d.entries.sort }.grep(pattern)
  (files - files.last(max)).each { |file| FileUtils.rm_f(File.join(dir, file)) } if files.size > max
  return [files.size, max].min
end

def choose_from_array(files)

  if files.empty?
    puts
    puts "Der er ingen backupfiler at gendanne fra."
    return nil
  end

  puts

  local_files = Hash.new
  (files.sort.reverse - %w{. ..}).each_with_index do |file,index|
    puts "(#{index + 1}) #{file}"
    local_files[(index+1).to_s] = file
  end

  puts
  print "Hvilken backup skal indlæses? (1,2,...) "
  choice = STDIN.gets.chomp
  unless local_files.key?(choice)
    puts
    puts "'#{choice}' er ikke et gyldigt valg."
    return nil
  end

  local_files[choice]
end