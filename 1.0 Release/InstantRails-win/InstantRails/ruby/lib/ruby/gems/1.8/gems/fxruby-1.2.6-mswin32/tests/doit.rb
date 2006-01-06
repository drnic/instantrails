Dir.glob("*.rb") do |filename|
  system("cp #{filename} #{filename+'.bak'}")
  system("sed -e \"s/require 'fox12'/require 'fox12'/g\" #{filename+'.bak'} > #{filename}")
end

