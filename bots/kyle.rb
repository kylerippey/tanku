class Kyle < RTanque::Bot::Brain
  NAME = 'kyle'
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
    rotate_tank(3)
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
        @rotation_rate = (diff > 0.0 ? 4 : -4)
      end

      @rotation_rate ||= -4
      rotate_turret_and_radar(@rotation_rate)
    end
  end

  def fire_power_control
    if target && target.distance < 100
      3.0
    else
      10.0
    end
  end

  def destroy
    if target
      # Make sure we don't waste shots by firing before our turret can come around
      diff = sensors.turret_heading.delta(predicted_target_heading).abs
      if diff < 6.0 * RTanque::Heading::ONE_DEGREE
        command.fire(fire_power_control)
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

        number_of_ticks = target.distance / fire_power_control / Math::PI

        future_target_position = calculate_position(last_target_position, target_path, distance_traveled * number_of_ticks)
        our_future_position = calculate_position(sensors.position, sensors.heading, sensors.speed)
        our_future_position.heading(future_target_position)
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
