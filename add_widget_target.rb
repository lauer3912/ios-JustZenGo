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

# Get the widget extension path
widget_path = File.join(__dir__, 'FocusTimerWidget')
widget_group = project.main_group.find_subpath(File.join('FocusTimerWidget'), true)

# Create the target using the correct API
widget_target = project.new_target(:app_extension, 'FocusTimerWidget', :ios)

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

# Set deployment target
widget_target.deployment_target = '26.2'

# Set build settings
widget_target.build_configurations.each do |config|
    config.build_settings['INFOPLIST_FILE'] = 'FocusTimerWidget/Info.plist'
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.ggsheng.FocusTimer.widget'
    config.build_settings['SKIP_INSTALL'] = 'YES'
end

# Add widget extension to embedded binaries in main target
main_target = project.targets.find { |t| t.name == 'FocusTimer' }
if main_target
    widget_ref = widget_group
    main_target.add_dependency(widget_target)
end

# Save the project
project.save

puts "Successfully added FocusTimerWidget target!"
puts "Bundle ID: com.ggsheng.FocusTimer.widget"
