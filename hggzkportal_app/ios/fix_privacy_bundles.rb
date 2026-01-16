#!/usr/bin/env ruby
# frozen_string_literal: true

# CRITICAL FIX: Remove privacy bundle dependencies that cause build failures
# This script fixes the Xcode 15+ privacy bundle issue with Flutter plugins
# Run this after pod install: ruby ios/fix_privacy_bundles.rb

require 'xcodeproj'

def fix_privacy_bundles
  project_path = File.exist?('Pods/Pods.xcodeproj') ? 'Pods/Pods.xcodeproj' : 'Runner.xcodeproj'
  
  unless File.exist?(project_path)
    puts "❌ Error: #{project_path} not found!"
    exit 1
  end
  
  project = Xcodeproj::Project.open(project_path)
  puts "🔧 Patching Xcode project: #{project_path}"
  
  modified = false
  
  # Find and remove privacy bundle references
  project.targets.each do |target|
    next unless target.name.match?(/privacy$/i)
    
    puts "🔍 Processing target: #{target.name}"
    
    # Remove privacy bundles from Copy Resources phase
    phases_to_remove = []
    target.build_phases.each do |build_phase|
      if build_phase.is_a?(Xcodeproj::Project::Object::PBXResourcesBuildPhase) ||
         build_phase.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
        
        files_to_remove = []
        
        build_phase.files.each do |file|
          if file.display_name&.include?('privacy.bundle') ||
             file.file_ref&.path&.include?('privacy.bundle')
            puts "  ❌ Removing problematic privacy bundle: #{file.display_name || file.file_ref&.path}"
            files_to_remove << file
            modified = true
          end
        end
        
        files_to_remove.each { |file| build_phase.files.delete(file) }
      end

      if build_phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
        phases_to_remove << build_phase
      end
    end

    phases_to_remove.each do |phase|
      target.build_phases.delete(phase)
      modified = true
    end

    target.build_configurations.each do |config|
      config.build_settings['PRODUCT_TYPE'] = 'com.apple.product-type.bundle'
      config.build_settings['SKIP_INSTALL'] = 'YES'
      config.build_settings['WRAPPER_EXTENSION'] = 'bundle'

      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
      config.build_settings['EMBEDDED_CONTENT_CONTAINS_SWIFT'] = 'NO'
      config.build_settings['DEFINES_MODULE'] = 'NO'

      config.build_settings['EXECUTABLE_NAME'] = ''
      config.build_settings['MACH_O_TYPE'] = 'none'

      config.build_settings['CODE_SIGN_IDENTITY'] = ''
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'

      config.build_settings.delete('LD_RUNPATH_SEARCH_PATHS')
      config.build_settings.delete('DYLIB_INSTALL_NAME_BASE')
      config.build_settings.delete('LIBRARY_SEARCH_PATHS')
      config.build_settings.delete('OTHER_LDFLAGS')
      config.build_settings.delete('SWIFT_VERSION')
      config.build_settings.delete('SWIFT_COMPILATION_MODE')
      config.build_settings.delete('SWIFT_ACTIVE_COMPILATION_CONDITIONS')
      config.build_settings.delete('SWIFT_INCLUDE_PATHS')
    end
    modified = true
    
    # Remove privacy bundle file references
    project.files.each do |file_ref|
      if file_ref.path&.include?('privacy.bundle')
        puts "  ❌ Removing file reference: #{file_ref.path}"
        file_ref.remove_from_project
        modified = true
      end
    end
  end

  support_files_dir = File.join(__dir__, 'Pods', 'Target Support Files')
  if Dir.exist?(support_files_dir)
    Dir.glob(File.join(support_files_dir, '**', '*.xcfilelist')).each do |file|
      begin
        original = File.read(file)
        filtered = original.lines.reject do |line|
          line.include?('PrivacyInfo.xcprivacy') || line.match?(/privacy\.bundle/i) || line.match?(/_privacy/i)
        end.join
        if filtered != original
          File.write(file, filtered)
          modified = true
        end
      rescue StandardError
      end
    end
  end
  
  if modified
    project.save
    puts "✅ Successfully removed privacy bundle dependencies!"
  else
    puts "ℹ️ No privacy bundle dependencies found to remove."
  end
  
rescue StandardError => e
  puts "❌ Error fixing privacy bundles: #{e.message}"
  puts e.backtrace
  exit 1
end

# Run if called directly
if __FILE__ == $PROGRAM_NAME
  Dir.chdir(File.dirname(__FILE__))
  fix_privacy_bundles
end
