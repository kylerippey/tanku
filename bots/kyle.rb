class KyleBot < RTanque::Bot::Brain
  NAME = 'kyle_bot'
  include RTanque::Bot::BrainHelper

  @last_position = nil
  @last_heading = nil

  def tick!
    ## main logic goes here
    drive

    seek

    destroy

    record_target_history

    #print_info
  end

  protected

  def drive
    command.speed = 10
    rotate_tank
  end

  def seek
    if target
      command.radar_heading = target.heading
      command.turret_heading = predicted_target_heading
    else
      if target_history
        last_target_heading = target_history[:heading]
        # We had a target and we lost it.
        # Should we search left or right?

        diff = sensors.radar_heading.delta(last_target_heading)

        if diff > 0.0
          @rotation_rate = 3
        else
          @rotation_rate = -3
        end
      end

      @rotation_rate ||= -3
      rotate_turret_and_radar(@rotation_rate)
    end
  end

  def destroy
    if target
      if target.distance < 100
        command.fire(3)
      else
        command.fire(10)
      end
    end
  end

  def print_info
    puts "----- System Status -----"
    puts "Position: #{sensors.position.x}, #{sensors.position.y}"
    puts "Heading: #{sensors.heading.to_degrees}"
    puts "Radar Heading: #{sensors.radar_heading.to_degrees}"
    puts "Turret Heading: #{sensors.turret_heading.to_degrees}"
    puts "Gun Energy: #{sensors.gun_energy}"
    if target
      puts "\t----- Current Target -----"
      puts "\tName: #{target.name}"
      puts "\tDistance #{target.distance}"
      puts "\tHeading: #{target.heading.to_degrees}"
      puts "\tPosition: #{target_position.x}, #{target_position.y}"
    end
    puts ""
  end

  def predicted_target_heading
    if target
      if target_history
        last_target_position = target_history[:position]
        new_target_position = target_position

        target_path = last_target_position.heading(new_target_position)
        distance_traveled = last_target_position.distance(new_target_position)

        number_of_ticks = target.distance / 10.0 / 2

        future_position = calculate_position(last_target_position, target_path, distance_traveled * number_of_ticks)

        RTanque::Heading.new_between_points(sensors.position, future_position)
      else
        target.heading
      end
    end
  end

  def target
    sensors.radar.first
  end

  def target_history
    @target_history
  end

  def record_target_history
    if target
      @target_history = {:name => target.name, :distance => target.distance, :heading => target.heading, :position => target_position}
    else
      @target_history = nil
    end
  end

  def target_position
    if target
      calculate_position(sensors.position, target.heading, target.distance)
    else
      nil
    end
  end

  def calculate_position(initial_position, heading, distance)
    RTanque::Point.new(
      initial_position.x + Math.sin(heading) * distance,
      initial_position.y + Math.cos(heading) * distance,
      self.arena
    )
  end

  def rotate_turret_and_radar(rotation=1)
    rotate_turret(rotation)
    rotate_radar(rotation)
  end

  def rotate_tank(rotation=1)
    command.heading = sensors.heading + RTanque::Heading.new_from_degrees(rotation)
  end

  def rotate_turret(rotation=1)
    command.turret_heading = sensors.turret_heading + RTanque::Heading.new_from_degrees(rotation)
  end

  def rotate_radar(rotation=1)
    command.radar_heading = sensors.radar_heading + RTanque::Heading.new_from_degrees(rotation)
  end
end
