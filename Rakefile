desc 'Default task: run all tests'
task :default => [:test]

task :test do
  exec "thor monk:test"
end

desc "This task is called by the Heroku cron add-on"
task :cron do
  expunge
end

desc "Delete all expired secrets from Redis database"
task :expunge do
  require "./init"
  
  expired = Secret.expired
  expired.each do |secret|
    secret.delete
  end
  
  puts "#{expired.length} secrets expunged."
end