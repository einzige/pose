# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec' do
  watch(%r{^app/(controllers|helpers|lib|models|services)/(.+)\.rb$})       { |m| "spec/#{m[1]}/#{m[2]}_spec.rb" }
  watch(%r{^spec/(controllers|helpers|lib|models|services)/(.+)_spec\.rb$}) { |m| "spec/#{m[1]}/#{m[2]}_spec.rb" }
  watch(%r{^spec/(.+)_spec\.rb$})                                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^(spec/)?lib/(.+)\.rb$})                                         { |m| "spec/lib/#{m[2]}_spec.rb" }
  watch('app/controllers/application_controller.rb')                        { "spec/controllers" }
end

