#!/usr/bin/env ruby
# add_widget_target.rb - Add Widget Extension target to FocusTimer project

require 'xcodeproj'

project_path = File.join(__dir__, 'FocusTimer.xcodeproj')
project = Xcodeproj::Project.open(project_path)

# Check if target already exists
if project.targets.any? { |t| t.name == 'FocusTimerWidget' }
    puts "FocusTimerWidget target already exists!"
    exit 0
end

# Get main target and its build configuration list
main_target = project.targets.find { |t| t.name == 'FocusTimer' }
raise "Main target not found!" unless main_target

# Get the widget extension path
widget_path = File.join(__dir__, 'FocusTimerWidget')
widget_group = project.main_group.find_subpath(File.join('FocusTimerWidget'), true)

# Create the target
widget_target = project.new_target(:app_extension, 'FocusTimerWidget', :ios, '26.2', {:cFBundleShortVersionString => '1.0', :cFBundleVersion => '1'})

# Set product bundle identifier
widget_target.product_bundle_identifier = 'com.ggsheng.FocusTimer.widget'

# Add the source files
Dir.glob(File.join(widget_path, '*.swift')).each do |file|
    file_name = File.basename(file)
    file_ref = widget_group.new_file(file_name)
    widget_target.source_build_phase.add_file_reference(file_ref)
end

# Add Info.plist
info_plist_path = File.join(widget_path, 'Info.plist')
info_plist_ref = widget_group.new_file(info_plist_path)
widget_target.info_plist = info_plist_ref
widget_target.infoplist_path = info_plist_path

# Set deployment target to match main app
widget_target.deployment_target = '26.2'

# Add to build phases - embed in main app
main_target.frameworks_build_phase.add_file_reference(project.main_group.find_subpath('FocusTimerWidget', true).resolve)

# Save the project
project.save

puts "Successfully added FocusTimerWidget target!"
puts "Bundle ID: com.ggsheng.FocusTimer.widget"
